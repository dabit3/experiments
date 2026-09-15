import SwiftUI
import AppKit
import UniformTypeIdentifiers
import DevinCore

struct ProColorPanel: View {
    @ObservedObject var session: StudioSession
    @State private var tab = "Color"
    @State private var hue = 0.0
    @State private var saturation = 0.0
    @State private var brightness = 0.0
    private let swatches = ["000000", "FFFFFF", "808080", "C0C0C0", "FF0000", "FF8000", "FFFF00", "80FF00", "00FF00", "00FF80", "00FFFF", "0080FF", "0000FF", "8000FF", "FF00FF", "FF0080", "663333", "996633", "CCCC99", "669966", "336666", "333366", "663399", "993366", "E6B7A7", "D8D4B5", "ADBA9D", "A3BACA", "C1B4C9", "292D32", "406AB8", "E6AA39"]
    var body: some View {
        VStack(spacing: 0) {
            ProTabs(tabs: ["Color", "Swatches"], selected: $tab)
            if tab == "Color" {
                HStack(alignment: .top, spacing: 10) {
                    ForegroundColors(session: session).frame(width: 37)
                    GeometryReader { geo in
                        ZStack(alignment: .topLeading) {
                            Rectangle().fill(Color(hue: hue, saturation: 1, brightness: 1))
                            LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .leading, endPoint: .trailing)
                            LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                            Circle().stroke(.white, lineWidth: 1.2).frame(width: 8, height: 8).shadow(color: .black, radius: 1).offset(x: saturation * (geo.size.width - 8), y: (1 - brightness) * (geo.size.height - 8))
                        }.gesture(DragGesture(minimumDistance: 0).onChanged { value in
                            saturation = min(1, max(0, value.location.x / geo.size.width)); brightness = min(1, max(0, 1 - value.location.y / geo.size.height)); apply()
                        })
                    }
                    GeometryReader { geo in
                        LinearGradient(colors: stride(from: 0.0, through: 1.0, by: 0.1).map { Color(hue: $0, saturation: 1, brightness: 1) }, startPoint: .top, endPoint: .bottom)
                            .overlay(alignment: .top) { Rectangle().stroke(.white, lineWidth: 1).frame(height: 4).offset(y: hue * max(0, geo.size.height - 4)) }
                            .gesture(DragGesture(minimumDistance: 0).onChanged { value in hue = min(1, max(0, value.location.y / geo.size.height)); apply() })
                    }.frame(width: 14)
                }.padding(11).frame(minHeight: 140)
                HStack { Text("#").foregroundStyle(ProTheme.secondary); TextField("Hex", text: $session.drawingColor).textFieldStyle(.plain).font(.system(size: 11, design: .monospaced)).padding(4).background(ProTheme.field).frame(width: 75); Spacer(); ProColorControl("Color", selection: Binding(get: { Color(hex: session.drawingColor) }, set: { session.drawingColor = $0.hex }), supportsOpacity: false).labelsHidden().frame(width: 28) }.padding(.horizontal, 12).padding(.bottom, 9)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 8), spacing: 2) {
                    ForEach(swatches, id: \.self) { color in
                        Button { session.drawingColor = color; if session.tool != .pixel { session.updateElement { $0.fill = color } } } label: { Rectangle().fill(Color(hex: color)).frame(height: 23).overlay(Rectangle().stroke(.black.opacity(0.25), lineWidth: 0.5)) }.buttonStyle(.plain).help("#" + color)
                    }
                }.padding(12)
                Spacer(minLength: 0)
            }
        }.background(ProTheme.panel).onAppear { synchronize() }.onChange(of: session.drawingColor) { _, _ in synchronize() }
    }
    func synchronize() {
        let color = NSColor(hex: session.drawingColor).usingColorSpace(.deviceRGB)!
        hue = color.hueComponent; saturation = color.saturationComponent; brightness = color.brightnessComponent
    }
    func apply() { session.drawingColor = NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1).hex }
}

