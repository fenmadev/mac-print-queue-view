// Draws the MacPrintQueueView app icon (1024×1024 PNG): a printer on a graphite rounded square,
// with a magnifying glass over the sheet it prints (proposal A of phase 02, D45).
// Full-bleed: the rim fills the whole canvas, without its own rounded outline or drop shadow, so that
// macOS applies its own icon shape. (A pre-shaped icon with transparent margins is shown by macOS 26
// and later reduced on a grey plate.)
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
func rr(_ r: CGRect, _ rad: CGFloat) -> NSBezierPath { NSBezierPath(roundedRect: r, xRadius: rad, yRadius: rad) }

// The artwork is laid out on an 824-point body in the middle of the canvas and scaled up so that the
// body fills the canvas; the printer and the magnifying glass are scaled less, so the handle stays
// inside the shape macOS cuts out.
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
func scale(_ f: CGFloat) {
    ctx.translateBy(x: size / 2, y: size / 2); ctx.scaleBy(x: f, y: f); ctx.translateBy(x: -size / 2, y: -size / 2)
}
ctx.saveGState()
scale(size / body.width)
// --- Background: light metal rim over the whole canvas, graphite face
NSGradient(starting: rgb(232, 232, 236), ending: rgb(150, 150, 156))!.draw(in: body, angle: -90)
NSGradient(starting: rgb(84, 84, 90), ending: rgb(36, 36, 40))!.draw(in: rr(body.insetBy(dx: 30, dy: 30), 158), angle: -90)
ctx.restoreGState()
ctx.saveGState()
scale(1.1)

// --- Sheet content: title bar, picture, text lines. `dark` makes the lines readable (inside the lens).
func drawContent(in r: CGRect, dark: Bool = false) {
    let m: CGFloat = 34
    rgb(37, 99, 235).setFill()
    rr(CGRect(x: r.minX + m, y: r.maxY - 52, width: 150, height: 22), 11).fill()
    rgb(191, 219, 254).setFill()
    rr(CGRect(x: r.minX + m, y: r.maxY - 150, width: r.width - 2*m, height: 80), 12).fill()
    rgb(147, 197, 253).setFill()
    let hill = NSBezierPath()
    hill.move(to: CGPoint(x: r.minX + m, y: r.maxY - 140))
    hill.line(to: CGPoint(x: r.minX + m + 90, y: r.maxY - 88))
    hill.line(to: CGPoint(x: r.minX + m + 160, y: r.maxY - 125))
    hill.line(to: CGPoint(x: r.minX + m + 220, y: r.maxY - 98))
    hill.line(to: CGPoint(x: r.maxX - m, y: r.maxY - 140))
    hill.close(); hill.fill()
    rgb(253, 186, 116).setFill()
    NSBezierPath(ovalIn: CGRect(x: r.maxX - m - 62, y: r.maxY - 100, width: 26, height: 26)).fill()
    (dark ? rgb(71, 85, 105) : rgb(203, 213, 225)).setFill()
    let widths: [CGFloat] = [1, 0.88, 1, 0.74, 0.94, 0.6, 1]
    for (i, w) in widths.enumerated() {
        let y = r.maxY - 180 - CGFloat(i) * 28
        if y < r.minY + 20 { break }
        rr(CGRect(x: r.minX + m, y: y, width: (r.width - 2*m) * w, height: 13), 6.5).fill()
    }
}

let paperRect = CGRect(x: 332, y: 196, width: 360, height: 284)
let contentRect = CGRect(x: paperRect.minX, y: paperRect.minY, width: paperRect.width, height: paperRect.height - 18)

// --- Printer: paper tray at the back
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: NSColor.black.withAlphaComponent(0.35).cgColor)
NSGradient(starting: rgb(224, 224, 228), ending: rgb(168, 168, 174))!.draw(in: rr(CGRect(x: 312, y: 600, width: 400, height: 170), 30), angle: -90)
ctx.restoreGState()
// body
let printer = CGRect(x: 226, y: 412, width: 572, height: 244)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: NSColor.black.withAlphaComponent(0.45).cgColor)
NSGradient(starting: rgb(74, 74, 80), ending: rgb(24, 24, 28))!.draw(in: rr(printer, 62), angle: -90)
ctx.restoreGState()
// top edge highlight
ctx.saveGState(); rr(printer, 62).addClip()
NSGradient(starting: NSColor.white.withAlphaComponent(0.22), ending: NSColor.white.withAlphaComponent(0))!
    .draw(in: CGRect(x: printer.minX, y: printer.maxY - 60, width: printer.width, height: 60), angle: -90)
