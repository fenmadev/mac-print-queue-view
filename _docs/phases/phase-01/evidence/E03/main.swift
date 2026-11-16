// Phase 01 evidence E03: queue rows rendered with ImageRenderer at the seven thumbnail steps
// (RM-001), selected and not selected, light and dark. Writes PNG files to the folder given as the
// first argument (temporary; inspected by the executor, not retained). No CUPS call.
// Build from the project root:
//   swiftc -O MacPrintQueueView/CUPSClient.swift MacPrintQueueView/PreviewBuilder.swift \
//     MacPrintQueueView/QueueLayout.swift MacPrintQueueView/JobRows.swift \
//     _docs/phases/phase-01/evidence/E03/main.swift -o <tmp>/e03
import AppKit
import CUPS
import SwiftUI

let folder = URL(fileURLWithPath: CommandLine.arguments[1])

func pdf(_ size: CGSize) -> Data {
    let data = NSMutableData()
    var box = CGRect(origin: .zero, size: size)
    let context = CGContext(consumer: CGDataConsumer(data: data as CFMutableData)!, mediaBox: &box, nil)!
    context.beginPDFPage(nil)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    ("Invoice 2026-114\n\nLorem ipsum dolor sit amet,\nconsectetur adipiscing elit." as NSString)
        .draw(at: CGPoint(x: 60, y: size.height - 260), withAttributes: [.font: NSFont.systemFont(ofSize: 36)])
    context.endPDFPage()
    context.closePDF()
    return data as Data
}

let png = try PreviewBuilder.makeThumbnailPNG(from: [JobDocument(data: pdf(CGSize(width: 595, height: 842)), format: "application/pdf")],
                                              maxPixelSize: ThumbnailZoom.renderPixelSize)
let thumbnail = NSImage(data: png)!
let job = PrintJob(id: 1201, printer: "Test", title: "Invoice 2026-114.pdf", user: "test", format: "application/pdf",
                   state: IPP_JSTATE_HELD, priority: 50, sizeKB: 90, created: Date(), completed: nil)

@MainActor
func render() {
    for scheme in [ColorScheme.light, .dark] {
        let rows = VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(ThumbnailZoom.steps), id: \.self) { step in
                QueueJobRow(job: job, thumbnail: thumbnail, thumbnailSize: ThumbnailZoom.size(step: step),
                            isSelected: step == 3, canPause: false, canResume: true, canCancel: true)
                    .padding(.horizontal, 10)
                    .background(step == 3 ? Color.accentColor : Color.clear)
                    .environment(\.backgroundProminence, step == 3 ? .increased : .standard)
                QueueJobRow(job: job, thumbnail: nil, thumbnailSize: ThumbnailZoom.size(step: step))
                    .padding(.horizontal, 10)
            }
        }
        .frame(width: 320)
        .background(scheme == .dark ? Color.black : Color.white)
        .environment(\.colorScheme, scheme)
        let renderer = ImageRenderer(content: rows)
        renderer.scale = 2
        let image = renderer.nsImage!
        let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let url = folder.appendingPathComponent("rows-\(scheme == .dark ? "dark" : "light").png")
        try! rep.representation(using: .png, properties: [:])!.write(to: url)
        print("\(url.lastPathComponent): \(rep.pixelsWide)x\(rep.pixelsHigh) pixels")
    }
}
MainActor.assumeIsolated { render() }
