import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import DevinCore

final class PDFWorkspaceState: ObservableObject {
    @Published var document = PDFDocument()
    @Published var query = ""
    @Published var results: [PDFSelection] = []
    weak var view: PDFView?
}

struct PDFSurface: NSViewRepresentable {
    @ObservedObject var session: StudioSession
    @ObservedObject var state: PDFWorkspaceState
    func makeCoordinator() -> Coordinator { Coordinator(session: session) }
    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true; view.displayMode = .singlePageContinuous; view.displayDirection = .vertical
        view.backgroundColor = NSColor(hex: "252826"); view.displaysPageBreaks = true
        state.view = view
        context.coordinator.observer = NotificationCenter.default.addObserver(forName: .PDFViewPageChanged, object: view, queue: .main) { [weak view, weak session] _ in
            guard let view, let page = view.currentPage, let document = view.document else { return }
            let index = document.index(for: page)
            DispatchQueue.main.async { if index != NSNotFound { session?.page = index } }
        }
        return view
    }
    func updateNSView(_ view: PDFView, context: Context) {
        if view.document !== state.document { view.document = state.document; view.autoScales = true }
        if let page = state.document.page(at: session.page), view.currentPage !== page { view.go(to: page) }
        state.view = view
    }
    final class Coordinator {
        let session: StudioSession
        var observer: NSObjectProtocol?
        init(session: StudioSession) { self.session = session }
        deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
    }
}

