import CUPS
import Foundation

/// A printer queue as configured in the local CUPS server (cupsd).
struct Printer: Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let displayName: String
    let isDefault: Bool
}

/// Simplified job state for the user interface.
enum JobStatus: Sendable {
    case pending, held, printing, stopped, canceled, aborted, completed, unknown
}

/// A print job from the existing macOS print queue.
struct PrintJob: Identifiable, Hashable, Sendable {
    let id: Int32
    let printer: String
    let title: String
    let user: String
    let format: String
    let state: ipp_jstate_t
    var priority: Int
    let sizeKB: Int
    let created: Date
    let completed: Date?

    /// Pending and held jobs can still change position in the queue.
    var isWaiting: Bool { state == IPP_JSTATE_PENDING || state == IPP_JSTATE_HELD }

    /// The title shown to the user; jobs without a title get "Job <number>".
    var displayTitle: String {
        title.isEmpty ? String(localized: "Job \(id)", comment: "Title for a print job without a name") : title
    }

    var status: JobStatus {
        switch state {
        case IPP_JSTATE_PENDING: .pending
        case IPP_JSTATE_HELD: .held
        case IPP_JSTATE_PROCESSING: .printing
        case IPP_JSTATE_STOPPED: .stopped
        case IPP_JSTATE_CANCELED: .canceled
        case IPP_JSTATE_ABORTED: .aborted
        case IPP_JSTATE_COMPLETED: .completed
        default: .unknown
        }
    }

    var stateDescription: String {
        switch state {
        case IPP_JSTATE_PENDING: String(localized: "Pending", comment: "Print job state")
        case IPP_JSTATE_HELD: String(localized: "Paused", comment: "Print job state (held)")
        case IPP_JSTATE_PROCESSING: String(localized: "Printing", comment: "Print job state")
        case IPP_JSTATE_STOPPED: String(localized: "Stopped", comment: "Print job state")
        case IPP_JSTATE_CANCELED: String(localized: "Canceled", comment: "Print job state")
        case IPP_JSTATE_ABORTED: String(localized: "Aborted", comment: "Print job state")
        case IPP_JSTATE_COMPLETED: String(localized: "Completed", comment: "Print job state")
        default: String(localized: "Unknown", comment: "Print job state")
        }
    }
}

/// One document from a print job, exactly as it was sent to the queue.
struct JobDocument: Sendable {
    let data: Data
    let format: String
}

struct CUPSError: LocalizedError, Sendable {
    let message: String
    var errorDescription: String? { message }

    /// A localized message followed by the (untranslated) technical detail from CUPS.
    init(_ message: String, cupsDetail: String? = nil) {
        self.message = cupsDetail.map { "\(message)\n(CUPS: \($0))" } ?? message
    }
}

/// Thin, synchronous layer over libcups. All functions block (local IPP calls
/// over /private/var/run/cupsd) and should therefore run off the main thread.
///
/// Only the current user's own jobs are queried and changed. The queue is only
/// modified when the user explicitly asks for it (cancel, pause, resume, purge, restart, reorder).
enum CUPSClient {

    // MARK: Printers

    static func printers() throws -> [Printer] {
        try withConnection { http in
            let request = ippNewRequest(IPP_OP_CUPS_GET_PRINTERS)
            addRequestedAttributes(request, ["printer-name", "printer-info", "printer-is-temporary"])
            guard let response = cupsDoRequest(http, request, "/") else { throw lastError() }
            defer { ippDelete(response) }
            if cupsLastError().rawValue > IPP_STATUS_OK_EVENTS_COMPLETE.rawValue {
                // No printers configured returns "not-found"; that is not an error.
                if cupsLastError() == IPP_STATUS_ERROR_NOT_FOUND { return [] }
                throw lastError()
            }

            let defaultName = cupsGetDefault2(http).map { String(cString: $0) }
            var result: [Printer] = []
            var name: String?
            var info: String?
            var temporary = false

            func flush() {
                if let name, !temporary {
                    let display = (info?.isEmpty == false ? info! : name)
                    result.append(Printer(name: name, displayName: display, isDefault: name == defaultName))
                }
                name = nil; info = nil; temporary = false
            }

            var attr = ippFirstAttribute(response)
            while let a = attr {
                if ippGetGroupTag(a) != IPP_TAG_PRINTER {
                    flush()
                } else if let attrName = ippGetName(a).map({ String(cString: $0) }) {
                    switch attrName {
                    case "printer-name": name = string(a)
                    case "printer-info": info = string(a)
                    case "printer-is-temporary": temporary = ippGetBoolean(a, 0) != 0
                    default: break
                    }
                }
                attr = ippNextAttribute(response)
            }
            flush()
            return result.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
        }
    }

