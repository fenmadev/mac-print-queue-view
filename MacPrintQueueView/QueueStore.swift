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

    var selectedPrinterName: String? {
        didSet {
            guard selectedPrinterName != oldValue else { return }
            finishedJobs = []
            selectedJobID = nil
            Task { await refresh() }
        }
    }

    var selectedJobID: Int32? {
        didSet {
            guard selectedJobID != oldValue else { return }
            loadPreview()
        }
    }

    /// How many finished jobs are shown per printer.
    private let finishedLimit = 50
    private var previewTask: Task<Void, Never>?

    var selectedJob: PrintJob? {
        guard let id = selectedJobID else { return nil }
        return activeJobs.first { $0.id == id } ?? finishedJobs.first { $0.id == id }
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

    /// Own completed jobs can be removed from the list (permanently, after confirmation).
    func canRemove(jobID: Int32?) -> Bool {
        guard let jobID, let job = finishedJobs.first(where: { $0.id == jobID }) else { return false }
        return job.user == CUPSClient.currentUser
    }

    func requestRemove(jobID: Int32?) {
        guard canRemove(jobID: jobID), let job = job(withID: jobID) else { return }
        pendingAction = .purge(job)
    }

    /// The ⌫ key: cancel a job in the queue right away, or ask to remove a completed job.
    func deleteSelection() {
        if canCancel(jobID: selectedJobID) {
            Task { await cancel(jobID: selectedJobID) }
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

    func pause(jobID: Int32?) async {
        guard let jobID, canPause(jobID: jobID) else { return }
        // Check the current state with cupsd first: never pause a job that has just started printing.
        let current = await Task.detached(priority: .userInitiated) { try? CUPSClient.activeJobs() }.value
        let status = current?.first(where: { $0.id == jobID })?.status
        guard status == .pending else {
            if status == .printing {
                actionError = String(localized: "This job has already started printing and can no longer be paused. You can cancel it instead.")
            }
            return await refresh()
        }
        await run { try CUPSClient.holdJob(id: jobID) }
    }

    func resume(jobID: Int32?) async {
        guard let jobID, canResume(jobID: jobID) else { return }
        await run { try CUPSClient.releaseJob(id: jobID) }
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

    /// Can the job move one place up (`offset` -1) or down (+1)?
    func canMove(jobID: Int32?, by offset: Int) -> Bool {
        guard let jobID, let job = activeJobs.first(where: { $0.id == jobID }), canMove(job) else { return false }
        let waiting = activeJobs(for: job.printer).filter(\.isWaiting)
        guard let index = waiting.firstIndex(of: job) else { return false }
        return waiting.indices.contains(index + offset)
    }

    func move(jobID: Int32?, by offset: Int) async {
        guard canMove(jobID: jobID, by: offset), let jobID,
              let job = activeJobs.first(where: { $0.id == jobID }) else { return }
        var waiting = activeJobs(for: job.printer).filter(\.isWaiting)
        let index = waiting.firstIndex(of: job)!
        waiting.swapAt(index, index + offset)
        await apply(order: waiting, moved: [jobID])
    }

    /// Dragging in the list; `jobs` is the list as shown (including jobs that are already printing).
    func move(in jobs: [PrintJob], from source: IndexSet, to destination: Int) async {
        guard source.allSatisfy({ canMove(jobs[$0]) }) else { return }
        var reordered = jobs
        reordered.move(fromOffsets: source, toOffset: destination)
        await apply(order: reordered.filter(\.isWaiting), moved: source.map { jobs[$0].id })
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
            if printers != self.printers { self.printers = printers }
            let sortedActive = active.sorted(by: Self.queueOrder)
            if sortedActive != activeJobs { activeJobs = sortedActive }
            // Only apply if the user did not select another printer in the meantime.
            if requested == selectedPrinterName {
                if chosen != selectedPrinterName { selectedPrinterName = chosen }
                if finished != finishedJobs { finishedJobs = finished }
                // Job was removed: clear the selection and preview.
                if let id = selectedJobID, !activeJobs.contains(where: { $0.id == id }),
                   !finishedJobs.contains(where: { $0.id == id }) {
                    selectedJobID = nil
                }
            }
            updateThumbnails()
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
                    try? PreviewBuilder.makeThumbnailPNG(from: CUPSClient.documents(jobID: id), maxPixelSize: 160)
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
}