struct ProLayerPanel: View {
    @ObservedObject var session: StudioSession
    var pixelStyle = false
    @State private var tab = "Layers"
    @State private var filter = ""
    var body: some View {
        VStack(spacing: 0) {
            ProTabs(tabs: pixelStyle ? ["Layers", "Channels", "Paths"] : ["Layers"], selected: $tab)
            if tab == "Channels" {
                VStack(spacing: 1) {
                    ForEach(["RGB", "Red", "Green", "Blue"], id: \.self) { channel in
                        HStack(spacing: 10) {
                            Image(systemName: "eye").font(.system(size: 11))
                            Rectangle().fill(channel == "Red" ? .red.opacity(0.5) : channel == "Green" ? .green.opacity(0.5) : channel == "Blue" ? .blue.opacity(0.5) : .gray).frame(width: 34, height: 26)
                            Text(channel).font(.system(size: 11)); Spacer()
                        }.padding(8).background((session.channelPreview ?? "RGB") == channel ? Color(hex: "4B4B4B") : ProTheme.panel).contentShape(Rectangle()).onTapGesture { session.channelPreview = channel == "RGB" ? nil : channel }
                    }
                    Spacer()
                }
            } else {
                if pixelStyle && tab == "Layers" {
                    HStack(spacing: 7) { Image(systemName: "magnifyingglass").font(.system(size: 10)); TextField("Kind / name", text: $filter).textFieldStyle(.plain).font(.system(size: 10)); Spacer(); Image(systemName: "photo"); Image(systemName: "textformat"); Image(systemName: "rectangle") }.font(.system(size: 10)).foregroundStyle(ProTheme.secondary).padding(8)
                    HStack(spacing: 8) {
                        Picker("Blend", selection: Binding(get: { session.selected?.blendMode ?? .normal }, set: { value in session.updateElement { $0.blendMode = value } })) { ForEach(LayerBlendMode.allCases, id: \.self) { Text($0.title).tag($0) } }.labelsHidden().controlSize(.small)
                        ProField(label: "Opacity", value: Binding(get: { (session.selected?.opacity ?? 1) * 100 }, set: { value in session.updateElement { $0.opacity = value / 100 } }), range: 0...100, suffix: "%").frame(width: 104)
                    }.padding(.horizontal, 8)
                    HStack(spacing: 5) { Text("Lock:").font(.system(size: 10)).foregroundStyle(ProTheme.secondary); ProIcon(symbol: session.selected?.locked == true ? "lock.fill" : "lock", help: "Lock layer", active: session.selected?.locked == true, size: 22) { session.updateElement { $0.locked.toggle() } }; Spacer(); Text("\(session.currentElements.count) layers").font(.system(size: 9)).foregroundStyle(ProTheme.secondary) }.padding(.horizontal, 8).padding(.vertical, 3)
                }
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(session.currentElements.reversed().filter { (tab != "Paths" || $0.kind == .path) && (filter.isEmpty || $0.name.localizedCaseInsensitiveContains(filter)) }) { layer in
                            HStack(spacing: 8) {
                                ProIcon(symbol: layer.visible ? "eye" : "eye.slash", help: "Toggle visibility", size: 19) { session.updateElement(layer.id) { $0.visible.toggle() } }
                                layerThumbnail(layer).frame(width: pixelStyle ? 39 : 24, height: pixelStyle ? 29 : 22).background(Color(hex: "626262")).border(Color(hex: "777777"), width: 0.5)
                                if let data = layer.maskData, let mask = NSImage(data: data) {
                                    Image(systemName: "link").font(.system(size: 9))
                                    Button { session.select(layer.id); session.editingMask = true; session.drawingTool = .brush } label: {
                                        Image(nsImage: mask).resizable().scaledToFit().frame(width: 25, height: 24).overlay(Rectangle().stroke(session.selectedID == layer.id && session.editingMask ? ProTheme.blue : .gray, lineWidth: 1))
                                    }.buttonStyle(.plain).help("Paint this layer mask")
                                }
                                Text(layer.name).font(.system(size: 11)).lineLimit(1)
                                Spacer(minLength: 0)
                                if layer.locked { Image(systemName: "lock.fill").font(.system(size: 10)) }
                            }.foregroundStyle(ProTheme.text).padding(.horizontal, 5).frame(height: pixelStyle ? 42 : 30)
                                .background(session.selectedIDs.contains(layer.id) ? Color(hex: "505050") : ProTheme.panel)
                                .contentShape(Rectangle()).onTapGesture { session.select(layer.id, extending: NSEvent.modifierFlags.contains(.shift)); session.drawingTool = .select }
                                .onDrag { NSItemProvider(object: ("layer:" + layer.id.uuidString) as NSString) }
                                .onDrop(of: [.text], isTargeted: nil) { providers in
                                    guard let provider = providers.first else { return false }
                                    _ = provider.loadObject(ofClass: String.self) { value, _ in
                                        guard let value, let id = UUID(uuidString: value.replacingOccurrences(of: "layer:", with: "")) else { return }
                                        DispatchQueue.main.async {
                                            guard let from = session.document.elements.firstIndex(where: { $0.id == id }), let to = session.document.elements.firstIndex(where: { $0.id == layer.id }) else { return }
                                            session.mutate { let item = $0.elements.remove(at: from); $0.elements.insert(item, at: to) }
                                        }
                                    }
                                    return true
                                }
                                .contextMenu {
                                    Button("Duplicate Layer") { session.select(layer.id); session.duplicate() }
                                    Button(layer.locked ? "Unlock Layer" : "Lock Layer") { session.updateElement(layer.id) { $0.locked.toggle() } }
                                    Button("Rasterize Layer") { session.select(layer.id); session.rasterizeSelection() }.disabled(layer.kind == .image)
                                    if layer.maskData != nil { Button("Delete Layer Mask") { session.updateElement(layer.id) { $0.maskData = nil } } }
                                    Divider()
                                    Button("Delete Layer") { session.select(layer.id); session.deleteSelection() }
                                }
                        }
                    }
                }
                HStack(spacing: 3) {
                    if pixelStyle {
                        ProIcon(symbol: "rectangle.inset.filled", help: "Add layer mask from selection", size: 25) { session.addMask() }.disabled(session.selected?.kind != .image)
                        Menu {
                            Button("Exposure +0.25") { session.updateElement { $0.adjustments.exposure += 0.25 } }
                            Button("Black & White") { session.updateElement { $0.adjustments.saturation = 0 } }
                            Button("Reset Adjustments") { session.updateElement { $0.adjustments = ImageAdjustments() } }
                        } label: { Image(systemName: "circle.lefthalf.filled").font(.system(size: 12)) }
                        .menuStyle(.borderlessButton).frame(width: 26).disabled(session.selected?.kind != .image)
                    }
                    ProIcon(symbol: "arrow.up", help: "Bring forward", size: 25) { if let id = session.selectedID { session.reorder(id, offset: 1) } }
                    ProIcon(symbol: "arrow.down", help: "Send backward", size: 25) { if let id = session.selectedID { session.reorder(id, offset: -1) } }
                    Spacer()
                    ProIcon(symbol: "plus.square", help: "Create new layer", size: 25) { session.addElement(pixelStyle ? .image : .rectangle) }
                    ProIcon(symbol: "trash", help: "Delete selected layers", size: 25) { session.deleteSelection() }
                }.padding(.horizontal, 7).frame(height: 29).background(ProTheme.header)
            }
        }.background(ProTheme.panel)
    }
    @ViewBuilder func layerThumbnail(_ layer: CanvasElement) -> some View {
        if let data = layer.imageData, let image = NSImage(data: data) { Image(nsImage: image).resizable().scaledToFit() }
        else if layer.kind == .text { Text("T").font(.system(size: 22, weight: .medium)).foregroundStyle(.white) }
        else { Image(systemName: layer.kind == .ellipse ? "circle.fill" : layer.kind == .path ? "point.topleft.down.to.point.bottomright.curvepath" : "rectangle.fill").font(.system(size: 18)).foregroundStyle(Color(hex: layer.fill)) }
    }
}

