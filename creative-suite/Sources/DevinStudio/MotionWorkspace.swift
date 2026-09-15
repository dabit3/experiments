import SwiftUI
import DevinCore

func frameTimecode(_ seconds: Double, fps: Int = 24) -> String {
    guard seconds.isFinite, abs(seconds) < Double(Int.max / max(1, fps)) else { return "0:00:00:00" }
    let frames = max(0, Int((seconds * Double(fps)).rounded(.down))), rate = max(1, fps)
    return String(format: "%d:%02d:%02d:%02d", frames / (rate * 3600), (frames / (rate * 60)) % 60, (frames / rate) % 60, frames % rate)
}

struct MotionWorkspace: View {
    @ObservedObject var session: StudioSession
    @State private var leftTab = "Project"
    @State private var compositionTab = "Composition"
    @State private var expanded = Set<UUID>()
    @State private var graph = false
    @State private var graphProperty = "Position X"
    @State private var loop = true
    @State private var lastTick = Date()
    @State private var effectSearch = ""
    @State private var keyframeOrigin: Double?
    private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack(spacing: 0) {
            ProAppBar(session: session)
            toolBar
            VSplitView {
                HSplitView {
                    if !session.panelsHidden { projectPanel.frame(minWidth: 210, idealWidth: 265, maxWidth: 340) }
                    VStack(spacing: 0) {
                        ProTabs(tabs: ["Composition"], selected: $compositionTab, accent: true)
                        HStack { Text(session.document.title); Image(systemName: "chevron.down").font(.system(size: 8)); Spacer() }.font(.system(size: 10)).padding(.horizontal, 13).frame(height: 25).background(ProTheme.header)
                        ProCanvasViewport(session: session)
                        HStack(spacing: 13) {
                            Text(String(format: "%.1f%%", session.canvasScale * 100))
                            ProIcon(symbol: "grid", help: "Grid", active: session.showGrid, size: 21) { session.showGrid.toggle() }
                            Text("Full").foregroundStyle(ProTheme.secondary)
                            Text(frameTimecode(session.playhead, fps: session.document.fps)).foregroundStyle(ProTheme.blue)
                            Spacer()
                            Text("2D Composition").foregroundStyle(ProTheme.secondary)
                            Text("1 View").foregroundStyle(ProTheme.secondary)
                        }.font(.system(size: 10)).padding(.horizontal, 12).frame(height: 29).background(ProTheme.panel)
                    }.frame(minWidth: 380)
                    if !session.panelsHidden { rightPanel.frame(minWidth: 220, idealWidth: 245, maxWidth: 300) }
                }.frame(minHeight: 270, idealHeight: 510)
                timeline.frame(minHeight: 230, idealHeight: 295)
            }
        }.background(ProTheme.background).foregroundStyle(ProTheme.text)
            .onReceive(timer) { now in
                guard session.isPlaying else { return }
                let delta = min(0.2, now.timeIntervalSince(lastTick)); lastTick = now
                let next = session.document.playbackArea.advanced(from: session.playhead, by: delta, fps: session.document.fps, loop: loop)
                session.playhead = next.time; session.isPlaying = next.playing
            }
            .onAppear { if session.workspacePreset == "Animation" { expanded = Set(session.selectedID.map { [$0] } ?? []) } }
            .onChange(of: session.isPlaying) { _, _ in lastTick = Date() }
            .onChange(of: session.workspacePreset) { _, preset in if preset == "Animation" { expanded = Set(session.document.elements.map(\.id)) } }
    }
    var toolBar: some View {
        HStack(spacing: 4) {
            ForEach([DrawingTool.select, .hand, .zoom, .rectangle, .ellipse, .pen, .text, .brush], id: \.self) { tool in ProIcon(symbol: tool.symbol, help: tool.title + " (" + tool.shortcut + ")", active: session.drawingTool == tool) { session.drawingTool = tool } }
            Divider().frame(height: 20).padding(.horizontal, 6)
            ProColorControl("Fill", selection: session.elementColor(\.fill), supportsOpacity: false).font(.system(size: 10)).frame(width: 80)
            ProColorControl("Stroke", selection: session.elementColor(\.stroke), supportsOpacity: false).font(.system(size: 10)).frame(width: 95)
            ProField(label: "", value: session.elementBinding(\.strokeWidth, 0), range: 0...100, suffix: "px").frame(width: 55)
            Spacer()
            Button("Import…") { session.importFiles() }.buttonStyle(ProButtonStyle())
            Button("Render") { session.showExport = true }.buttonStyle(ProButtonStyle())
        }.padding(.horizontal, 9).frame(height: 35).background(ProTheme.panel)
    }
    var projectPanel: some View {
        VStack(spacing: 0) {
            ProTabs(tabs: ["Project", "Effect Controls"], selected: $leftTab, accent: true)
            if leftTab == "Project" {
                HStack(alignment: .top, spacing: 10) {
                    if let image = Renderer.image(session.document, time: 1.5, maxDimension: 160) { Image(nsImage: NSImage(cgImage: image, size: .zero)).resizable().scaledToFit().frame(width: 88, height: 58).background(.black) }
                    VStack(alignment: .leading, spacing: 3) { Text(session.document.title).font(.system(size: 11, weight: .medium)); Text("\(Int(session.document.width)) × \(Int(session.document.height))"); Text("\(frameTimecode(session.document.duration, fps: session.document.fps))  \(session.document.fps) fps") }.font(.system(size: 9)).foregroundStyle(ProTheme.secondary)
                    Spacer(minLength: 0)
                }.padding(10)
                HStack { Image(systemName: "magnifyingglass"); TextField("Search", text: $effectSearch).textFieldStyle(.plain) }.font(.system(size: 10)).padding(6).background(ProTheme.field).padding(.horizontal, 9)
                HStack { Text("Name"); Spacer(); Text("Type") }.font(.system(size: 10)).foregroundStyle(ProTheme.secondary).padding(.horizontal, 10).frame(height: 26)
                HStack { Image(systemName: "film").foregroundStyle(Color(hex: "BE95D0")); Text(session.document.title).lineLimit(1); Spacer(); Text("Comp").foregroundStyle(ProTheme.secondary) }.font(.system(size: 11)).padding(8).background(Color(hex: "484848"))
                ForEach(session.document.elements.filter { $0.kind == .image && (effectSearch.isEmpty || $0.name.localizedCaseInsensitiveContains(effectSearch)) }) { item in
                    HStack { Image(systemName: "photo"); Text(item.name).lineLimit(1); Spacer() }.font(.system(size: 11)).padding(8).contentShape(Rectangle()).onTapGesture { session.select(item.id) }
                }
                Spacer()
                HStack { ProIcon(symbol: "plus.rectangle.on.rectangle", help: "New composition") { session.showNew = true }; ProIcon(symbol: "photo.badge.plus", help: "Import footage") { session.importFiles() }; Spacer(); Text("8 bpc").font(.system(size: 9)).foregroundStyle(ProTheme.secondary) }.padding(.horizontal, 7).frame(height: 28)
            } else { ProPropertiesPanel(session: session) }
        }.background(ProTheme.panel)
    }
    var rightPanel: some View {
        ScrollView {
            VStack(spacing: 0) {
                ProSection(title: "Info") {
                    HStack { Text("X: \(Int(session.editableSelection?.x ?? 0))"); Spacer(); Text("Y: \(Int(session.editableSelection?.y ?? 0))") }.font(.system(size: 10)).foregroundStyle(ProTheme.secondary)
                    Text("Duration: " + frameTimecode(session.document.duration, fps: session.document.fps)).font(.system(size: 10))
                }
                ProSection(title: "Preview") {
                    HStack(spacing: 5) {
                        ProIcon(symbol: "backward.end.fill", help: "First frame") { session.playhead = 0 }
                        ProIcon(symbol: "backward.frame.fill", help: "Previous frame") { session.playhead = max(0, session.playhead - 1 / Double(session.document.fps)) }
                        ProIcon(symbol: session.isPlaying ? "stop.fill" : "play.fill", help: "Preview · Space") { if session.playhead >= session.document.duration { session.playhead = 0 }; session.isPlaying.toggle() }
                        ProIcon(symbol: "forward.frame.fill", help: "Next frame") { session.playhead = min(session.document.duration, session.playhead + 1 / Double(session.document.fps)) }
                        ProIcon(symbol: "forward.end.fill", help: "Last frame") { session.playhead = session.document.playbackArea.lastFrame(fps: session.document.fps) }
                    }
                    ProCheck(title: "Loop", value: $loop)
                    ProField(label: "Work In", value: session.workAreaBinding(start: true), range: 0...session.document.duration, suffix: "s")
                    ProField(label: "Work Out", value: session.workAreaBinding(start: false), range: 0...session.document.duration, suffix: "s")
                    Button("Reset Work Area") { session.mutate { $0.workArea = nil } }.buttonStyle(ProButtonStyle())
                    Picker("Frame Rate", selection: Binding(get: { session.document.fps }, set: { value in session.mutate { $0.fps = value } })) { ForEach([12, 24, 25, 30, 60], id: \.self) { Text("\($0)").tag($0) } }.font(.system(size: 10)).controlSize(.small)
                    ProField(label: "Duration", value: Binding(get: { session.document.duration }, set: { value in session.mutate { $0.duration = value }; session.playhead = min(session.playhead, value) }), range: 0.1...3600, suffix: "s")
                }
                ProSection(title: "Effects & Presets") {
                    Button("Easy Ease") { session.setInterpolation(.easeInOut) }.buttonStyle(ProButtonStyle()).disabled(session.selected?.hasAnimation != true)
                    Button("Hold Keyframes") { session.setInterpolation(.hold) }.buttonStyle(ProButtonStyle()).disabled(session.selected?.hasAnimation != true)
                    Button("Linear Keyframes") { session.setInterpolation(.linear) }.buttonStyle(ProButtonStyle()).disabled(session.selected?.hasAnimation != true)
                }
                if session.selected?.kind == .text { ProTypographyPanel(session: session) }
                if session.selected?.kind == .image { ProAdjustmentsPanel(session: session) }
            }
        }.background(ProTheme.panel)
    }
    var timeline: some View {
        VStack(spacing: 0) {
            HStack {
                Text(session.document.title).font(.system(size: 11)).foregroundStyle(ProTheme.blue)
                Spacer()
                ProIcon(symbol: "chart.xyaxis.line", help: "Graph Editor", active: graph, size: 24) { graph.toggle() }
                Button("Add Keyframe") { session.addKeyframe() }.buttonStyle(ProButtonStyle()).disabled(session.selected == nil)
            }.padding(.horizontal, 13).frame(height: 30).background(ProTheme.header)
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(frameTimecode(session.playhead, fps: session.document.fps)).font(.system(size: 19)).foregroundStyle(ProTheme.blue)
                    Text("\(Int(session.playhead * Double(session.document.fps)))  (\(session.document.fps) fps)").font(.system(size: 9)).foregroundStyle(ProTheme.secondary)
                }.padding(.leading, 14).frame(width: 400, height: 49, alignment: .leading)
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        Rectangle().fill(Color(hex: "858585")).frame(height: 7).padding(.top, 2)
                        ForEach(0..<11) { tick in
                            let time = Double(tick) / 10 * session.document.duration
                            Text(frameTimecode(time, fps: session.document.fps)).font(.system(size: 9)).foregroundStyle(ProTheme.secondary).position(x: CGFloat(tick) / 10 * max(1, geo.size.width - 48) + 24, y: 27)
                        }
                        playheadLine(width: geo.size.width, height: 48)
                    }.contentShape(Rectangle()).gesture(DragGesture(minimumDistance: 0).onChanged { value in session.isPlaying = false; session.playhead = min(session.document.duration, max(0, value.location.x / geo.size.width * session.document.duration)) })
                }
            }.frame(height: 49).background(ProTheme.panel)
            if graph { graphView }
            else {
                ScrollView {
                    VStack(spacing: 0) {
                        HStack { Text("   ◇     #       Source Name"); Spacer(); Text("Mode          Animation") }.font(.system(size: 9)).foregroundStyle(ProTheme.secondary).frame(width: 380, alignment: .leading).padding(.leading, 10).frame(maxWidth: .infinity, alignment: .leading).frame(height: 22).background(ProTheme.header)
                        ForEach(Array(session.document.elements.reversed().enumerated()), id: \.element.id) { index, layer in
                            timelineLayer(layer, index: index)
                        }
                    }
                }
            }
            HStack { Text("Independent property animation"); Spacer(); Text("\(session.document.elements.count) layers    \(Int(session.document.width)) × \(Int(session.document.height))") }.font(.system(size: 9)).foregroundStyle(ProTheme.secondary).padding(.horizontal, 12).frame(height: 23).background(ProTheme.header)
        }.background(ProTheme.panel)
    }
    func timelineLayer(_ layer: CanvasElement, index: Int) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 5) {
                    ProIcon(symbol: layer.visible ? "eye" : "eye.slash", help: "Layer visibility", size: 20) { session.updateElement(layer.id) { $0.visible.toggle() } }
                    ProIcon(symbol: layer.locked ? "lock.fill" : "lock.open", help: "Lock layer", size: 18) { session.updateElement(layer.id) { $0.locked.toggle() } }
                    Rectangle().fill(layer.kind == .text ? Color(hex: "DC7979") : Color(hex: "9C9FCC")).frame(width: 8, height: 14)
                    Text("\(index + 1)").font(.system(size: 10)).frame(width: 18)
                    Button { if expanded.contains(layer.id) { expanded.remove(layer.id) } else { expanded.insert(layer.id) } } label: { Image(systemName: expanded.contains(layer.id) ? "chevron.down" : "chevron.right").font(.system(size: 8)) }.buttonStyle(.plain)
                    Text(layer.name).font(.system(size: 10)).lineLimit(1)
                    Spacer(minLength: 3)
                    Text((layer.blendMode ?? .normal).title).font(.system(size: 9)).foregroundStyle(ProTheme.secondary).frame(width: 55)
                    Text("\(layer.effectiveAnimationChannels.count) props").font(.system(size: 9)).foregroundStyle(ProTheme.secondary).frame(width: 46)
                }.padding(.horizontal, 5).frame(width: 400, height: 26).contentShape(Rectangle()).onTapGesture { session.select(layer.id) }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color(hex: "202020"))
                        let start = layer.inPoint ?? 0, end = min(session.document.duration, layer.outPoint ?? session.document.duration)
                        Rectangle().fill(layer.kind == .text ? Color(hex: "D17B7B") : Color(hex: "A0A3CD"))
                            .frame(width: max(1, (end - start) / session.document.duration * geo.size.width), height: 18)
                            .offset(x: start / session.document.duration * geo.size.width)
                        ForEach(Array(Set(layer.effectiveAnimationChannels.flatMap { $0.keyframes.map(\.time) })).sorted(), id: \.self) { time in
                            Image(systemName: "diamond.fill").font(.system(size: 8)).foregroundStyle(Color(hex: "E8E6C1")).offset(x: max(0, min(geo.size.width - 8, time / session.document.duration * geo.size.width - 4)))
                                .onTapGesture { session.select(layer.id); session.playhead = time }
                        }
                        playheadLine(width: geo.size.width, height: 26).allowsHitTesting(false)
                    }.clipped().contentShape(Rectangle()).onTapGesture { session.select(layer.id) }
                }.frame(height: 26)
            }.background(session.selectedID == layer.id ? Color(hex: "474747") : ProTheme.panel)
            if expanded.contains(layer.id) {
                ForEach(AnimationProperty.allCases, id: \.self) { property in AnimationChannelRow(session: session, layerID: layer.id, property: property) }
                HStack(spacing: 12) {
                    Text("Layer timing").font(.system(size: 10)).foregroundStyle(ProTheme.secondary)
                    ProField(label: "In", value: timeBinding(layer, start: true), range: 0...session.document.duration).frame(width: 100)
                    ProField(label: "Out", value: timeBinding(layer, start: false), range: 0.01...3600).frame(width: 100)
                    Spacer()
                }.padding(.leading, 42).frame(height: 28).disabled(layer.locked)
            }
        }
    }
    func propertyBinding(_ layer: CanvasElement, _ key: WritableKeyPath<CanvasElement, Double>) -> Binding<Double> {
        Binding(get: { session.document.elements.first { $0.id == layer.id }?.evaluated(at: session.playhead)[keyPath: key] ?? 0 }, set: { value in session.select(layer.id); session.updateElement { $0[keyPath: key] = value } })
    }
    func timeBinding(_ layer: CanvasElement, start: Bool) -> Binding<Double> {
        Binding(get: { start ? (layer.inPoint ?? 0) : (layer.outPoint ?? session.document.duration) }, set: { value in session.updateElement(layer.id) { e in if start { e.inPoint = min(value, (e.outPoint ?? session.document.duration) - 0.01) } else { e.outPoint = max(value, (e.inPoint ?? 0) + 0.01) } } })
    }
    func keyframeDiamond(_ frame: Keyframe, layer: CanvasElement, width: Double) -> some View {
        Image(systemName: frame.interpolation == .hold ? "square.fill" : "diamond.fill").font(.system(size: 9)).foregroundStyle(session.selectedID == layer.id ? Color(hex: "D6E9FF") : Color(hex: "E7E4B4"))
            .offset(x: min(width - 8, max(0, frame.time / session.document.duration * width - 4)))
            .onTapGesture { session.select(layer.id); session.playhead = frame.time }
            .gesture(DragGesture(minimumDistance: 3).onChanged { value in
                if keyframeOrigin == nil { keyframeOrigin = frame.time; session.beginTransaction() }
                guard let i = session.document.elements.firstIndex(where: { $0.id == layer.id }), let k = session.document.elements[i].keyframes.firstIndex(where: { $0.id == frame.id }) else { return }
                let time = min(session.document.duration, max(0, (keyframeOrigin ?? frame.time) + value.translation.width / width * session.document.duration))
                session.document.elements[i].keyframes[k].time = (time * Double(session.document.fps)).rounded() / Double(session.document.fps)
            }.onEnded { _ in session.endTransaction(); keyframeOrigin = nil })
            .contextMenu { Button("Delete Keyframe") { session.updateElement(layer.id) { $0.keyframes.removeAll { $0.id == frame.id } } } }
    }
    func playheadLine(width: Double, height: Double) -> some View {
        VStack(spacing: 0) { Image(systemName: "arrowtriangle.down.fill").font(.system(size: 9)); Rectangle().frame(width: 1) }.foregroundStyle(ProTheme.blue).frame(width: 9, height: height).offset(x: min(width - 5, max(0, session.playhead / session.document.duration * width - 4)))
    }
    var graphView: some View {
        VStack(spacing: 0) {
            Picker("Value", selection: $graphProperty) { ForEach(["Position X", "Position Y", "Rotation", "Opacity"], id: \.self) { Text($0).tag($0) } }.frame(width: 230).controlSize(.small).padding(7)
            Canvas { context, size in
                for i in 0...8 { let y = Double(i) / 8 * size.height; var line = Path(); line.move(to: CGPoint(x: 0, y: y)); line.addLine(to: CGPoint(x: size.width, y: y)); context.stroke(line, with: .color(.white.opacity(0.08)), lineWidth: 1) }
                guard let layer = session.selected else { return }
                let values = (0...200).map { i -> Double in
                    let e = layer.evaluated(at: Double(i) / 200 * session.document.duration)
                    switch graphProperty { case "Position Y": return e.y; case "Rotation": return e.rotation; case "Opacity": return e.opacity; default: return e.x }
                }
                let low = values.min() ?? 0, high = values.max() ?? 1, range = max(0.01, high - low)
                var path = Path()
                for (i, value) in values.enumerated() {
                    let point = CGPoint(x: Double(i) / 200 * size.width, y: size.height - 12 - (value - low) / range * max(1, size.height - 24))
                    if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                context.stroke(path, with: .color(Color(hex: "E57878")), lineWidth: 1.5)
                context.draw(Text(String(format: "%.2f", high)).font(.system(size: 9)).foregroundColor(.gray), at: CGPoint(x: 26, y: 10))
            }.background(Color(hex: "1D1D1D"))
        }
    }
}