    // MARK: Jobs

    /// The user's own active jobs (pending, held, printing, stopped) on all printers.
    /// Other users' jobs are not requested.
    static func activeJobs() throws -> [PrintJob] {
        try jobs(printer: nil, which: CUPS_WHICHJOBS_ACTIVE)
    }

    /// The user's own completed/canceled jobs for one printer, newest first.
    static func finishedJobs(printer: String, limit: Int) throws -> [PrintJob] {
        let all = try jobs(printer: printer, which: CUPS_WHICHJOBS_COMPLETED)
        return Array(all.sorted { $0.id > $1.id }.prefix(limit))
    }

    private static func jobs(printer: String?, which: Int32) throws -> [PrintJob] {
        try withConnection { http in
            var list: UnsafeMutablePointer<cups_job_t>?
            let count = cupsGetJobs2(http, &list, printer, 1, which)  // 1 = own jobs only (my-jobs)
            if count < 0 { throw lastError() }
            defer { cupsFreeJobs(count, list) }
            guard let list else { return [] }

            return (0..<Int(count)).map { i in
                let j = list[i]
                return PrintJob(
                    id: j.id,
                    printer: j.dest.map { String(cString: $0) } ?? "",
                    title: j.title.map { String(cString: $0) } ?? "",
                    user: j.user.map { String(cString: $0) } ?? "",
                    format: j.format.map { String(cString: $0) } ?? "",
                    state: j.state,
                    priority: Int(j.priority),
                    sizeKB: Int(j.size),
                    created: Date(timeIntervalSince1970: TimeInterval(j.creation_time)),
                    completed: j.completed_time > 0 ? Date(timeIntervalSince1970: TimeInterval(j.completed_time)) : nil
                )
            }
        }
    }

    /// Removes (cancels) a job from the queue. cupsd allows this without a
    /// password only for the owner of the job.
    static func cancelJob(id: Int32, printer: String) throws {
        try withConnection { http in
            let status = cupsCancelJob2(http, printer, id, 0)
            if status.rawValue > IPP_STATUS_OK_EVENTS_COMPLETE.rawValue {
                throw CUPSError(String(localized: "The job could not be deleted."), cupsDetail: lastErrorDetail)
            }
        }
    }

    /// Permanently removes a finished job from the job history, including the
    /// retained document (Cancel-Job with purge-job). Allowed for the owner without a password.
    static func purgeJob(id: Int32, printer: String) throws {
        try withConnection { http in
            let status = cupsCancelJob2(http, printer, id, 1)
            if status.rawValue > IPP_STATUS_OK_EVENTS_COMPLETE.rawValue {
                throw CUPSError(String(localized: "The job could not be removed."), cupsDetail: lastErrorDetail)
            }
        }
    }

