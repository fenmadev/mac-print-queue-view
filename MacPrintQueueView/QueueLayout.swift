import CoreGraphics

/// Size steps of the page thumbnails in the "In Queue" list (D38, D42). Step 1 is the base size;
/// step n is n times that size.
enum ThumbnailZoom {
    static let steps = 1...7
    static let defaultStep = 1
    /// Size of the thumbnail at step 1.
    static let baseSize = CGSize(width: 40, height: 52)
    /// Longest side, in pixels, of the rendered thumbnail image: the largest step at 2× scale.
    static let renderPixelSize = baseSize.height * CGFloat(steps.upperBound) * 2

    static func size(step: Int) -> CGSize {
        let factor = CGFloat(clamped(step))
        return CGSize(width: baseSize.width * factor, height: baseSize.height * factor)
    }

    /// Room the job column keeps next to the thumbnail for title, status and time.
    static let textWidth: CGFloat = 200

    /// Minimum width of the job column at a step: 240 points at step 1, growing with the thumbnail.
    static func minimumColumnWidth(step: Int) -> CGFloat {
        size(step: step).width + textWidth
    }

    /// Ideal width of the job column at a step: 300 points at step 1, growing with the thumbnail.
    static func idealColumnWidth(step: Int) -> CGFloat {
        size(step: step).width + textWidth + 60
    }

    static func clamped(_ step: Int) -> Int {
        min(max(step, steps.lowerBound), steps.upperBound)
    }

    static func canZoomIn(from step: Int) -> Bool { step < steps.upperBound }
    static func canZoomOut(from step: Int) -> Bool { step > steps.lowerBound }
}

/// Grid in which several selected jobs are previewed side by side (D39).
enum PreviewGrid {
    /// At most this many jobs are shown in the grid.
    static let maximumCount = 16

    /// Columns and rows for `count` selected jobs: 2 → 2 × 1, 3–4 → 2 × 2, 5–9 → 3 × 3,
    /// 10 or more → 4 × 4 (only the first 16 are shown).
    static func layout(for count: Int) -> (columns: Int, rows: Int) {
        switch count {
        case ...1: (1, 1)
        case 2: (2, 1)
        case 3...4: (2, 2)
        case 5...9: (3, 3)
        default: (4, 4)
        }
    }
}

/// Selection rules of the job list (D39): several jobs can be selected only in "In Queue";
/// a completed job is always selected on its own.
enum QueueSelection {
    /// The selection to use when the list asks for `new`. `previous` is the current selection
    /// and `queued` the IDs of the jobs in the queue (all other IDs are completed jobs).
    /// - A single job, or only queued jobs: unchanged.
    /// - Exactly one completed job was added (a click or ⌘-click on it): only that job.
    /// - Otherwise the queued jobs are kept (for example queue jobs ⌘-clicked while a completed
    ///   job was selected, or select-all); if there are none (a ⇧-click range of completed jobs),
    ///   the clicked job: the end of the range farthest from the previous selection. The list shows
    ///   the highest job number first, so a range below the previous selection ends at its lowest
    ///   job number and a range above it at its highest.
    static func normalized<ID: Hashable & Comparable>(_ new: Set<ID>, previous: Set<ID>, queued: Set<ID>) -> Set<ID> {
        let completed = new.subtracting(queued)
        guard new.count > 1, !completed.isEmpty else { return new }
        let added = new.subtracting(previous)
        if added.count == 1, let id = added.first, completed.contains(id) { return [id] }
        let kept = new.intersection(queued)
        if !kept.isEmpty { return kept }
        let addedCompleted = added.intersection(completed)
        guard let lowest = addedCompleted.min(), let highest = addedCompleted.max() else { return [completed.max()!] }
        if let below = previous.min(), highest < below { return [lowest] }
        return [highest]
    }

