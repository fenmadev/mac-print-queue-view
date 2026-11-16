// Phase 01 evidence E01: the pure logic of RM-001 and RM-003 in QueueLayout.swift, including the
// per-job state check when pausing several jobs (JOB-001-AC11, fake client).
// Build from the project root:
//   swiftc -O MacPrintQueueView/QueueLayout.swift _docs/phases/phase-01/evidence/E01/main.swift -o <tmp>/e01
// No CUPS call, no print job.
import CoreGraphics

var failures = 0
func check(_ label: String, _ actual: String, _ expected: String) {
    let ok = actual == expected
    if !ok { failures += 1 }
    print("\(ok ? "PASS" : "FAIL") \(label): \(actual)\(ok ? "" : " (expected \(expected))")")
}

// QUEUE-001-AC08: zoom steps (D38, D42: seven steps).
for step in 0...8 {
    let size = ThumbnailZoom.size(step: step)
    print("step \(step) -> \(Int(size.width))x\(Int(size.height)), in \(ThumbnailZoom.canZoomIn(from: ThumbnailZoom.clamped(step))), out \(ThumbnailZoom.canZoomOut(from: ThumbnailZoom.clamped(step)))")
}
check("step 1", "\(ThumbnailZoom.size(step: 1))", "(40.0, 52.0)")
check("step 5 = 5 x step 1", "\(ThumbnailZoom.size(step: 5))", "(200.0, 260.0)")
check("step 6 = 6 x step 1", "\(ThumbnailZoom.size(step: 6))", "(240.0, 312.0)")
check("step 7 = 7 x step 1", "\(ThumbnailZoom.size(step: 7))", "(280.0, 364.0)")
check("steps", "\(ThumbnailZoom.steps)", "1...7")
check("default step", "\(ThumbnailZoom.defaultStep)", "1")
check("render pixel size", "\(ThumbnailZoom.renderPixelSize)", "728.0")
check("no zoom out at 1, no zoom in at 7", "\(ThumbnailZoom.canZoomOut(from: 1)) \(ThumbnailZoom.canZoomIn(from: 7))", "false false")
check("zoom in at 5 and 6", "\(ThumbnailZoom.canZoomIn(from: 5)) \(ThumbnailZoom.canZoomIn(from: 6))", "true true")

// PREV-001-AC07: grid layout (D39).
let expected: [Int: String] = [2: "2x1", 3: "2x2", 4: "2x2", 5: "3x3", 9: "3x3", 10: "4x4", 11: "4x4", 16: "4x4", 17: "4x4", 40: "4x4"]
for count in expected.keys.sorted() {
    let layout = PreviewGrid.layout(for: count)
    check("grid \(count)", "\(layout.columns)x\(layout.rows)", expected[count]!)
}
for count in 2...16 {
    // Every shown job has a cell.
    let layout = PreviewGrid.layout(for: count)
    if layout.columns * layout.rows < count { failures += 1; print("FAIL grid \(count) has too few cells") }
}
check("maximum shown", "\(PreviewGrid.maximumCount)", "16")

// JOB-001-AC10: moving a selection with the arrow buttons (D39).
func move(_ order: String, _ selected: String, _ offset: Int) -> String {
    let result = QueueReorder.gatheredMove(order.map(String.init), selected: Set(selected.map(String.init)), by: offset)
    return result.map { $0.joined() } ?? "nil"
}
check("D39 example: A B C D E, B D up", move("ABCDE", "BD", -1), "BDACE")
check("again up (already at top)", move("BDACE", "BD", -1), "nil")
check("B D down (mirror, gathered at D)", move("ABCDE", "BD", 1), "ACEBD")
check("contiguous C D up", move("ABCDE", "CD", -1), "ACDBE")
check("contiguous C D down", move("ABCDE", "CD", 1), "ABECD")
check("single B up = swap", move("ABCDE", "B", -1), "BACDE")
check("single B down = swap", move("ABCDE", "B", 1), "ACBDE")
check("single A up (top)", move("ABCDE", "A", -1), "nil")
check("single E down (bottom)", move("ABCDE", "E", 1), "nil")
check("A C at top up: gathered only", move("ABCDE", "AC", -1), "ACBDE")
check("C E at bottom down: gathered only", move("ABCDE", "CE", 1), "ABDCE")
check("all selected", move("ABCDE", "ABCDE", -1), "nil")
check("none selected", move("ABCDE", "", -1), "nil")
check("unknown IDs ignored", move("ABCDE", "BX", -1), "BACDE")
check("offset 2 refused", move("ABCDE", "B", 2), "nil")
check("A E up", move("ABCDE", "AE", -1), "AEBCD")
check("A E down", move("ABCDE", "AE", 1), "BCDAE")

