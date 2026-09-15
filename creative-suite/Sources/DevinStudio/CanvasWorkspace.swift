import SwiftUI
import DevinCore

struct CanvasWorkspace: View {
    @ObservedObject var session: StudioSession
    private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()
    @State private var lastTick = Date()
    @State private var thumbnails: [Int: NSImage] = [:]
    @State private var thumbnailTask: Task<Void, Never>?
    var body: some View {
        HStack(spacing: 0) {
            layers
            VStack(spacing: 0) {
                toolbar
                GeometryReader { geo in
                    let fit = min((geo.size.width - 96) / session.document.width, (geo.size.height - 96) / session.document.height)
                    let scale = max(0.02, fit * session.zoom)
                    ScrollView([.horizontal, .vertical]) {
                        NativeCanvas(session: session, scale: scale)
                            .frame(width: session.document.width * scale, height: session.document.height * scale)
                            .shadow(color: .black.opacity(0.4), radius: 22, y: 12)
                            .padding(48)
                            .frame(minWidth: geo.size.width, minHeight: geo.size.height)
                    }
                    .background(Color(hex: "242725"))
                    .overlay(alignment: .topLeading) {
                        Text("\(session.document.title.uppercased())  /  \(Int(session.document.width)) × \(Int(session.document.height))")
                            .font(.system(size: 8, design: .monospaced)).tracking(1.2).foregroundStyle(Theme.muted).padding(15).allowsHitTesting(false)
                    }
                }
                if [.press, .frame, .lens].contains(session.tool) { pageStrip }
                if session.tool == .motion { motionTimeline }
                HStack {
                    Text(session.drawingTool == .select ? "Drag to move · lower-right handle to resize · Shift to constrain" : "Click and drag to create · V to select")
                    Spacer()
                    Text("\(session.currentElements.count) layers")
                }.font(.system(size: 9)).foregroundStyle(Theme.muted).padding(.horizontal, 16).frame(height: 28)
            }
            CanvasInspector(session: session).frame(width: 254).background(Theme.sidebar)
                .overlay(alignment: .leading) { Rectangle().fill(Theme.line).frame(width: 1) }
        }.onReceive(timer) { now in
            guard session.isPlaying else { return }
            let elapsed = min(0.15, now.timeIntervalSince(lastTick)); lastTick = now
            if session.tool == .motion { session.playhead = (session.playhead + elapsed).truncatingRemainder(dividingBy: session.document.duration) }
            else if session.tool == .frame {
                session.playhead += elapsed
                session.page = Int(session.playhead * Double(session.document.fps)) % session.document.pageCount
            }
        }
        .onAppear { refreshThumbnails() }
        .onChange(of: session.document) { _, _ in refreshThumbnails() }
        .onChange(of: session.isPlaying) { _, playing in lastTick = Date(); if playing && session.tool == .frame { session.playhead = Double(session.page) / Double(session.document.fps) } }
        .onDisappear { thumbnailTask?.cancel() }
    }
    func refreshThumbnails() {
        guard [.press, .frame, .lens].contains(session.tool) else { return }
        thumbnailTask?.cancel()
        let document = session.document
        thumbnailTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 80_000_000)
                var images: [Int: NSImage] = [:]
                for page in 0..<document.pageCount {
                    try Task.checkCancellation()
                    images[page] = Renderer.thumbnail(document, page: page)
                    await Task.yield()
                }
                try Task.checkCancellation()
                thumbnails = images
            } catch { }
        }
    }
    var toolbar: some View {
        HStack(spacing: 2) {
            ForEach([DrawingTool.select, .rectangle, .ellipse, .text, .brush, .line, .crop], id: \.self) { tool in
                IconButton(symbol: tool.symbol, help: "\(tool.rawValue.capitalized) · \(tool.shortcut)", active: session.drawingTool == tool) { session.drawingTool = tool }
            }
            Divider().frame(height: 18).padding(.horizontal, 8)
            ColorPicker("Drawing color", selection: Binding(get: { Color(hex: session.drawingColor) }, set: { session.drawingColor = $0.hex }), supportsOpacity: false).labelsHidden().frame(width: 28)
            if session.drawingTool == .brush || session.drawingTool == .line {
                Slider(value: $session.brushSize, in: 1...100).frame(width: 60).controlSize(.small)
                Text("\(Int(session.brushSize))").font(.system(size: 10, design: .monospaced))
            }
            Spacer(minLength: 4)
            IconButton(symbol: "grid", help: "Toggle grid", active: session.showGrid) { session.showGrid.toggle() }
            Menu {
                ForEach([0.5, 0.75, 1.0, 1.5, 2.0, 3.0], id: \.self) { zoom in Button("\(Int(zoom * 100))% of fit") { session.zoom = zoom } }
            } label: { Text("\(Int(session.zoom * 100))%").font(.system(size: 10, design: .monospaced)).frame(width: 50) }.menuStyle(.borderlessButton).fixedSize()
        }.padding(.horizontal, 12).frame(height: 46).background(Theme.sidebar)
    }
    var layers: some View {
        VStack(spacing: 0) {
            HStack { Text("Layers").font(.system(size: 12, weight: .semibold)); Spacer(); Text("\(session.currentElements.count)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.muted) }.padding(16).frame(height: 46)
            Divider().overlay(Theme.line)
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(session.currentElements.reversed()) { layer in
                        HStack(spacing: 8) {
                            Button { session.updateElement(layer.id) { $0.visible.toggle() } } label: { Image(systemName: layer.visible ? "eye" : "eye.slash").font(.system(size: 10)).frame(width: 16) }.buttonStyle(.plain).foregroundStyle(Theme.muted)
                            Image(systemName: layer.kind == .text ? "textformat" : layer.kind == .image ? "photo" : layer.kind == .ellipse ? "circle" : layer.kind == .path ? "scribble" : "rectangle")
                                .font(.system(size: 11)).foregroundStyle(Color(hex: layer.fill)).frame(width: 24, height: 26).background(Theme.background, in: RoundedRectangle(cornerRadius: 4))
                            Text(layer.name).font(.system(size: 10)).lineLimit(1)
                            Spacer(minLength: 0)
                            if layer.locked { Image(systemName: "lock.fill").font(.system(size: 8)).foregroundStyle(Theme.muted) }
                        }.padding(.horizontal, 9).frame(height: 41)
                            .background(session.selectedID == layer.id ? Theme.accent.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 5))
                            .contentShape(Rectangle()).onTapGesture { session.selectedID = layer.id; session.drawingTool = .select }
                            .contextMenu {
                                Button(layer.locked ? "Unlock" : "Lock") { session.updateElement(layer.id) { $0.locked.toggle() } }
                                Button("Bring forward") { session.reorder(layer.id, offset: 1) }
                                Button("Send backward") { session.reorder(layer.id, offset: -1) }
                                Button("Duplicate") { session.selectedID = layer.id; session.duplicate() }
                                Button("Delete", role: .destructive) { session.selectedID = layer.id; session.deleteSelection() }
                            }
                    }
                }.padding(6)
            }
            HStack(spacing: 6) {
                IconButton(symbol: "square.on.square", help: "Duplicate layer · ⌘D") { session.duplicate() }
                IconButton(symbol: "arrow.up", help: "Bring forward") { if let id = session.selectedID { session.reorder(id, offset: 1) } }
                IconButton(symbol: "arrow.down", help: "Send backward") { if let id = session.selectedID { session.reorder(id, offset: -1) } }
                Spacer(minLength: 0)
                IconButton(symbol: "trash", help: "Delete layer") { session.deleteSelection() }
            }.padding(5).overlay(alignment: .top) { Rectangle().fill(Theme.line).frame(height: 1) }
        }.frame(width: 196).background(Theme.sidebar).overlay(alignment: .trailing) { Rectangle().fill(Theme.line).frame(width: 1) }
    }
    var pageStrip: some View {
        VStack(spacing: 0) {
            HStack {
                Text(session.tool == .frame ? "FRAMES" : session.tool == .lens ? "COLLECTION" : "PAGES").tracking(1.4).font(.system(size: 9, weight: .semibold)).foregroundStyle(Theme.muted)
                if session.tool == .frame {
                    IconButton(symbol: session.isPlaying ? "pause.fill" : "play.fill", help: "Play animation") { session.isPlaying.toggle() }
                    Toggle("Onion skin", isOn: $session.onionSkin).font(.system(size: 10)).toggleStyle(.checkbox)
                }
                Spacer()
                Button { session.addPage() } label: { Image(systemName: "plus") }.buttonStyle(.plain).help("Add blank page or frame")
                Button { session.addPage(duplicate: true) } label: { Image(systemName: "square.on.square") }.buttonStyle(.plain).help("Duplicate page or frame")
                Button { session.deletePage() } label: { Image(systemName: "trash") }.buttonStyle(.plain).disabled(session.document.pageCount <= 1)
            }.padding(.horizontal, 15).frame(height: 35)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(0..<session.document.pageCount, id: \.self) { page in
                        VStack(spacing: 5) {
                            if let image = thumbnails[page] {
                                Image(nsImage: image).resizable().scaledToFit().frame(width: 78, height: 58)
                                    .padding(4).background(Theme.background)
                                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(session.page == page ? Theme.accent : .clear, lineWidth: 2))
                            } else { Rectangle().fill(Theme.background).frame(width: 86, height: 66) }
                            Text(String(format: "%02d", page + 1)).font(.system(size: 8, design: .monospaced)).foregroundStyle(Theme.muted)
                        }.onTapGesture { session.page = page; session.select(nil); session.isPlaying = false }
                            .contextMenu {
                                Button("Move Earlier") { session.page = page; session.moveCurrentPage(-1) }.disabled(page == 0)
                                Button("Move Later") { session.page = page; session.moveCurrentPage(1) }.disabled(page == session.document.pageCount - 1)
                                Button("Duplicate") { session.page = page; session.addPage(duplicate: true) }
                                Button("Delete") { session.page = page; session.deletePage() }.disabled(session.document.pageCount <= 1)
                            }
                    }
                }.padding(.horizontal, 15).padding(.bottom, 12)
            }
        }.background(Theme.panel)
    }
    var motionTimeline: some View {
        VStack(spacing: 10) {
            HStack {
                IconButton(symbol: session.isPlaying ? "pause.fill" : "play.fill", help: "Play animation") { session.isPlaying.toggle() }
                Text(timecode(session.playhead)).font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.accent)
                Spacer()
                Button { session.addKeyframe() } label: { Label("Add keyframe", systemImage: "diamond") }.buttonStyle(StudioButtonStyle()).disabled(session.selected == nil)
                Text("\(session.document.fps) FPS").font(.system(size: 9, design: .monospaced)).foregroundStyle(Theme.muted)
            }
            Slider(value: $session.playhead, in: 0...session.document.duration).tint(Theme.accent)
            GeometryReader { geo in
                ForEach(session.selected?.keyframes ?? []) { frame in
                    Image(systemName: "diamond.fill").font(.system(size: 9)).foregroundStyle(Theme.accent)
                        .position(x: max(6, min(geo.size.width - 6, frame.time / session.document.duration * geo.size.width)), y: 8)
                        .onTapGesture { session.playhead = frame.time }
                }
            }.frame(height: 18)
            HStack { Text("00:00"); Spacer(); Text(timecode(session.document.duration)) }.font(.system(size: 9, design: .monospaced)).foregroundStyle(Theme.muted)
        }.padding(14).background(Theme.panel)
    }
}

