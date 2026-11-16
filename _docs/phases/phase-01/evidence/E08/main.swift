// Phase 01 evidence E08: the list shows exactly the selection that the selection rules keep
// (QUEUE-001 rule 9, AC09; internal review 02 finding S1). Builds the app's window content off
// screen (as E06), selects rows through the job list's table the way the list does for ⌘A and
// ⇧-click ranges, and compares the table's highlighted rows with the store's selection.
// Needs at least 3 queued jobs and 3 completed jobs on one printer; run through E07/run.sh.
// Only reads the queue and fetches documents; no job is changed.
import AppKit
import SwiftUI

/// Stand-in for the app entry point, which cannot be compiled into a harness.
enum MacPrintQueueViewApp { static let displayName = "Mac Print Queue View" }

@main
enum ListSelection {
    @MainActor static func main() {
        NSApplication.shared.setActivationPolicy(.accessory)
        let store = QueueStore()
        let host = NSHostingController(rootView: ContentView(store: store).frame(minWidth: 900, minHeight: 560))
        host.sceneBridgingOptions = [.toolbars, .title]
        let window = NSWindow(contentViewController: host)
        window.setFrame(NSRect(x: -4000, y: -4000, width: 1100, height: 700), display: true)
        window.orderBack(nil)
        RunLoop.main.run(until: Date() + 3)
        let counts = Dictionary(grouping: store.activeJobs, by: \.printer).mapValues(\.count)
        if let busiest = counts.max(by: { $0.value < $1.value }) {
            store.selectedPrinterName = busiest.key
            RunLoop.main.run(until: Date() + 3)
        }
        let queued = store.activeJobs(for: store.selectedPrinterName ?? "")
        guard queued.count >= 3, store.finishedJobs.count >= 3 else {
            print("FAIL needs at least 3 queued and 3 completed jobs (\(queued.count), \(store.finishedJobs.count))"); exit(5)
        }
        func all(_ v: NSView) -> [NSView] { [v] + v.subviews.flatMap(all) }
        guard let table = all(window.contentView!.superview!).compactMap({ $0 as? NSTableView }).first(where: { $0.numberOfRows > 5 }) else {
            print("FAIL no job table"); exit(3)
        }
        var failures = 0
        func report(_ label: String, expectQueuedOnly: Bool, expectCount: Int? = nil) {
            RunLoop.main.run(until: Date() + 1.5)
            let ids = store.selectedJobIDs
            let queuedIDs = Set(store.activeJobs.map(\.id))
            let kinds = ids.allSatisfy { queuedIDs.contains($0) } ? "queued only" : (ids.allSatisfy { !queuedIDs.contains($0) } ? "completed only" : "mixed")
            // Section header rows ("In Queue", "Completed") cannot be clicked; selecting rows
            // programmatically bypasses that, so they are left out of the comparison and listed.
            let isHeader: (Int) -> Bool = { row in
                (table.delegate?.tableView?(table, isGroupRow: row) ?? false)
                    || (table.rowView(atRow: row, makeIfNecessary: false)?.isGroupRowStyle ?? false)
            }
            let headers = table.selectedRowIndexes.filter(isHeader)
            let highlighted = table.selectedRowIndexes.count - headers.count
            var ok = highlighted == ids.count
            if expectQueuedOnly { ok = ok && kinds == "queued only" }
            if let expectCount { ok = ok && ids.count == expectCount }
            if !ok { failures += 1 }
            if !ok { print("  highlighted rows \(Array(table.selectedRowIndexes)); rows 0–\(table.numberOfRows - 1); header-styled rows \((0..<table.numberOfRows).filter(isHeader))") }
            print("\(ok ? "PASS" : "FAIL") \(label): list highlights \(highlighted) job rows\(headers.isEmpty ? "" : " (+ header rows \(Array(headers)), selected programmatically)"), store keeps \(ids.count) (\(kinds))")
        }
        // Row 0 is the "In Queue" header; the queued jobs follow; the last row is a completed job.
        let lastRow = table.numberOfRows - 1
        table.selectRowIndexes([1], byExtendingSelection: false)
        report("one queue row", expectQueuedOnly: true, expectCount: 1)
        table.selectAll(nil)
        report("select all (⌘A)", expectQueuedOnly: true, expectCount: queued.count)
        table.selectAll(nil)
        report("select all again (selection unchanged by the rules)", expectQueuedOnly: true, expectCount: queued.count)
        table.selectRowIndexes([1], byExtendingSelection: false)
        RunLoop.main.run(until: Date() + 1)
        table.selectRowIndexes(IndexSet(1...lastRow), byExtendingSelection: false)
        report("⇧-range from the first queue row into Completed", expectQueuedOnly: true, expectCount: queued.count)
        table.selectRowIndexes([lastRow - 2], byExtendingSelection: false)
        report("one completed row", expectQueuedOnly: false, expectCount: 1)
        let anchor = store.selectedJobIDs
        table.selectRowIndexes(IndexSet((lastRow - 2)...lastRow), byExtendingSelection: false)
        RunLoop.main.run(until: Date() + 1.5)
        let clicked = store.selectedJobIDs
        // The completed rows show the completed jobs in the store's order (highest job number
        // first), so the last row — the clicked end of this downward range — is the last of them.
        let expected = store.finishedJobs.last!.id
        let ok = clicked == [expected]
        if !ok { failures += 1 }
        print("\(ok ? "PASS" : "FAIL") ⇧-range of completed rows downwards keeps the clicked job (the last row, \(expected)): \(anchor.first!) → \(clicked.sorted())")
        report("  list after that range", expectQueuedOnly: false, expectCount: 1)
        print(failures == 0 ? "ALL PASS" : "FAILURES: \(failures)")
        exit(failures == 0 ? 0 : 1)
    }
}
