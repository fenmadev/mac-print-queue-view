// Phase 01 evidence E02: thumbnails at the new render size (RM-001) and the first-page document
// of a grid block (RM-003), with the app's PreviewBuilder. In-memory documents only; no CUPS call.
// Build from the project root:
//   swiftc -O MacPrintQueueView/CUPSClient.swift MacPrintQueueView/PreviewBuilder.swift \
//     MacPrintQueueView/QueueLayout.swift _docs/phases/phase-01/evidence/E02/main.swift -o <tmp>/e02
import AppKit
import PDFKit

var failures = 0
func check(_ label: String, _ actual: String, _ expected: String) {
    let ok = actual == expected
    if !ok { failures += 1 }
    print("\(ok ? "PASS" : "FAIL") \(label): \(actual)\(ok ? "" : " (expected \(expected))")")
}

/// A PDF with `pages` pages of the given size, each with its page number drawn large.
func makePDF(pages: Int, size: CGSize) -> Data {
    let data = NSMutableData()
    var box = CGRect(origin: .zero, size: size)
    let consumer = CGDataConsumer(data: data as CFMutableData)!
    let context = CGContext(consumer: consumer, mediaBox: &box, nil)!
    for number in 1...pages {
        context.beginPDFPage(nil)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        ("\(number)" as NSString).draw(at: CGPoint(x: 40, y: 40), withAttributes: [.font: NSFont.systemFont(ofSize: 120)])
        context.endPDFPage()
    }
    context.closePDF()
    return data as Data
}

let a4 = CGSize(width: 595, height: 842)
let landscape = CGSize(width: 842, height: 595)

// QUEUE-001-AC08: thumbnails are rendered sharp enough for step 7 (364 points high) at 2x.
for (label, size) in [("portrait A4", a4), ("landscape A4", landscape)] {
    let png = try PreviewBuilder.makeThumbnailPNG(from: [JobDocument(data: makePDF(pages: 3, size: size), format: "application/pdf")],
                                                  maxPixelSize: ThumbnailZoom.renderPixelSize)
    let rep = NSBitmapImageRep(data: png)!
    check("thumbnail \(label) longest side in pixels", "\(max(rep.pixelsWide, rep.pixelsHigh))", "728")
    print("  \(label): \(rep.pixelsWide)x\(rep.pixelsHigh) pixels, \(png.count) bytes")
}

// PREV-001-AC07: a grid block shows only the first page; the page count is that of the whole job.
func firstPage(_ documents: [JobDocument]) -> (pages: Int, firstPagePages: Int, bounds: CGRect, problems: Int) {
    let preview = try! PreviewBuilder.makePreview(from: documents)
    let document = PDFDocument(data: preview.pdfData)!
    let copy = document.page(at: 0)!.copy() as! PDFPage
    let single = PDFDocument()
    single.insert(copy, at: 0)
    return (document.pageCount, single.pageCount, single.page(at: 0)!.bounds(for: .cropBox), preview.problems.count)
}
let five = firstPage([JobDocument(data: makePDF(pages: 5, size: a4), format: "application/pdf")])
check("5-page job: pages, block pages", "\(five.pages) \(five.firstPagePages)", "5 1")
check("5-page job: block page size", "\(Int(five.bounds.width))x\(Int(five.bounds.height))", "595x842")
let text = String(repeating: "line\n", count: 200)
let mixed = firstPage([JobDocument(data: Data(text.utf8), format: "text/plain"),
                       JobDocument(data: makePDF(pages: 2, size: landscape), format: "application/pdf")])
check("text + PDF job: pages > 2, block pages 1", "\(mixed.pages > 2) \(mixed.firstPagePages)", "true 1")
let partial = firstPage([JobDocument(data: makePDF(pages: 1, size: a4), format: "application/pdf"),
                         JobDocument(data: Data([0, 1, 2, 3]), format: "image/png")])
check("PDF + unreadable image: block marked partial", "\(partial.pages) \(partial.problems)", "1 1")

print(failures == 0 ? "ALL PASS" : "FAILURES: \(failures)")
