import PDFKit
import SwiftUI

struct ContentView: View {
    @State private var store: QueueStore

    /// `store` is for checks that drive the window's state; the app uses a new store.
    @MainActor init(store: QueueStore? = nil) {
        _store = State(initialValue: store ?? QueueStore())
    }

    var body: some View {
        NavigationSplitView {
            PrinterList(store: store)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } content: {
            JobList(store: store)
                // The job column widens with the thumbnails, so title and status keep their room.
                .navigationSplitViewColumnWidth(min: ThumbnailZoom.minimumColumnWidth(step: store.thumbnailStep),
                                                ideal: ThumbnailZoom.idealColumnWidth(step: store.thumbnailStep))
        } detail: {
            PreviewPane(store: store)
        }
        .background(ColumnSplitSupport(thumbnailStep: store.thumbnailStep))
        .task { await store.run() }
    }
}

/// Window support for the three columns, which SwiftUI offers no settings for:
/// - makes the dividers thick (9 points instead of 1), so they are easy to grab, and puts a visible
///   line with a grip on the divider before the preview (D43). The dividers belong to the split view
///   that AppKit uses for `NavigationSplitView`, which applies one style to all its dividers and
///   draws them transparent. The split view itself is only changed through its public
///   `dividerStyle`; the line is a separate view on top (`DividerMarkView`). (AppKit's toolbar
///   observes the split view: replacing its class to draw the divider made the app crash as soon as
///   the toolbar changed, for example when a row was clicked.)
/// - widens the window when larger thumbnails make the columns wider than the window (D42), so the
///   preview is not cut off; never beyond the screen, and the window is not narrowed again.
private struct ColumnSplitSupport: NSViewRepresentable {
    /// Passed in so that the window is checked again after every thumbnail step change.
    let thumbnailStep: Int