// JOB-001-AC12: dragging one block of the preview grid (D40).
func gridMove(_ grid: String, _ moving: Character, _ target: Character) -> String {
    QueueReorder.gridMove(grid.map(String.init), moving: String(moving), onto: String(target)).map { $0.joined() } ?? "nil"
}
func rearranged(_ order: String, _ arranged: String) -> String {
    QueueReorder.rearranged(order.map(String.init), as: arranged.map(String.init)).map { $0.joined() } ?? "nil"
}
check("grid B D E, drag E onto B", gridMove("BDE", "E", "B"), "EBD")
check("queue A B C D E as E B D", rearranged("ABCDE", "EBD"), "AECBD")
check("grid B D E, drag B onto E", gridMove("BDE", "B", "E"), "DEB")
check("queue A B C D E as D E B", rearranged("ABCDE", "DEB"), "ADCEB")
check("grid drag D onto E", gridMove("BDE", "D", "E"), "BED")
check("drag onto itself", gridMove("BDE", "D", "D"), "nil")
check("unknown target", gridMove("BDE", "D", "X"), "nil")
check("unchanged arrangement", rearranged("ABCDE", "BDE"), "nil")
check("arranged job not in order ignored", rearranged("ABCDE", "XEB"), "AECDB")

// QUEUE-001-AC09: selection rules (D39). Queue: 1 2 3; completed: 7 8 9.
let queued: Set<Int> = [1, 2, 3]
func normalized(_ new: Set<Int>, _ previous: Set<Int>) -> String {
    QueueSelection.normalized(new, previous: previous, queued: queued).sorted().map(String.init).joined(separator: ",")
}
check("cmd-click queue jobs", normalized([1, 3], [1]), "1,3")
check("single completed", normalized([8], [1, 3]), "8")
check("cmd-click completed onto queue selection", normalized([1, 3, 8], [1, 3]), "8")
check("cmd-click queue job onto completed", normalized([8, 2], [8]), "2")
check("select all", normalized([1, 2, 3, 7, 8, 9], [1]), "1,2,3")
check("shift range in completed, downwards: the clicked (lowest) job", normalized([7, 8, 9], [9]), "7")
check("shift range in completed, upwards: the clicked (highest) job", normalized([7, 8, 9], [7]), "9")
check("range only completed, from nothing: the top job", normalized([7, 8], []), "8")
check("deselect to empty", normalized([], [1, 2]), "")

