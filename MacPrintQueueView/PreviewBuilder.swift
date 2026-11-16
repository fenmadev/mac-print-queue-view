import AppKit
import CoreText
import ImageIO
import PDFKit

/// Converts the raw documents of a print job into a single PDF for the preview.
///
/// Supported: PDF (which macOS apps almost always send to the queue),
/// images (JPEG, PNG, TIFF, GIF, HEIC, …) and plain text.
/// Other formats (such as PostScript or printer-specific data) can no longer be
/// rendered by macOS itself; a clear message is shown for those.
enum PreviewBuilder {

    enum Kind { case pdf, image, text, postscript, unsupported }

    /// The preview of a job: the pages that could be rendered, plus a description of every
    /// document of the job that could not be rendered (empty when the preview is complete).
    struct Preview: Sendable {
        let pdfData: Data
        let problems: [String]
    }

    /// Builds the preview. Runs on a background thread; returns Data because PDFDocument must
    /// not be shared between threads.
    ///
    /// Every document is rendered separately. If some documents, or some images within a
    /// multi-image document, cannot be rendered, the readable pages are returned together with
    /// a description of what is missing, so the user is never shown a partial preview as if it
    /// were complete. If no document can be rendered, an error is thrown.
    static func makePreview(from documents: [JobDocument]) throws -> Preview {
        let combined = PDFDocument()
        var problems: [String] = []
        for (index, document) in documents.enumerated() {
            func record(_ reason: String) {
                problems.append(documents.count > 1
                    ? String(localized: "Document \(index + 1) of \(documents.count): \(reason)")
                    : reason)
            }
            do {
                let part = try render(document)
                for pageIndex in 0..<part.pdf.pageCount {
                    if let page = part.pdf.page(at: pageIndex)?.copy() as? PDFPage {
                        combined.insert(page, at: combined.pageCount)
                    }
                }
                if let missing = part.missing { record(missing) }
            } catch {
                record(error.localizedDescription)
            }
        }
        guard combined.pageCount > 0, let data = combined.dataRepresentation() else {
            if documents.count == 1, let only = problems.first {
                throw CUPSError(only)
            }
            let header = String(localized: "None of the documents in this job can be displayed.")
            throw CUPSError(([header] + problems).joined(separator: "\n"))
        }
        return Preview(pdfData: data, problems: problems)
    }

