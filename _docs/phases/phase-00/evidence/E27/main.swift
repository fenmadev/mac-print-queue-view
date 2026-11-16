// E27 harness: checks PreviewBuilder.makePreview and PreviewBuilder.tiffImageCount with in-memory
// documents only (no CUPS, no printing). Run from the project root:
//   swiftc -module-cache-path /tmp/e27-cache MacPrintQueueView/CUPSClient.swift \
//     MacPrintQueueView/PreviewBuilder.swift _docs/phases/phase-00/evidence/E27/main.swift -o /tmp/e27-check
//   /tmp/e27-check _docs/phases/phase-00/evidence/E27
// The fixtures two.tiff, bad-compression.tiff and bad-second.tiff were created by the external
// reviewer during review 09; report 09 names and hashes the first two, and bad-second.tiff comes
// from the same temporary folder. Their SHA-256 values are listed in the evidence register.
import Darwin
setvbuf(stdout, nil, _IONBF, 0)
import Foundation
import ImageIO
import AppKit
import UniformTypeIdentifiers

func show(_ name: String, _ docs: [JobDocument]) {
    do {
        let p = try PreviewBuilder.makePreview(from: docs)
        let pages = PDFDocumentPages(p.pdfData)
        print("\(name): pages=\(pages) problems=\(p.problems)")
    } catch { print("\(name): ERROR \(error.localizedDescription.replacingOccurrences(of: "\n", with: " | "))") }
}
import PDFKit
func PDFDocumentPages(_ d: Data) -> Int { PDFDocument(data: d)?.pageCount ?? -1 }