// QUEUE-001-AC11: the selection after a refresh (D44). Queue before: 1 2 3; completed: 7 8 9.
func kept(_ selected: Set<Int>, queuedNow: Set<Int>, completedNow: Set<Int>) -> String {
    QueueSelection.keptAfterRefresh(selected, previouslyQueued: [1, 2, 3], queued: queuedNow, completed: completedNow)
        .sorted().map(String.init).joined(separator: ",")
}
check("selected queue job printed (now completed)", kept([2], queuedNow: [1, 3], completedNow: [2, 7, 8, 9]), "")
check("selected queue job canceled, not yet listed", kept([2], queuedNow: [1, 3], completedNow: [7, 8, 9]), "")
check("selected queue job still queued", kept([2], queuedNow: [1, 2, 3], completedNow: [7, 8, 9]), "2")
check("selected completed job stays", kept([8], queuedNow: [1, 2, 3], completedNow: [7, 8, 9]), "8")
check("selected completed job removed", kept([8], queuedNow: [1, 2, 3], completedNow: [7, 9]), "")
check("completed job printed again (back in the queue)", kept([8], queuedNow: [1, 2, 3, 8], completedNow: [7, 9]), "8")
check("several: one printed", kept([1, 2, 3], queuedNow: [1, 3], completedNow: [2, 7, 8, 9]), "1,3")
check("several: all canceled", kept([1, 2], queuedNow: [3], completedNow: [1, 2, 7, 8, 9]), "")

// JOB-001-AC11: pausing several jobs re-checks each job right before pausing it (D17, D39).
// A fake client: the states change while the jobs are handled, as cupsd's could.
struct FakeError: Error {}
final class FakeQueue {
    var state: [String: BulkPause.Check]
    var log: [String] = []
    var onHold: [String: () -> Void] = [:]
    var failingCheck: Set<String> = []
    var failingHold: Set<String> = []
    init(_ state: [String: BulkPause.Check]) { self.state = state }
    func check(_ id: String) throws -> BulkPause.Check {
        log.append("check \(id)")
        if failingCheck.contains(id) { throw FakeError() }
        return state[id] ?? .other
    }
    func hold(_ id: String) throws {
        log.append("hold \(id)")
        // Other jobs may change state while this request is under way, also when it fails.
        onHold[id]?()
        if failingHold.contains(id) { throw FakeError() }
        state[id] = .other
    }
    func run(_ ids: [String]) -> String {
        let outcome = BulkPause.run(ids, check: check, hold: hold)
        return "paused \(outcome.paused), started \(outcome.started), failure \(outcome.failure != nil); " + log.joined(separator: ", ")
    }
}
var fake = FakeQueue(["A": .waiting, "B": .waiting, "C": .waiting])
fake.onHold["A"] = { fake.state["B"] = .printing }
check("B starts printing while A is paused: B never held", fake.run(["A", "B", "C"]),
      "paused 2, started 1, failure false; check A, hold A, check B, check C, hold C")
fake = FakeQueue(["A": .waiting, "B": .waiting, "C": .waiting])
fake.failingHold = ["A"]
fake.onHold["A"] = { fake.state["B"] = .printing }
check("pausing A fails, B started meanwhile: B never held, C still paused", fake.run(["A", "B", "C"]),
      "paused 1, started 1, failure true; check A, hold A, check B, check C, hold C")
fake = FakeQueue(["A": .waiting, "B": .waiting, "C": .waiting])
fake.failingCheck = ["B"]
check("state of B cannot be read: B not held, C still paused", fake.run(["A", "B", "C"]),
      "paused 2, started 0, failure true; check A, hold A, check B, check C, hold C")
// Negative control: the earlier implementation read all states once and then paused every job
// that was waiting in that snapshot; with the same fake client it pauses B although B is printing.
fake = FakeQueue(["A": .waiting, "B": .waiting, "C": .waiting])
fake.onHold["A"] = { fake.state["B"] = .printing }
let snapshot = ["A", "B", "C"].filter { (try? fake.check($0)) == .waiting }
for id in snapshot { try? fake.hold(id) }
check("negative control, one snapshot for all jobs: B is held while printing", fake.log.joined(separator: ", "),
      "check A, check B, check C, hold A, hold B, hold C")
fake = FakeQueue(["A": .printing, "B": .other, "C": .waiting])
check("printing, gone or paused jobs are not held", fake.run(["A", "B", "C"]),
      "paused 1, started 1, failure false; check A, check B, check C, hold C")

print(failures == 0 ? "ALL PASS" : "FAILURES: \(failures)")