struct ProPropertiesPanel: View {
    @ObservedObject var session: StudioSession
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let layer = session.selected {
                    HStack { Text(layer.kind == .text ? "Type Layer" : layer.kind == .image ? "Pixel Layer" : "\(layer.kind.rawValue.capitalized)").font(.system(size: 11, weight: .semibold)); Spacer() }.padding(12)
                    ProSection(title: "Transform") {
                        HStack { ProField(label: "W", value: session.elementBinding(\.width, 100), range: 1...16384, suffix: session.tool == .press ? "pt" : "px"); ProField(label: "H", value: session.elementBinding(\.height, 100), range: 1...16384, suffix: session.tool == .press ? "pt" : "px") }
                        HStack { ProField(label: "X", value: session.elementBinding(\.x, 0)); ProField(label: "Y", value: session.elementBinding(\.y, 0)) }
                        HStack { ProField(label: "↻", value: session.elementBinding(\.rotation, 0), range: -360...360, suffix: "°").frame(width: 104); Spacer() }
                    }.disabled(layer.locked)
                    if layer.maskData != nil {
                        ProSection(title: "Layer Mask") {
                            ProCheck(title: "Paint Mask", value: $session.editingMask)
                            ProCheck(title: "Enabled", value: Binding(get: { session.selected?.maskEnabled ?? true }, set: { value in session.updateElement { $0.maskEnabled = value } }))
                            ProCheck(title: "Inverted", value: Binding(get: { session.selected?.maskInverted ?? false }, set: { value in session.updateElement { $0.maskInverted = value } }))
                            ProSlider(title: "Feather (pixels)", value: Binding(get: { session.selected?.maskFeather ?? 0 }, set: { value in session.updateElement { $0.maskFeather = value } }), range: 0...50)
                        }.disabled(layer.locked)
                    }
                    if layer.kind == .text { ProTypographyPanel(session: session).disabled(layer.locked) }
                    if layer.kind != .image {
                        ProSection(title: "Appearance") {
                            HStack { ProColorControl("Fill", selection: session.elementColor(\.fill), supportsOpacity: false).font(.system(size: 11)); Spacer() }
                            HStack { ProColorControl("Stroke", selection: session.elementColor(\.stroke), supportsOpacity: false).font(.system(size: 11)); ProField(label: "", value: session.elementBinding(\.strokeWidth, 0), range: 0...200, suffix: "pt").frame(width: 75) }
                            ProField(label: "Opacity", value: Binding(get: { (session.selected?.opacity ?? 1) * 100 }, set: { value in session.updateElement { $0.opacity = value / 100 } }), range: 0...100, suffix: "%")
                            if layer.kind == .rectangle { ProField(label: "Corners", value: session.elementBinding(\.cornerRadius, 0), range: 0...1000, suffix: "px") }
                        }.disabled(layer.locked)
                    } else { ProAdjustmentsPanel(session: session) }
                    if session.tool == .form {
                        ProSection(title: "Align") {
                            HStack(spacing: 7) {
                                ForEach([("left", "align.horizontal.left"), ("horizontal", "align.horizontal.center"), ("right", "align.horizontal.right"), ("top", "align.vertical.top"), ("vertical", "align.vertical.center"), ("bottom", "align.vertical.bottom")], id: \.0) { alignment, symbol in ProIcon(symbol: symbol, help: "Align " + alignment, size: 25) { session.alignSelection(alignment) } }
                            }
                        }
                        ProSection(title: "Pathfinder") {
                            HStack(spacing: 4) {
                                ForEach([("Unite", "square.on.square.fill"), ("Subtract", "rectangle.on.rectangle.slash"), ("Intersect", "square.intersection.dashed"), ("Exclude", "square.on.square")], id: \.0) { name, symbol in ProIcon(symbol: symbol, help: name, size: 34) { session.combineShapes(name) } }
                            }.disabled(session.selectedIDs.count < 2)
                            Text("Shift-click layers or shapes to select more than one.").font(.system(size: 10)).foregroundStyle(ProTheme.secondary)
                        }
                    }
                    ProSection(title: "Quick Actions") {
                        HStack { Button("Duplicate") { session.duplicate() }.buttonStyle(ProButtonStyle()); Button("Delete") { session.deleteSelection() }.buttonStyle(ProButtonStyle()) }
                        if layer.kind != .image && session.tool == .pixel { Button("Rasterize Layer") { session.rasterizeSelection() }.buttonStyle(ProButtonStyle()) }
                        if session.tool == .press && layer.kind == .text {
                            Menu("Thread to text frame") {
                                Button("Unlink") { session.linkText(to: nil) }
                                ForEach(session.document.elements.filter { $0.kind == .text && $0.id != layer.id }) { target in Button("Page \(target.page + 1): \(target.name)") { session.linkText(to: target.id) } }
                            }.font(.system(size: 11))
                        }
                    }
                } else {
                    ProSection(title: "Document") {
                        Text("No Selection").font(.system(size: 11)).foregroundStyle(ProTheme.secondary)
                        HStack { ProField(label: "W", value: Binding(get: { session.document.width }, set: { value in session.mutate { $0.width = value } }), range: 16...16384); ProField(label: "H", value: Binding(get: { session.document.height }, set: { value in session.mutate { $0.height = value } }), range: 16...16384) }
                        ProColorControl("Canvas", selection: Binding(get: { Color(hex: session.document.background) }, set: { value in session.mutate { $0.background = value.hex } }), supportsOpacity: false).font(.system(size: 11))
                        ProCheck(title: "Transparent background", value: Binding(get: { session.document.transparentBackground ?? false }, set: { value in session.mutate { $0.transparentBackground = value } }))
                        HStack { ProIcon(symbol: "ruler", help: "Show rulers", active: session.showRulers) { session.showRulers.toggle() }; ProIcon(symbol: "grid", help: "Show grid", active: session.showGrid) { session.showGrid.toggle() } }
                    }
                }
            }
        }.background(ProTheme.panel).foregroundStyle(ProTheme.text)
    }
}

