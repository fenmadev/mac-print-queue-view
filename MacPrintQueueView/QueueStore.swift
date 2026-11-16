import AppKit
import Foundation
import Observation
import PDFKit

/// Keeps track of printers, jobs and the selected preview.
/// The queue is requested from CUPS every 2 seconds, so new and disappearing
/// jobs show up automatically.
@MainActor
@Observable
final class QueueStore {

    enum PreviewState {
        case none
        case loading
        /// The rendered pages and, if part of the job could not be rendered, a warning that says which part.
        case loaded(PDFDocument, warning: String?)
        case unavailable(String)
    }

    private(set) var printers: [Printer] = []
    private(set) var activeJobs: [PrintJob] = []
    private(set) var finishedJobs: [PrintJob] = []
    private(set) var connectionError: String?
    private(set) var preview: PreviewState = .none
    /// Size step of the thumbnails in the queue (D38, D42); not remembered after a restart.
    var thumbnailStep = ThumbnailZoom.defaultStep

    var selectedPrinterName: String? {
        didSet {
            guard selectedPrinterName != oldValue else { return }
            finishedJobs = []
            selectedJobID = nil
            Task { await refresh() }
        }
    }

    /// The selected jobs. Several jobs can only be selected in "In Queue"; a completed job is
    /// always selected on its own (D39). See `QueueSelection.normalized`.
    private(set) var selectedJobIDs: Set<Int32> = []

    /// The list selection. Setting it applies the selection rules and loads the preview.
    var selection: Set<Int32> {
        get { selectedJobIDs }
        set {
            let queued = Set(activeJobs.map(\.id))
            let normalized = QueueSelection.normalized(newValue, previous: selectedJobIDs, queued: queued)
            // The list has highlighted rows that the rules dropped: make it redraw with the
            // selection that applies, also when that selection itself does not change.
            if normalized != newValue { selectionCorrections += 1 }
            guard normalized != selectedJobIDs else { return }
            selectedJobIDs = normalized
            loadPreview()
        }
    }

    /// Counts the times the list asked for a selection that the rules corrected. The job list reads
    /// it, so it redraws with the corrected selection (and the table drops the rows it highlighted).
    private(set) var selectionCorrections = 0

    /// The selected job when exactly one job is selected.
    var selectedJobID: Int32? {
        get { selectedJobIDs.count == 1 ? selectedJobIDs.first : nil }
        set { selection = newValue.map { [$0] } ?? [] }
    }

    /// How many finished jobs are shown per printer.
    private let finishedLimit = 50
    private var previewTask: Task<Void, Never>?

    var selectedJob: PrintJob? {
        guard let id = selectedJobID else { return nil }
        return activeJobs.first { $0.id == id } ?? finishedJobs.first { $0.id == id }
    }

    /// The selected jobs that are in the queue, in print order.
    var selectedQueuedJobs: [PrintJob] {
        activeJobs.filter { selectedJobIDs.contains($0.id) }
    }

    /// Is every selected job in the queue (and at least one selected)?
    var selectionIsQueued: Bool {
        !selectedJobIDs.isEmpty && selectedJobIDs.allSatisfy { id in activeJobs.contains { $0.id == id } }
    }

    func activeJobs(for printer: String) -> [PrintJob] {
        activeJobs.filter { $0.printer == printer }
    }

    // MARK: Actions that need confirmation

    enum PendingAction {
        /// Permanently remove a finished job, including the retained document.
        case purge(PrintJob)
        /// Remove all of the user's own finished jobs for a printer.
        case purgeAll(printer: String)
        /// Put a finished job back in the queue (asked from the row buttons and swipe actions,
        /// where a mis-click would otherwise waste paper).
        case reprint(PrintJob)
        /// Cancel several jobs in the queue at once (one job is canceled without asking, D18).
        case cancel([PrintJob])

        var isDestructive: Bool {
            if case .reprint = self { false } else { true }
        }
    }

    /// Action awaiting confirmation.
    var pendingAction: PendingAction?
    /// Error message after a failed action.
    var actionError: String?
    /// Information after an action that did not do everything that was asked, without failing
    /// (for example jobs that were no longer completed and therefore not removed).
    var actionNotice: String?

    /// Own jobs in the queue can be canceled, also while printing. This happens immediately,
    /// without confirmation: the job moves to "Completed" and can be printed again from there.
    func canCancel(jobID: Int32?) -> Bool {
        queuedOwnJob(jobID) != nil
    }

