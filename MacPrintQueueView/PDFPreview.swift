import Observation
import PDFKit
import SwiftUI

/// Drives the PDFView from the SwiftUI toolbar (paging and zooming).
@MainActor
@Observable
final class PDFViewController {
    @ObservationIgnored weak var view: PDFView?
    private(set) var pageIndex = 0
    private(set) var pageCount = 0

    var canGoBack: Bool { pageIndex > 0 }
    var canGoForward: Bool { pageIndex < pageCount - 1 }

    func previousPage() { view?.goToPreviousPage(nil) }
    func nextPage() { view?.goToNextPage(nil) }

    func zoomIn() {
        guard let view else { return }
        view.autoScales = false
        view.zoomIn(nil)
    }

    func zoomOut() {
        guard let view else { return }
        view.autoScales = false
        view.zoomOut(nil)
    }

    func zoomToFit() { view?.autoScales = true }

    func actualSize() {
        guard let view else { return }
        view.autoScales = false
        view.scaleFactor = 1
    }

    fileprivate func update() {
        guard let view, let document = view.document else {
            pageIndex = 0; pageCount = 0
            return
        }
        pageCount = document.pageCount
        pageIndex = view.currentPage.map { document.index(for: $0) } ?? 0
    }
}

struct PDFPreview: NSViewRepresentable {
    let document: PDFDocument
    let controller: PDFViewController

    final class Coordinator {
        var observer: NSObjectProtocol?
        deinit { observer.map(NotificationCenter.default.removeObserver) }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.displayMode = .singlePageContinuous
        view.displaysPageBreaks = true
        view.autoScales = true
        view.backgroundColor = .windowBackgroundColor
        context.coordinator.observer = NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged, object: view, queue: .main
        ) { [controller] _ in
            MainActor.assumeIsolated { controller.update() }
        }
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        controller.view = view
        if view.document !== document {
            view.document = document
            view.autoScales = true
            if let first = document.page(at: 0) { view.go(to: first) }
        }
        // Do not modify observed state during the SwiftUI update itself.
        Task { @MainActor [controller] in controller.update() }
    }
}
