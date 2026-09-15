import AppKit
import SwiftUI
import DevinCore

@MainActor enum WorkspaceBehaviorVerification {
    static func run(directory: URL) async throws -> Int {
        let coordinator = AppCoordinator.shared
        let existing = coordinator.windows
        defer {
            for controller in coordinator.windows where !existing.contains(where: { $0 === controller }) {
                controller.workspace.stopAllPlayback(); controller.window?.delegate = nil; controller.window?.orderOut(nil); controller.window?.contentView = nil
            }
            coordinator.windows = existing
        }
        var failures: [String] = [], checks = 0, observations: [String: Bool] = [:]
        func check(_ value: Bool, _ id: String, _ title: String) {
            observations[id] = value
            if value { checks += 1; print("PASS " + title) }
            else { failures.append(title); print("FAIL " + title) }
        }
        let first = CreativeDocument(title: "First tab", tool: .pixel)
        let second = CreativeDocument(title: "Second tab", tool: .pixel)
        let firstSession = coordinator.openWindow(tool: .pixel, document: first)!
        let firstController = coordinator.windows.last!
        let secondSession = coordinator.openWindow(tool: .pixel, document: second)!
        let workspace = firstController.workspace
        check(coordinator.windows.count == existing.count + 1, "sameWindow", "Creating a Pixel document reuses the application window")
        check(workspace.sessions.count == 2 && workspace.activeSession === secondSession, "twoTabs", "Both documents remain open and the new tab becomes active")
        firstSession.mutate { $0.title = "Edited first tab" }
        workspace.select(firstSession.id); firstSession.undo()
        check(firstSession.document.title == "First tab" && secondSession.document.title == "Second tab", "independentUndo", "Document tabs retain independent artwork and undo histories")
        firstSession.zoom = 1.75; firstSession.drawingColor = "AABBCC"
        workspace.select(secondSession.id); workspace.select(firstSession.id)
        check(firstSession.zoom == 1.75 && firstSession.drawingColor == "AABBCC", "sessionState", "Tab switching preserves document editing state")
        firstSession.showNew = true
        try await Task.sleep(nanoseconds: 350_000_000)
        check(firstController.window?.attachedSheet != nil, "newDialog", "New Document settings stay attached to the existing workspace")
        let created = coordinator.createDocument(from: firstSession, title: "Created in workspace", width: 320, height: 240, background: "FFFFFF")!
        try await Task.sleep(nanoseconds: 350_000_000)
        check(firstController.window?.attachedSheet == nil, "dismissNewDialog", "Creating a tab dismisses the New Document settings panel")
        check(coordinator.windows.count == existing.count + 1 && workspace.activeSession === created && created.isDirty, "createAction", "The New Document action creates an unsaved tab rather than a new window")
        if let view = firstController.window?.contentView {
            view.layoutSubtreeIfNeeded()
            if let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: bitmap)
                try bitmap.representation(using: .png, properties: [:])?.write(to: directory.appendingPathComponent("document-tabs.png"))
            }
        }
        let count = workspace.sessions.count
        check(!workspace.close(created.id, confirm: { _ in false }) && workspace.sessions.count == count, "cancelClose", "Canceling a tab close preserves the document")
        firstSession.mutate { $0.title = "Unsaved background tab" }
        workspace.select(secondSession.id)
        var prompted: [UUID] = []
        let canClose = workspace.canCloseAll { prompted.append($0.id); return false }
        check(!canClose && prompted.contains(firstSession.id) && workspace.sessions.count == count, "backgroundUnsaved", "Closing a workspace checks unsaved background tabs")
        created.busy = true
        check(!workspace.close(created.id, confirm: { _ in true }) && workspace.sessions.contains(where: { $0 === created }), "busyClose", "A busy document cannot be closed through its tab")
        created.busy = false; created.error = nil
        let url = directory.appendingPathComponent("same-file.devin")
        secondSession.fileURL = url
        let duplicate = StudioSession(tool: .pixel, document: second); duplicate.fileURL = url
        check(workspace.add(duplicate) === secondSession && workspace.sessions.count == count, "duplicateOpen", "Opening the same file selects its existing tab")
        let host = NSHostingView(rootView: PixelToolRail(session: firstSession))
        host.frame = CGRect(x: 0, y: 0, width: 43, height: 850)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host; window.setFrameOrigin(CGPoint(x: -5000, y: -5000)); window.orderFront(nil)
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(nanoseconds: 100_000_000)
        func descendants(_ view: NSView) -> [NSView] { [view] + view.subviews.flatMap(descendants) }
        let native = descendants(host).first { $0.identifier?.rawValue == "tool-group.Marquee" } as? GroupedToolControl
        check(native != nil, "nativeGroupControl", "Grouped tools expose a native control with a clickable flyout")
        if let native {
            var menus: [NSMenu] = []
            native.menuPresenter = { menus.append($0) }
            func event(_ type: NSEvent.EventType, _ point: CGPoint) -> NSEvent { NSEvent.mouseEvent(with: type, location: native.convert(point, to: nil), modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)! }
            native.mouseDown(with: event(.leftMouseDown, CGPoint(x: native.bounds.maxX - 3, y: native.bounds.maxY - 3)))
            check(menus.last?.items.count == 4, "arrowFlyout", "Clicking the toolbar triangle opens all Marquee variants")
            if let item = menus.last?.items.first(where: { ($0.representedObject as? String) == DrawingTool.ellipseSelect.rawValue }) {
                _ = NSApp.sendAction(item.action!, to: item.target, from: item)
            }
            check(firstSession.drawingTool == .ellipseSelect, "menuDispatch", "Choosing a grouped menu item activates that exact tool")
            native.mouseUp(with: event(.leftMouseUp, CGPoint(x: 25, y: 24)))
            check(firstSession.drawingTool == .ellipseSelect, "menuRelease", "Releasing a flyout click does not revert the selected tool")
            let beforeHold = menus.count
            native.mouseDown(with: event(.leftMouseDown, CGPoint(x: 8, y: 8)))
            try await Task.sleep(nanoseconds: 400_000_000)
            check(menus.count == beforeHold + 1, "heldFlyout", "Holding a toolbar button opens its grouped tools")
            native.mouseUp(with: event(.leftMouseUp, CGPoint(x: 8, y: 8)))
            let beforeRight = menus.count
            native.rightMouseDown(with: event(.rightMouseDown, CGPoint(x: 8, y: 8)))
            check(menus.count == beforeRight + 1, "rightFlyout", "Right-click opens the same grouped-tool menu")
            firstSession.drawingTool = .crop
            check(GroupedToolControl(session: firstSession, group: native.group).current == .ellipseSelect, "rememberVariant", "Toolbar groups remember the selected variant across view recreation")
            native.menuPresenter = nil
        }
        window.orderOut(nil); window.contentView = nil
        for session in Array(workspace.sessions) { _ = workspace.close(session.id, confirm: { _ in true }) }
        check(workspace.activeSession == nil && coordinator.windows.contains(where: { $0 === firstController }), "lastTab", "Closing the last tab leaves the application workspace open")
        let next = coordinator.createDocument(from: workspace.creationSession, title: "After last close", width: 100, height: 100, background: "FFFFFF")
        check(next?.workspace === workspace && coordinator.windows.count == existing.count + 1, "reopenEmpty", "A new document opens in the existing empty workspace")
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(observations).write(to: directory.appendingPathComponent("workspace-behavior.json"), options: .atomic)
        if !failures.isEmpty { throw DocumentError.invalid("Workspace behavior failures: " + failures.joined(separator: "; ")) }
        return checks
    }
}
