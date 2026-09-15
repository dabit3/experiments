import AppKit
import SwiftUI
import Combine
import DevinCore

final class WorkspaceWindowController: NSWindowController, NSWindowDelegate {
    let workspace: DocumentWorkspace
    var session: StudioSession? { workspace.activeSession }
    var subscription: AnyCancellable?
    init(tool: StudioTool?, document: CreativeDocument? = nil, url: URL? = nil) {
        let initial = tool.map { StudioSession(tool: $0, document: document) }
        initial?.fileURL = url
        workspace = DocumentWorkspace(tool: tool, initial: initial)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1440, height: 930), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.minSize = NSSize(width: 1120, height: 720)
        window.titlebarAppearsTransparent = true; window.titleVisibility = .hidden
        window.backgroundColor = NSColor(hex: "111312"); window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false; window.tabbingMode = .disallowed
        super.init(window: window)
        window.delegate = self
        window.contentView = NSHostingView(rootView: WorkspaceWindowRoot(workspace: workspace))
        workspace.onSelectionChanged = { [weak self] session in
            self?.observe(session)
            guard let self, self.window?.isKeyWindow == true else { return }
            self.window?.makeFirstResponder(nil)
            DispatchQueue.main.async { [weak self, weak session] in
                guard let self, let session, self.session === session, let window = self.window, window.attachedSheet == nil else { return }
                window.contentView?.layoutSubtreeIfNeeded()
                func canvas(in view: NSView) -> CanvasNSView? { if let canvas = view as? CanvasNSView, canvas.session === session { return canvas }; return view.subviews.compactMap { canvas(in: $0) }.first }
                if let root = window.contentView, let target = canvas(in: root), window.firstResponder === window || window.firstResponder === root { window.makeFirstResponder(target) }
            }
            AppCoordinator.shared.installMenus()
        }
        observe(initial)
        window.center(); window.setFrameAutosaveName(tool?.rawValue ?? "studio")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    func observe(_ session: StudioSession?) {
        subscription = nil
        guard let session else { window?.title = workspace.tool?.name ?? "Devin Studio"; window?.isDocumentEdited = false; return }
        subscription = session.$document.map(\.title).removeDuplicates().combineLatest(session.$isDirty.removeDuplicates()).receive(on: RunLoop.main).sink { [weak window] title, dirty in
            window?.isDocumentEdited = dirty; window?.title = title + " — " + session.tool.name
        }
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool { workspace.canCloseAll() }
    func windowDidBecomeKey(_ notification: Notification) { AppCoordinator.shared.installMenus() }
    func windowWillClose(_ notification: Notification) {
        workspace.stopAllPlayback()
        AppCoordinator.shared.windows.removeAll { $0 === self }
    }
}

final class AppCoordinator: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    static let shared = AppCoordinator()
    var windows: [WorkspaceWindowController] = []
    var keyboardMonitor: Any?
    var featureWindow: NSWindow?
    var currentController: WorkspaceWindowController? {
        let key = NSApp.keyWindow?.sheetParent ?? NSApp.keyWindow
        return windows.first { $0.window === key } ?? windows.first { $0.window === NSApp.mainWindow }
    }
    var current: StudioSession? { currentController?.session }
    func applicationDidFinishLaunching(_ notification: Notification) {
        installMenus()
        let args = CommandLine.arguments
        let mode = Bundle.main.object(forInfoDictionaryKey: "DevinTool") as? String
        let flagMode = args.firstIndex(of: "--tool").flatMap { args.indices.contains($0 + 1) ? args[$0 + 1] : nil }
        if windows.isEmpty { openWindow(tool: StudioTool(rawValue: flagMode ?? mode ?? "studio")) }
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let session = self?.current, !session.busy, !(NSApp.keyWindow?.firstResponder is NSTextView), !event.modifierFlags.contains(.command) else { return event }
            if event.keyCode == 48 && event.modifierFlags.contains(.control) { session.workspace?.selectRelative(event.modifierFlags.contains(.shift) ? -1 : 1); return nil }
            if event.keyCode == 49 && [.cut, .motion, .sound, .frame].contains(session.tool) { session.togglePlayback(); return nil }
            return event
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    @discardableResult func openWindow(tool: StudioTool?, document: CreativeDocument? = nil, url: URL? = nil, preferring workspace: DocumentWorkspace? = nil, separateWindow: Bool = false) -> StudioSession? {
        if !separateWindow, let tool {
            let preferred = workspace.flatMap { target in windows.first { $0.workspace === target } }
            let candidate = preferred ?? (currentController?.workspace.tool == tool ? currentController : nil) ?? windows.last { $0.workspace.tool == tool }
            if let candidate, candidate.workspace.usesTabs, candidate.workspace.tool == tool {
                let session = StudioSession(tool: tool, document: document); session.fileURL = url
                let opened = candidate.workspace.add(session)
                candidate.window?.makeKeyAndOrderFront(nil)
                return opened
            }
        }
        let controller = WorkspaceWindowController(tool: tool, document: document, url: url)
        windows.append(controller); controller.showWindow(nil); controller.window?.makeKeyAndOrderFront(nil)
        return controller.session
    }
    @discardableResult func createDocument(from source: StudioSession, title: String, width: Double, height: Double, background: String) -> StudioSession? {
        var document = Samples.document(for: source.tool, blank: true)
        document.title = title.isEmpty ? "Untitled" : title; document.width = width; document.height = height; document.background = background
        do { _ = try document.validated() } catch { source.error = error.localizedDescription; return nil }
        source.showNew = false; source.workspace?.showsNewDocument = false
        let session = openWindow(tool: source.tool, document: document, preferring: source.workspace)
        session?.needsInitialSave = true; session?.isDirty = true
        return session
    }
    func launch(_ tool: StudioTool) {
        let appURL = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent(tool.name + ".app")
        if Bundle.main.bundleURL.pathExtension == "app", FileManager.default.fileExists(atPath: appURL.path), appURL != Bundle.main.bundleURL {
            let running = NSRunningApplication.runningApplications(withBundleIdentifier: "ai.devin.creative." + tool.rawValue)
            if let matching = running.first(where: { $0.bundleURL?.standardizedFileURL == appURL.standardizedFileURL }) { matching.activate(options: []); return }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = !running.isEmpty
            NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
                if let error { DispatchQueue.main.async { self.report(error) } }
            }
        } else { openWindow(tool: tool) }
    }
    @objc func home() { openWindow(tool: nil) }
    @objc func newDocument() {
        if let current { current.showNew = true }
        else if let workspace = currentController?.workspace, workspace.tool != nil { workspace.showsNewDocument = true }
        else { openWindow(tool: .pixel)?.showNew = true }
    }
    @objc func openDocument() {
        let panel = NSOpenPanel()
        let tool = current?.tool ?? currentController?.workspace.tool
        panel.allowedContentTypes = [.init(filenameExtension: "devin") ?? .json]
        if let tool { panel.allowedContentTypes += StudioSession.importTypes(for: tool) }
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if url.pathExtension.lowercased() == "devin" || tool == nil { openProject(url); return }
        guard let tool else { return }
        var document = Samples.document(for: tool, blank: true)
        document.title = url.deletingPathExtension().lastPathComponent
        if let image = NSImage(contentsOf: url)?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let factor = min(1, 16384 / Double(max(image.width, image.height)))
            document.width = max(16, Double(image.width) * factor); document.height = max(16, Double(image.height) * factor)
        }
        openWindow(tool: tool, document: document)?.importURLs([url])
    }
    func openProject(_ url: URL) {
        do {
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            guard (values.fileSize ?? 0) <= 512_000_000 else { throw DocumentError.invalid("This project exceeds the 512 MB project size limit.") }
            let document = try CreativeDocument.load(from: Data(contentsOf: url))
            openWindow(tool: document.tool, document: document, url: url)
            RecentProjects.add(url, tool: document.tool, title: document.title)
        } catch { report(error) }
    }
    func application(_ sender: NSApplication, openFile filename: String) -> Bool { openProject(URL(fileURLWithPath: filename)); return true }
    @objc func closeDocument() {
        guard let controller = currentController else { return }
        if controller.workspace.usesTabs, let session = controller.session { controller.workspace.close(session.id) }
        else { controller.window?.performClose(nil) }
    }
    @objc func nextDocument() { currentController?.workspace.selectRelative(1) }
    @objc func previousDocument() { currentController?.workspace.selectRelative(-1) }
    @objc func saveDocument() { _ = current?.save() }
    @objc func saveAs() { _ = current?.save(as: true) }
    @objc func importAssets() { current?.importFiles() }
    @objc func exportDocument() { current?.showExport = true }
    @objc func undoDocument() { current?.undo() }
    @objc func redoDocument() { current?.redo() }
    @objc func duplicateLayer() { current?.duplicate() }
    @objc func deleteLayer() { current?.deleteSelection() }
    @objc func clearDocumentSelection() { current?.clearSelection() }
    @objc func zoomIn() { if let current { current.zoom = min(20, current.zoom * 1.25) } }
    @objc func zoomOut() { if let current { current.zoom = max(0.15, current.zoom / 1.25) } }
    @objc func zoomFit() { current?.zoom = 1 }
    @objc func showFeatures() {
        if let current { current.showFeatureInventory = true; return }
        if let featureWindow { featureWindow.makeKeyAndOrderFront(nil); return }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 960, height: 690), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Feature Parity Ledger"; window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: FeatureInventoryView(initialTool: .pixel, close: { [weak window] in window?.close() }))
        featureWindow = window; window.center(); window.makeKeyAndOrderFront(nil)
    }
    @objc func about() {
        NSApp.orderFrontStandardAboutPanel(options: [.applicationName: "Devin Creative", .applicationVersion: "0.4.2", .credits: NSAttributedString(string: "Twelve creative workspaces. One native foundation.\nBuilt with Swift and Apple frameworks.\nIndependent software. Not affiliated with Adobe.\nThis is an early, limited implementation, not feature parity with Creative Cloud.")])
    }
    func report(_ error: Error) {
        if let current { current.error = error.localizedDescription }
        else { let alert = NSAlert(error: error); alert.runModal() }
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        for controller in windows {
            controller.window?.makeKeyAndOrderFront(nil)
            if !controller.workspace.canCloseAll() { return .terminateCancel }
        }
        return .terminateNow
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(professionalCommand(_:)), let identifier = menuItem.representedObject as? String { return validateProfessionalCommand(identifier) }
        switch menuItem.action {
        case #selector(saveDocument), #selector(saveAs), #selector(exportDocument): return current != nil && current?.busy == false
        case #selector(importAssets): return current != nil && current?.tool != .space && current?.busy == false
        case #selector(undoDocument): return current?.history.undoStack.isEmpty == false
        case #selector(redoDocument): return current?.history.redoStack.isEmpty == false
        case #selector(duplicateLayer): return current?.selected != nil
        case #selector(deleteLayer), #selector(clearDocumentSelection): return current?.selectedID != nil
        default: return true
        }
    }
    func installMenus() {
        if let session = current, session.usesProfessionalWorkspace { installProfessionalMenus(session); return }
        let menu = NSMenu()
        func section(_ title: String) -> NSMenu {
            let item = NSMenuItem(); item.title = title
            let sub = NSMenu(title: title); item.submenu = sub; menu.addItem(item); return sub
        }
        func item(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String = "", shift: Bool = false, target: AnyObject? = AppCoordinator.shared) {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
            item.target = target
            item.keyEquivalentModifierMask = shift ? [.command, .shift] : [.command]
            menu.addItem(item)
        }
        let app = section("Devin")
        item(app, "About Devin Creative", #selector(about))
        app.addItem(.separator())
        item(app, "Hide", #selector(NSApplication.hide(_:)), "h", target: NSApp)
        app.addItem(.separator())
        item(app, "Quit", #selector(NSApplication.terminate(_:)), "q", target: NSApp)
        let file = section("File")
        item(file, "New Project…", #selector(newDocument), "n")
        item(file, "Open Project…", #selector(openDocument), "o")
        item(file, "Import…", #selector(importAssets), "i")
        file.addItem(.separator())
        item(file, "Save", #selector(saveDocument), "s")
        item(file, "Save As…", #selector(saveAs), "s", shift: true)
        item(file, "Export…", #selector(exportDocument), "e", shift: true)
        file.addItem(.separator())
        item(file, "Close Document", #selector(closeDocument), "w")
        let edit = section("Edit")
        item(edit, "Undo Project Change", #selector(undoDocument), "z")
        item(edit, "Redo Project Change", #selector(redoDocument), "z", shift: true)
        edit.addItem(.separator())
        item(edit, "Cut", #selector(NSText.cut(_:)), "x", target: nil)
        item(edit, "Copy", #selector(NSText.copy(_:)), "c", target: nil)
        item(edit, "Paste", #selector(NSText.paste(_:)), "v", target: nil)
        item(edit, "Select All", #selector(NSText.selectAll(_:)), "a", target: nil)
        edit.addItem(.separator())
        item(edit, "Duplicate Layer", #selector(duplicateLayer), "d")
        item(edit, "Delete Selected Object", #selector(deleteLayer), "\u{8}")
        let view = section("View")
        item(view, "Zoom In", #selector(zoomIn), "+")
        item(view, "Zoom Out", #selector(zoomOut), "-")
        item(view, "Fit Canvas", #selector(zoomFit), "0")
        item(view, "Creative Home", #selector(home), "h", shift: true)
        let window = section("Window")
        item(window, "Next Document", #selector(nextDocument), "]", shift: true)
        item(window, "Previous Document", #selector(previousDocument), "[", shift: true)
        item(window, "Minimize", #selector(NSWindow.performMiniaturize(_:)), "m", target: nil)
        item(window, "Zoom", #selector(NSWindow.performZoom(_:)), target: nil)
        NSApp.windowsMenu = window
        let help = section("Help")
        item(help, "Feature Parity Ledger…", #selector(showFeatures))
        item(help, "About This Build", #selector(about))
        NSApp.mainMenu = menu
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
if let index = CommandLine.arguments.firstIndex(of: "--parity-cycle"), CommandLine.arguments.indices.contains(index + 1) {
    let root = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true).standardizedFileURL
    Task { @MainActor in exit(await ParityCycle.run(root: root, workspaceOnly: CommandLine.arguments.contains("--workspace-only"))) }
    app.run()
} else if let index = CommandLine.arguments.firstIndex(of: "--source-fingerprint"), CommandLine.arguments.indices.contains(index + 1) {
    do { print(try ParityCycle.fingerprint(root: URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true).standardizedFileURL)) }
    catch { print(error.localizedDescription); exit(1) }
} else if CommandLine.arguments.contains("--parity-report") {
    let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(ParityLedger.all) { FileHandle.standardOutput.write(data) }
} else if CommandLine.arguments.contains("--parity-summary") {
    for tool in StudioTool.allCases {
        let features = ParityLedger.features(tool)
        print("\(tool.name): \(features.count) listed, \(features.filter { $0.status == .missing }.count) missing, \(features.filter { $0.status == .partial }.count) partial, \(features.filter { $0.status == .verified }.count) reference-verified")
    }
    print(ParityLedger.warning)
} else if CommandLine.arguments.contains("--verify") || CommandLine.arguments.contains("--verify-pixel-tools") {
    Task { @MainActor in
        let result = await Verification.run(pixelOnly: CommandLine.arguments.contains("--verify-pixel-tools"))
        exit(result ? 0 : 1)
    }
    app.run()
} else if CommandLine.arguments.contains("--generate-icons") {
    let index = CommandLine.arguments.firstIndex(of: "--generate-icons")!
    if CommandLine.arguments.indices.contains(index + 1) {
        IconGenerator.generate(at: URL(fileURLWithPath: CommandLine.arguments[index + 1]))
    }
} else {
    app.delegate = AppCoordinator.shared
    app.run()
}