    func cancel(jobID: Int32?) async {
        guard let job = queuedOwnJob(jobID) else { return }
        let (id, printer) = (job.id, job.printer)
        await run { try CUPSClient.cancelJob(id: id, printer: printer) }
    }

    /// How many of these jobs can be canceled (the user's own jobs in the queue). One is canceled
    /// right away, several after confirmation.
    func cancelableCount(_ ids: Set<Int32>) -> Int {
        queuedOwnJobs(ids).count
    }

    /// Can at least one of these jobs be canceled?
    func canCancel(_ ids: Set<Int32>) -> Bool {
        !queuedOwnJobs(ids).isEmpty
    }

    /// Cancels one job right away, or asks for confirmation before canceling several (D39).
    func requestCancel(_ ids: Set<Int32>) {
        let jobs = queuedOwnJobs(ids)
        if jobs.count == 1 {
            let id = jobs[0].id
            Task { await cancel(jobID: id) }
        } else if jobs.count > 1 {
            pendingAction = .cancel(jobs)
        }
    }

    /// Own completed jobs can be removed from the list (permanently, after confirmation).
    func canRemove(jobID: Int32?) -> Bool {
        guard let jobID, let job = finishedJobs.first(where: { $0.id == jobID }) else { return false }
        return job.user == CUPSClient.currentUser
    }

    func requestRemove(jobID: Int32?) {
        guard canRemove(jobID: jobID), let job = job(withID: jobID) else { return }
        pendingAction = .purge(job)
    }

    /// The ⌫ key: cancel the selected jobs in the queue (one right away, several after
    /// confirmation), or ask to remove a completed job.
    func deleteSelection() {
        if canCancel(selectedJobIDs) {
            requestCancel(selectedJobIDs)
        } else {
            requestRemove(jobID: selectedJobID)
        }
    }

    var canPurgeAll: Bool {
        finishedJobs.contains { $0.user == CUPSClient.currentUser }
    }

    func requestPurgeAll() {
        guard canPurgeAll, let printer = selectedPrinterName else { return }
        pendingAction = .purgeAll(printer: printer)
    }

    func requestReprint(jobID: Int32?) {
        guard canRestart(jobID: jobID), let job = job(withID: jobID) else { return }
        pendingAction = .reprint(job)
    }

    func perform(_ action: PendingAction) async {
        // Removal re-checks each job's state with cupsd right before acting, so a confirmation
        // that was opened earlier can never remove a job that is back in the queue.
        let result = await Task.detached(priority: .userInitiated) {
            Result { () throws -> String? in
                switch action {
                case .purge(let job):
                    let removed = try CUPSClient.purgeJobIfFinished(id: job.id, printer: job.printer)
                    return removed ? nil
                        : String(localized: "“\(job.displayTitle)” is no longer completed and was not removed.")
                case .purgeAll(let printer):
                    let outcome = try CUPSClient.purgeFinishedJobs(printer: printer)
                    return outcome.skipped == 0 ? nil
                        : String(localized: "Jobs no longer completed, and therefore not removed: \(outcome.skipped)")
                case .reprint(let job):
                    try CUPSClient.restartJob(id: job.id)
                    return nil
                case .cancel(let jobs):
                    // Cancel every job, also when one fails; report the first failure.
                    var failure: Error?
                    for job in jobs {
                        do { try CUPSClient.cancelJob(id: job.id, printer: job.printer) } catch { failure = failure ?? error }
                    }
                    if let failure { throw failure }
                    return nil
                }
            }
        }.value
        switch result {
        case .success(let notice?): actionNotice = notice
        case .success(nil): break
        case .failure(let error): actionError = error.localizedDescription
        }
        await refresh()
    }

    private func job(withID id: Int32?) -> PrintJob? {
        guard let id else { return nil }
        return activeJobs.first { $0.id == id } ?? finishedJobs.first { $0.id == id }
    }

    // MARK: Printing again

    /// Only own jobs from the "Completed" list can be put back in the queue.
    func canRestart(jobID: Int32?) -> Bool {
        guard let jobID, let job = finishedJobs.first(where: { $0.id == jobID }) else { return false }
        return job.user == CUPSClient.currentUser
    }