struct PDFWorkspace: View {
    @ObservedObject var session: StudioSession
    @StateObject private var state = PDFWorkspaceState()
    @State private var annotation = "A note worth keeping."
    @State private var annotationColor = Color(hex: "8A3D32")
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack { Text("Pages").font(.system(size: 12, weight: .semibold)); Spacer(); Text("\(state.document.pageCount)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.muted) }.padding(18).frame(height: 46)
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(0..<state.document.pageCount, id: \.self) { index in
                            if let page = state.document.page(at: index) {
                                VStack(spacing: 8) {
                                    Image(nsImage: page.thumbnail(of: NSSize(width: 136, height: 180), for: .cropBox)).resizable().scaledToFit().frame(width: 136, height: 180)
                                        .padding(5).overlay(RoundedRectangle(cornerRadius: 4).stroke(session.page == index ? Theme.accent : .clear, lineWidth: 2))
                                    Text("\(index + 1)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.muted)
                                }.onTapGesture { session.page = index }
                            }
                        }
                    }.padding(15)
                }
            }.frame(width: 192).background(Theme.sidebar)
            VStack(spacing: 0) {
                HStack {
                    IconButton(symbol: "chevron.left", help: "Previous page") { session.page = max(0, session.page - 1) }
                    Text("\(state.document.pageCount == 0 ? 0 : session.page + 1) / \(state.document.pageCount)").font(.system(size: 11, design: .monospaced))
                    IconButton(symbol: "chevron.right", help: "Next page") { session.page = min(max(0, state.document.pageCount - 1), session.page + 1) }
                    Spacer()
                    IconButton(symbol: "minus.magnifyingglass", help: "Zoom out") { state.view?.zoomOut(nil) }
                    IconButton(symbol: "plus.magnifyingglass", help: "Zoom in") { state.view?.zoomIn(nil) }
                    Button("Fit page") { state.view?.autoScales = true }.buttonStyle(StudioButtonStyle())
                }.padding(.horizontal, 16).frame(height: 46).background(Theme.sidebar)
                if state.document.pageCount == 0 {
                    EmptyWorkspace(symbol: "doc.richtext", title: "Make room for the details.", description: "Read, search, rotate, arrange, merge, and annotate PDF documents. Export your changes as a PDF.", button: "Open PDF") { session.importFiles() }
                } else { PDFSurface(session: session, state: state) }
            }
            ScrollView {
                VStack(spacing: 0) {
                    InspectorSection(title: "Find in document") {
                        HStack { TextField("Search text", text: $state.query).textFieldStyle(.roundedBorder).onSubmit { search() }; Button { search() } label: { Image(systemName: "magnifyingglass") }.buttonStyle(.plain) }
                        if !state.results.isEmpty {
                            Text("\(state.results.count) matches").font(.system(size: 10)).foregroundStyle(Theme.muted)
                            ForEach(Array(state.results.prefix(30).enumerated()), id: \.offset) { _, selection in
                                Button(selection.string ?? "Match") {
                                    state.view?.setCurrentSelection(selection, animate: true)
                                    state.view?.go(to: selection)
                                }.buttonStyle(.plain).font(.system(size: 10)).lineLimit(2)
                            }
                        }
                    }
                    InspectorSection(title: "Organize") {
                        Button { edit { if let page = $0.page(at: session.page) { page.rotation = (page.rotation + 90) % 360 } } } label: { Label("Rotate clockwise", systemImage: "rotate.right") }.buttonStyle(StudioButtonStyle())
                        HStack { Button("Earlier") { move(-1) }.buttonStyle(StudioButtonStyle()); Button("Later") { move(1) }.buttonStyle(StudioButtonStyle()) }
                        Button { merge() } label: { Label("Append PDF…", systemImage: "doc.on.doc") }.buttonStyle(StudioButtonStyle())
                        Button("Delete page") {
                            guard state.document.pageCount > 1 else { return }
                            edit { $0.removePage(at: session.page) }
                            session.page = min(session.page, state.document.pageCount - 1)
                        }.buttonStyle(StudioButtonStyle()).disabled(state.document.pageCount < 2)
                    }
                    InspectorSection(title: "Annotate") {
                        TextEditor(text: $annotation).font(.system(size: 12)).frame(height: 95).scrollContentBackground(.hidden).padding(6).background(Theme.background, in: RoundedRectangle(cornerRadius: 5))
                        ColorPicker("Text color", selection: $annotationColor, supportsOpacity: false).font(.system(size: 11))
                        Button("Add note to page") { addNote() }.buttonStyle(StudioButtonStyle())
                        Button("Highlight selected text") { highlight() }.buttonStyle(StudioButtonStyle())
                        Text("Select text in the document to highlight it. Notes are added near the top of the current page.").font(.system(size: 10)).foregroundStyle(Theme.muted).lineSpacing(3)
                        ForEach(Array((state.document.page(at: session.page)?.annotations ?? []).enumerated()), id: \.offset) { index, item in
                            HStack {
                                Text(item.contents ?? item.type ?? "Annotation").font(.system(size: 10)).lineLimit(2)
                                Spacer()
                                Button { edit { document in if let page = document.page(at: session.page), page.annotations.indices.contains(index) { page.removeAnnotation(page.annotations[index]) } } } label: { Image(systemName: "trash") }.buttonStyle(.plain).help("Delete annotation")
                            }
                        }
                    }
                    InspectorSection(title: "Document") {
                        Text("\(state.document.pageCount) pages").font(.system(size: 12))
                        Text("Edits are stored in your Devin project. Export to create a separate PDF; the original stays untouched.").font(.system(size: 10)).foregroundStyle(Theme.muted).lineSpacing(4)
                    }
                }
            }.frame(width: 250).background(Theme.sidebar)
        }.onAppear { load() }.onChange(of: session.document.pdfData) { _, _ in load() }
    }
    func load() {
        state.document = session.document.pdfData.flatMap { PDFDocument(data: $0) } ?? PDFDocument()
        session.page = min(session.page, max(0, state.document.pageCount - 1))
        state.results = []
    }
    func edit(_ action: (PDFDocument) -> Void) {
        guard let data = state.document.dataRepresentation(), let copy = PDFDocument(data: data) else { return }
        action(copy)
        guard let result = copy.dataRepresentation() else { session.error = "The PDF change could not be saved."; return }
        session.mutate { $0.pdfData = result }
        state.document = copy
    }
    func search() {
        state.results = state.query.isEmpty ? [] : state.document.findString(state.query, withOptions: [.caseInsensitive])
        state.view?.highlightedSelections = state.results
        if let first = state.results.first { state.view?.go(to: first) }
        if !state.query.isEmpty && state.results.isEmpty { session.message = "No matching text found." }
    }
    func move(_ direction: Int) {
        let target = session.page + direction
        guard target >= 0, target < state.document.pageCount else { return }
        edit { document in
            guard let page = document.page(at: session.page) else { return }
            document.removePage(at: session.page); document.insert(page, at: target)
        }
        session.page = target
    }
    func merge() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.pdf]; panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        var incoming: [PDFDocument] = []
        for url in panel.urls {
            guard let document = PDFDocument(url: url), !document.isLocked else { session.error = "One of the selected PDFs is locked or unreadable."; return }
            incoming.append(document)
        }
        if state.document.pageCount == 0 {
            let document = PDFDocument()
            for pdf in incoming { for i in 0..<pdf.pageCount { if let page = pdf.page(at: i)?.copy() as? PDFPage { document.insert(page, at: document.pageCount) } } }
            session.mutate { $0.pdfData = document.dataRepresentation() }
        } else {
            edit { document in for pdf in incoming { for i in 0..<pdf.pageCount { if let page = pdf.page(at: i)?.copy() as? PDFPage { document.insert(page, at: document.pageCount) } } } }
        }
    }
    static func noteBounds(in bounds: CGRect) -> CGRect {
        let margin = min(36, bounds.width / 10, bounds.height / 10)
        let width = max(1, min(320, bounds.width - margin * 2)), height = max(1, min(90, bounds.height - margin * 2))
        return CGRect(x: bounds.minX + margin, y: bounds.maxY - margin - height, width: width, height: height)
    }
    func addNote() {
        guard !annotation.isEmpty, state.document.pageCount > 0 else { return }
        edit { document in
            guard let page = document.page(at: session.page) else { return }
            let bounds = page.bounds(for: .cropBox)
            let note = PDFAnnotation(bounds: Self.noteBounds(in: bounds), forType: .freeText, withProperties: nil)
            note.contents = annotation; note.font = .systemFont(ofSize: 16); note.fontColor = NSColor(annotationColor)
            note.color = .clear; note.border = PDFBorder(); note.border?.lineWidth = 0
            page.addAnnotation(note)
        }
    }
    func highlight() {
        guard let selection = state.view?.currentSelection else { session.message = "Select text in the PDF first."; return }
        var ranges: [(Int, CGRect)] = []
        for line in selection.selectionsByLine() {
            for page in line.pages { ranges.append((state.document.index(for: page), line.bounds(for: page))) }
        }
        edit { document in
            for (index, rect) in ranges {
                let annotation = PDFAnnotation(bounds: rect, forType: .highlight, withProperties: nil)
                annotation.color = NSColor.systemYellow.withAlphaComponent(0.35)
                document.page(at: index)?.addAnnotation(annotation)
            }
        }
    }
}