    /// Renders the first page of the first document as a small PNG (longest side
    /// `maxPixelSize` pixels), for the thumbnails in the job list.
    static func makeThumbnailPNG(from documents: [JobDocument], maxPixelSize: CGFloat) throws -> Data {
        // Keep a reference to the document: a PDFPage cannot be drawn once its document is gone.
        guard let first = documents.first else {
            throw CUPSError(String(localized: "The document contains no pages to show."))
        }
        let document = try render(first, checkCompleteness: false).pdf
        guard let page = document.page(at: 0) else {
            throw CUPSError(String(localized: "The document contains no pages to show."))
        }
        defer { withExtendedLifetime(document) {} }
        let bounds = page.bounds(for: .cropBox)
        let scale = maxPixelSize / max(bounds.width, bounds.height, 1)
        let image = page.thumbnail(of: CGSize(width: bounds.width * scale, height: bounds.height * scale), for: .cropBox)
        guard let tiff = image.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
            throw CUPSError(String(localized: "The document cannot be displayed."))
        }
        return png
    }

    /// Renders one document, or throws an error that says why it cannot be shown. `missing`
    /// describes content of the document that could not be rendered (nil when complete).
    /// Thumbnails pass `checkCompleteness: false`: they show only the first page and skip the
    /// extra TIFF check.
    private static func render(_ document: JobDocument, checkCompleteness: Bool = true) throws -> (pdf: PDFDocument, missing: String?) {
        guard !document.data.isEmpty else {
            throw CUPSError(String(localized: "The document is empty."))
        }
        let rendered: PDFDocument?
        var missing: String?
        switch kind(of: document) {
        case .pdf:
            guard let pdf = PDFDocument(data: document.data) else {
                throw CUPSError(String(localized: "The PDF document in the queue could not be read."))
            }
            if pdf.isLocked {
                throw CUPSError(String(localized: "The PDF document is password protected."))
            }
            rendered = pdf
        case .image:
            let image = pdfFromImage(document.data, checkCompleteness: checkCompleteness)
            rendered = image?.document
            missing = image?.missing
        case .text:
            rendered = pdfFromText(document.data)
        case .postscript:
            throw CUPSError(String(localized: "This document is PostScript; macOS can no longer render that format itself."))
        case .unsupported:
            throw CUPSError(String(localized: "Document format “\(document.format)” cannot be displayed."))
        }
        guard let rendered, rendered.pageCount > 0 else {
            throw CUPSError(String(localized: "Document format “\(document.format)” cannot be displayed."))
        }
        return (rendered, missing)
    }

    static func kind(of document: JobDocument) -> Kind {
        let data = document.data
        let format = document.format.lowercased()
        if data.starts(with: Array("%PDF".utf8)) { return .pdf }
        // A text label wins over the "%!" signature: plain text may start with those characters.
        if format.hasPrefix("text/") { return .text }
        if data.starts(with: Array("%!".utf8)) { return .postscript }

        switch format {
        case "application/pdf": return .pdf
        case "application/postscript", "application/vnd.cups-postscript": return .postscript
        case _ where format.hasPrefix("image/") && !format.contains("raster") && !format.contains("pwg"):
            return .image
        case _ where format.hasPrefix("text/"):
            return .text
        default:
            // Unknown label: detect images by their content.
            if let source = CGImageSourceCreateWithData(data as CFData, nil),
               CGImageSourceGetType(source) != nil, CGImageSourceGetCount(source) > 0 {
                return .image
            }
            return .unsupported
        }
    }

    /// Renders every image of an image document as a page. `missing` is set when fewer pages
    /// were rendered than the document contains: an image that cannot be decoded, or (for TIFF)
    /// images in the file that ImageIO does not report at all. The TIFF count is skipped when
    /// `checkCompleteness` is false or when ImageIO reports no image (the document then cannot
    /// be displayed anyway).
    private static func pdfFromImage(_ data: Data, checkCompleteness: Bool) -> (document: PDFDocument, missing: String?)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let reported = CGImageSourceGetCount(source)
        var expected = reported
        if checkCompleteness, reported > 0,
           let type = CGImageSourceGetType(source), type as String == "public.tiff",
           let inFile = tiffImageCount(data) {
            expected = max(expected, inFile)
        }
        let document = PDFDocument()
        for index in 0..<reported {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil),
                  let page = PDFPage(image: NSImage(cgImage: cgImage, size: .zero)) else { continue }
            document.insert(page, at: document.pageCount)
        }
        let shown = document.pageCount
        let missing = shown < expected
            ? String(localized: "Only \(shown) of the \(expected) images in this document can be displayed.")
            : nil
        return (document, missing)
    }

    /// Counts the full-resolution images in a TIFF file by following its chain of image file
    /// directories (IFDs), independently of ImageIO. Reduced-resolution images (thumbnails) and
    /// transparency masks (NewSubfileType bits 0 and 2) are not counted. A directory that the
    /// chain points to but that lies outside the file is counted, because the file claims an
    /// image that cannot be read. Returns nil if the data is not a TIFF file.
    ///
    /// The work is bounded for crafted files: at most 10,000 directories, and per directory at
    /// most the first 255 entries are searched for NewSubfileType (254). In a valid file the
    /// entries are sorted by tag, so tag 254 is always among them; files with unsorted tags are
    /// searched as well.
    static func tiffImageCount(_ data: Data) -> Int? {
        let bytes = [UInt8](data)
        guard bytes.count >= 8 else { return nil }
        let little: Bool
        switch (bytes[0], bytes[1]) {
        case (0x49, 0x49): little = true
        case (0x4D, 0x4D): little = false
        default: return nil
        }
        func read(_ offset: Int, _ size: Int) -> UInt64? {
            guard offset >= 0, size <= 8, offset <= bytes.count - size else { return nil }
            var value: UInt64 = 0
            for i in 0..<size {
                let byte = UInt64(bytes[offset + (little ? size - 1 - i : i)])
                value = value << 8 | byte
            }
            return value
        }
        let big: Bool
        switch read(2, 2) {
        case 42: big = false
        case 43: big = true
        default: return nil
        }
        // Classic TIFF: 2-byte entry count, 12-byte entries, 4-byte offsets.
        // BigTIFF: 8-byte entry count, 20-byte entries, 8-byte offsets.
        let countSize = big ? 8 : 2, entrySize = big ? 20 : 12, offsetSize = big ? 8 : 4
        let valueOffset = big ? 12 : 8
        guard var next = read(big ? 8 : 4, offsetSize) else { return nil }
        var visited = Set<UInt64>()
        var images = 0
        while next != 0, visited.insert(next).inserted, visited.count <= 10_000 {
            guard next <= UInt64(Int.max), let entries = read(Int(next), countSize),
                  entries <= UInt64(bytes.count) else {
                images += 1 // the chain points to an image that cannot be read
                break
            }
            let start = Int(next) + countSize
            let end = start + Int(entries) * entrySize
            guard let following = read(end, offsetSize) else {
                images += 1
                break
            }
            var auxiliary = false
            for entry in 0..<min(Int(entries), 255) {
                let at = start + entry * entrySize
                guard let tag = read(at, 2) else { break }
                guard tag == 254, let type = read(at + 2, 2) else { continue }
                // SHORT (3) is 2 bytes, LONG8 (16, BigTIFF only) 8 bytes, LONG (4) and others 4 bytes.
                let size = type == 3 ? 2 : (type == 16 && big ? 8 : 4)
                auxiliary = (read(at + valueOffset, size) ?? 0) & 0b101 != 0
                break
            }
            if !auxiliary { images += 1 }
            next = following
        }
        return images
    }

    /// Lays out text over multiple A4 pages in a monospaced font.
    private static func pdfFromText(_ data: Data) -> PDFDocument? {
        let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
        let attributed = NSAttributedString(string: text.isEmpty ? " " : text, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor.black,
        ])

        let output = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 in points
        guard let consumer = CGDataConsumer(data: output as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let textPath = CGPath(rect: mediaBox.insetBy(dx: 50, dy: 50), transform: nil)
        var location = 0
        repeat {
            context.beginPDFPage(nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: location, length: 0), textPath, nil)
            CTFrameDraw(frame, context)
            context.endPDFPage()
            let visible = CTFrameGetVisibleStringRange(frame).length
            if visible == 0 { break }
            location += visible
        } while location < attributed.length
        context.closePDF()

        return PDFDocument(data: output as Data)
    }
}