    final class Probe: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            // The split view is set up after this view joins the window.
            DispatchQueue.main.async { [weak self] in self?.apply() }
        }

        func apply() {
            // This view sits behind the columns, so search the window for the column split view.
            guard let root = window?.contentView?.superview,
                  let split = Self.columnSplitView(in: root) else { return }
            if split.dividerStyle != .thick { split.dividerStyle = .thick }
            installMark(on: split)
        }

        private var mark: DividerMarkView?
        private weak var observedSplit: NSSplitView?

        /// Puts the visible line on the divider before the preview and keeps it there.
        private func installMark(on split: NSSplitView) {
            guard let container = split.superview else { return }
            if mark?.superview !== container {
                mark?.removeFromSuperview()
                let view = DividerMarkView()
                container.addSubview(view, positioned: .above, relativeTo: split)
                mark = view
            }
            if observedSplit !== split {
                // A selector-based observer is removed by the system when this view goes away.
                NotificationCenter.default.removeObserver(self, name: NSSplitView.didResizeSubviewsNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(splitViewDidResize(_:)),
                                                       name: NSSplitView.didResizeSubviewsNotification, object: split)
                // Also when the split view itself moves or changes size without resizing its columns.
                split.postsFrameChangedNotifications = true
                NotificationCenter.default.addObserver(self, selector: #selector(splitViewDidResize(_:)),
                                                       name: NSView.frameDidChangeNotification, object: split)
                observedSplit = split
            }
            placeMark()
            // Again after the next layout pass, which applies the new divider style.
            DispatchQueue.main.async { [weak self] in self?.placeMark() }
        }

        @objc private func splitViewDidResize(_ notification: Notification) {
            placeMark()
        }

        /// Places the line exactly over the divider between the job list and the preview.
        private func placeMark() {
            guard let split = observedSplit, let mark, let container = mark.superview else { return }
            let items = split.arrangedSubviews
            guard items.count >= 3, !items[items.count - 1].isHidden else {
                mark.isHidden = true
                return
            }
            // The divider starts where the job column ends and is as wide as the divider style.
            let before = items[items.count - 2].frame
            let divider = NSRect(x: before.maxX, y: 0, width: split.dividerThickness, height: split.bounds.height)
            mark.frame = split.convert(divider, to: container)
            mark.isHidden = false
            mark.needsDisplay = true
        }

        /// Widens the window by as much as the columns no longer fit, within the screen.
        func fitWindow() {
            guard let window, let content = window.contentView, let root = content.superview,
                  let split = Self.columnSplitView(in: root) else { return }
            root.layoutSubtreeIfNeeded()
            let overflow = split.frame.width - content.bounds.width
            guard overflow > 0.5 else { return }
            var frame = window.frame
            frame.size.width += overflow.rounded(.up)
            if let visible = window.screen?.visibleFrame {
                frame.size.width = min(frame.width, visible.width)
                if frame.maxX > visible.maxX { frame.origin.x = max(visible.minX, visible.maxX - frame.width) }
            }
            window.setFrame(frame, display: true, animate: window.isVisible && window.screen != nil)
        }

        private static func columnSplitView(in view: NSView) -> NSSplitView? {
            if let split = view as? NSSplitView, split.isVertical, split.arrangedSubviews.count >= 3 { return split }
            for subview in view.subviews {
                if let found = columnSplitView(in: subview) { return found }
            }
            return nil
        }
    }

    func makeNSView(context: Context) -> Probe { Probe() }

    func updateNSView(_ view: Probe, context: Context) {
        view.apply()
        // After SwiftUI has applied the new column width.
        DispatchQueue.main.async { view.fitWindow() }
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

        // Redraw when the selection rules corrected what the list asked for (see `selection`).
        let _ = store.selectionCorrections
        List(selection: $store.selection) {
            Section {
                if active.isEmpty {
                    EmptyQueueRow()
                }
                ForEach(active) { job in
                    QueueJobRow(
                        job: job,
                        thumbnail: store.thumbnails[job.id],
                        thumbnailSize: ThumbnailZoom.size(step: store.thumbnailStep),
                        isSelected: store.selection.contains(job.id),
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
                            isSelected: store.selection.contains(job.id),
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
            if ids.count == 1, store.canRestart(jobID: ids.first) {
                Button("Print Again", systemImage: "arrow.clockwise") {
                    Task { await store.restart(jobID: ids.first) }
                }
                Divider()
                Button("Remove from List…", systemImage: "trash", role: .destructive) {
                    store.requestRemove(jobID: ids.first)
                }
            } else if !ids.isEmpty {
                // Jobs in the queue: the actions apply to every job of the menu (D39).
                if store.canPause(ids) || !store.canResume(ids) {
                    Button("Pause", systemImage: "pause.fill") {
                        Task { await store.pause(ids) }
                    }
                    .disabled(!store.canPause(ids))
                }
                if store.canResume(ids) {
                    Button("Resume", systemImage: "play.fill") {
                        Task { await store.resume(ids) }
                    }
                }
                Divider()
                Button("Print Earlier", systemImage: "arrow.up") {
                    Task { await store.move(ids, by: -1) }
                }
                .disabled(!store.canMove(ids, by: -1))
                Button("Print Later", systemImage: "arrow.down") {
                    Task { await store.move(ids, by: 1) }
                }
                .disabled(!store.canMove(ids, by: 1))
                Divider()
                Button(store.cancelableCount(ids) > 1 ? "Cancel Jobs…" : "Cancel Job", systemImage: "xmark.circle", role: .destructive) {
                    store.requestCancel(ids)
                }
                .disabled(!store.canCancel(ids))
            }
        }
        .onDeleteCommand { store.deleteSelection() }
        .toolbar {
            // Size of the page thumbnails in the queue (D38).
            ToolbarItemGroup {
                Button("Smaller Thumbnails", systemImage: "arrow.down.right.and.arrow.up.left") {
                    withAnimation { store.thumbnailStep = ThumbnailZoom.clamped(store.thumbnailStep - 1) }
                }
                .help("Make the page thumbnails in the queue smaller (⌥⌘-)")
                .keyboardShortcut("-", modifiers: [.option, .command])
                .disabled(!ThumbnailZoom.canZoomOut(from: store.thumbnailStep))
                Button("Larger Thumbnails", systemImage: "arrow.up.left.and.arrow.down.right") {
                    withAnimation { store.thumbnailStep = ThumbnailZoom.clamped(store.thumbnailStep + 1) }
                }
                .help("Make the page thumbnails in the queue larger (⌥⌘=)")
                .keyboardShortcut("=", modifiers: [.option, .command])
                .disabled(!ThumbnailZoom.canZoomIn(from: store.thumbnailStep))
            }
            // Only show the buttons that apply to the selected jobs: reordering for jobs in
            // the queue, printing again for a completed job. With several jobs in the queue
            // selected, the actions apply to all of them (D39).
            if store.selectionIsQueued {
                ToolbarItemGroup {
                    Button("Print Earlier", systemImage: "arrow.up") {
                        Task { await store.move(store.selection, by: -1) }
                    }
                    .help(several ? "Move the selected jobs one place up in the queue, as one block (⌥⌘↑)" : "Move the job one place up in the queue (⌥⌘↑)")
                    .keyboardShortcut(.upArrow, modifiers: [.option, .command])
                    .disabled(!store.canMove(store.selection, by: -1))
                    Button("Print Later", systemImage: "arrow.down") {
                        Task { await store.move(store.selection, by: 1) }
                    }
                    .help(several ? "Move the selected jobs one place down in the queue, as one block (⌥⌘↓)" : "Move the job one place down in the queue (⌥⌘↓)")
                    .keyboardShortcut(.downArrow, modifiers: [.option, .command])
                    .disabled(!store.canMove(store.selection, by: 1))
                }
                ToolbarItem {
                    if store.canResume(store.selection) && !store.canPause(store.selection) {
                        Button("Resume", systemImage: "play.fill") {
                            Task { await store.resume(store.selection) }
                        }
                        .help(several ? "Resume the selected paused jobs" : "Resume the job")
                    } else {
                        Button("Pause", systemImage: "pause.fill") {
                            Task { await store.pause(store.selection) }
                        }
                        .help(several ? "Pause the selected jobs that are waiting; the other jobs keep printing" : "Pause the job; the other jobs keep printing")
                        .disabled(!store.canPause(store.selection))
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
                if store.selectionIsQueued {
                    Button(store.cancelableCount(store.selection) > 1 ? "Cancel Jobs…" : "Cancel Job", systemImage: "xmark.circle") {
                        store.requestCancel(store.selection)
                    }
                    .help(store.cancelableCount(store.selection) > 1 ? "Cancel the selected jobs, after confirmation (⌫)" : "Cancel the selected job right away (⌫)")
                    .disabled(!store.canCancel(store.selection))
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
            if case .cancel = action {
                Button("Cancel Jobs", role: .destructive) { Task { await store.perform(action) } }
                Button("Don’t Cancel", role: .cancel) {}
            } else {
                if action.isDestructive {
                    Button("Delete", role: .destructive) { Task { await store.perform(action) } }
                } else {
                    Button("Print") { Task { await store.perform(action) } }
                        .keyboardShortcut(.defaultAction)
                }
                Button("Cancel", role: .cancel) {}
            }
        } message: { action in
            switch action {
            case .purge(let job):
                Text("“\(name(of: job))” and its retained document will be permanently removed. You will no longer be able to view or reprint it.")
            case .purgeAll:
                Text("All your completed jobs for this printer and their retained documents will be permanently removed, including older jobs not shown in the list. Jobs in the queue are kept.")
            case .reprint:
                Text("The job will be put back in the queue and printed again.")
            case .cancel:
                Text("The selected jobs will be canceled right away. They move to “Completed”, where you can print them again.")
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

    /// Are several jobs selected? Then the toolbar's tooltips speak of the selected jobs.
    private var several: Bool { store.selection.count > 1 }

    private var actionTitle: LocalizedStringKey {
        switch store.pendingAction {
        case .purge: "Remove Completed Job?"
        case .purgeAll: "Clear Completed Jobs?"
        case .reprint(let job): "Print “\(job.displayTitle)” Again?"
        case .cancel(let jobs): "Cancel \(jobs.count) Jobs?"
        case nil: ""
        }
    }

    private func name(of job: PrintJob) -> String { job.displayTitle }
}

// MARK: - Preview

private struct PreviewPane: View {
    let store: QueueStore
    @State private var pdf = PDFViewController()

    var body: some View {
        Group {
            if !store.gridJobs.isEmpty {
                PreviewGridView(store: store)
            } else {
                singlePreview
            }
        }
        .frame(minWidth: 360, maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(store.selectedJob?.displayTitle ?? MacPrintQueueViewApp.displayName)
        .navigationSubtitle(subtitle)
        .toolbar { documentControls }
    }

    private var subtitle: String {
        if let job = store.selectedJob {
            return String(localized: "Job \(job.id)") + " · \(job.stateDescription) · \(job.printer)"
        }
        let count = store.selection.count
        return count > 1 ? String(localized: "\(count) jobs selected") : ""
    }

    @ViewBuilder
    private var singlePreview: some View {
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

// MARK: - Preview of several jobs

/// Several selected jobs side by side in a grid of equal blocks, each showing the first page (D39).
private struct PreviewGridView: View {
    let store: QueueStore

    private let spacing: CGFloat = 12

    var body: some View {
        let jobs = store.gridJobs
        let total = store.selectedQueuedJobs.count
        let layout = PreviewGrid.layout(for: jobs.count)
        VStack(spacing: 0) {
            if total > jobs.count {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Showing the first \(jobs.count) of \(total) selected jobs.")
                        .font(.callout)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.quaternary.opacity(0.5))
            }
            GeometryReader { geometry in
                let width = (geometry.size.width - spacing * CGFloat(layout.columns + 1)) / CGFloat(layout.columns)
                let height = (geometry.size.height - spacing * CGFloat(layout.rows + 1)) / CGFloat(layout.rows)
                VStack(spacing: spacing) {
                    ForEach(0..<layout.rows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<layout.columns, id: \.self) { column in
                                let index = row * layout.columns + column
                                Group {
                                    if index < jobs.count {
                                        let job = jobs[index]
                                        PreviewTile(job: job, number: index + 1, state: store.tiles[job.id] ?? .loading,
                                                    canDrag: store.canDragInGrid(job)) { dropped in
                                            Task { await store.moveInGrid(dropped, onto: job.id) }
                                        }
                                    } else {
                                        Color.clear
                                    }
                                }
                                .frame(width: max(width, 0), height: max(height, 0))
                            }
                        }
                    }
                }
                .padding(spacing)
            }
        }
    }
}

/// One block of the grid: title, state and page count, and the first page. A block of a job that
/// can move can be dragged onto another block to change the print order (D40).
private struct PreviewTile: View {
    let job: PrintJob
    /// Position in the grid, left to right and then the next row; the order in which the selected
    /// jobs print (D41).
    let number: Int
    let state: QueueStore.TileState
    let canDrag: Bool
    /// Called with the job ID of a block dropped on this block.
    let onDrop: (Int32) -> Void
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(verbatim: job.displayTitle)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
                if case .loaded(_, let pageCount, let warning) = state {
                    if let warning {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .help(Text(verbatim: warning))
                            .accessibilityLabel(Text(verbatim: warning))
                    }
                    Text("Pages: \(pageCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .fixedSize()
                }
                StatusBadge(status: job.status, text: job.stateDescription)
                    .fixedSize()
            }
            ZStack {
                switch state {
                case .loading:
                    ProgressView()
                        .controlSize(.small)
                case .loaded(let firstPage, _, _):
                    FirstPageView(document: firstPage)
                        .allowsHitTesting(false)
                case .unavailable(let message):
                    VStack(spacing: 6) {
                        Image(systemName: "eye.slash")
                            .font(.title2)
                        Text(verbatim: message)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(.secondary)
                    .padding(8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.quaternary.opacity(0.4)))
        .overlay(alignment: .bottomTrailing) {
            Text(verbatim: "\(number)")
                .font(.callout.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(minWidth: 26, minHeight: 26)
                .padding(.horizontal, number > 9 ? 4 : 0)
                .background(Capsule().fill(Color.accentColor))
                .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
                .padding(10)
                .accessibilityLabel(Text("Position \(number)"))
        }
        .overlay {
            if isTargeted {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: 3)
            }
        }
        .contentShape(Rectangle())
        .modifier(TileDrag(job: job, enabled: canDrag))
        .dropDestination(for: String.self) { items, _ in
            guard let id = items.first.flatMap({ Int32($0) }), id != job.id else { return false }
            onDrop(id)
            return true
        } isTargeted: { isTargeted = $0 && canDrag }
        .help(Text(verbatim: "\(job.displayTitle) · \(job.format)"))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: job.displayTitle))
    }
}

/// Makes a block of the grid draggable; the payload is the job ID.
private struct TileDrag: ViewModifier {
    let job: PrintJob
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.draggable(String(job.id)) {
                Label {
                    Text(verbatim: job.displayTitle)
                } icon: {
                    Image(systemName: "doc.text")
                }
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
            }
        } else {
            content
        }
    }
}

/// The visible line of the divider before the preview (D43): a line over the full height and a grip
/// in the middle, in system colours that follow light and dark mode. It lies on top of the divider
/// as a separate view and lets every click through, so the divider underneath can still be dragged.
private final class DividerMarkView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.secondaryLabelColor.setFill()
        NSRect(x: bounds.midX - 1, y: bounds.minY, width: 2, height: bounds.height).fill()
        NSColor.labelColor.withAlphaComponent(0.75).setFill()
        NSBezierPath(roundedRect: NSRect(x: bounds.midX - 3, y: bounds.midY - 22, width: 6, height: 44),
                     xRadius: 3, yRadius: 3).fill()
    }
}
