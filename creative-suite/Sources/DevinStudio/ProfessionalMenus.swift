import AppKit
import DevinCore

extension AppCoordinator {
    func installProfessionalMenus(_ session: StudioSession) {
        let main = NSMenu()
        func section(_ title: String) -> NSMenu {
            let entry = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            let menu = NSMenu(title: title); entry.submenu = menu; main.addItem(entry); return menu
        }
        func action(_ menu: NSMenu, _ title: String, _ selector: Selector, _ key: String = "", modifiers: NSEvent.ModifierFlags = .command, target: AnyObject? = AppCoordinator.shared) {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: key); item.target = target; item.keyEquivalentModifierMask = modifiers; menu.addItem(item)
        }
        func command(_ menu: NSMenu, _ title: String, _ identifier: String, _ key: String = "", modifiers: NSEvent.ModifierFlags = .command) {
            let item = NSMenuItem(title: title, action: #selector(professionalCommand(_:)), keyEquivalent: key)
            item.target = self; item.representedObject = identifier; item.keyEquivalentModifierMask = modifiers; menu.addItem(item)
        }
        let app = section(session.tool.name)
        action(app, "About " + session.tool.name, #selector(about)); app.addItem(.separator())
        action(app, "Hide " + session.tool.name, #selector(NSApplication.hide(_:)), "h", target: NSApp)
        action(app, "Quit " + session.tool.name, #selector(NSApplication.terminate(_:)), "q", target: NSApp)
        let file = section("File")
        action(file, "New…", #selector(newDocument), "n")
        action(file, "Open…", #selector(openDocument), "o")
        action(file, session.tool == .press ? "Place…" : "Import…", #selector(importAssets), "i")
        file.addItem(.separator())
        action(file, "Save", #selector(saveDocument), "s")
        action(file, "Save As…", #selector(saveAs), "s", modifiers: [.command, .shift])
        action(file, "Export…", #selector(exportDocument), "e", modifiers: [.command, .shift])
        action(file, "Close Document", #selector(closeDocument), "w")
        let edit = section("Edit")
        action(edit, "Undo", #selector(undoDocument), "z")
        action(edit, "Redo", #selector(redoDocument), "z", modifiers: [.command, .shift])
        edit.addItem(.separator())
        action(edit, "Cut", #selector(NSText.cut(_:)), "x", target: nil)
        action(edit, "Copy", #selector(NSText.copy(_:)), "c", target: nil)
        action(edit, "Paste", #selector(NSText.paste(_:)), "v", target: nil)
        command(edit, "Duplicate", "duplicate", session.tool == .pixel ? "j" : "d")
        action(edit, "Clear", #selector(clearDocumentSelection), "\u{8}")
        if session.tool == .pixel {
            let image = section("Image")
            command(image, "Image Size…", "imageSize")
            command(image, "Canvas Size…", "canvasSize")
            command(image, "Crop Tool", "crop")
        }
        if session.tool == .press {
            let layout = section("Layout")
            command(layout, "Document Setup…", "canvasSize")
            command(layout, "Add Page", "addPage")
            command(layout, "Duplicate Page", "duplicatePage")
            command(layout, "Delete Page", "deletePage")
            layout.addItem(.separator())
            command(layout, "Next Page", "nextPage")
            command(layout, "Previous Page", "previousPage")
        }
        if session.tool == .motion {
            let composition = section("Composition")
            command(composition, "Composition Settings…", "canvasSize")
            command(composition, "Preview", "play")
            action(composition, "Add to Render Queue…", #selector(exportDocument), "m", modifiers: [.command, .control])
        }
        if session.tool == .cut {
            let clip = section("Clip")
            command(clip, "Duplicate Clip", "duplicate")
            command(clip, "Mute Audio", "muteClip")
            let sequence = section("Sequence")
            command(sequence, "Add Edit", "splitClip", "k")
            command(sequence, "Go to Start", "sequenceStart")
            command(sequence, "Play / Stop", "play")
        } else {
            let layers = section([.form, .press].contains(session.tool) ? "Object" : "Layer")
            command(layers, session.tool == .pixel ? "New Pixel Layer" : "New Rectangle", session.tool == .pixel ? "newPixelLayer" : "newRectangle", "n", modifiers: [.command, .shift])
            command(layers, "New Text Layer", "newText")
            command(layers, "Duplicate Layer", "duplicate")
            command(layers, "Lock / Unlock", "lock")
            command(layers, "Bring Forward", "forward", "]")
            command(layers, "Send Backward", "backward", "[")
            if session.tool == .pixel {
                layers.addItem(.separator())
                command(layers, "Rasterize Layer", "rasterize")
                command(layers, "Add Layer Mask", "mask")
                command(layers, "Delete Layer Mask", "removeMask")
                command(layers, "Flatten Image", "flatten")
            }
            if session.tool == .form {
                layers.addItem(.separator())
                for operation in ["Unite", "Subtract", "Intersect", "Exclude"] { command(layers, operation, "path:" + operation) }
                command(layers, "Add Artboard", "addPage")
            }
        }
        if session.tool != .cut {
            let type = section(session.tool == .motion ? "Animation" : "Type")
            if session.tool == .motion {
                command(type, "Add Keyframe", "keyframe")
                command(type, "Easy Ease", "ease")
                command(type, "Hold Keyframes", "hold")
                command(type, "Linear Keyframes", "linear")
            } else {
                command(type, "Create Text", "newText")
                command(type, "Increase Size", "largerText")
                command(type, "Decrease Size", "smallerText")
                if session.tool == .press { command(type, "Unlink Text Frame", "unlinkText") }
            }
        }
        if [.pixel, .form].contains(session.tool) {
            let select = section("Select")
            command(select, "All", "selectAll", "a")
            command(select, "Deselect", "deselect", "d", modifiers: session.tool == .pixel ? .command : [.command, .shift])
            if session.tool == .pixel { command(select, "Inverse", "invertSelection", "i", modifiers: [.command, .shift]) }
        }
        if [.pixel, .form, .motion].contains(session.tool) {
            let effects = section(session.tool == .pixel ? "Filter" : "Effect")
            command(effects, "Gaussian Blur…", "blur")
            command(effects, "Black & White", "monochrome")
            command(effects, "Reset Image Adjustments", "resetImage")
        }
        let view = section("View")
        action(view, "Zoom In", #selector(zoomIn), "+"); action(view, "Zoom Out", #selector(zoomOut), "-"); action(view, "Fit on Screen", #selector(zoomFit), "0")
        if session.tool != .cut { command(view, "Rulers", "rulers", "r"); command(view, "Grid", "grid", "'") }
        if session.tool == .press { command(view, "Guides", "guides", ";") }
        let window = section("Window")
        action(window, "Next Document", #selector(nextDocument), "]", modifiers: [.command, .shift])
        action(window, "Previous Document", #selector(previousDocument), "[", modifiers: [.command, .shift])
        command(window, "Reset Workspace", "resetWorkspace")
        command(window, "Show / Hide Panels", "panels")
        action(window, "Minimize", #selector(NSWindow.performMiniaturize(_:)), "m", target: nil)
        NSApp.windowsMenu = window
        let help = section("Help")
        action(help, "Feature Parity Ledger…", #selector(showFeatures))
        action(help, "About This Build", #selector(about))
        action(help, "Devin Studio", #selector(home))
        NSApp.mainMenu = main
    }
    func validateProfessionalCommand(_ identifier: String) -> Bool {
        guard let session = current, !session.busy else { return false }
        if identifier.hasPrefix("path:") { return session.selectedIDs.count > 1 }
        if ["mask", "removeMask", "blur", "monochrome", "resetImage"].contains(identifier) { return session.selected?.kind == .image && session.selected?.locked == false }
        if ["lock", "forward", "backward", "rasterize", "keyframe", "ease", "hold", "linear"].contains(identifier) { return session.selected != nil }
        if ["largerText", "smallerText", "unlinkText"].contains(identifier) { return session.selected?.kind == .text }
        if ["splitClip", "muteClip"].contains(identifier) { return session.document.clips.contains { $0.id == session.selectedID } }
        if identifier == "deletePage" { return session.document.pageCount > 1 }
        return true
    }
    @objc func professionalCommand(_ sender: NSMenuItem) {
        guard let session = current, let command = sender.representedObject as? String else { return }
        if command.hasPrefix("path:") { session.combineShapes(String(command.dropFirst(5))); return }
        switch command {
        case "newPixelLayer": session.addElement(.image)
        case "newRectangle": session.addElement(.rectangle)
        case "newText": session.addElement(.text)
        case "duplicate":
            if session.tool == .cut, var clip = session.document.clips.first(where: { $0.id == session.selectedID }) { clip.id = UUID(); clip.timelineStart = session.document.sequenceDuration; session.mutate { $0.clips.append(clip) }; session.select(clip.id) }
            else { session.duplicate() }
        case "lock": session.updateElement { $0.locked.toggle() }
        case "forward": if let id = session.selectedID { session.reorder(id, offset: 1) }
        case "backward": if let id = session.selectedID { session.reorder(id, offset: -1) }
        case "rasterize": session.rasterizeSelection()
        case "mask": session.addMask()
        case "removeMask": session.updateElement { $0.maskData = nil }
        case "flatten": session.flattenPage()
        case "addPage": session.addPage()
        case "duplicatePage": session.addPage(duplicate: true)
        case "deletePage": session.deletePage()
        case "nextPage": session.page = min(session.document.pageCount - 1, session.page + 1)
        case "previousPage": session.page = max(0, session.page - 1)
        case "crop": session.drawingTool = .crop
        case "keyframe": session.addKeyframe()
        case "ease": session.setInterpolation(.easeInOut)
        case "hold": session.setInterpolation(.hold)
        case "linear": session.setInterpolation(.linear)
        case "largerText": session.updateElement { $0.fontSize = min(1000, $0.fontSize + 2) }
        case "smallerText": session.updateElement { $0.fontSize = max(1, $0.fontSize - 2) }
        case "unlinkText": session.linkText(to: nil)
        case "selectAll":
            if session.tool == .pixel { session.selectionRect = CGRect(x: 0, y: 0, width: session.document.width, height: session.document.height) }
            else { session.additionalSelection = Set(session.currentElements.filter { !$0.locked }.map(\.id)); session.selectedID = session.currentElements.last?.id }
        case "deselect": if session.tool != .pixel { session.select(nil) }; session.selectionRect = nil
        case "invertSelection": session.invertSelection()
        case "monochrome": session.updateElement { $0.adjustments.saturation = 0 }
        case "resetImage": session.updateElement { $0.adjustments = ImageAdjustments() }
        case "blur":
            let alert = NSAlert(); alert.messageText = "Gaussian Blur"; alert.informativeText = "Radius in pixels (0–40)"
            let field = NSTextField(string: String(session.selected?.adjustments.blur ?? 0)); field.frame = NSRect(x: 0, y: 0, width: 180, height: 24)
            alert.accessoryView = field; alert.addButton(withTitle: "OK"); alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn { let radius = min(40, max(0, field.doubleValue)); session.updateElement { $0.adjustments.blur = radius } }
        case "rulers": session.showRulers.toggle()
        case "grid": session.showGrid.toggle()
        case "guides": session.showGuides.toggle()
        case "panels": session.panelsHidden.toggle()
        case "resetWorkspace": session.panelsHidden = false; session.zoom = 1
        case "splitClip": session.splitSelectedClip()
        case "muteClip": if let i = session.document.clips.firstIndex(where: { $0.id == session.selectedID }) { session.mutate { $0.clips[i].muted = !($0.clips[i].muted ?? false) } }
        case "sequenceStart": session.playhead = 0; session.player.seek(to: .zero)
        case "play": session.togglePlayback()
        case "imageSize", "canvasSize": showDocumentSize(session, scaleContent: command == "imageSize")
        default: break
        }
    }
    func showDocumentSize(_ session: StudioSession, scaleContent: Bool) {
        let alert = NSAlert(); alert.messageText = scaleContent ? "Image Size" : session.tool == .motion ? "Composition Settings" : "Canvas Size"
        let stack = NSStackView(); stack.orientation = .vertical; stack.spacing = 8
        let width = NSTextField(string: String(Int(session.document.width))), height = NSTextField(string: String(Int(session.document.height)))
        for (title, field) in [("Width", width), ("Height", height)] {
            let row = NSStackView(views: [NSTextField(labelWithString: title), field]); row.spacing = 12; stack.addArrangedSubview(row)
        }
        stack.frame = NSRect(x: 0, y: 0, width: 250, height: 70); alert.accessoryView = stack
        alert.addButton(withTitle: "OK"); alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let w = width.doubleValue, h = height.doubleValue
        guard w.isFinite, h.isFinite, (16...16384).contains(w), (16...16384).contains(h) else { session.error = "Dimensions must be between 16 and 16,384 pixels."; return }
        let sx = w / session.document.width, sy = h / session.document.height
        session.mutate { d in
            d.width = w; d.height = h
            if scaleContent {
                for i in d.elements.indices {
                    d.elements[i].x *= sx; d.elements[i].y *= sy; d.elements[i].width *= sx; d.elements[i].height *= sy; d.elements[i].fontSize *= sy
                    d.elements[i].points = d.elements[i].points.map { Point2D($0.x * sx, $0.y * sy) }
                    d.elements[i].vectorPath = d.elements[i].vectorPath?.map { $0.scaled(x: sx, y: sy) }
                    for k in d.elements[i].keyframes.indices { d.elements[i].keyframes[k].x *= sx; d.elements[i].keyframes[k].y *= sy }
                }
            }
        }
    }
}
