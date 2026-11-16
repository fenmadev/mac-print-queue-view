// Phase 01 evidence E05: the column dividers of the real ContentView are thick (RM-005, D43; the
// visible line is checked in E06), and
// the job column widens with the thumbnail step, widening the window when needed (D42).
// Builds the app's window content in an off-screen window (not shown, not on the user's screen)
// and inspects the split view that AppKit uses for NavigationSplitView. The store's refresh only
// reads the queue; no job is changed.
// Build from the project root (all app sources except the app entry point):
//   swiftc -O -parse-as-library MacPrintQueueView/CUPSClient.swift MacPrintQueueView/PreviewBuilder.swift \
//     MacPrintQueueView/QueueLayout.swift MacPrintQueueView/QueueStore.swift MacPrintQueueView/JobRows.swift \
//     MacPrintQueueView/PDFPreview.swift MacPrintQueueView/ContentView.swift \
//     _docs/phases/phase-01/evidence/E05/main.swift -o <tmp>/e05
import AppKit
import SwiftUI

/// Stand-in for the app entry point, which cannot be compiled into a harness.
enum MacPrintQueueViewApp { static let displayName = "Mac Print Queue View" }

@main
enum Harness {
    @MainActor static func main() {
        NSApplication.shared.setActivationPolicy(.prohibited)
        let store = QueueStore()
        let window = NSWindow(contentViewController: NSHostingController(rootView: ContentView(store: store).frame(minWidth: 900, minHeight: 560)))
        window.setFrame(NSRect(x: -4000, y: -4000, width: 1100, height: 700), display: true)
        window.orderBack(nil)
        RunLoop.main.run(until: Date() + 2)
        func all(_ view: NSView) -> [NSView] { [view] + view.subviews.flatMap(all) }
        let splits = all(window.contentView!.superview!).compactMap { $0 as? NSSplitView }
        var failures = 0
        for split in splits {
            let thick = split.dividerStyle == .thick
            if !thick { failures += 1 }
            print("\(thick ? "PASS" : "FAIL") split view: vertical \(split.isVertical), columns \(split.arrangedSubviews.count), style \(split.dividerStyle == .thick ? "thick" : "\(split.dividerStyle.rawValue)"), divider \(split.dividerThickness) points")
        }
        // Resizing the window must keep the style.
        window.setFrame(NSRect(x: -4000, y: -4000, width: 1300, height: 800), display: true)
        RunLoop.main.run(until: Date() + 1)
        for split in splits {
            let thick = split.dividerStyle == .thick
            if !thick { failures += 1 }
            print("\(thick ? "PASS" : "FAIL") after resize: divider \(split.dividerThickness) points, column widths \(split.arrangedSubviews.map { Int($0.frame.width) })")
        }
        if splits.isEmpty { failures += 1; print("FAIL no split view found") }

        // The visible line on the divider before the preview is checked in E06.

        // The job column follows the thumbnail steps (minimum = thumbnail width + 200 points).
        for width in [1100.0, 900.0] {
            window.setFrame(NSRect(x: -4000, y: -4000, width: width, height: 700), display: true)
            for step in Array(ThumbnailZoom.steps) + [1] {
                store.thumbnailStep = step
                RunLoop.main.run(until: Date() + 0.6)
                guard let split = splits.first, split.arrangedSubviews.count == 3 else { continue }
                // The sidebar floats over the job column (the job column's frame starts under it), so
                // the visible job column runs from the sidebar's right edge to the next divider.
                let frames = split.arrangedSubviews.map(\.frame)
                let sidebar = Int(frames[0].maxX)
                let visibleJobColumn = Int(frames[1].maxX) - max(Int(frames[1].minX), sidebar)
                let columns = [sidebar, visibleJobColumn, Int(frames[2].width)]
                let minimum = Int(ThumbnailZoom.minimumColumnWidth(step: step))
                // The job column keeps its minimum and the columns fit in the window (no cut-off preview).
                let ok = columns[1] >= minimum && split.bounds.width <= window.contentView!.bounds.width + 0.5
                if !ok { failures += 1 }
                print("\(ok ? "PASS" : "FAIL") window \(Int(window.frame.width)), step \(step): sidebar, visible job column, preview \(columns) (job column minimum \(minimum)); split view \(Int(split.bounds.width)), window content \(Int(window.contentView!.bounds.width))")
            }
        }
        print(failures == 0 ? "ALL PASS" : "FAILURES: \(failures)")
        window.close()
    }
}