struct CanvasInspector: View {
    @ObservedObject var session: StudioSession
    func binding<T>(_ key: WritableKeyPath<CanvasElement, T>, fallback: T) -> Binding<T> {
        Binding(get: { session.editableSelection?[keyPath: key] ?? fallback }, set: { value in session.updateElement { $0[keyPath: key] = value } })
    }
    func color(_ key: WritableKeyPath<CanvasElement, String>) -> Binding<Color> {
        Binding(get: { Color(hex: session.selected?[keyPath: key] ?? "FFFFFF") }, set: { value in session.updateElement { $0[keyPath: key] = value.hex } })
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack { Text("Properties").font(.system(size: 12, weight: .semibold)); Spacer(); Image(systemName: "slider.horizontal.3").foregroundStyle(Theme.muted) }.padding(18).frame(height: 46)
                if let selected = session.selected {
                    InspectorSection(title: "Selection") {
                        TextField("Layer name", text: binding(\.name, fallback: "")).textFieldStyle(.plain).font(.system(size: 12, weight: .medium))
                        HStack { Text(selected.kind.rawValue.capitalized).font(.system(size: 10)).foregroundStyle(Theme.muted); Spacer(); Toggle("Lock", isOn: binding(\.locked, fallback: false)).toggleStyle(.checkbox).font(.system(size: 10)) }
                    }
                    Group {
                        InspectorSection(title: "Transform") {
                            HStack { NumberField(label: "X", value: binding(\.x, fallback: 0)); NumberField(label: "Y", value: binding(\.y, fallback: 0)) }
                            HStack { NumberField(label: "W", value: binding(\.width, fallback: 100), range: 1...16384); NumberField(label: "H", value: binding(\.height, fallback: 100), range: 1...16384) }
                            HStack { NumberField(label: "°", value: binding(\.rotation, fallback: 0), range: -360...360); Button("Center") { session.updateElement { $0.x = (session.document.width-$0.width)/2; $0.y = (session.document.height-$0.height)/2 } }.buttonStyle(StudioButtonStyle()) }
                        }
                        InspectorSection(title: "Appearance") {
                            LabeledSlider(title: "Opacity", value: binding(\.opacity, fallback: 1), range: 0...1)
                            if selected.kind != .image {
                                ColorPicker("Fill", selection: color(\.fill), supportsOpacity: false).font(.system(size: 11))
                                ColorPicker("Stroke", selection: color(\.stroke), supportsOpacity: false).font(.system(size: 11))
                                NumberField(label: "Stroke width", value: binding(\.strokeWidth, fallback: 0), range: 0...200)
                                if selected.kind == .rectangle { NumberField(label: "Corner radius", value: binding(\.cornerRadius, fallback: 0), range: 0...1000) }
                            }
                        }
                        if selected.kind == .text {
                            InspectorSection(title: "Typography") {
                                TextEditor(text: binding(\.text, fallback: "")).font(.system(size: 12)).scrollContentBackground(.hidden).padding(6).frame(height: 110).background(Theme.background, in: RoundedRectangle(cornerRadius: 5))
                                Picker("Font", selection: binding(\.fontName, fallback: "HelveticaNeue-Bold")) {
                                    ForEach(["HelveticaNeue-Bold", "HelveticaNeue", "Georgia", "Georgia-Bold", "AvenirNext-DemiBold", "Menlo-Regular", "Didot", "Futura-Medium"], id: \.self) { Text($0).tag($0) }
                                }.labelsHidden()
                                NumberField(label: "Size", value: binding(\.fontSize, fallback: 64), range: 1...1000)
                            }
                        }
                        if selected.kind == .image {
                            InspectorSection(title: "Develop") {
                                LabeledSlider(title: "Exposure", value: binding(\.adjustments.exposure, fallback: 0), range: -3...3)
                                LabeledSlider(title: "Contrast", value: binding(\.adjustments.contrast, fallback: 1), range: 0.25...2)
                                LabeledSlider(title: "Saturation", value: binding(\.adjustments.saturation, fallback: 1), range: 0...2)
                                LabeledSlider(title: "Temperature", value: binding(\.adjustments.temperature, fallback: 6500), range: 2500...10000)
                                LabeledSlider(title: "Blur", value: binding(\.adjustments.blur, fallback: 0), range: 0...40)
                                Button("Reset adjustments") { session.updateElement { $0.adjustments = ImageAdjustments() } }.buttonStyle(StudioButtonStyle())
                                Button("Fit to canvas") { session.fitSelectedImage() }.buttonStyle(StudioButtonStyle())
                                Button("Fill canvas") { session.fitSelectedImage(fill: true) }.buttonStyle(StudioButtonStyle())
                                if session.tool == .lens {
                                    Button("Copy adjustments") { session.copiedAdjustments = selected.adjustments }.buttonStyle(StudioButtonStyle())
                                    Button("Paste adjustments") { if let adjustments = session.copiedAdjustments { session.updateElement { $0.adjustments = adjustments } } }.buttonStyle(StudioButtonStyle()).disabled(session.copiedAdjustments == nil)
                                }
                            }
                        }
                    }.disabled(selected.locked)
                    if session.tool == .motion {
                        InspectorSection(title: "Keyframes") {
                            Text("Add a keyframe to start animating. Position, rotation, and opacity edits then create or update a keyframe at the playhead.").font(.system(size: 10)).foregroundStyle(Theme.muted).lineSpacing(3)
                            ForEach(selected.keyframes) { frame in
                                HStack {
                                    Button(timecode(frame.time)) { session.playhead = frame.time }.buttonStyle(.plain).font(.system(size: 10, design: .monospaced))
                                    Spacer()
                                    Button { session.updateElement { $0.keyframes.removeAll { $0.id == frame.id } } } label: { Image(systemName: "xmark").font(.system(size: 9)) }.buttonStyle(.plain)
                                }
                            }
                        }
                    }
                } else {
                    InspectorSection(title: "Nothing selected") { Text("Choose a layer or draw on the canvas to get started.").font(.system(size: 11)).foregroundStyle(Theme.muted).lineSpacing(4) }
                }
                InspectorSection(title: "Document") {
                    HStack {
                        NumberField(label: "W", value: Binding(get: { session.document.width }, set: { value in session.mutate { $0.width = value } }), range: 16...16384)
                        NumberField(label: "H", value: Binding(get: { session.document.height }, set: { value in session.mutate { $0.height = value } }), range: 16...16384)
                    }
                    ColorPicker("Background", selection: Binding(get: { Color(hex: session.document.background) }, set: { value in session.mutate { $0.background = value.hex } }), supportsOpacity: false).font(.system(size: 11))
                    Toggle("Transparent background", isOn: Binding(get: { session.document.transparentBackground ?? false }, set: { value in session.mutate { $0.transparentBackground = value } })).toggleStyle(.checkbox).font(.system(size: 11))
                    if session.tool == .motion {
                        NumberField(label: "Duration (s)", value: Binding(get: { session.document.duration }, set: { value in session.mutate { $0.duration = value } }), range: 0.1...3600)
                    }
                    if [.motion, .frame].contains(session.tool) {
                        Picker("Frame rate", selection: Binding(get: { session.document.fps }, set: { value in session.mutate { $0.fps = value } })) { ForEach([6, 12, 24, 25, 30, 60], id: \.self) { Text("\($0) fps").tag($0) } }.font(.system(size: 11))
                    }
                    Button("New project…") { session.showNew = true }.buttonStyle(StudioButtonStyle())
                }
            }
        }
    }
}
