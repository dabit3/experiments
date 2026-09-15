import AppKit
import SwiftUI
import DevinCore

final class DocumentWorkspace: ObservableObject {
    let tool: StudioTool?
    @Published private(set) var sessions: [StudioSession] = []
    @Published private(set) var activeID: UUID?
    @Published var showsNewDocument = false
    var onSelectionChanged: ((StudioSession?) -> Void)?
    var activeSession: StudioSession? { sessions.first { $0.id == activeID } }
    var usesTabs: Bool { tool.map { [.pixel, .form, .press, .folio, .code].contains($0) } ?? false }
    lazy var creationSession: StudioSession = {
        let target = tool ?? .pixel
        let session = StudioSession(tool: target, document: Samples.document(for: target, blank: true))
        session.workspace = self
        return session
    }()
    init(tool: StudioTool?, initial: StudioSession? = nil) {
        self.tool = tool
        if let initial { sessions = [initial]; activeID = initial.id; initial.workspace = self }
    }
    @discardableResult func add(_ session: StudioSession) -> StudioSession {
        if let url = session.fileURL, let existing = sessions.first(where: { $0.fileURL?.standardizedFileURL == url.standardizedFileURL }) { select(existing.id); return existing }
        session.workspace = self; sessions.append(session); select(session.id)
        return session
    }
    func select(_ id: UUID) {
        guard sessions.contains(where: { $0.id == id }), activeID != id else { return }
        activeSession?.isPlaying = false; activeSession?.player.pause()
        activeID = id; onSelectionChanged?(activeSession)
    }
    func selectRelative(_ offset: Int) {
        guard let index = sessions.firstIndex(where: { $0.id == activeID }), !sessions.isEmpty else { return }
        select(sessions[(index + offset % sessions.count + sessions.count) % sessions.count].id)
    }
    @discardableResult func close(_ id: UUID, confirm: ((StudioSession) -> Bool)? = nil) -> Bool {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return false }
        let session = sessions[index]
        if session.busy { select(id); session.error = "Finish or cancel this document's operation before closing it."; return false }
        if session.isDirty { select(id) }
        guard confirm?(session) ?? session.confirmDiscard() else { return false }
        session.isPlaying = false; session.player.pause(); session.workspace = nil
        sessions.remove(at: index)
        if activeID == id {
            activeID = nil
            if sessions.isEmpty { onSelectionChanged?(nil) }
            else { select(sessions[min(index, sessions.count - 1)].id) }
        }
        return true
    }
    func canCloseAll(confirm: ((StudioSession) -> Bool)? = nil) -> Bool {
        if let busy = sessions.first(where: \.busy) { select(busy.id); busy.error = "Finish or cancel the operation before closing this workspace."; return false }
        for session in sessions where session.isDirty {
            select(session.id)
            if !(confirm?(session) ?? session.confirmDiscard()) { return false }
        }
        return true
    }
    func stopAllPlayback() { for session in sessions { session.isPlaying = false; session.player.pause() } }
}

struct WorkspaceWindowRoot: View {
    @ObservedObject var workspace: DocumentWorkspace
    var body: some View {
        Group {
            if let session = workspace.activeSession { WorkspaceRoot(session: session).id(session.id) }
            else if let tool = workspace.tool {
                VStack(spacing: 22) {
                    Text(tool.name).font(.system(size: 28, weight: .medium))
                    Text("No documents open").foregroundStyle(Theme.muted)
                    HStack {
                        Button("New Document…") { workspace.showsNewDocument = true }.buttonStyle(ProButtonStyle(prominent: true))
                        Button("Open…") { AppCoordinator.shared.openDocument() }.buttonStyle(ProButtonStyle())
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(ProTheme.background).foregroundStyle(ProTheme.text)
                    .sheet(isPresented: $workspace.showsNewDocument) { NewProjectSheet(session: workspace.creationSession) }
            } else { DashboardView() }
        }.preferredColorScheme(.dark)
    }
}

struct WorkspaceDocumentTabs: View {
    @ObservedObject var workspace: DocumentWorkspace
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(workspace.sessions, id: \.id) { session in WorkspaceDocumentTab(workspace: workspace, session: session).id(session.id) }
                }
            }.scrollIndicators(.hidden)
                .onChange(of: workspace.activeID) { _, id in if let id { proxy.scrollTo(id) } }
        }.frame(height: 29).background(Color(hex: "222222"))
    }
}

struct WorkspaceDocumentTab: View {
    @ObservedObject var workspace: DocumentWorkspace
    @ObservedObject var session: StudioSession
    var title: String {
        let zoom = session.tool.isCanvas ? String(format: " @ %.1f%%", session.canvasScale * 100) : ""
        return session.document.title + (session.isDirty ? " *" : "") + zoom + (session.tool == .pixel ? " (RGB/8)" : "")
    }
    var body: some View {
        HStack(spacing: 0) {
            Button { workspace.select(session.id) } label: { Text(title).font(.system(size: 11)).lineLimit(1).padding(.leading, 12).padding(.trailing, 8).frame(height: 29) }.buttonStyle(.plain).accessibilityLabel("Select document " + session.document.title)
            Button { workspace.close(session.id) } label: { Image(systemName: "xmark").font(.system(size: 8)).frame(width: 24, height: 29) }.buttonStyle(.plain).accessibilityLabel("Close document " + session.document.title)
        }.foregroundStyle(workspace.activeID == session.id ? ProTheme.text : ProTheme.secondary)
            .background(workspace.activeID == session.id ? Color(hex: "3A3A3A") : Color(hex: "292929"))
            .overlay(alignment: .trailing) { Rectangle().fill(ProTheme.border).frame(width: 1) }
            .contextMenu { Button("Close Document") { workspace.close(session.id) } }
    }
}
