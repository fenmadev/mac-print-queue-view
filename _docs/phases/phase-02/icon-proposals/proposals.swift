// Draws the icon proposals A–D of phase 02 and the overview image. Usage (from the repository root):
// swiftc _docs/phases/phase-02/icon-proposals/proposals.swift -o /tmp/proposals && /tmp/proposals <outdir> <current-icon-1024.png>
import AppKit

let outDir = CommandLine.arguments[1]
let currentIcon = NSImage(contentsOfFile: CommandLine.arguments[2])!

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor { NSColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: a) }
func rr(_ r: CGRect, _ rad: CGFloat) -> NSBezierPath { NSBezierPath(roundedRect: r, xRadius: rad, yRadius: rad) }

enum Bg { case graphite, blue }
enum Emblem { case loupe, queue, none }
struct Variant { let id: String; let title: String; let bg: Bg; let emblem: Emblem; let led: NSColor }

let green = rgb(52, 199, 89), blueLED = rgb(64, 156, 255)
let variants = [
    Variant(id: "A", title: "A  Graphite printer + loupe", bg: .graphite, emblem: .loupe, led: green),
    Variant(id: "B", title: "B  Graphite printer + queue", bg: .graphite, emblem: .queue, led: green),
    Variant(id: "C", title: "C  Blue printer + loupe", bg: .blue, emblem: .loupe, led: green),
    Variant(id: "D", title: "D  Graphite printer, preview sheet", bg: .graphite, emblem: .none, led: blueLED),
]

func drawBackground(_ ctx: CGContext, _ bg: Bg) {
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let path = rr(body, 185)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    rgb(60, 60, 64).setFill(); path.fill()
    ctx.restoreGState()
    switch bg {
    case .graphite:
        NSGradient(starting: rgb(232, 232, 236), ending: rgb(150, 150, 156))!.draw(in: path, angle: -90)
        let inner = rr(body.insetBy(dx: 30, dy: 30), 158)
        NSGradient(starting: rgb(84, 84, 90), ending: rgb(36, 36, 40))!.draw(in: inner, angle: -90)
    case .blue:
        NSGradient(starting: rgb(96, 165, 250), ending: rgb(29, 78, 216))!.draw(in: path, angle: -90)
        ctx.saveGState(); path.addClip()
        NSGradient(starting: NSColor.white.withAlphaComponent(0.18), ending: NSColor.white.withAlphaComponent(0))!
            .draw(in: CGRect(x: 100, y: 560, width: 824, height: 364), angle: -90)
        ctx.restoreGState()
    }
}

// Paper content: title bar, picture, text lines. `dark` makes the lines readable (inside the loupe).
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

func drawPrinter(_ ctx: CGContext, _ v: Variant) {
    // queued sheets standing in the input tray (behind everything else)
    if v.emblem == .queue {
        let headers = [rgb(249, 115, 22), rgb(16, 185, 129), rgb(37, 99, 235)]
        for i in 0..<3 {
            let dx = CGFloat(i - 1) * 46, top = 862 - CGFloat(i) * 34
            let r = CGRect(x: 382 + dx, y: 640, width: 260, height: top - 640)
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 12, color: NSColor.black.withAlphaComponent(0.35).cgColor)
            rgb(250, 250, 252).setFill(); rr(r, 14).fill()
            ctx.restoreGState()
            headers[i].setFill(); rr(CGRect(x: r.minX + 26, y: r.maxY - 46, width: 110, height: 20), 10).fill()
            rgb(203, 213, 225).setFill()
            for j in 0..<3 { rr(CGRect(x: r.minX + 26, y: r.maxY - 80 - CGFloat(j) * 24, width: 200 - CGFloat(j % 2) * 50, height: 11), 5.5).fill() }
        }
    }
    // input tray (back)
    let tray = CGRect(x: 312, y: 600, width: 400, height: v.emblem == .queue ? 110 : 170)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    NSGradient(starting: rgb(224, 224, 228), ending: rgb(168, 168, 174))!.draw(in: rr(tray, 30), angle: -90)
    ctx.restoreGState()
    // body
    let body = CGRect(x: 226, y: 412, width: 572, height: 244)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: NSColor.black.withAlphaComponent(0.45).cgColor)
    NSGradient(starting: rgb(74, 74, 80), ending: rgb(24, 24, 28))!.draw(in: rr(body, 62), angle: -90)
    ctx.restoreGState()
    // top edge highlight
    ctx.saveGState(); rr(body, 62).addClip()
    NSGradient(starting: NSColor.white.withAlphaComponent(0.22), ending: NSColor.white.withAlphaComponent(0))!
        .draw(in: CGRect(x: body.minX, y: body.maxY - 60, width: body.width, height: 60), angle: -90)
    ctx.restoreGState()
    // status LED with glow
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 22, color: v.led.cgColor)
    v.led.setFill(); NSBezierPath(ovalIn: CGRect(x: 694, y: 590, width: 30, height: 30)).fill()
    ctx.restoreGState()
    // output slot
    rgb(8, 8, 10).setFill(); rr(CGRect(x: 296, y: 452, width: 432, height: 36), 18).fill()
    // paper coming out
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
    // slot shade over the top of the paper
    NSGradient(starting: NSColor.black.withAlphaComponent(0.25), ending: NSColor.black.withAlphaComponent(0))!
        .draw(in: CGRect(x: paperRect.minX, y: paperRect.maxY - 30, width: paperRect.width, height: 30), angle: -90)
    drawContent(in: CGRect(x: paperRect.minX, y: paperRect.minY, width: paperRect.width, height: paperRect.height - 18))

    if v.emblem == .loupe { drawLoupe(ctx) }
}

