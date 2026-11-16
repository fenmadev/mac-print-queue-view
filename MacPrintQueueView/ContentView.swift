import PDFKit
import SwiftUI

struct ContentView: View {
    @State private var store = QueueStore()

    var body: some View {
        NavigationSplitView {
            PrinterList(store: store)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } content: {
            JobList(store: store)
                .navigationSplitViewColumnWidth(min: 240, ideal: 300)
        } detail: {
            PreviewPane(store: store)
        }
        .task { await store.run() }
    }
}

// MARK: - Printers

private struct PrinterList: View {
    @Bindable var store: QueueStore

    var body: some View {
        List(selection: $store.selectedPrinterName) {
            Section("Printers") {
                ForEach(store.printers) { printer in
                    Label(printer.displayName, systemImage: "printer")
                        .badge(store.activeJobs(for: printer.name).count)
                        .help(printer.isDefault ? String(localized: "\(printer.name) (default printer)") : printer.name)
                        .tag(printer.name)
                }
            }
        }
        .overlay {
            if let error = store.connectionError {
                ContentUnavailableView("No connection to the printing service",
                                       systemImage: "exclamationmark.triangle",
                                       description: Text(error))
            } else if store.printers.isEmpty {
                ContentUnavailableView("No Printers", systemImage: "printer",
                                       description: Text("No printers are set up on this Mac."))
            }
        }
    }
}

// MARK: - Jobs

private struct JobList: View {
    @Bindable var store: QueueStore

