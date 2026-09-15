import AppKit
import CoreImage
import DevinCore

extension CanvasNSView {
    func drawCanvasDocument(_ document: CreativeDocument, in context: CGContext) {
        if document.transparentBackground == true, let tile = TransparencyGrid.image {
            context.saveGState(); context.clip(to: CGRect(x: 0, y: 0, width: document.width, height: document.height))
            context.draw(tile, in: CGRect(x: 0, y: 0, width: 16 / scale, height: 16 / scale), byTiling: true); context.restoreGState()
        }
        guard session.tool == .pixel, let channel = session.channelPreview, let image = Renderer.image(document, page: activePage, maxDimension: 4096) else {
            Renderer.draw(document, in: context, page: activePage, time: session.tool == .motion ? session.playhead : nil)
            return
        }
        let vector = CIVector(x: channel == "Red" ? 1 : 0, y: channel == "Green" ? 1 : 0, z: channel == "Blue" ? 1 : 0, w: 0)
        let input = CIImage(cgImage: image)
        let output = input.applyingFilter("CIColorMatrix", parameters: ["inputRVector": vector, "inputGVector": vector, "inputBVector": vector])
        if let result = Renderer.imageContext.createCGImage(output, from: input.extent) {
            context.saveGState(); context.translateBy(x: 0, y: document.height); context.scaleBy(x: 1, y: -1)
            context.draw(result, in: CGRect(x: 0, y: 0, width: document.width, height: document.height)); context.restoreGState()
        }
    }
    func professionalMouseDown(_ event: NSEvent, point p: CGPoint) -> Bool {
        freeformGesture = nil; anchorGesture = nil
        if session.drawingTool != .pen && activePenID != nil {
            let requestedTool = session.drawingTool
            finishPen()
            session.drawingTool = requestedTool
        }
        if pixelMouseDown(event, point: p) { return true }
        switch session.drawingTool {
        case .hand:
            handScrollOrigin = enclosingScrollView?.contentView.bounds.origin ?? .zero
            return true
        case .zoom:
            session.zoom = min(20, max(0.05, session.zoom * (event.modifierFlags.contains(.option) ? 0.8 : 1.25)))
            return true
        case .eyedropper:
            if let image = Renderer.image(session.document, page: activePage, maxDimension: 2048), let data = image.dataProvider?.data, let bytes = CFDataGetBytePtr(data) {
                let x = min(image.width - 1, max(0, Int(p.x / session.document.width * Double(image.width))))
                let y = min(image.height - 1, max(0, Int(p.y / session.document.height * Double(image.height))))
                let index = y * image.bytesPerRow + x * 4
                session.drawingColor = String(format: "%02X%02X%02X", bytes[index], bytes[index + 1], bytes[index + 2])
            }
            return true
        case .marquee, .ellipseSelect, .lasso:
            selectionBefore = session.effectiveSelectionPath
            selectionGestureMode = selectionMode(event)
            selectingMarquee = true; lassoPoints = [p]
            if selectionGestureMode == .replace { session.selectionRect = CGRect(origin: p, size: .zero) }
            return true
        case .freeformPen:
            return freeformMouseDown(point: p)
        case .pen:
            session.beginTransaction(); penGesture = true
            if let id = activePenID, let i = session.document.elements.firstIndex(where: { $0.id == id }), let first = session.document.elements[i].vectorPath?.first {
                if event.clickCount > 1 { finishPen(); return true }
                if (session.document.elements[i].vectorPath?.count ?? 0) > 2 && hypot(p.x - first.point.x, p.y - first.point.y) < 10 / scale {
                    session.document.elements[i].vectorPath?.append(VectorCommand(.close, first.point)); finishPen(); return true
                }
                let previous = session.document.elements[i].vectorPath?.last?.point ?? Point2D(p.x, p.y)
                session.document.elements[i].vectorPath?.append(VectorCommand(.curve, Point2D(p.x, p.y), control1: penOutgoing ?? previous, control2: Point2D(p.x, p.y)))
                penOutgoing = Point2D(p.x, p.y)
            } else {
                var layer = CanvasElement(kind: .path, name: "Path \(session.document.elements.count + 1)", x: 0, y: 0, width: session.document.width, height: session.document.height, fill: session.drawingColor, page: activePage)
                layer.vectorPath = [VectorCommand(.move, Point2D(p.x, p.y))]; layer.stroke = session.drawingColor; layer.strokeWidth = 2
                session.document.elements.append(layer); activePenID = layer.id; session.select(layer.id); penOutgoing = Point2D(p.x, p.y)
            }
            return true
        case .directSelect:
            if session.tool == .pixel && session.editingMask { return true }
            guard let layer = session.selected, !layer.locked, layer.visible, layer.page == activePage, let commands = layer.vectorPath else { return false }
            let local = localPoint(p, element: pose(layer))
            for (index, command) in commands.enumerated() where command.verb != .close {
                for (control, point) in [(0, Optional(command.point)), (1, command.control1), (2, command.control2)] {
                    if let point, hypot(local.x - point.x, local.y - point.y) < 8 / scale {
                        if session.tool == .pixel {
                            anchorGesture = AnchorEditGesture(sessionID: session.id, tool: .directSelect, original: layer, source: commands, anchor: nil, commands: commands, node: (index, control))
                        } else { draggedNode = (index, control); originalElement = layer; session.beginTransaction() }
                        return true
                    }
                }
            }
            return false
        case .addAnchor, .deleteAnchor, .convertAnchor:
            return anchorMouseDown(event, point: p)
        case .brush, .eraser:
            guard session.tool == .pixel else { return false }
            if session.selected?.locked == true { session.message = "Unlock the selected layer before painting."; return true }
            if session.editingMask && session.selected?.maskData == nil { session.editingMask = false }
            if session.drawingTool == .eraser && session.selected?.kind != .image { session.message = "Select a pixel layer, or rasterize the selected layer first."; return true }
            session.beginTransaction(); paintPoints = [p]
            return true
        default: return false
        }
    }
    func professionalMouseDragged(_ event: NSEvent, point p: CGPoint) -> Bool {
        if freeformMouseDragged(point: p) { return true }
        if anchorMouseDragged(event, point: p) { return true }
        if pixelMouseDragged(event, point: p) { return true }
        if let origin = handScrollOrigin, let scroll = enclosingScrollView {
            let point = CGPoint(x: origin.x - (p.x - dragOrigin.x) * scale, y: origin.y - (p.y - dragOrigin.y) * scale)
            scroll.contentView.scroll(to: point); scroll.reflectScrolledClipView(scroll.contentView)
            return true
        }
        if selectingMarquee {
            let rect = CGRect(x: min(p.x, dragOrigin.x), y: min(p.y, dragOrigin.y), width: abs(p.x - dragOrigin.x), height: abs(p.y - dragOrigin.y))
            let path: CGPath
            if session.drawingTool == .lasso {
                lassoPoints.append(p)
                let lasso = CGMutablePath(); lasso.move(to: lassoPoints[0]); lasso.addLines(between: lassoPoints); lasso.closeSubpath(); path = lasso
            } else { path = session.drawingTool == .ellipseSelect ? CGPath(ellipseIn: rect, transform: nil) : CGPath(rect: rect, transform: nil) }
            session.setSelection(path, mode: selectionGestureMode, previous: selectionBefore)
            return true
        }
        if !paintPoints.isEmpty { paintPoints.append(p); return true }
        if penGesture, let id = activePenID, let i = session.document.elements.firstIndex(where: { $0.id == id }), let last = session.document.elements[i].vectorPath?.indices.last {
            let dx = p.x - dragOrigin.x, dy = p.y - dragOrigin.y
            if session.document.elements[i].vectorPath?[last].verb == .curve { session.document.elements[i].vectorPath?[last].control2 = Point2D(dragOrigin.x - dx, dragOrigin.y - dy) }
            penOutgoing = Point2D(p.x, p.y)
            return true
        }
        if let node = draggedNode, let original = originalElement, let i = session.document.elements.firstIndex(where: { $0.id == original.id }) {
            let local = localPoint(p, element: original)
            let point = Point2D(local.x, local.y)
            switch node.control {
            case 1: session.document.elements[i].vectorPath?[node.index].control1 = point
            case 2: session.document.elements[i].vectorPath?[node.index].control2 = point
            default: session.document.elements[i].vectorPath?[node.index].point = point
            }
            return true
        }
        return false
    }
    func professionalMouseUp(_ event: NSEvent) -> Bool {
        if freeformMouseUp(event) { return true }
        if pixelMouseUp(event) { return true }
        if handScrollOrigin != nil { handScrollOrigin = nil; return true }
        if selectingMarquee { _ = professionalMouseDragged(event, point: point(event)); selectingMarquee = false; return true }
        if anchorMouseUp(event) { return true }
        if penGesture { penGesture = false; session.endTransaction(); return true }
        if draggedNode != nil { draggedNode = nil; originalElement = nil; session.endTransaction(); return true }
        if !paintPoints.isEmpty {
            do {
                let original = session.selected?.kind == .image ? session.selected : nil
                var layer = try RasterEditing.paint(original, document: session.document, points: paintPoints, size: session.brushSize, color: session.drawingColor, opacity: session.brushOpacity, erase: session.drawingTool == .eraser, selection: session.selectionRect, selectionPath: session.effectiveSelectionPath, hardness: session.brushHardness, target: session.editingMask ? .mask : .pixels)
                layer.page = activePage
                if let i = session.document.elements.firstIndex(where: { $0.id == layer.id }) { session.document.elements[i] = layer }
                else { session.document.elements.append(layer) }
                session.select(layer.id)
            } catch { session.error = error.localizedDescription }
            paintPoints = []; session.endTransaction(); return true
        }
        return false
    }
    func finishPen() {
        guard let id = activePenID, let i = session.document.elements.firstIndex(where: { $0.id == id }) else { activePenID = nil; return }
        let old = session.document.elements[i]
        if old.locked {
            activePenID = nil; penOutgoing = nil; penGesture = false
            session.endTransaction(); session.drawingTool = .select
            return
        }
        if (old.vectorPath?.count ?? 0) > 1 {
            var normalized = VectorGeometry.element(from: VectorGeometry.worldPath(old), name: old.name, fill: old.fill, page: old.page)
            normalized.id = old.id; normalized.stroke = old.stroke; normalized.strokeWidth = old.strokeWidth
            session.document.elements[i] = normalized
        } else { session.document.elements.remove(at: i); session.select(nil) }
        activePenID = nil; penOutgoing = nil
        session.endTransaction(); session.drawingTool = .select
    }
    func professionalKeyDown(_ event: NSEvent) -> Bool {
        if event.keyCode == 53 && freeformGesture != nil {
            freeformGesture = nil; needsDisplay = true; return true
        }
        if event.keyCode == 53 && anchorGesture != nil {
            anchorGesture = nil; needsDisplay = true; return true
        }
        if pixelKeyDown(event) { return true }
        if !event.modifierFlags.contains(.command) {
            let key = event.charactersIgnoringModifiers?.lowercased()
            if session.tool == .pixel, key == "m", event.modifierFlags.contains(.shift) { session.drawingTool = session.drawingTool == .marquee ? .ellipseSelect : .marquee; return true }
            if [.form, .press].contains(session.tool), key == "m" { session.drawingTool = .rectangle; return true }
            if session.tool == .form, key == "l" { session.drawingTool = .ellipse; return true }
            if session.tool == .form, key == "\\" { session.drawingTool = .line; return true }
            if session.tool == .press, key == "w" { session.showGuides.toggle(); session.showTransformControls = session.showGuides; return true }
        }
        if event.keyCode == 36 && activePenID != nil { session.beginTransaction(); finishPen(); needsDisplay = true; return true }
        if event.keyCode == 53 {
            if selectingMarquee { session.selectionRect = selectionBefore?.boundingBoxOfPath; session.selectionPath = selectionBefore }
            paintPoints = []; selectingMarquee = false; draggedNode = nil; handScrollOrigin = nil
            if activePenID != nil { session.beginTransaction(); finishPen(); needsDisplay = true; return true }
        }
        if event.keyCode == 49 && [.motion, .frame].contains(session.tool) { session.togglePlayback(); return true }
        if event.keyCode == 48 && session.usesProfessionalWorkspace { session.panelsHidden.toggle(); return true }
        if event.charactersIgnoringModifiers?.lowercased() == "x" && !event.modifierFlags.contains(.command) {
            let foreground = session.drawingColor; session.drawingColor = session.backgroundColor; session.backgroundColor = foreground; return true
        }
        if event.charactersIgnoringModifiers?.lowercased() == "d" && !event.modifierFlags.contains(.command) { session.drawingColor = "000000"; session.backgroundColor = "FFFFFF"; return true }
        if event.characters == "[" { session.brushSize = max(1, session.brushSize - 5); return true }
        if event.characters == "]" { session.brushSize = min(500, session.brushSize + 5); return true }
        return false
    }
    func drawProfessionalOverlays(_ context: CGContext) {
        drawFreeformOverlay(context)
        drawPixelOverlays(context)
        context.saveGState()
        if let path = session.effectiveSelectionPath, session.page == activePage {
            context.setLineWidth(1 / scale); context.setStrokeColor(NSColor.white.cgColor); context.addPath(path); context.strokePath()
            context.setStrokeColor(NSColor.black.cgColor); context.setLineDash(phase: 0, lengths: [4 / scale, 4 / scale]); context.addPath(path); context.strokePath(); context.setLineDash(phase: 0, lengths: [])
        }
        if !paintPoints.isEmpty {
            context.setLineWidth(session.brushSize); context.setLineCap(.round); context.setLineJoin(.round)
            context.setStrokeColor((session.drawingTool == .eraser ? NSColor.gray : NSColor(hex: session.drawingColor)).withAlphaComponent(session.brushOpacity * 0.65).cgColor)
            context.move(to: paintPoints[0]); for point in paintPoints.dropFirst() { context.addLine(to: point) }; context.strokePath()
        }
        for layer in session.currentElements where session.additionalSelection.contains(layer.id) {
            context.setStrokeColor(NSColor(hex: "5BA9F5").cgColor); context.setLineWidth(1 / scale)
            context.stroke(CGRect(x: layer.x, y: layer.y, width: layer.width, height: layer.height))
        }
        if session.drawingTool == .directSelect || session.drawingTool.isAnchorEditor || activePenID != nil, let layer = anchorPreviewLayer, layer.kind == .path, layer.visible, layer.page == activePage {
            let commands = layer.vectorPath ?? layer.points.enumerated().map { VectorCommand($0.offset == 0 ? .move : .line, $0.element) }
            context.translateBy(x: layer.x + layer.width / 2, y: layer.y + layer.height / 2); context.rotate(by: layer.rotation * .pi / 180); context.translateBy(x: -layer.width / 2, y: -layer.height / 2)
            context.setStrokeColor(NSColor(hex: "4AA4FF").cgColor); context.setFillColor(NSColor.white.cgColor); context.setLineWidth(1 / scale)
            context.addPath(VectorGeometry.path(layer)); context.strokePath()
            var previous = commands.first?.point ?? Point2D(0, 0)
            for command in commands where command.verb != .close {
                let point = CGPoint(x: command.point.x, y: command.point.y)
                for (control, anchor) in [(command.control1, previous), (command.control2, command.point)] {
                    if let control {
                        context.move(to: CGPoint(x: anchor.x, y: anchor.y)); context.addLine(to: CGPoint(x: control.x, y: control.y)); context.strokePath()
                        context.strokeEllipse(in: CGRect(x: control.x - 3 / scale, y: control.y - 3 / scale, width: 6 / scale, height: 6 / scale))
                    }
                }
                let box = CGRect(x: point.x - 3 / scale, y: point.y - 3 / scale, width: 6 / scale, height: 6 / scale)
                context.fill(box); context.stroke(box); previous = command.point
            }
        }
        context.restoreGState()
        if session.tool == .press && session.showGuides {
            context.saveGState(); context.setStrokeColor(NSColor(hex: "40A7D2").cgColor); context.setLineWidth(0.7 / scale)
            let overflow = TextFlow.overflows(session.document)
            for element in session.document.elements where element.page == activePage && element.kind == .text {
                context.stroke(CGRect(x: element.x, y: element.y, width: element.width, height: element.height))
                if overflow.contains(element.id) {
                    context.saveGState(); context.setStrokeColor(NSColor.red.cgColor)
                    let rect = CGRect(x: element.x + element.width - 8 / scale, y: element.y + element.height - 8 / scale, width: 8 / scale, height: 8 / scale)
                    context.stroke(rect); context.move(to: CGPoint(x: rect.midX, y: rect.minY + 2 / scale)); context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 2 / scale)); context.move(to: CGPoint(x: rect.minX + 2 / scale, y: rect.midY)); context.addLine(to: CGPoint(x: rect.maxX - 2 / scale, y: rect.midY)); context.strokePath(); context.restoreGState()
                }
            }
            context.restoreGState()
        }
    }
}
