// E28 harness: measures PreviewBuilder.tiffImageCount on two crafted worst-case TIFF files built
// in memory (no files, no CUPS, no printing). Run from the project root with optimization:
//   swiftc -O -module-cache-path /tmp/e28-cache MacPrintQueueView/CUPSClient.swift \
//     MacPrintQueueView/PreviewBuilder.swift _docs/phases/phase-00/evidence/E28/main.swift -o /tmp/e28-check
//   /tmp/e28-check
import Foundation
func le(_ v: Int, _ n: Int) -> [UInt8] { (0..<n).map { UInt8((v >> (8*$0)) & 0xff) } }
// (1) BigTIFF, one directory claiming ~1M entries with tag 0 (about 20 MB).
var big: [UInt8] = [0x49,0x49,43,0,8,0,0,0] + le(16, 8)
let n = 1_000_000
big += le(n, 8); big += [UInt8](repeating: 0, count: n * 20); big += le(0, 8)
// (2) Classic TIFF, chain of 10,000 directories with 255 entries each, tags 0..253 cycling (about 30 MB).
var chain: [UInt8] = [0x49,0x49,42,0] + le(8, 4)
var offset = 8
for i in 0..<10_000 {
    let size = 2 + 255 * 12 + 4
    chain += le(255, 2)
    for e in 0..<255 { chain += le(e % 254, 2) + le(3, 2) + le(1, 4) + le(0, 4) }
    chain += le(i == 9_999 ? 0 : offset + size, 4); offset += size
}
for (name, bytes) in [("BigTIFF 1M entries", big), ("classic 10,000 x 255", chain)] {
    let data = Data(bytes)
    let t = Date()
    let count = PreviewBuilder.tiffImageCount(data)
    print(name, "size", data.count, "count", count as Any, String(format: "%.3f s", Date().timeIntervalSince(t)))
}