func image(_ color: NSColor) -> CGImage {
    let ctx = CGContext(data: nil, width: 16, height: 16, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(color.cgColor); ctx.fill(CGRect(x: 0, y: 0, width: 16, height: 16)); return ctx.makeImage()!
}
func encode(_ type: String, _ images: [CGImage]) -> Data {
    let out = NSMutableData()
    let dest = CGImageDestinationCreateWithData(out, type as CFString, images.count, nil)!
    for i in images { CGImageDestinationAddImage(dest, i, nil) }
    precondition(CGImageDestinationFinalize(dest)); return out as Data
}
func le32(_ b: [UInt8], _ o: Int) -> Int { Int(b[o])<<24 | Int(b[o+1])<<16 | Int(b[o+2])<<8 | Int(b[o+3]) } // big-endian (two.tiff is MM)
func put32(_ b: inout [UInt8], _ o: Int, _ v: Int) { for i in 0..<4 { b[o+i] = UInt8((v >> (8*(3-i))) & 0xff) } }

let dir = CommandLine.arguments[1] + "/" // folder with the three TIFF fixtures
let two = try! Data(contentsOf: URL(fileURLWithPath: dir + "two.tiff"))
let badCompression = try! Data(contentsOf: URL(fileURLWithPath: dir + "bad-compression.tiff"))
let badSecond = try! Data(contentsOf: URL(fileURLWithPath: dir + "bad-second.tiff"))
let text = JobDocument(data: Data("Hello".utf8), format: "text/plain")

show("K1 valid two.tiff", [JobDocument(data: two, format: "image/tiff")])
show("K1 bad-compression.tiff", [JobDocument(data: badCompression, format: "image/tiff")])
show("K1 bad-compression.tiff labelled octet-stream", [JobDocument(data: badCompression, format: "application/octet-stream")])
show("Codex bad-second.tiff", [JobDocument(data: badSecond, format: "image/tiff")])
show("text + bad-compression.tiff", [text, JobDocument(data: badCompression, format: "image/tiff")])
show("text + undecodable image (E22)", [text, JobDocument(data: Data([1,2,3,4,5]), format: "image/png")])

// Chain points beyond the end of the file: IFD1's next pointer -> far away.
var beyond = [UInt8](two)
let ifd0 = le32(beyond, 4); let n0 = Int(beyond[ifd0])<<8 | Int(beyond[ifd0+1])
let ifd1 = le32(beyond, ifd0 + 2 + n0*12)
let n1 = Int(beyond[ifd1])<<8 | Int(beyond[ifd1+1])
put32(&beyond, ifd1 + 2 + n1*12, beyond.count + 1000)
show("two.tiff + third IFD beyond EOF", [JobDocument(data: Data(beyond), format: "image/tiff")])
// Loop: IFD1 points back to IFD0.
var loop = [UInt8](two); put32(&loop, ifd1 + 2 + n1*12, ifd0)
show("two.tiff with IFD loop", [JobDocument(data: Data(loop), format: "image/tiff")])

show("single TIFF", [JobDocument(data: encode(UTType.tiff.identifier, [image(.red)]), format: "image/tiff")])
show("three-frame GIF", [JobDocument(data: encode(UTType.gif.identifier, [image(.red), image(.blue), image(.green)]), format: "image/gif")])
show("PNG", [JobDocument(data: encode(UTType.png.identifier, [image(.red)]), format: "image/png")])
show("JPEG", [JobDocument(data: encode(UTType.jpeg.identifier, [image(.red)]), format: "image/jpeg")])
show("text only", [text])

// tiffImageCount on hand-built files.
func classic(little: Bool, subfileTypes: [UInt32?]) -> Data {
    var b: [UInt8] = little ? [0x49,0x49,42,0] : [0x4D,0x4D,0,42]
    func u16(_ v: Int) -> [UInt8] { little ? [UInt8(v & 0xff), UInt8(v >> 8)] : [UInt8(v >> 8), UInt8(v & 0xff)] }
    func u32(_ v: Int) -> [UInt8] { little ? (0..<4).map { UInt8((v >> (8*$0)) & 0xff) } : (0..<4).reversed().map { UInt8((v >> (8*$0)) & 0xff) } }
    var offset = 8; b += u32(offset)
    for (i, t) in subfileTypes.enumerated() {
        let entries = t == nil ? 0 : 1
        let size = 2 + entries*12 + 4
        var ifd = u16(entries)
        if let t { ifd += u16(254) + u16(4) + u32(1) + u32(Int(t)) }
        ifd += u32(i == subfileTypes.count - 1 ? 0 : offset + size)
        b += ifd; offset += size
    }
    return Data(b)
}
func bigTIFF(count: Int) -> Data {
    var b: [UInt8] = [0x49,0x49,43,0,8,0,0,0]
    func u64(_ v: Int) -> [UInt8] { (0..<8).map { UInt8((v >> (8*$0)) & 0xff) } }
    var offset = 16; b += u64(offset)
    for i in 0..<count { let size = 8 + 8; b += u64(0) + u64(i == count - 1 ? 0 : offset + size); offset += size }
    return Data(b)
}
print("count LE [nil,nil,nil] =", PreviewBuilder.tiffImageCount(classic(little: true, subfileTypes: [nil, nil, nil])) as Any)
print("count BE [nil,nil] =", PreviewBuilder.tiffImageCount(classic(little: false, subfileTypes: [nil, nil])) as Any)
print("count LE [0, 1 (thumbnail), 4 (mask), 2 (page)] =", PreviewBuilder.tiffImageCount(classic(little: true, subfileTypes: [0, 1, 4, 2])) as Any)
print("count BigTIFF x3 =", PreviewBuilder.tiffImageCount(bigTIFF(count: 3)) as Any)
print("count two.tiff =", PreviewBuilder.tiffImageCount(two) as Any, " bad-compression =", PreviewBuilder.tiffImageCount(badCompression) as Any, " beyond =", PreviewBuilder.tiffImageCount(Data(beyond)) as Any, " loop =", PreviewBuilder.tiffImageCount(Data(loop)) as Any)
print("count PNG =", PreviewBuilder.tiffImageCount(encode(UTType.png.identifier, [image(.red)])) as Any, " short =", PreviewBuilder.tiffImageCount(Data([0x49,0x49,42])) as Any)

// Round 7 (findings M1, M2 of report 13): a thumbnail directory whose NewSubfileType entry comes
// after another tag (unsorted, malformed) and a big-endian BigTIFF with NewSubfileType as LONG8.
func classicUnsorted() -> Data {
    func u16(_ v: Int) -> [UInt8] { [UInt8(v & 0xff), UInt8(v >> 8)] }
    func u32(_ v: Int) -> [UInt8] { (0..<4).map { UInt8((v >> (8*$0)) & 0xff) } }
    var b: [UInt8] = [0x49,0x49,42,0] + u32(8)
    b += u16(0) + u32(8 + 6)                                   // directory 1: page, no entries
    b += u16(2) + u16(256) + u16(3) + u32(1) + u32(16)         // directory 2: ImageWidth first,
    b += u16(254) + u16(4) + u32(1) + u32(1) + u32(0)          // then NewSubfileType = 1 (thumbnail)
    return Data(b)
}
func bigEndianBigTIFFLong8() -> Data {
    func be(_ v: Int, _ n: Int) -> [UInt8] { (0..<n).reversed().map { UInt8((v >> (8*$0)) & 0xff) } }
    var b: [UInt8] = [0x4D,0x4D,0,43,0,8,0,0] + be(16, 8)
    b += be(0, 8) + be(16 + 16, 8)                             // directory 1: page, no entries
    b += be(1, 8) + be(254, 2) + be(16, 2) + be(1, 8) + be(1, 8) + be(0, 8) // directory 2: LONG8 = 1
    return Data(b)
}
print("count LE unsorted [page, thumbnail after tag 256] =", PreviewBuilder.tiffImageCount(classicUnsorted()) as Any)
print("count BigTIFF BE [page, thumbnail as LONG8] =", PreviewBuilder.tiffImageCount(bigEndianBigTIFFLong8()) as Any)
