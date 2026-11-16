// Combines PNGs into one image, three per row. Usage: montage <out.png> <in.png>...
import AppKit
let files = Array(CommandLine.arguments.dropFirst(2))
let imgs = files.map { NSImage(contentsOfFile: $0)! }
let w = imgs.map { $0.size.width }.max()!, h = imgs.map { $0.size.height }.max()!
let cols = 3, rows = (imgs.count + cols - 1) / cols, pad: CGFloat = 12
let W = CGFloat(cols) * (w + pad) + pad, H = CGFloat(rows) * (h + pad) + pad
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W*2), pixelsHigh: Int(H*2), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: W, height: H)
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSColor(white: 0.5, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
for (i, img) in imgs.enumerated() {
  let c = i % cols, r = i / cols
  img.draw(in: NSRect(x: pad + CGFloat(c) * (w + pad), y: H - CGFloat(r + 1) * (h + pad), width: img.size.width, height: img.size.height))
}
NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