    func restart(jobID: Int32?) async {
        guard let jobID, canRestart(jobID: jobID) else { return }
        let result = await Task.detached(priority: .userInitiated) {
            Result { try CUPSClient.restartJob(id: jobID) }
        }.value
        if case .failure(let error) = result {
            actionError = error.localizedDescription
        }
        await refresh()
    }

    // MARK: Pausing

    /// Own jobs that are waiting to print can be paused; a job that is already printing cannot
    /// (CUPS would abort it and start it again from page 1 when resumed).
    func canPause(jobID: Int32?) -> Bool {
        queuedOwnJob(jobID)?.status == .pending
    }

    func canResume(jobID: Int32?) -> Bool {
        queuedOwnJob(jobID)?.status == .held
    }

    /// Can at least one of these jobs be paused, or resumed?
    func canPause(_ ids: Set<Int32>) -> Bool { queuedOwnJobs(ids).contains { $0.status == .pending } }
    func canResume(_ ids: Set<Int32>) -> Bool { queuedOwnJobs(ids).contains { $0.status == .held } }

    func pause(jobID: Int32?) async {
        guard let jobID else { return }
        await pause([jobID])
    }

    func resume(jobID: Int32?) async {
        guard let jobID else { return }
        await resume([jobID])
    }

    /// Pauses every waiting job among `ids`; jobs that are printing are left alone (D17, D39).
    func pause(_ ids: Set<Int32>) async {
        let candidates = queuedOwnJobs(ids).filter { $0.status == .pending }.map(\.id)
        guard !candidates.isEmpty else { return }
        // Check each job's current state with cupsd right before pausing that job: never pause a
        // job that has just started printing, also while earlier jobs are being paused. Every job
        // is handled, also when one fails; the first failure is reported (as for canceling).
        let outcome = await Task.detached(priority: .userInitiated) {
            let outcome = BulkPause.run(candidates, check: { id in
                switch try CUPSClient.jobStatus(id: id) {
                case .pending?: .waiting
                case .printing?: .printing
                default: .other
                }
            }, hold: { id in
                try CUPSClient.holdJob(id: id)
            })
            return (started: outcome.started, failure: outcome.failure?.localizedDescription)
        }.value
        if outcome.started > 0 {
            actionError = candidates.count == 1
                ? String(localized: "This job has already started printing and can no longer be paused. You can cancel it instead.")
                : String(localized: "Jobs that had already started printing and were not paused: \(outcome.started)")
        }
        if let failure = outcome.failure {
            actionError = failure
        }
        await refresh()
    }

    /// Resumes every paused job among `ids`.
    func resume(_ ids: Set<Int32>) async {
        let held = queuedOwnJobs(ids).filter { $0.status == .held }.map(\.id)
        guard !held.isEmpty else { return }
        // Release every job, also when one fails; report the first failure (as for pausing).
        await run {
            var failure: Error?
            for id in held {
                do { try CUPSClient.releaseJob(id: id) } catch { failure = failure ?? error }
            }
            if let failure { throw failure }
        }
    }

    /// The user's own jobs in the queue among `ids`, in print order.
    private func queuedOwnJobs(_ ids: Set<Int32>) -> [PrintJob] {
        let me = CUPSClient.currentUser
        return activeJobs.filter { ids.contains($0.id) && $0.user == me }
    }

    private func queuedOwnJob(_ id: Int32?) -> PrintJob? {
        guard let id, let job = activeJobs.first(where: { $0.id == id }),
              job.user == CUPSClient.currentUser else { return nil }
        return job
    }

    /// Runs a CUPS operation in the background, shows any error and refreshes the queue.
    private func run(_ operation: @escaping @Sendable () throws -> Void) async {
        let result = await Task.detached(priority: .userInitiated) { Result { try operation() } }.value
        if case .failure(let error) = result {
            actionError = error.localizedDescription
        }
        await refresh()
    }

    // MARK: Order

    /// The order in which cupsd prints: whatever is already printing first, then
    /// highest priority, and for equal priority the lowest job number.
    nonisolated static func queueOrder(_ a: PrintJob, _ b: PrintJob) -> Bool {
        if a.isWaiting != b.isWaiting { return !a.isWaiting }
        if a.priority != b.priority { return a.priority > b.priority }
        return a.id < b.id
    }

    /// Own pending or held jobs can change position.
    func canMove(_ job: PrintJob) -> Bool {
        job.isWaiting && job.user == CUPSClient.currentUser
    }