func drawLoupe(_ ctx: CGContext) {
    let c = CGPoint(x: 640, y: 300), radius: CGFloat = 112
    ctx.saveGState()
    ctx.translateBy(x: c.x, y: c.y); ctx.rotate(by: -45 * .pi / 180)
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 18, color: NSColor.black.withAlphaComponent(0.4).cgColor)
    NSGradient(starting: rgb(100, 100, 108), ending: rgb(20, 20, 24))!
        .draw(in: rr(CGRect(x: radius - 4, y: -28, width: 160, height: 56), 28), angle: 90)
    ctx.restoreGState()
    let lens = CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2)
    ctx.saveGState()
    ctx.addEllipse(in: lens); ctx.clip()
    ctx.setFillColor(NSColor.white.cgColor); ctx.fill(lens)
    ctx.translateBy(x: c.x, y: c.y); ctx.scaleBy(x: 1.6, y: 1.6); ctx.translateBy(x: -c.x, y: -c.y)
    drawContent(in: CGRect(x: paperRect.minX, y: paperRect.minY, width: paperRect.width, height: paperRect.height - 18), dark: true)
    ctx.restoreGState()
    ctx.saveGState(); NSBezierPath(ovalIn: lens).addClip()
    NSGradient(starting: NSColor.white.withAlphaComponent(0.45), ending: NSColor.white.withAlphaComponent(0))!
        .draw(in: CGRect(x: lens.minX, y: c.y, width: lens.width, height: radius), angle: -90)
    ctx.restoreGState()
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    let ring = NSBezierPath(ovalIn: lens.insetBy(dx: -14, dy: -14)); ring.appendOval(in: lens); ring.windingRule = .evenOdd
    NSGradient(starting: rgb(150, 150, 158), ending: rgb(40, 40, 46))!.draw(in: ring, angle: -90)
    ctx.restoreGState()
}

func render(_ v: Variant) -> NSImage {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    drawBackground(ctx, v.bg)
    drawPrinter(ctx, v)
    NSGraphicsContext.current = nil
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(outDir)/proposal-\(v.id)-1024.png"))
    let img = NSImage(size: NSSize(width: 1024, height: 1024)); img.addRepresentation(rep); return img
}

// Contact sheet: current icon + A–D, each at 256, 64 and 32 pt, on a light and a dark strip.
let items: [(String, NSImage)] = [("Current", currentIcon)] + variants.map { ($0.title, render($0)) }
let colW: CGFloat = 300, sheetW = colW * CGFloat(items.count), sheetH: CGFloat = 640
let sheet = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(sheetW), pixelsHigh: Int(sheetH), bitsPerSample: 8, samplesPerPixel: 4,
                             hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: sheet)
NSGraphicsContext.current!.imageInterpolation = .high
rgb(236, 236, 240).setFill(); NSRect(x: 0, y: 140, width: sheetW, height: sheetH - 140).fill()
rgb(30, 30, 34).setFill(); NSRect(x: 0, y: 0, width: sheetW, height: 140).fill()
for (i, (title, img)) in items.enumerated() {
    let x0 = CGFloat(i) * colW
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 17), .foregroundColor: NSColor.black]
    (title as NSString).draw(at: NSPoint(x: x0 + 22, y: sheetH - 40), withAttributes: attrs)
    img.draw(in: NSRect(x: x0 + 22, y: 300, width: 256, height: 256))
    img.draw(in: NSRect(x: x0 + 60, y: 180, width: 96, height: 96))
    img.draw(in: NSRect(x: x0 + 180, y: 200, width: 48, height: 48))
    img.draw(in: NSRect(x: x0 + 60, y: 30, width: 64, height: 64))
    img.draw(in: NSRect(x: x0 + 150, y: 46, width: 32, height: 32))
    img.draw(in: NSRect(x: x0 + 210, y: 54, width: 16, height: 16))
}
NSGraphicsContext.current = nil
try! sheet.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(outDir)/proposals-overview.png"))
print("done")
