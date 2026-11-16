// Phase 01 evidence E06: clicking a row must not crash the app (regression of the crash reported by
// the user, caused by replacing the class of the column split view), and the divider before the
// preview is visible. Builds the app's window content in an off-screen window (not on the user's
// screen) whose SwiftUI toolbar is bridged to the window as in the app, selects rows through the
// job list's table (only reads the queue and fetches documents), and exits 0 if the app survived.
// It needs at least 3 queued jobs on one printer (for example the test printer with test jobs).
// Build from the project root (all app sources except the app entry point):
//   swiftc -swift-version 6 -Onone -parse-as-library MacPrintQueueView/CUPSClient.swift \
//     MacPrintQueueView/PreviewBuilder.swift MacPrintQueueView/QueueLayout.swift MacPrintQueueView/QueueStore.swift \
//     MacPrintQueueView/JobRows.swift MacPrintQueueView/PDFPreview.swift MacPrintQueueView/ContentView.swift \
//     _docs/phases/phase-01/evidence/E06/main.swift -o <tmp>/e06
import AppKit
import SwiftUI

/// Stand-in for the app entry point, which cannot be compiled into a harness.
enum MacPrintQueueViewApp { static let displayName = "Mac Print Queue View" }
@main
enum Toolbar {
    @MainActor static func main() {
        NSApplication.shared.setActivationPolicy(.accessory)
        // Select the printer with the most of the user's queued jobs, so that the first rows are
        // queue jobs (only reads the queue).
        let store = QueueStore()
        let host = NSHostingController(rootView: ContentView(store: store).frame(minWidth: 900, minHeight: 560))
        host.sceneBridgingOptions = [.toolbars, .title]
        let window = NSWindow(contentViewController: host)
        window.styleMask.insert(.fullSizeContentView)
        window.toolbarStyle = .unified
        window.setFrame(NSRect(x: -4000, y: -4000, width: 1100, height: 700), display: true)
        window.orderBack(nil)
        RunLoop.main.run(until: Date() + 3)
        let counts = Dictionary(grouping: store.activeJobs, by: \.printer).mapValues(\.count)
        if let busiest = counts.max(by: { $0.value < $1.value }) {
            store.selectedPrinterName = busiest.key
            RunLoop.main.run(until: Date() + 3)
            print("printer with the most queued jobs: \(busiest.value) queued")
        }
        if store.activeJobs(for: store.selectedPrinterName ?? "").count < 3 {
            print("FAIL fewer than 3 queued jobs on any printer; submit test jobs first (Tools/test-printer.sh jobs)"); exit(5)
        }
        print("toolbar: \(window.toolbar.map { "\($0.items.count) items" } ?? "none")"); fflush(stdout)
        func all(_ v: NSView) -> [NSView] { [v] + v.subviews.flatMap(all) }
        guard let jobs = all(window.contentView!.superview!).compactMap({ $0 as? NSTableView }).first(where: { $0.numberOfRows > 3 }) else { print("no job table"); exit(3) }
        // The last row of the list is always a completed job (the "Completed" section comes last).
        for (label, rows, extend) in [("queue row 1", [1], false), ("queue row 2", [2], false), ("add row 3", [3], true),
                                      ("completed row", [jobs.numberOfRows - 1], false), ("queue row 1 again", [1], false)] {
            print("select \(label)"); fflush(stdout)
            jobs.selectRowIndexes(IndexSet(rows), byExtendingSelection: extend)
            RunLoop.main.run(until: Date() + 2)
            let queued = Set(store.activeJobs.map(\.id))
            let kinds = store.selectedJobIDs.map { queued.contains($0) ? "queued" : "completed" }.sorted()
            print("  selected: \(kinds.joined(separator: ", ")); toolbar items \(window.toolbar?.items.count ?? 0)"); fflush(stdout)
            let expected = label == "completed row" ? "completed" : "queued"
            if kinds.isEmpty || !kinds.allSatisfy({ $0 == expected }) {
                print("FAIL \(label) did not select a \(expected) job"); exit(6)
            }
        }
        if let split = all(window.contentView!.superview!).compactMap({ $0 as? NSSplitView }).first, split.arrangedSubviews.count == 3 {
            print("divider \(split.dividerThickness) points, split view class \(type(of: split))")
            // Pixels across the divider before the preview, at a quarter (line) and half (grip) height.
            let root = window.contentView!.superview!
            let rep = root.bitmapImageRepForCachingDisplay(in: root.bounds)!
            root.cacheDisplay(in: root.bounds, to: rep)
            let scale = CGFloat(rep.pixelsWide) / root.bounds.width
            let start = split.convert(NSPoint(x: split.arrangedSubviews[1].frame.maxX, y: 0), to: root).x
            for (label, fraction) in [("line", 0.25), ("grip", 0.5)] {
                let y = Int(root.bounds.height * scale * fraction)
                let samples = (-2...11).map { dx -> String in
                    let c = rep.colorAt(x: Int((start + CGFloat(dx)) * scale), y: y)!.usingColorSpace(.sRGB)!
                    return String(format: "%d:%.2f", dx, c.brightnessComponent * c.alphaComponent)
                }
                print("  \(label) across the divider (offset: brightness × alpha): \(samples.joined(separator: " "))")
            }
        }
        // A click on the line or grip must reach the split view (which drags the divider), not the
        // line on top of it. (Dragging itself cannot be simulated in an off-screen window.)
        if let split = all(window.contentView!.superview!).compactMap({ $0 as? NSSplitView }).first, split.arrangedSubviews.count == 3 {
            let root = window.contentView!.superview!
            let edge = split.arrangedSubviews[1].frame.maxX
            for (label, y) in [("line", split.bounds.height * 0.25), ("grip", split.bounds.midY)] {
                let point = split.convert(NSPoint(x: edge + split.dividerThickness / 2, y: y), to: nil)
                let hit = root.hitTest(point)
                var receiver: NSView? = hit
                while let view = receiver, !(view is NSSplitView) { receiver = view.superview }
                let ok = receiver === split && !String(describing: type(of: hit as Any)).contains("DividerMark")
                print("\(ok ? "PASS" : "FAIL") click on the \(label) goes to \(hit.map { "\(type(of: $0))" } ?? "nothing") (inside the split view: \(receiver === split))")
                if !ok { exit(4) }
            }
        }
        print("survived"); fflush(stdout)
        exit(0)
    }
}