    /// Can the selected jobs (or the jobs of a context menu) move one place up (`offset` -1)
    /// or down (+1)? See `QueueReorder.gatheredMove`.
    func canMove(_ ids: Set<Int32>, by offset: Int) -> Bool {
        reorder(ids, by: offset) != nil
    }

    /// Moves the waiting jobs among `ids` one place, gathered into one block (D39). Jobs that are
    /// printing do not move.
    func move(_ ids: Set<Int32>, by offset: Int) async {
        guard let change = reorder(ids, by: offset) else { return }
        await apply(order: change.order, moved: change.moved)
    }

    /// The new order of the waiting jobs and the IDs of the jobs that move, or nil if nothing moves.
    private func reorder(_ ids: Set<Int32>, by offset: Int) -> (order: [PrintJob], moved: [Int32])? {
        let movable = activeJobs.filter { ids.contains($0.id) && canMove($0) }
        guard let printer = movable.first?.printer else { return nil }
        let waiting = activeJobs(for: printer).filter(\.isWaiting)
        let moved = movable.filter { $0.printer == printer }.map(\.id)
        guard let newOrder = QueueReorder.gatheredMove(waiting.map(\.id), selected: Set(moved), by: offset) else { return nil }
        let byID = Dictionary(waiting.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return (newOrder.compactMap { byID[$0] }, moved)
    }

    /// Dragging in the list; `jobs` is the list as shown (including jobs that are already printing).
    /// The dragged jobs that can move are put together at the drop position; jobs that are
    /// printing stay where they are.
    func move(in jobs: [PrintJob], from source: IndexSet, to destination: Int) async {
        let movable = IndexSet(source.filter { canMove(jobs[$0]) })
        guard !movable.isEmpty else { return }
        var reordered = jobs
        reordered.move(fromOffsets: movable, toOffset: destination)
        await apply(order: reordered.filter(\.isWaiting), moved: movable.map { jobs[$0].id })
    }

    /// Assigns priorities so that cupsd prints the waiting jobs in the given order.
    /// Only own jobs are changed; priorities stay as close as possible to the
    /// default of 50, so jobs added later still go to the end of the queue.
    ///
    /// Right before changing anything, the current state is requested from cupsd again: if a
    /// moved job has started printing in the meantime (e.g. while it was being dragged), nothing
    /// is changed and the list simply shows the actual queue again.
    private func apply(order requested: [PrintJob], moved: [Int32]) async {
        let current = await Task.detached(priority: .userInitiated) { try? CUPSClient.activeJobs() }.value
        guard let current else { return await refresh() }
        let currentByID = Dictionary(current.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        guard moved.allSatisfy({ currentByID[$0]?.isWaiting == true }) else { return await refresh() }
        // Use the current state and priorities; leave out jobs that are no longer waiting.
        let order = requested.compactMap { currentByID[$0.id] }.filter(\.isWaiting)

        let me = CUPSClient.currentUser
        var changes: [(id: Int32, priority: Int)] = []
        var below: PrintJob?
        for var job in order.reversed() {
            if job.user == me {
                var required = 1
                if let below {
                    // With equal priority the lowest job number goes first.
                    required = job.id < below.id ? below.priority : below.priority + 1
                }
                let priority = min(100, max(required, 50))
                if priority != job.priority { changes.append((job.id, priority)) }
                job.priority = priority
            }
            below = job
        }
        guard !changes.isEmpty else { return }

        // Show immediately; the next refresh confirms the order from cupsd.
        activeJobs = activeJobs.map { job in
            var job = job
            if let change = changes.first(where: { $0.id == job.id }) { job.priority = change.priority }
            return job
        }.sorted(by: Self.queueOrder)

        let result = await Task.detached(priority: .userInitiated) {
            Result { for change in changes { try CUPSClient.setPriority(change.priority, jobID: change.id) } }
        }.value
        if case .failure(let error) = result {
            actionError = error.localizedDescription
        }
        await refresh()
    }

    // MARK: Refreshing

    /// Keeps refreshing the queue for as long as the calling task runs.
    func run() async {
        while !Task.isCancelled {
            await refresh()
            try? await Task.sleep(for: .seconds(2))
        }
    }

    func refresh() async {
        let requested = selectedPrinterName
        let limit = finishedLimit
        let result = await Task.detached(priority: .utility) {
            Result {
                let printers = try CUPSClient.printers()
                let active = try CUPSClient.activeJobs()
                // Choose the printer from the fresh list first: if the selected printer has
                // disappeared, fall back to the default (or first) printer, so its completed jobs
                // are never requested from a printer that no longer exists.
                let chosen = requested.flatMap { name in printers.contains { $0.name == name } ? name : nil }
                    ?? (printers.first(where: \.isDefault) ?? printers.first)?.name
                let finished = try chosen.map { try CUPSClient.finishedJobs(printer: $0, limit: limit) } ?? []
                return (printers, active, chosen, finished)
            }
        }.value

        switch result {
        case .success(let (printers, active, chosen, finished)):
            connectionError = nil
            let previouslyQueued = Set(activeJobs.map(\.id))
            if printers != self.printers { self.printers = printers }
            let sortedActive = active.sorted(by: Self.queueOrder)
            if sortedActive != activeJobs { activeJobs = sortedActive }
            // Only apply if the user did not select another printer in the meantime.
            if requested == selectedPrinterName {
                if chosen != selectedPrinterName { selectedPrinterName = chosen }
                if finished != finishedJobs { finishedJobs = finished }
                // Jobs that left the queue (printed, canceled, aborted) or were removed leave the
                // selection, so their preview disappears right away (D44).
                let kept = QueueSelection.keptAfterRefresh(
                    selectedJobIDs, previouslyQueued: previouslyQueued,
                    queued: Set(activeJobs.map(\.id)), completed: Set(finishedJobs.map(\.id)))
                if kept != selectedJobIDs {
                    selectedJobIDs = kept
                    loadPreview()
                }
            }
            updateThumbnails()
            // The order can bring another selected job into the grid (more than 16 selected).
            if gridJobs.contains(where: { tiles[$0.id] == nil }) { loadTiles() }
        case .failure(let error):
            connectionError = error.localizedDescription
        }
    }

    // MARK: Thumbnails

    /// Thumbnails of the first page of jobs in the queue (not of completed jobs).
    private(set) var thumbnails: [Int32: NSImage] = [:]
    /// When a thumbnail was last attempted, so failures are retried only now and then
    /// (e.g. a job that is still being spooled has no document yet).
    private var thumbnailAttempts: [Int32: Date] = [:]
    private var thumbnailTask: Task<Void, Never>?

    private func updateThumbnails() {
        let queued = Set(activeJobs.map(\.id))
        if thumbnails.keys.contains(where: { !queued.contains($0) }) {
            thumbnails = thumbnails.filter { queued.contains($0.key) }
        }
        thumbnailAttempts = thumbnailAttempts.filter { queued.contains($0.key) }

        guard thumbnailTask == nil else { return }
        let me = CUPSClient.currentUser
        let now = Date()
        let wanted = activeJobs.filter { job in
            job.user == me && thumbnails[job.id] == nil
                && (thumbnailAttempts[job.id].map { now.timeIntervalSince($0) > 5 } ?? true)
        }.map(\.id)
        guard !wanted.isEmpty else { return }
        wanted.forEach { thumbnailAttempts[$0] = now }

        thumbnailTask = Task {
            for id in wanted {
                let png = await Task.detached(priority: .utility) {
                    try? PreviewBuilder.makeThumbnailPNG(from: CUPSClient.documents(jobID: id), maxPixelSize: ThumbnailZoom.renderPixelSize)
                }.value
                if let png, let image = NSImage(data: png), activeJobs.contains(where: { $0.id == id }) {
                    thumbnails[id] = image
                }
            }
            thumbnailTask = nil
        }
    }

    // MARK: Preview

    private func loadPreview() {
        previewTask?.cancel()
        loadTiles()
        guard let job = selectedJob else {
            preview = .none
            return
        }
        // Other users' jobs are protected by cupsd; don't try
        // (it would only lead to a password prompt or an error).
        if job.user != CUPSClient.currentUser {
            preview = .unavailable(String(localized: "This job belongs to another user. macOS only gives the owner of a job access to its content."))
            return
        }

        preview = .loading
        let jobID = job.id
        previewTask = Task {
            let result = await Task.detached(priority: .userInitiated) {
                Result { try PreviewBuilder.makePreview(from: CUPSClient.documents(jobID: jobID)) }
            }.value
            guard !Task.isCancelled, selectedJobID == jobID else { return }
            switch result {
            case .success(let result):
                if let document = PDFDocument(data: result.pdfData) {
                    let warning = result.problems.isEmpty ? nil
                        : ([String(localized: "Part of this job cannot be displayed:")] + result.problems).joined(separator: "\n")
                    preview = .loaded(document, warning: warning)
                } else {
                    preview = .unavailable(String(localized: "The document cannot be displayed."))
                }
            case .failure(let error):
                preview = .unavailable(error.localizedDescription)
            }
        }
    }

    // MARK: Preview of several jobs

    /// One block of the grid shown when several jobs are selected (D39): only the first page.
    enum TileState {
        case loading
        /// A document containing only the first page; `pageCount` is the number of pages of the
        /// whole job and `warning` says which part cannot be displayed, if any.
        case loaded(firstPage: PDFDocument, pageCount: Int, warning: String?)
        case unavailable(String)

        var isLoading: Bool {
            if case .loading = self { true } else { false }
        }
    }

    /// Blocks of the jobs shown in the grid, by job ID.
    private(set) var tiles: [Int32: TileState] = [:]
    private var tileTask: Task<Void, Never>?

    /// The jobs shown in the grid: the first selected jobs in print order (at most
    /// `PreviewGrid.maximumCount`), or none when fewer than two jobs are selected.
    var gridJobs: [PrintJob] {
        let jobs = selectedQueuedJobs
        return jobs.count > 1 ? Array(jobs.prefix(PreviewGrid.maximumCount)) : []
    }

    /// Can the block of this job be dragged in the grid? Jobs that are printing cannot move (D40).
    func canDragInGrid(_ job: PrintJob) -> Bool {
        canMove(job) && gridJobs.contains { $0.id == job.id }
    }

    /// Dragging block `jobID` onto block `targetID` in the grid (D40): the dragged job takes the
    /// target's place among the movable jobs of the grid; these jobs keep the places they occupy
    /// together in the queue, and all other jobs stay where they are.
    func moveInGrid(_ jobID: Int32, onto targetID: Int32) async {
        let grid = gridJobs.filter { canMove($0) }
        guard let printer = grid.first?.printer,
              let arranged = QueueReorder.gridMove(grid.map(\.id), moving: jobID, onto: targetID) else { return }
        let waiting = activeJobs(for: printer).filter(\.isWaiting)
        guard let newOrder = QueueReorder.rearranged(waiting.map(\.id), as: arranged) else { return }
        let byID = Dictionary(waiting.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let moved = zip(grid.map(\.id), arranged).filter { $0 != $1 }.map(\.1)
        await apply(order: newOrder.compactMap { byID[$0] }, moved: moved)
    }

    /// Fetches the first page of every job in the grid that does not have a block yet; blocks of
    /// jobs that are no longer in the grid are dropped.
    private func loadTiles() {
        tileTask?.cancel()
        let jobs = gridJobs
        let wanted = Set(jobs.map(\.id))
        if tiles.keys.contains(where: { !wanted.contains($0) }) {
            tiles = tiles.filter { wanted.contains($0.key) }
        }
        let me = CUPSClient.currentUser
        var missing: [Int32] = []
        for job in jobs where tiles[job.id]?.isLoading ?? true {
            if job.user != me {
                tiles[job.id] = .unavailable(String(localized: "This job belongs to another user. macOS only gives the owner of a job access to its content."))
            } else {
                tiles[job.id] = .loading
                missing.append(job.id)
            }
        }
        guard !missing.isEmpty else { return }
        tileTask = Task {
            for id in missing {
                let result = await Task.detached(priority: .userInitiated) {
                    Result { try PreviewBuilder.makePreview(from: CUPSClient.documents(jobID: id)) }
                }.value
                guard !Task.isCancelled else { return }
                guard tiles[id] != nil else { continue }
                switch result {
                case .success(let result):
                    if let document = PDFDocument(data: result.pdfData), let page = document.page(at: 0),
                       let copy = page.copy() as? PDFPage {
                        let firstPage = PDFDocument()
                        firstPage.insert(copy, at: 0)
                        let warning = result.problems.isEmpty ? nil
                            : ([String(localized: "Part of this job cannot be displayed:")] + result.problems).joined(separator: "\n")
                        tiles[id] = .loaded(firstPage: firstPage, pageCount: document.pageCount, warning: warning)
                    } else {
                        tiles[id] = .unavailable(String(localized: "The document cannot be displayed."))
                    }
                case .failure(let error):
                    tiles[id] = .unavailable(error.localizedDescription)
                }
            }
        }
    }
}
