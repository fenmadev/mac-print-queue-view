import SwiftUI

// MARK: - Rows

/// A job in the queue: page thumbnail, title, status badge and time. Pause/resume and
/// delete buttons appear when the pointer is over the row or the row is selected.
struct QueueJobRow: View {
    let job: PrintJob
    let thumbnail: NSImage?
    var isSelected = false
    var canPause = false
    var canResume = false
    var canCancel = false
    var onPause: () -> Void = {}
    var onResume: () -> Void = {}
    var onCancel: () -> Void = {}
    @State private var isHovering = false

    private var showsActions: Bool { (isHovering || isSelected) && (canPause || canResume || canCancel) }

    var body: some View {
        HStack(spacing: 12) {
            PageThumbnail(image: thumbnail)
            VStack(alignment: .leading, spacing: 5) {
                Text(verbatim: job.displayTitle)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 6) {
                    StatusBadge(status: job.status, text: job.stateDescription)
                    Text(verbatim: job.created.shortTimestamp)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            Spacer(minLength: 0)
            if showsActions {
                HStack(spacing: 2) {
                    if canPause {
                        RowActionButton(systemImage: "pause.fill", help: "Pause the job; the other jobs keep printing", action: onPause)
                    } else if canResume {
                        RowActionButton(systemImage: "play.fill", help: "Resume the job", action: onResume)
                    }
                    if canCancel {
                        RowActionButton(systemImage: "xmark.circle", help: "Cancel Job", action: onCancel)
                    }
                }
                .transition(.opacity)
            } else if job.status == .printing {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isHovering = hovering }
        }
        .help(Text(verbatim: "\(job.displayTitle) · \(job.format)"))
    }
}

/// A completed, canceled or aborted job: compact, with a status icon instead of a thumbnail.
/// "Print again" and "remove" buttons appear when the pointer is over the row or the row is selected.
struct FinishedJobRow: View {
    let job: PrintJob
    var isSelected = false
    var onPrintAgain: () -> Void = {}
    var onRemove: () -> Void = {}
    @Environment(\.backgroundProminence) private var prominence
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: job.status.symbol)
                .font(.system(size: 16))
                .foregroundStyle(prominence == .increased ? .white : job.status.tint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: job.displayTitle)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(verbatim: "\(job.stateDescription) · \((job.completed ?? job.created).shortTimestamp)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if isHovering || isSelected {
                HStack(spacing: 2) {
                    RowActionButton(systemImage: "arrow.clockwise", help: "Print Again", action: onPrintAgain)
                    RowActionButton(systemImage: "trash", help: "Remove from List…", action: onRemove)
                }
                .transition(.opacity)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isHovering = hovering }
        }
        .help(Text(verbatim: "\(job.displayTitle) · \(job.format)"))
    }
}

// MARK: - Building blocks

/// Small, quiet icon button used inside a row.
struct RowActionButton: View {
    let systemImage: String
    let help: LocalizedStringKey
    let action: () -> Void
    @Environment(\.backgroundProminence) private var prominence
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 24, height: 22)
                .background(isHovering ? Color.primary.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 5))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(prominence == .increased ? Color.white : .secondary)
        .help(help)
        .accessibilityLabel(Text(help))
        .onHover { isHovering = $0 }
    }
}

/// Small "sheet of paper" showing the first page of the document.
struct PageThumbnail: View {
    let image: NSImage?

    private let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)

    var body: some View {
        ZStack {
            shape.fill(.white)
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: 16))
                    .foregroundStyle(.gray.opacity(0.6))
            }
        }
        .frame(width: 40, height: 52)
        .clipShape(shape)
        .overlay(shape.strokeBorder(.black.opacity(0.15), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.18), radius: 1.5, y: 1)
    }
}

/// Coloured capsule with the job state. Turns white on a selected row.
struct StatusBadge: View {
    let status: JobStatus
    let text: String
    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        let selected = prominence == .increased
        Text(verbatim: text)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .foregroundStyle(selected ? .white : status.tint)
            .background(selected ? Color.white.opacity(0.22) : status.tint.opacity(0.15), in: Capsule())
    }
}

/// Section header with a title, a count and optional trailing content.
struct JobSectionHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    let count: Int
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
            Text(verbatim: "\(count)")
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(.quaternary, in: Capsule())
            Spacer()
            trailing
        }
    }
}

extension JobSectionHeader where Trailing == EmptyView {
    init(title: LocalizedStringKey, count: Int) {
        self.init(title: title, count: count) { EmptyView() }
    }
}

/// Shown in the queue section when there are no jobs.
struct EmptyQueueRow: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray")
                .font(.system(size: 22, weight: .light))
            Text("No jobs in the queue")
                .font(.callout)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

// MARK: - Styling helpers

extension JobStatus {
    var tint: Color {
        switch self {
        case .printing: .blue
        case .held: .orange
        case .stopped, .aborted: .red
        case .completed: .green
        case .pending, .canceled, .unknown: .gray
        }
    }

    var symbol: String {
        switch self {
        case .completed: "checkmark.circle.fill"
        case .canceled: "xmark.circle.fill"
        case .aborted, .stopped: "exclamationmark.circle.fill"
        default: "circle"
        }
    }
}

extension Date {
    /// Time only for today, otherwise a short date and time.
    var shortTimestamp: String {
        Calendar.current.isDateInToday(self)
            ? formatted(date: .omitted, time: .shortened)
            : formatted(date: .abbreviated, time: .shortened)
    }
}