ctx.restoreGState()
// green status light with glow
let led = rgb(52, 199, 89)
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 22, color: led.cgColor)
led.setFill(); NSBezierPath(ovalIn: CGRect(x: 694, y: 590, width: 30, height: 30)).fill()
ctx.restoreGState()
// output slot
rgb(8, 8, 10).setFill(); rr(CGRect(x: 296, y: 452, width: 432, height: 36), 18).fill()
// sheet coming out of the slot (square top, rounded bottom)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 18, color: NSColor.black.withAlphaComponent(0.35).cgColor)
rgb(252, 252, 253).setFill()
let paper = NSBezierPath()
paper.move(to: CGPoint(x: paperRect.minX, y: paperRect.maxY))
paper.line(to: CGPoint(x: paperRect.minX, y: paperRect.minY + 18))
paper.appendArc(withCenter: CGPoint(x: paperRect.minX + 18, y: paperRect.minY + 18), radius: 18, startAngle: 180, endAngle: 270)
paper.line(to: CGPoint(x: paperRect.maxX - 18, y: paperRect.minY))
paper.appendArc(withCenter: CGPoint(x: paperRect.maxX - 18, y: paperRect.minY + 18), radius: 18, startAngle: 270, endAngle: 0)
paper.line(to: CGPoint(x: paperRect.maxX, y: paperRect.maxY)); paper.close()
paper.fill()
ctx.restoreGState()
// shade of the slot over the top of the sheet
NSGradient(starting: NSColor.black.withAlphaComponent(0.25), ending: NSColor.black.withAlphaComponent(0))!
    .draw(in: CGRect(x: paperRect.minX, y: paperRect.maxY - 30, width: paperRect.width, height: 30), angle: -90)
drawContent(in: contentRect)

// --- Magnifying glass over the sheet
let lens = CGPoint(x: 640, y: 300)
let radius: CGFloat = 112
// handle
ctx.saveGState()
ctx.translateBy(x: lens.x, y: lens.y); ctx.rotate(by: -45 * .pi / 180)
ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 18, color: NSColor.black.withAlphaComponent(0.4).cgColor)
NSGradient(starting: rgb(100, 100, 108), ending: rgb(20, 20, 24))!
    .draw(in: rr(CGRect(x: radius - 4, y: -28, width: 160, height: 56), 28), angle: 90)
ctx.restoreGState()
// lens content: magnified view of the sheet
let lensRect = CGRect(x: lens.x - radius, y: lens.y - radius, width: radius * 2, height: radius * 2)
ctx.saveGState()
ctx.addEllipse(in: lensRect); ctx.clip()
ctx.setFillColor(NSColor.white.cgColor); ctx.fill(lensRect)
ctx.translateBy(x: lens.x, y: lens.y); ctx.scaleBy(x: 1.6, y: 1.6); ctx.translateBy(x: -lens.x, y: -lens.y)
drawContent(in: contentRect, dark: true)
ctx.restoreGState()
// glass shine
ctx.saveGState(); NSBezierPath(ovalIn: lensRect).addClip()
NSGradient(starting: NSColor.white.withAlphaComponent(0.45), ending: NSColor.white.withAlphaComponent(0))!
    .draw(in: CGRect(x: lensRect.minX, y: lens.y, width: lensRect.width, height: radius), angle: -90)
ctx.restoreGState()
// ring
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: NSColor.black.withAlphaComponent(0.35).cgColor)
let ring = NSBezierPath(ovalIn: lensRect.insetBy(dx: -14, dy: -14))
ring.appendOval(in: lensRect)
ring.windingRule = .evenOdd
NSGradient(starting: rgb(150, 150, 158), ending: rgb(40, 40, 46))!.draw(in: ring, angle: -90)
ctx.restoreGState()
ctx.restoreGState()

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