struct ProTypographyPanel: View {
    @ObservedObject var session: StudioSession
    func style<T>(_ key: WritableKeyPath<Typography, T>, fallback: T) -> Binding<T> {
        Binding(get: { session.selected?.typography?[keyPath: key] ?? fallback }, set: { value in session.updateElement { e in var s = e.typography ?? Typography(); s[keyPath: key] = value; e.typography = s } })
    }
    var body: some View {
        ProSection(title: "Character") {
            Picker("Font", selection: session.elementBinding(\.fontName, "HelveticaNeue")) { ForEach(["HelveticaNeue", "HelveticaNeue-Bold", "Georgia", "Georgia-Bold", "AvenirNext-DemiBold", "Menlo-Regular", "Didot", "Futura-Medium"], id: \.self) { Text($0).tag($0) } }.labelsHidden().controlSize(.small)
            HStack { ProField(label: "T", value: session.elementBinding(\.fontSize, 24), range: 1...1000, suffix: "pt"); ProField(label: "↕", value: style(\.leading, fallback: 1.2), range: 0.5...5) }
            ProField(label: "Tracking", value: style(\.tracking, fallback: 0), range: -500...1000)
            HStack(spacing: 8) {
                ForEach([(DevinCore.TextAlignment.left, "text.alignleft"), (.center, "text.aligncenter"), (.right, "text.alignright"), (.justified, "text.justify")], id: \.0) { alignment, symbol in
                    ProIcon(symbol: symbol, help: "Align " + alignment.rawValue, active: (session.selected?.typography?.alignment ?? .left) == alignment) { style(\.alignment, fallback: .left).wrappedValue = alignment }
                }
            }
            TextEditor(text: session.tool == .press ? session.storyBinding : session.elementBinding(\.text, "")).font(.system(size: 11)).scrollContentBackground(.hidden).padding(4).frame(height: 88).background(ProTheme.field)
        }
    }
}

struct ProAdjustmentsPanel: View {
    @ObservedObject var session: StudioSession
    var body: some View {
        ProSection(title: "Adjustments") {
            if session.selected?.kind == .image {
                ProSlider(title: "Exposure", value: session.elementBinding(\.adjustments.exposure, 0), range: -3...3)
                ProSlider(title: "Contrast", value: session.elementBinding(\.adjustments.contrast, 1), range: 0.25...2)
                ProSlider(title: "Saturation", value: session.elementBinding(\.adjustments.saturation, 1), range: 0...2)
                ProSlider(title: "Temperature", value: session.elementBinding(\.adjustments.temperature, 6500), range: 2500...10000)
                ProSlider(title: "Gaussian Blur", value: session.elementBinding(\.adjustments.blur, 0), range: 0...40)
                Button("Reset Adjustments") { session.updateElement { $0.adjustments = ImageAdjustments() } }.buttonStyle(ProButtonStyle())
            } else { Text("Select a pixel layer to adjust its image.").font(.system(size: 11)).foregroundStyle(ProTheme.secondary) }
        }
    }
}