    var body: some View {
        let printer = store.selectedPrinterName
        let active = printer.map { store.activeJobs(for: $0) } ?? []

        List(selection: $store.selectedJobID) {
            Section {
                if active.isEmpty {
                    EmptyQueueRow()
                }
                ForEach(active) { job in
                    QueueJobRow(
                        job: job,
                        thumbnail: store.thumbnails[job.id],
                        isSelected: store.selectedJobID == job.id,
                        canPause: store.canPause(jobID: job.id),
                        canResume: store.canResume(jobID: job.id),
                        canCancel: store.canCancel(jobID: job.id),
                        onPause: { Task { await store.pause(jobID: job.id) } },
                        onResume: { Task { await store.resume(jobID: job.id) } },
                        onCancel: { Task { await store.cancel(jobID: job.id) } }
                    )
                        .tag(job.id)
                        .moveDisabled(!store.canMove(job))
                }
                .onMove { source, destination in
                    Task { await store.move(in: active, from: source, to: destination) }
                }
            } header: {
                JobSectionHeader(title: "In Queue", count: active.count)
            }
            if !store.finishedJobs.isEmpty {
                Section {
                    ForEach(store.finishedJobs) { job in
                        FinishedJobRow(
                            job: job,
                            isSelected: store.selectedJobID == job.id,
                            onPrintAgain: { store.requestReprint(jobID: job.id) },
                            onRemove: { store.requestRemove(jobID: job.id) }
                        )
                        .tag(job.id)
                        // Trackpad: swipe right to print again, swipe left to remove.
                        .swipeActions(edge: .leading) {
                            Button { store.requestReprint(jobID: job.id) } label: {
                                Label("Print Again", systemImage: "arrow.clockwise")
                            }
                            .tint(.accentColor)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { store.requestRemove(jobID: job.id) } label: {
                                Label("Remove from List…", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    JobSectionHeader(title: "Completed", count: store.finishedJobs.count) {
                        if store.canPurgeAll {
                            Button("Clear…") { store.requestPurgeAll() }
                                .buttonStyle(.borderless)
                                .help("Remove all your completed jobs for this printer")
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .animation(.default, value: active.map(\.id))
        .contextMenu(forSelectionType: Int32.self) { ids in
            if store.canRestart(jobID: ids.first) {
                Button("Print Again", systemImage: "arrow.clockwise") {
                    Task { await store.restart(jobID: ids.first) }
                }
                Divider()
                Button("Remove from List…", systemImage: "trash", role: .destructive) {
                    store.requestRemove(jobID: ids.first)
                }
            } else {
                if store.canResume(jobID: ids.first) {
                    Button("Resume", systemImage: "play.fill") {
                        Task { await store.resume(jobID: ids.first) }
                    }
                } else {
                    Button("Pause", systemImage: "pause.fill") {
                        Task { await store.pause(jobID: ids.first) }
                    }
                    .disabled(!store.canPause(jobID: ids.first))
                }
                Divider()
                Button("Print Earlier", systemImage: "arrow.up") {
                    Task { await store.move(jobID: ids.first, by: -1) }
                }
                .disabled(!store.canMove(jobID: ids.first, by: -1))
                Button("Print Later", systemImage: "arrow.down") {
                    Task { await store.move(jobID: ids.first, by: 1) }
                }
                .disabled(!store.canMove(jobID: ids.first, by: 1))
                Divider()
                Button("Cancel Job", systemImage: "xmark.circle", role: .destructive) {
                    Task { await store.cancel(jobID: ids.first) }
                }
                .disabled(!store.canCancel(jobID: ids.first))
            }
        }
        .onDeleteCommand { store.deleteSelection() }
        .toolbar {
            // Only show the buttons that apply to the selected job: reordering for jobs in
            // the queue, printing again for completed jobs.
            if selectedJobIsQueued {
                ToolbarItemGroup {
                    Button("Print Earlier", systemImage: "arrow.up") {
                        Task { await store.move(jobID: store.selectedJobID, by: -1) }
                    }
                    .help("Move the job one place up in the queue (⌥⌘↑)")
                    .keyboardShortcut(.upArrow, modifiers: [.option, .command])
                    .disabled(!store.canMove(jobID: store.selectedJobID, by: -1))
                    Button("Print Later", systemImage: "arrow.down") {
                        Task { await store.move(jobID: store.selectedJobID, by: 1) }
                    }
                    .help("Move the job one place down in the queue (⌥⌘↓)")
                    .keyboardShortcut(.downArrow, modifiers: [.option, .command])
                    .disabled(!store.canMove(jobID: store.selectedJobID, by: 1))
                }
                ToolbarItem {
                    if store.canResume(jobID: store.selectedJobID) {
                        Button("Resume", systemImage: "play.fill") {
                            Task { await store.resume(jobID: store.selectedJobID) }
                        }
                        .help("Resume the job")
                    } else {
                        Button("Pause", systemImage: "pause.fill") {
                            Task { await store.pause(jobID: store.selectedJobID) }
                        }
                        .help("Pause the job; the other jobs keep printing")
                        .disabled(!store.canPause(jobID: store.selectedJobID))
                    }
                }
            }
            if store.canRestart(jobID: store.selectedJobID) {
                ToolbarItem {
                    Button("Print Again", systemImage: "arrow.clockwise") {
                        Task { await store.restart(jobID: store.selectedJobID) }
                    }
                    .help("Put the selected completed job back in the queue")
                }
            }
            ToolbarItem {
                if selectedJobIsQueued {
                    Button("Cancel Job", systemImage: "xmark.circle") {
                        Task { await store.cancel(jobID: store.selectedJobID) }
                    }
                    .help("Cancel the selected job right away (⌫)")
                    .disabled(!store.canCancel(jobID: store.selectedJobID))
                } else {
                    Button("Remove from List…", systemImage: "trash") {
                        store.requestRemove(jobID: store.selectedJobID)
                    }
                    .help("Remove the selected job from the list (⌫)")
                    .disabled(!store.canRemove(jobID: store.selectedJobID))
                }
            }
        }
        .confirmationDialog(
            actionTitle,
            isPresented: Binding(get: { store.pendingAction != nil },
                                 set: { if !$0 { store.pendingAction = nil } }),
            presenting: store.pendingAction
        ) { action in
            if action.isDestructive {
                Button("Delete", role: .destructive) { Task { await store.perform(action) } }
            } else {
                Button("Print") { Task { await store.perform(action) } }
                    .keyboardShortcut(.defaultAction)
            }
            Button("Cancel", role: .cancel) {}
        } message: { action in
            switch action {
            case .purge(let job):
                Text("“\(name(of: job))” and its retained document will be permanently removed. You will no longer be able to view or reprint it.")
            case .purgeAll:
                Text("All your completed jobs for this printer and their retained documents will be permanently removed, including older jobs not shown in the list. Jobs in the queue are kept.")
            case .reprint:
                Text("The job will be put back in the queue and printed again.")
            }
        }
        .alert(
            store.actionError != nil ? "Action Failed" : "Not Removed",
            isPresented: Binding(get: { store.actionError != nil || store.actionNotice != nil },
                                 set: { if !$0 { store.actionError = nil; store.actionNotice = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(verbatim: store.actionError ?? store.actionNotice ?? "")
        }
    }

    private var actionTitle: LocalizedStringKey {
        switch store.pendingAction {
        case .purge: "Remove Completed Job?"
        case .purgeAll: "Clear Completed Jobs?"
        case .reprint(let job): "Print “\(job.displayTitle)” Again?"
        case nil: ""
        }
    }

    private func name(of job: PrintJob) -> String { job.displayTitle }

    private var selectedJobIsQueued: Bool {
        guard let id = store.selectedJobID else { return false }
        return store.activeJobs.contains { $0.id == id }
    }
}

// MARK: - Preview

private struct PreviewPane: View {
    let store: QueueStore
    @State private var pdf = PDFViewController()

    var body: some View {
        Group {
            switch store.preview {
            case .none:
                ContentUnavailableView("No Job Selected", systemImage: "doc.text.magnifyingglass",
                                       description: Text("Select a print job to see what is being printed."))
            case .loading:
                ProgressView("Fetching document from the queue…")
            case .unavailable(let message):
                ContentUnavailableView("Print Preview Not Available", systemImage: "eye.slash",
                                       description: Text(message))
            case .loaded(let document, let warning):
                VStack(spacing: 0) {
                    if let warning {
                        PartialPreviewBanner(message: warning)
                    }
                    PDFPreview(document: document, controller: pdf)
                }
            }
        }
        .frame(minWidth: 360, maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(store.selectedJob?.displayTitle ?? MacPrintQueueViewApp.displayName)
        .navigationSubtitle(store.selectedJob.map { String(localized: "Job \($0.id)") + " · \($0.stateDescription) · \($0.printer)" } ?? "")
        .toolbar { documentControls }
    }

    /// Page and zoom controls. They stay in place (disabled) while the next document
    /// loads, so the toolbar does not jump around when switching between jobs.
    @ToolbarContentBuilder
    private var documentControls: some ToolbarContent {
        if isLoaded || isLoading {
            ToolbarItemGroup {
                Button("Previous Page", systemImage: "chevron.up", action: pdf.previousPage)
                    .disabled(!isLoaded || !pdf.canGoBack)
                    .keyboardShortcut(.upArrow, modifiers: .command)
                Text("Page \(pdf.pageIndex + 1) of \(pdf.pageCount)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .opacity(isLoaded ? 1 : 0)
                Button("Next Page", systemImage: "chevron.down", action: pdf.nextPage)
                    .disabled(!isLoaded || !pdf.canGoForward)
                    .keyboardShortcut(.downArrow, modifiers: .command)
            }
            ToolbarItemGroup {
                Button("Zoom Out", systemImage: "minus.magnifyingglass", action: pdf.zoomOut)
                    .keyboardShortcut("-", modifiers: .command)
                    .disabled(!isLoaded)
                Button("Zoom to Fit", systemImage: "arrow.up.left.and.down.right.magnifyingglass", action: pdf.zoomToFit)
                    .keyboardShortcut("0", modifiers: .command)
                    .disabled(!isLoaded)
                Button("Zoom In", systemImage: "plus.magnifyingglass", action: pdf.zoomIn)
                    .keyboardShortcut("=", modifiers: .command)
                    .disabled(!isLoaded)
            }
        }
    }

    private var isLoaded: Bool {
        if case .loaded = store.preview { true } else { false }
    }

    private var isLoading: Bool {
        if case .loading = store.preview { true } else { false }
    }
}

/// Shown above a preview that does not contain every document of the job.
private struct PartialPreviewBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(verbatim: message)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.15))
        .accessibilityElement(children: .combine)
    }
}
