// Phase 01 evidence E04: the store with several selected jobs (RM-003, RM-004) and the selection of
// a job that leaves the queue (D44), against the real
// cupsd, with test jobs only. Run through run.sh, which creates the test jobs and removes them.
// Test jobs: two held jobs with a small text document ("MPQV E04 A", "MPQV E04 B"; held, so they
// never print) and two empty jobs without a document ("MPQV E04 empty C/D", Create-Job only;
// cupsd aborts them when released, without processing anything).
// The user's own jobs in the queue are not moved, paused, resumed or canceled: the harness only
// reads them, and computes (without applying) whether a move would be possible.
import CUPS
import Foundation
import SwiftUI // QueueStore uses SwiftUI's move(fromOffsets:toOffset:)

let printer = CommandLine.arguments[1]
var failures = 0
func check(_ label: String, _ actual: String, _ expected: String) {
    let ok = actual == expected
    if !ok { failures += 1 }
    print("\(ok ? "PASS" : "FAIL") \(label): \(actual)\(ok ? "" : " (expected \(expected))")")
}

@MainActor
func run() async {
    let store = QueueStore()
    store.selectedPrinterName = printer
    await store.refresh()
    let tests = store.activeJobs.filter { $0.title.hasPrefix("MPQV E04") }
    guard let a = tests.first(where: { $0.title == "MPQV E04 A" }), let b = tests.first(where: { $0.title == "MPQV E04 B" }),
          let c = tests.first(where: { $0.title == "MPQV E04 empty C" }), let d = tests.first(where: { $0.title == "MPQV E04 empty D" }),
          let completed = store.finishedJobs.first else {
        print("FAIL test jobs or a completed job not found"); failures += 1; return
    }
    print("test jobs A \(a.id), B \(b.id), C \(c.id), D \(d.id); completed job used for selection \(completed.id)")

    // QUEUE-001-AC09: selection rules in the store.
    store.selection = [a.id, b.id]
    check("select A and B", "\(store.selectedJobIDs == [a.id, b.id])", "true")
    store.selection = [a.id, b.id, completed.id]
    check("cmd-click completed job", "\(store.selectedJobIDs == [completed.id])", "true")
    store.selection = [completed.id, a.id]
    check("cmd-click queue job onto completed", "\(store.selectedJobIDs == [a.id])", "true")

    // PREV-001-AC07: grid blocks for A and B (first page, page count of the whole job).
    store.selection = [a.id, b.id]
    check("grid jobs", "\(store.gridJobs.map(\.id) == [a.id, b.id].sorted { x, y in store.activeJobs.firstIndex { $0.id == x }! < store.activeJobs.firstIndex { $0.id == y }! })", "true")
    for _ in 0..<100 where store.tiles.values.contains(where: \.isLoading) {
        try? await Task.sleep(for: .milliseconds(100))
    }
    for job in [a, b] {
        switch store.tiles[job.id] {
        case .loaded(let firstPage, let pageCount, let warning):
            check("block \(job.title)", "pages \(pageCount), block pages \(firstPage.pageCount), warning \(warning != nil)", "pages 1, block pages 1, warning false")
        default:
            check("block \(job.title)", "\(String(describing: store.tiles[job.id]))", "loaded")
        }
    }
    check("preview state with a grid is none", "\(String(describing: store.preview))", "none")

    // JOB-001: what the actions allow for A and B (both held = paused). Moves are only computed.
    check("can pause A+B (paused)", "\(store.canPause([a.id, b.id]))", "false")
    check("can resume A+B", "\(store.canResume([a.id, b.id]))", "true")
    check("can cancel A+B", "\(store.canCancel([a.id, b.id]))", "true")
    check("can drag A in grid", "\(store.canDragInGrid(a))", "true")
    print("can move A+B up: \(store.canMove([a.id, b.id], by: -1)), down: \(store.canMove([a.id, b.id], by: 1)) (computed only, not applied)")

    // QUEUE-001-AC11: a selected job that leaves the queue (here: aborted by cupsd after resuming)
    // leaves the selection, so its preview disappears right away (D44).
    store.selection = [c.id]
    check("empty job C selected alone", "\(store.selectedJobIDs == [c.id])", "true")

    // JOB-001-AC11: resume several jobs at once (empty jobs only).
    await store.resume([c.id, d.id])
    await store.refresh()
    if store.activeJobs.contains(where: { $0.id == c.id }) {
        // The printer is busy with other jobs, so C waits instead of being aborted: cancel it.
        print("  C still waits behind other jobs; canceling it to make it leave the queue")
        await store.cancel(jobID: c.id)
        await store.refresh()
    }
    check("C left the queue: selection empty, preview none", "\(store.selectedJobIDs.isEmpty) \(store.preview)", "true none")
    for job in [c, d] {
        let state = (try? CUPSClient.jobState(id: job.id)).flatMap { $0 }
        check("resumed empty job \(job.title) is no longer held", "\(state.map { $0 != IPP_JSTATE_HELD } ?? true)", "true")
        // (C may already have been canceled above; D waits or is aborted.)
        print("  state of \(job.id) after resume: \(state.map { "\($0.rawValue)" } ?? "none")")
    }

    // JOB-001-AC09: canceling several jobs asks first, then cancels all of them.
    store.selection = [a.id, b.id]
    store.deleteSelection()
    if case .cancel(let jobs)? = store.pendingAction {
        check("⌫ with two jobs asks for confirmation", "\(Set(jobs.map(\.id)) == [a.id, b.id])", "true")
        store.pendingAction = nil
        await store.perform(.cancel(jobs))
    } else {
        check("⌫ with two jobs asks for confirmation", "\(String(describing: store.pendingAction))", "cancel")
    }
    for job in [a, b] {
        let state = (try? CUPSClient.jobState(id: job.id)).flatMap { $0 }
        check("\(job.title) canceled", "\(state == IPP_JSTATE_CANCELED)", "true")
    }
    check("selection after canceling both", "\(store.selectedJobIDs.isEmpty)", "true")
    check("no error", "\(store.actionError ?? "none")", "none")
}

let done = DispatchSemaphore(value: 0)
Task { @MainActor in
    await run()
    print(failures == 0 ? "ALL PASS" : "FAILURES: \(failures)")
    done.signal()
}
while done.wait(timeout: .now() + 0.05) == .timedOut { RunLoop.main.run(until: Date() + 0.05) }
