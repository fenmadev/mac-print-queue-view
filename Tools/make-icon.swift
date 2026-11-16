// Draws the MacPrintQueueView app icon (1024×1024 PNG).
// Usage (from the repository root): swiftc Tools/make-icon.swift -o /tmp/make-icon && /tmp/make-icon icon_1024.png
// Then run Tools/update-app-icon.sh icon_1024.png to regenerate all sizes in the asset catalog.

import AppKit

let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor { NSColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: a) }

// --- Background squircle (Apple macOS icon grid: 824pt body in a 1024 canvas)
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let bodyPath = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: NSColor.black.withAlphaComponent(0.35).cgColor)
rgb(30, 64, 175).setFill(); bodyPath.fill()
ctx.restoreGState()
ctx.saveGState()
bodyPath.addClip()
NSGradient(starting: rgb(96, 165, 250), ending: rgb(29, 78, 216))!.draw(in: body, angle: -90)
// soft top highlight
NSGradient(starting: NSColor.white.withAlphaComponent(0.18), ending: NSColor.white.withAlphaComponent(0))!
    .draw(in: CGRect(x: 100, y: 560, width: 824, height: 364), angle: -90)
ctx.restoreGState()

// --- Paper sheets (the queue)
let sheetSize = CGSize(width: 380, height: 490)
func sheet(center: CGPoint, angle: CGFloat, alpha: CGFloat, content: Bool) {
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y)
    ctx.rotate(by: angle * .pi / 180)
    let r = CGRect(x: -sheetSize.width/2, y: -sheetSize.height/2, width: sheetSize.width, height: sheetSize.height)
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 22, color: NSColor.black.withAlphaComponent(0.28).cgColor)
    NSColor.white.withAlphaComponent(alpha).setFill()
    NSBezierPath(roundedRect: r, xRadius: 22, yRadius: 22).fill()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    if content { drawContent(in: r) }
    ctx.restoreGState()
}
func drawContent(in r: CGRect, focused: Bool = false) {
    // title bar
    rgb(37, 99, 235).setFill()
    NSBezierPath(roundedRect: CGRect(x: r.minX + 44, y: r.maxY - 92, width: 190, height: 30), xRadius: 15, yRadius: 15).fill()
    // picture block
    rgb(191, 219, 254).setFill()
    NSBezierPath(roundedRect: CGRect(x: r.minX + 44, y: r.maxY - 236, width: 292, height: 112), xRadius: 14, yRadius: 14).fill()
    rgb(147, 197, 253).setFill()
    let hill = NSBezierPath()
    hill.move(to: CGPoint(x: r.minX + 44, y: r.maxY - 236 + 14))
    hill.line(to: CGPoint(x: r.minX + 140, y: r.maxY - 160))
    hill.line(to: CGPoint(x: r.minX + 210, y: r.maxY - 205))
    hill.line(to: CGPoint(x: r.minX + 270, y: r.maxY - 170))
    hill.line(to: CGPoint(x: r.minX + 336, y: r.maxY - 236 + 14))
    hill.close(); hill.fill()
    // text lines (darker inside the lens: "now you can read it")
    (focused ? rgb(71, 85, 105) : rgb(203, 213, 225)).setFill()
    let widths: [CGFloat] = [292, 260, 292, 220, 276, 170]
    for (i, w) in widths.enumerated() {
        NSBezierPath(roundedRect: CGRect(x: r.minX + 44, y: r.maxY - 286 - CGFloat(i) * 34, width: w, height: 16), xRadius: 8, yRadius: 8).fill()
    }
}
sheet(center: CGPoint(x: 452, y: 548), angle: 9, alpha: 0.55, content: false)
sheet(center: CGPoint(x: 472, y: 536), angle: 4.5, alpha: 0.8, content: false)
sheet(center: CGPoint(x: 492, y: 524), angle: 0, alpha: 1, content: true)

// --- Magnifying glass
let lens = CGPoint(x: 572, y: 410)
let radius: CGFloat = 132
// handle
ctx.saveGState()
ctx.translateBy(x: lens.x, y: lens.y)
ctx.rotate(by: -45 * .pi / 180)
ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 18, color: NSColor.black.withAlphaComponent(0.35).cgColor)
let handle = NSBezierPath(roundedRect: CGRect(x: radius - 6, y: -30, width: 185, height: 62), xRadius: 31, yRadius: 30)
NSGradient(starting: rgb(51, 65, 85), ending: rgb(15, 23, 42))!.draw(in: handle, angle: 90)
ctx.restoreGState()
// lens content: magnified view of the sheet
let lensRect = CGRect(x: lens.x - radius, y: lens.y - radius, width: radius * 2, height: radius * 2)
ctx.saveGState()
ctx.addEllipse(in: lensRect); ctx.clip()
ctx.setFillColor(NSColor.white.cgColor); ctx.fill(lensRect)
ctx.translateBy(x: lens.x, y: lens.y); ctx.scaleBy(x: 1.5, y: 1.5); ctx.translateBy(x: -lens.x, y: -lens.y)
drawContent(in: CGRect(x: 492 - sheetSize.width/2, y: 524 - sheetSize.height/2, width: sheetSize.width, height: sheetSize.height), focused: true)
ctx.restoreGState()
// glass shine
ctx.saveGState()
NSBezierPath(ovalIn: lensRect).addClip()
NSGradient(starting: NSColor.white.withAlphaComponent(0.45), ending: NSColor.white.withAlphaComponent(0))!
    .draw(in: CGRect(x: lensRect.minX, y: lens.y, width: lensRect.width, height: radius), angle: -90)
ctx.restoreGState()
// ring
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: NSColor.black.withAlphaComponent(0.3).cgColor)
let ring = NSBezierPath(ovalIn: lensRect.insetBy(dx: -14, dy: -14))
ring.appendOval(in: lensRect)
ring.windingRule = .evenOdd
NSGradient(starting: rgb(71, 85, 105), ending: rgb(15, 23, 42))!.draw(in: ring, angle: -90)
ctx.restoreGState()

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