    /// The selection after a refresh (D44). A selected job that was in the queue and has left it —
    /// printed, canceled or aborted — leaves the selection, so its preview disappears right away.
    /// A completed job that the user selected in "Completed" stays selected while it is listed.
    /// Of several selected jobs only those still in the queue stay (they are all queue jobs, D39).
    static func keptAfterRefresh<ID: Hashable>(_ selected: Set<ID>, previouslyQueued: Set<ID>,
                                               queued: Set<ID>, completed: Set<ID>) -> Set<ID> {
        let kept = selected.filter { id in
            queued.contains(id) || (completed.contains(id) && !previouslyQueued.contains(id))
        }
        return selected.count > 1 ? kept.intersection(queued) : kept
    }
}

/// Reordering of several selected jobs with the arrow buttons (D39).
enum QueueReorder {
    /// The new order when the selected jobs move one place up (`offset` -1) or down (+1).
    /// The selected jobs are first gathered into one block, in their current order, at the first
    /// selected job (moving up) or the last selected job (moving down); the block then moves one
    /// place. Returns nil when the order would not change.
    ///
    /// `order` is the list of jobs that can change position (the waiting jobs, in print order);
    /// selected IDs that are not in `order` are ignored.
    static func gatheredMove<ID: Hashable>(_ order: [ID], selected: Set<ID>, by offset: Int) -> [ID]? {
        guard offset == -1 || offset == 1 else { return nil }
        let block = order.filter { selected.contains($0) }
        guard !block.isEmpty else { return nil }
        let rest = order.filter { !selected.contains($0) }
        let position: Int
        if offset < 0 {
            // Unselected jobs above the first selected job; the block goes one place higher.
            let before = order.firstIndex { selected.contains($0) }!
            position = max(before - 1, 0)
        } else {
            // Unselected jobs above the last selected job; the block goes one place lower.
            let last = order.lastIndex { selected.contains($0) }!
            let before = last + 1 - block.count
            position = min(before + 1, rest.count)
        }
        let result = Array(rest[..<position]) + block + Array(rest[position...])
        return result == order ? nil : result
    }

    /// The grid order after dragging block `moving` onto block `target` (D40): the dragged block
    /// takes the target's place and the blocks in between shift one place. Nil if nothing changes.
    static func gridMove<ID: Hashable>(_ grid: [ID], moving: ID, onto target: ID) -> [ID]? {
        guard moving != target, let from = grid.firstIndex(of: moving),
              let to = grid.firstIndex(of: target) else { return nil }
        var result = grid
        result.remove(at: from)
        result.insert(moving, at: to)
        return result
    }

    /// The new order when the jobs of `arranged` are put, in that order, on the places they
    /// occupy together in `order`; all other jobs keep their place (D40). Jobs of `arranged`
    /// that are not in `order` are ignored. Nil if nothing changes.
    static func rearranged<ID: Hashable>(_ order: [ID], as arranged: [ID]) -> [ID]? {
        let members = Set(order).intersection(arranged)
        var next = arranged.filter { members.contains($0) }.makeIterator()
        let result = order.map { members.contains($0) ? next.next()! : $0 }
        return result == order ? nil : result
    }
}

/// Pausing several jobs (D17, D39): the state of each job is checked right before that job is
/// paused, so a job that started printing while earlier jobs were being paused is left alone.
enum BulkPause {
    /// The state of one job as read from cupsd right before pausing it.
    enum Check: Sendable {
        /// Waiting to print: pause it.
        case waiting
        /// Has started printing: do not pause it (CUPS would abort it and start it again).
        case printing
        /// Anything else (already paused, finished or gone): leave it alone.
        case other
    }

    struct Outcome {
        var paused = 0
        var started = 0
        /// The first error of a state query or a pause; the remaining jobs are still handled.
        var failure: (any Error)?
    }

    /// Checks and pauses the jobs one after another, in the given order. A job whose state
    /// cannot be read is not paused (its error is reported) and the next job is still handled.
    static func run<ID>(_ ids: [ID], check: (ID) throws -> Check, hold: (ID) throws -> Void) -> Outcome {
        var outcome = Outcome()
        for id in ids {
            do {
                switch try check(id) {
                case .waiting:
                    try hold(id)
                    outcome.paused += 1
                case .printing:
                    outcome.started += 1
                case .other:
                    break
                }
            } catch {
                outcome.failure = outcome.failure ?? error
            }
        }
        return outcome
    }
}
