// Phase 01 evidence E07: moving several jobs, applied to the real cupsd (JOB-001-AC10, AC12).
// Run through run.sh, which submits five held test jobs "MPQV E07 A" … "E" (held, so they are never
// printed) and removes them afterwards. The harness refuses to move anything if the printer's queue
// holds any other job, because every move re-assigns the priorities of the user's waiting jobs.
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

/// The print order according to cupsd, as the letters of the test jobs.
func cupsdOrder() -> String {
    let jobs = ((try? CUPSClient.activeJobs()) ?? []).filter { $0.printer == printer }.sorted(by: QueueStore.queueOrder)
    return jobs.map { $0.title.hasPrefix("MPQV E07 ") ? String($0.title.dropFirst(9)) : "?" }.joined()
}

@MainActor
func run() async {
    let store = QueueStore()
    store.selectedPrinterName = printer
    await store.refresh()
    let queue = store.activeJobs(for: printer)
    guard queue.count == 5, queue.allSatisfy({ $0.title.hasPrefix("MPQV E07 ") }) else {
        print("FAIL the queue of \(printer) holds other jobs too (\(queue.count) jobs); nothing is moved")
        failures += 1
        return
    }
    var id: [String: Int32] = [:]
    for job in queue { id[String(job.title.dropFirst(9))] = job.id }
    func ids(_ letters: String) -> Set<Int32> { Set(letters.map { id[String($0)]! }) }
    func safe() async -> Bool {
        await store.refresh()
        let all = store.activeJobs(for: printer)
        if all.count != 5 || !all.allSatisfy({ $0.title.hasPrefix("MPQV E07 ") }) {
            print("FAIL another job appeared in the queue; stopping"); failures += 1; return false
        }
        return true
    }

    check("start", cupsdOrder(), "ABCDE")

    // D39: B and D up → gathered at B, then one place up.
    guard await safe() else { return }
    await store.move(ids("BD"), by: -1)
    check("B D up (D39 example)", cupsdOrder(), "BDACE")

    // Down mirrors: gathered at the last selected job (D), then one place down.
    guard await safe() else { return }
    await store.move(ids("BD"), by: 1)
    check("B D down", cupsdOrder(), "ABDCE")

    // D40: grid of the selected B and D (in queue order B D); drag D onto B.
    guard await safe() else { return }
    store.selection = ids("BD")
    check("grid shows", store.gridJobs.map { String($0.title.dropFirst(9)) }.joined(), "BD")
    await store.moveInGrid(id["D"]!, onto: id["B"]!)
    check("grid: D dragged onto B", cupsdOrder(), "ADBCE")
    await store.refresh()
    check("grid after the drag", store.gridJobs.map { String($0.title.dropFirst(9)) }.joined(), "DB")

    // Dragging the selected rows C and E in the list to the top.
    guard await safe() else { return }
    let shown = store.activeJobs(for: printer)
    let source = IndexSet(shown.indices.filter { ["C", "E"].contains(String(shown[$0].title.dropFirst(9))) })
    await store.move(in: shown, from: source, to: 0)
    check("list: C and E dragged to the top", cupsdOrder(), "CEADB")
    check("no error", store.actionError ?? "none", "none")
}

let done = DispatchSemaphore(value: 0)
Task { @MainActor in
    await run()
    print(failures == 0 ? "ALL PASS" : "FAILURES: \(failures)")
    done.signal()
}
while done.wait(timeout: .now() + 0.05) == .timedOut { RunLoop.main.run(until: Date() + 0.05) }
exit(failures == 0 ? 0 : 1)