    /// The current state of one job, read from cupsd (`Get-Job-Attributes`), or nil if the job
    /// no longer exists.
    static func jobState(id: Int32) throws -> ipp_jstate_t? {
        try withConnection { http in
            let request = ippNewRequest(IPP_OP_GET_JOB_ATTRIBUTES)
            ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_URI, "job-uri", nil, "ipp://localhost/jobs/\(id)")
            ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_NAME, "requesting-user-name", nil, cupsUser())
            addRequestedAttributes(request, ["job-state"])
            let response = cupsDoRequest(http, request, "/")
            defer { ippDelete(response) }
            if cupsLastError() == IPP_STATUS_ERROR_NOT_FOUND { return nil }
            if response == nil || cupsLastError().rawValue > IPP_STATUS_OK_EVENTS_COMPLETE.rawValue { throw lastError() }
            guard let attr = ippFindAttribute(response, "job-state", IPP_TAG_ENUM) else {
                throw CUPSError(String(localized: "The printing service returned an error."))
            }
            return ipp_jstate_t(rawValue: UInt32(ippGetInteger(attr, 0)))
        }
    }

    /// Removes a job permanently, but only if cupsd reports it as finished (completed,
    /// canceled or aborted) right before the removal. A job that is back in the queue, for
    /// example because it was restarted after the user asked to remove it, is left alone.
    /// Returns false when the job was not removed for that reason, or because it no longer exists.
    ///
    /// The state check and the removal are two separate requests; a state change in the
    /// milliseconds between them cannot be excluded.
    static func purgeJobIfFinished(id: Int32, printer: String) throws -> Bool {
        guard let state = try jobState(id: id), state.rawValue >= IPP_JSTATE_CANCELED.rawValue else { return false }
        try purgeJob(id: id, printer: printer)
        return true
    }

    /// Removes all of the current user's finished jobs for this printer, re-checking each
    /// job's state right before removing it. Active jobs and other users' jobs are left
    /// untouched; a job that has disappeared in the meantime is skipped and the others are still
    /// handled. Returns how many jobs were removed and how many were skipped.
    static func purgeFinishedJobs(printer: String) throws -> (removed: Int, skipped: Int) {
        let mine = try jobs(printer: printer, which: CUPS_WHICHJOBS_COMPLETED)
            .filter { $0.user == currentUser }
        var removed = 0
        for job in mine {
            if try purgeJobIfFinished(id: job.id, printer: printer) { removed += 1 }
        }
        return (removed, mine.count - removed)
    }

    /// Puts a completed, canceled or aborted job back in the queue (CUPS operation
    /// Restart-Job). Only possible while cupsd still retains the document.
    static func restartJob(id: Int32) throws {
        try withConnection { http in
            let request = ippNewRequest(IPP_OP_RESTART_JOB)
            ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_URI, "job-uri", nil, "ipp://localhost/jobs/\(id)")
            ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_NAME, "requesting-user-name", nil, cupsUser())
            ippDelete(cupsDoRequest(http, request, "/"))
            if cupsLastError().rawValue > IPP_STATUS_OK_EVENTS_COMPLETE.rawValue {
                throw CUPSError(String(localized: "The job could not be put back in the queue. The document may already have been removed."), cupsDetail: lastErrorDetail)
            }
        }
    }

    /// Pauses a waiting job (CUPS operation Hold-Job). The job stays in the queue but is
    /// skipped, so the jobs behind it keep printing. The owner may do this without a password.
    static func holdJob(id: Int32) throws {
        try jobOperation(IPP_OP_HOLD_JOB, id: id, failure: String(localized: "The job could not be paused.")) { request in
            ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_KEYWORD, "job-hold-until", nil, "indefinite")
        }
    }

    /// Resumes a paused job (CUPS operation Release-Job); it then prints in its place in the queue.
    static func releaseJob(id: Int32) throws {
        try jobOperation(IPP_OP_RELEASE_JOB, id: id, failure: String(localized: "The job could not be resumed."))
    }

    private static func jobOperation(_ operation: ipp_op_t, id: Int32, failure: String,
                                     configure: (OpaquePointer?) -> Void = { _ in }) throws {
        try withConnection { http in
            let request = ippNewRequest(operation)
            ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_URI, "job-uri", nil, "ipp://localhost/jobs/\(id)")
            ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_NAME, "requesting-user-name", nil, cupsUser())
            configure(request)
            ippDelete(cupsDoRequest(http, request, "/"))
            if cupsLastError().rawValue > IPP_STATUS_OK_EVENTS_COMPLETE.rawValue {
                throw CUPSError(failure, cupsDetail: lastErrorDetail)
            }
        }
    }

    /// Changes the priority (1–100) of a waiting job. cupsd prints waiting jobs in
    /// order of priority (highest first) and then by job number; this is how the
    /// queue order is changed. The owner may do this without a password.
    static func setPriority(_ priority: Int, jobID: Int32) throws {
        try withConnection { http in
            let request = ippNewRequest(IPP_OP_SET_JOB_ATTRIBUTES)
            ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_URI, "job-uri", nil, "ipp://localhost/jobs/\(jobID)")
            ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_NAME, "requesting-user-name", nil, cupsUser())
            ippAddInteger(request, IPP_TAG_JOB, IPP_TAG_INTEGER, "job-priority", Int32(priority))
            ippDelete(cupsDoRequest(http, request, "/"))
            if cupsLastError().rawValue > IPP_STATUS_OK_EVENTS_COMPLETE.rawValue {
                throw CUPSError(String(localized: "The queue order could not be changed."), cupsDetail: lastErrorDetail)
            }
        }
    }

    // MARK: Documents

    /// The user name CUPS knows this app by.
    static var currentUser: String { String(cString: cupsUser()) }

    /// Fetches the original document content of a job using the CUPS operation
    /// `CUPS-Get-Document`. cupsd only allows this for the owner of the job (or an
    /// administrator); the owner is identified over the local socket, so no password
    /// or root access is needed.
    static func documents(jobID: Int32) throws -> [JobDocument] {
        try withConnection { http in
            let jobURI = "ipp://localhost/jobs/\(jobID)"
            let count = try numberOfDocuments(http: http, jobURI: jobURI)
            guard count > 0 else {
                throw CUPSError(String(localized: "This job does not contain a document (yet)."))
            }
            return try (1...count).map { try document(http: http, jobURI: jobURI, number: $0) }
        }
    }

    private static func numberOfDocuments(http: OpaquePointer, jobURI: String) throws -> Int {
        let request = ippNewRequest(IPP_OP_GET_JOB_ATTRIBUTES)
        ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_URI, "job-uri", nil, jobURI)
        ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_NAME, "requesting-user-name", nil, cupsUser())
        addRequestedAttributes(request, ["number-of-documents"])
        guard let response = cupsDoRequest(http, request, "/") else { throw lastError() }
        defer { ippDelete(response) }
        if cupsLastError().rawValue > IPP_STATUS_OK_EVENTS_COMPLETE.rawValue { throw lastError() }
        guard let attr = ippFindAttribute(response, "number-of-documents", IPP_TAG_INTEGER) else { return 1 }
        return Int(ippGetInteger(attr, 0))
    }

    private static func document(http: OpaquePointer, jobURI: String, number: Int) throws -> JobDocument {
        // cupsDoIORequest writes the document data to a file descriptor.
        // We use a private temporary file (0600) that is unlinked immediately,
        // so no copy of the document is left behind.
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("job-\(UUID().uuidString)")
        let fd = open(tempURL.path, O_RDWR | O_CREAT | O_EXCL, 0o600)
        guard fd >= 0 else { throw CUPSError(String(localized: "Could not create a temporary file.")) }
        unlink(tempURL.path)
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)

        let request = ippNewRequest(IPP_OP_CUPS_GET_DOCUMENT)
        ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_URI, "job-uri", nil, jobURI)
        ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_NAME, "requesting-user-name", nil, cupsUser())
        ippAddInteger(request, IPP_TAG_OPERATION, IPP_TAG_INTEGER, "document-number", Int32(number))

        let response = cupsDoIORequest(http, request, "/", -1, fd)
        defer { ippDelete(response) }
        if response == nil || cupsLastError().rawValue > IPP_STATUS_OK_EVENTS_COMPLETE.rawValue {
            throw lastError()
        }

        var format = "application/octet-stream"
        if let attr = ippFindAttribute(response, "document-format", IPP_TAG_MIMETYPE) {
            format = string(attr) ?? format
        }
        try handle.seek(toOffset: 0)
        let data = try handle.readToEnd() ?? Data()
        return JobDocument(data: data, format: format)
    }

    // MARK: Helpers

    private static func withConnection<T>(_ body: (OpaquePointer) throws -> T) throws -> T {
        guard let http = httpConnect2(cupsServer(), ippPort(), nil, AF_UNSPEC, cupsEncryption(), 1, 10_000, nil) else {
            throw CUPSError(String(localized: "Could not connect to the macOS printing service (CUPS)."))
        }
        defer { httpClose(http) }
        return try body(http)
    }

    private static func addRequestedAttributes(_ request: OpaquePointer?, _ names: [String]) {
        let cStrings = names.map { strdup($0) }
        defer { cStrings.forEach { free($0) } }
        var pointers = cStrings.map { UnsafePointer<CChar>($0) }
        ippAddStrings(request, IPP_TAG_OPERATION, IPP_TAG_KEYWORD, "requested-attributes",
                      Int32(pointers.count), nil, &pointers)
    }

    private static func string(_ attr: OpaquePointer) -> String? {
        ippGetString(attr, 0, nil).map { String(cString: $0) }
    }

    private static var lastErrorDetail: String { String(cString: cupsLastErrorString()) }

    private static func lastError() -> CUPSError {
        let message = switch cupsLastError() {
        case IPP_STATUS_ERROR_FORBIDDEN, IPP_STATUS_ERROR_NOT_AUTHORIZED, IPP_STATUS_ERROR_NOT_AUTHENTICATED:
            String(localized: "No access to this job. Only the owner of the job or an administrator can view its content.")
        case IPP_STATUS_ERROR_NOT_FOUND:
            String(localized: "The document is no longer available in the queue.")
        default:
            String(localized: "The printing service returned an error.")
        }
        return CUPSError(message, cupsDetail: lastErrorDetail)
    }
}
