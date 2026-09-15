import SwiftUI
import AVKit
import UniformTypeIdentifiers
import DevinCore

final class CutWorkspaceState: ObservableObject {
    @Published var thumbnails: [URL: NSImage] = [:]
    @Published var waveforms: [URL: [Float]] = [:]
    @Published var source: MediaAsset?
    @Published var sourceTime = 0.0
    @Published var sourceIn = 0.0
    @Published var sourceOut = 0.0
    @Published var sourcePlaying = false
    @Published var preparing = false
    let sourcePlayer = AVPlayer()
    var previewTask: Task<Void, Never>?
    var assetTask: Task<Void, Never>?
    func openSource(_ asset: MediaAsset) {
        source = asset; sourceTime = 0; sourceIn = 0; sourceOut = asset.duration; sourcePlaying = false
        sourcePlayer.replaceCurrentItem(with: AVPlayerItem(url: asset.url))
    }
    func loadAssets(_ assets: [MediaAsset]) {
        assetTask?.cancel()
        assetTask = Task { @MainActor in
            for asset in assets {
                if Task.isCancelled { return }
                if asset.hasVideo && thumbnails[asset.url] == nil {
                    let generator = AVAssetImageGenerator(asset: AVURLAsset(url: asset.url))
                    generator.appliesPreferredTrackTransform = true; generator.maximumSize = CGSize(width: 320, height: 180)
                    if let result = try? await generator.image(at: CMTime(seconds: min(1, asset.duration / 2), preferredTimescale: 600)) { thumbnails[asset.url] = NSImage(cgImage: result.image, size: .zero) }
                }
                if waveforms[asset.url] == nil { waveforms[asset.url] = (try? await MediaEngine.waveform(url: asset.url, bins: 300)) ?? [] }
            }
        }
    }
    func rebuild(_ session: StudioSession) {
        previewTask?.cancel(); session.player.pause(); session.isPlaying = false
        let clips = session.document.clips
        guard !clips.isEmpty else { session.player.replaceCurrentItem(with: nil); preparing = false; return }
        preparing = true
        previewTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 100_000_000)
                let media = try await MediaEngine.compose(clips, video: true)
                try Task.checkCancellation()
                let item = AVPlayerItem(asset: media.composition); item.videoComposition = media.video; item.audioMix = media.audio
                session.player.replaceCurrentItem(with: item)
                await session.player.seek(to: CMTime(seconds: min(session.playhead, session.document.sequenceDuration), preferredTimescale: 60000), toleranceBefore: .zero, toleranceAfter: .zero)
                preparing = false
            } catch is CancellationError { }
            catch { preparing = false; session.error = error.localizedDescription }
        }
    }
}

struct CutWorkspace: View {
    @ObservedObject var session: StudioSession
    @StateObject private var state = CutWorkspaceState()
    @State private var sourceTab = "Source"
    @State private var programTab = "Program"
    @State private var projectTab = "Project"
    @State private var propertiesTab = "Properties"
    @State private var query = ""
    @State private var listView = false
    @State private var pixelsPerSecond = 75.0
    @State private var razor = false
    @State private var snapping = true
    @State private var clipOriginal: MediaClip?
    @State private var originalPosition = 0.0
    private let timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()
    var entries: [SequenceEntry] { SequenceLayout.entries(session.document.clips) }
    var selectedClip: MediaClip? { session.document.clips.first { $0.id == session.selectedID } }
    var tracks: Int { min(16, max(2, (entries.map(\.track).max() ?? 0) + 1)) }
    var duration: Double { session.document.sequenceDuration }
    var body: some View {
        VStack(spacing: 0) {
            ProAppBar(session: session)
            VSplitView {
                HSplitView {
                    VStack(spacing: 0) {
                        ProTabs(tabs: ["Source", "Effect Controls"], selected: $sourceTab, accent: true)
                        if sourceTab == "Source" { sourceMonitor } else { effectsPanel }
                    }.frame(minWidth: 290, idealWidth: 450)
                    VStack(spacing: 0) { ProTabs(tabs: ["Program"], selected: $programTab, accent: true); programMonitor }.frame(minWidth: 380, idealWidth: 610)
                    if !session.panelsHidden && session.workspacePreset != "Assembly" {
                        VStack(spacing: 0) { ProTabs(tabs: ["Properties"], selected: $propertiesTab, accent: true); effectsPanel }.frame(minWidth: 210, idealWidth: 255, maxWidth: 300)
                    }
                }.frame(minHeight: 280, idealHeight: 465)
                HSplitView {
                    projectPanel.frame(minWidth: 220, idealWidth: 330, maxWidth: 500)
                    timeline.frame(minWidth: 540)
                }.frame(minHeight: 260, idealHeight: 345)
            }
            HStack { Text(session.message ?? "").lineLimit(1); Spacer(); Text("\(session.document.mediaAssets.count) items   |   \(session.document.clips.count) timeline clips") }.font(.system(size: 9)).foregroundStyle(ProTheme.secondary).padding(.horizontal, 12).frame(height: 22).background(ProTheme.header)
        }.background(ProTheme.background).foregroundStyle(ProTheme.text)
            .onAppear { state.rebuild(session); state.loadAssets(session.document.mediaAssets) }
            .onChange(of: session.document.clips) { _, _ in state.rebuild(session) }
            .onChange(of: session.document.assets) { _, _ in state.loadAssets(session.document.mediaAssets) }
            .onChange(of: session.isPlaying) { _, playing in if playing { session.player.play() } else { session.player.pause() } }
            .onReceive(timer) { _ in
                if session.isPlaying {
                    let time = session.player.currentTime().seconds
                    if time.isFinite { session.playhead = time }
                    if session.playhead >= duration - 0.01 { session.isPlaying = false }
                }
                if state.sourcePlaying {
                    let time = state.sourcePlayer.currentTime().seconds
                    if time.isFinite { state.sourceTime = time }
                    if time >= state.sourceOut { state.sourcePlayer.pause(); state.sourcePlaying = false }
                }
            }
            .onDisappear { state.previewTask?.cancel(); state.assetTask?.cancel(); state.sourcePlayer.pause(); session.player.pause(); session.isPlaying = false }
    }
    var sourceMonitor: some View {
        VStack(spacing: 0) {
            HStack { Text(state.source?.name ?? "(no clips)").lineLimit(1); Spacer() }.font(.system(size: 10)).padding(.horizontal, 12).frame(height: 24).background(ProTheme.panel)
            ZStack {
                Color.black
                if let source = state.source {
                    if source.hasVideo { NativePlayer(player: state.sourcePlayer) }
                    else { WaveformView(peaks: state.waveforms[source.url] ?? [], color: Color(hex: "77B58C")).frame(height: 90).padding(16) }
                } else { Text("Double-click a clip in the Project panel").font(.system(size: 11)).foregroundStyle(ProTheme.secondary) }
            }
            HStack { Text(frameTimecode(state.sourceTime, fps: 30)).foregroundStyle(ProTheme.blue); Spacer(); Text("Fit"); Spacer(); Text(frameTimecode(state.source?.duration ?? 0, fps: 30)).foregroundStyle(ProTheme.secondary) }.font(.system(size: 10, design: .monospaced)).padding(.horizontal, 12).frame(height: 26).background(ProTheme.panel)
            Slider(value: Binding(get: { state.sourceTime }, set: { state.sourceTime = $0; state.sourcePlayer.seek(to: CMTime(seconds: $0, preferredTimescale: 60000), toleranceBefore: .zero, toleranceAfter: .zero) }), in: 0...max(0.1, state.source?.duration ?? 0.1)).controlSize(.mini).tint(ProTheme.blue).padding(.horizontal, 12).background(ProTheme.panel).disabled(state.source == nil)
            HStack(spacing: 7) {
                ProIcon(symbol: "curlybraces", help: "Mark In", size: 27) { state.sourceIn = min(state.sourceTime, state.sourceOut - 0.01) }.disabled(state.source == nil)
                ProIcon(symbol: "curlybraces.square", help: "Mark Out", size: 27) { state.sourceOut = max(state.sourceTime, state.sourceIn + 0.01) }.disabled(state.source == nil)
                ProIcon(symbol: "backward.frame.fill", help: "Previous source frame", size: 27) { state.sourceTime = max(0, state.sourceTime - 1 / 30); state.sourcePlayer.seek(to: CMTime(seconds: state.sourceTime, preferredTimescale: 60000)) }
                ProIcon(symbol: state.sourcePlaying ? "stop.fill" : "play.fill", help: "Play source", size: 27) {
                    if state.sourceTime >= state.sourceOut { state.sourcePlayer.seek(to: CMTime(seconds: state.sourceIn, preferredTimescale: 60000)) }
                    state.sourcePlaying.toggle(); if state.sourcePlaying { state.sourcePlayer.play() } else { state.sourcePlayer.pause() }
                }.disabled(state.source == nil)
                ProIcon(symbol: "forward.frame.fill", help: "Next source frame", size: 27) { state.sourceTime = min(state.source?.duration ?? 0, state.sourceTime + 1 / 30); state.sourcePlayer.seek(to: CMTime(seconds: state.sourceTime, preferredTimescale: 60000)) }
                Divider().frame(height: 18)
                ProIcon(symbol: "rectangle.badge.plus", help: "Add source range at playhead", size: 27) { if let asset = state.source { session.insertAsset(asset, at: session.playhead, start: state.sourceIn, end: state.sourceOut) } }.disabled(state.source == nil)
                ProIcon(symbol: "arrow.right.to.line", help: "Append source range", size: 27) { if let asset = state.source { session.insertAsset(asset, start: state.sourceIn, end: state.sourceOut) } }.disabled(state.source == nil)
            }.frame(maxWidth: .infinity).frame(height: 34).background(ProTheme.panel)
        }
    }
    var programMonitor: some View {
        VStack(spacing: 0) {
            HStack { Text(session.document.title); Spacer(); Text("1920 × 1080").foregroundStyle(ProTheme.secondary) }.font(.system(size: 10)).padding(.horizontal, 12).frame(height: 24).background(ProTheme.panel)
            ZStack {
                Color.black
                if !session.document.clips.isEmpty { NativePlayer(player: session.player) }
                else { Text("No sequence clips").font(.system(size: 11)).foregroundStyle(ProTheme.secondary) }
                if state.preparing { ProgressView().controlSize(.small) }
            }
            HStack { Text(frameTimecode(session.playhead, fps: 30)).foregroundStyle(ProTheme.blue); Spacer(); Text("Fit"); Spacer(); Text(frameTimecode(duration, fps: 30)).foregroundStyle(ProTheme.secondary) }.font(.system(size: 10, design: .monospaced)).padding(.horizontal, 12).frame(height: 26).background(ProTheme.panel)
            Slider(value: Binding(get: { min(session.playhead, max(0.1, duration)) }, set: { seek($0) }), in: 0...max(0.1, duration)).controlSize(.mini).tint(ProTheme.blue).padding(.horizontal, 12).background(ProTheme.panel)
            HStack(spacing: 9) {
                ProIcon(symbol: "backward.end.fill", help: "Sequence start", size: 27) { seek(0) }
                ProIcon(symbol: "backward.frame.fill", help: "Previous frame", size: 27) { seek(max(0, session.playhead - 1 / 30)) }
                ProIcon(symbol: session.isPlaying ? "stop.fill" : "play.fill", help: "Play sequence", size: 27) { if session.playhead >= duration - 0.01 { seek(0) }; session.isPlaying.toggle() }.disabled(duration == 0 || state.preparing)
                ProIcon(symbol: "forward.frame.fill", help: "Next frame", size: 27) { seek(min(duration, session.playhead + 1 / 30)) }
                ProIcon(symbol: "forward.end.fill", help: "Sequence end", size: 27) { seek(duration) }
                Divider().frame(height: 18)
                ProIcon(symbol: "scissors", help: "Add edit at playhead", size: 27) { session.splitSelectedClip() }.disabled(selectedClip == nil)
            }.frame(maxWidth: .infinity).frame(height: 34).background(ProTheme.panel)
        }
    }
    var projectPanel: some View {
        VStack(spacing: 0) {
            ProTabs(tabs: ["Project", "Effects"], selected: $projectTab, accent: true)
            if projectTab == "Project" {
                HStack { Text("Project: " + session.document.title).lineLimit(1); Spacer() }.font(.system(size: 10)).padding(10)
                HStack { Image(systemName: "magnifyingglass"); TextField("Search", text: $query).textFieldStyle(.plain) }.font(.system(size: 10)).padding(6).background(ProTheme.field).padding(.horizontal, 10)
                if session.document.mediaAssets.isEmpty {
                    VStack(spacing: 12) {
                        Text("Import media to start").font(.system(size: 13)).foregroundStyle(ProTheme.secondary)
                        Button("Import…") { session.importFiles() }.buttonStyle(ProButtonStyle())
                        Button("Generate sample clip") { generateSample() }.buttonStyle(ProButtonStyle())
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: listView ? 1 : 2), spacing: 10) {
                            ForEach(session.document.mediaAssets.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }) { asset in
                                VStack(alignment: .leading, spacing: 5) {
                                    if !listView {
                                        ZStack { Color.black; if let image = state.thumbnails[asset.url] { Image(nsImage: image).resizable().scaledToFit() } else { Image(systemName: asset.hasVideo ? "film" : "waveform").foregroundStyle(ProTheme.secondary) } }.frame(height: 70)
                                    }
                                    HStack(spacing: 4) { Image(systemName: asset.hasVideo ? "film" : "waveform").font(.system(size: 9)); Text(asset.name).font(.system(size: 10)).lineLimit(1); Spacer(minLength: 0) }
                                    Text(frameTimecode(asset.duration, fps: 30)).font(.system(size: 9)).foregroundStyle(ProTheme.secondary)
                                }.padding(5).background(state.source?.id == asset.id ? Color(hex: "4A4A4A") : .clear).contentShape(Rectangle())
                                    .onTapGesture(count: 2) { state.openSource(asset); sourceTab = "Source" }
                                    .onDrag { state.openSource(asset); return NSItemProvider(object: ("asset:" + asset.id.uuidString) as NSString) }
                                    .contextMenu { Button("Open in Source Monitor") { state.openSource(asset) }; Button("Append to Sequence") { session.insertAsset(asset) } }
                            }
                        }.padding(10)
                    }
                }
                HStack { ProIcon(symbol: "list.bullet", help: "List view", active: listView, size: 23) { listView = true }; ProIcon(symbol: "square.grid.2x2", help: "Icon view", active: !listView, size: 23) { listView = false }; Spacer(); Text("\(session.document.mediaAssets.count) items").font(.system(size: 9)); ProIcon(symbol: "plus", help: "Import media", size: 23) { session.importFiles() } }.padding(.horizontal, 8).frame(height: 28).background(ProTheme.header)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Video Effects").font(.system(size: 11, weight: .semibold))
                    Button("Scale to 50%") { transformBinding(\.scale).wrappedValue = 50 }.buttonStyle(ProButtonStyle())
                    Button("Opacity to 50%") { transformBinding(\.opacity).wrappedValue = 50 }.buttonStyle(ProButtonStyle())
                    Button("Reset Motion") { if let i = session.document.clips.firstIndex(where: { $0.id == session.selectedID }) { session.mutate { $0.clips[i].videoTransform = nil } } }.buttonStyle(ProButtonStyle())
                    Spacer()
                }.padding(15).frame(maxWidth: .infinity, alignment: .leading).disabled(selectedClip == nil)
            }
        }.background(ProTheme.panel)
    }
    var effectsPanel: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let clip = selectedClip {
                    HStack { Text(clip.name).font(.system(size: 11)).lineLimit(1); Spacer() }.padding(12)
                    if clip.audioOnly != true {
                        ProSection(title: "Motion") {
                            HStack { ProField(label: "X", value: transformBinding(\.x), range: -4000...4000); ProField(label: "Y", value: transformBinding(\.y), range: -4000...4000) }
                            ProField(label: "Scale", value: transformBinding(\.scale), range: 1...1000, suffix: "%")
                            ProField(label: "Rotation", value: transformBinding(\.rotation), range: -360...360, suffix: "°")
                            ProField(label: "Opacity", value: transformBinding(\.opacity), range: 0...100, suffix: "%")
                        }
                    }
                    ProSection(title: "Timing") {
                        Picker("Track", selection: Binding(get: { clip.trackIndex ?? 0 }, set: { value in if let i = session.document.clips.firstIndex(where: { $0.id == clip.id }) { session.mutate { $0.clips[i].trackIndex = value } } })) {
                            ForEach(0..<min(16, max(3, tracks + 1)), id: \.self) { index in Text("\(clip.audioOnly == true ? "A" : "V")\(index + 1)").tag(index) }
                        }.font(.system(size: 10)).controlSize(.small)
                        ProField(label: "Source In", value: clipBinding(\.start), range: 0...max(0, clip.end - 0.01), suffix: "s")
                        ProField(label: "Source Out", value: clipBinding(\.end), range: min(clip.sourceDuration, clip.start + 0.01)...clip.sourceDuration, suffix: "s")
                        Text("Duration: " + frameTimecode(clip.duration, fps: 30)).font(.system(size: 10)).foregroundStyle(ProTheme.secondary)
                    }
                    ProSection(title: "Audio") {
                        ProSlider(title: "Gain", value: clipBinding(\.gain), range: 0...2)
                        ProSlider(title: "Fade In", value: clipBinding(\.fadeIn), range: 0...max(0.01, clip.duration / 2))
                        ProSlider(title: "Fade Out", value: clipBinding(\.fadeOut), range: 0...max(0.01, clip.duration / 2))
                        ProCheck(title: "Mute", value: Binding(get: { selectedClip?.muted ?? false }, set: { value in if let i = session.document.clips.firstIndex(where: { $0.id == clip.id }) { session.mutate { $0.clips[i].muted = value } } }))
                    }
                } else { Text("Select a clip in the timeline to edit its properties.").font(.system(size: 11)).foregroundStyle(ProTheme.secondary).padding(20) }
            }
        }.background(ProTheme.panel)
    }
    var timeline: some View {
        VStack(spacing: 0) {
            HStack { Text(session.document.title).font(.system(size: 11)).foregroundStyle(ProTheme.blue); Spacer(); ProIcon(symbol: "cursorarrow", help: "Selection tool", active: !razor, size: 25) { razor = false }; ProIcon(symbol: "scissors", help: "Razor tool", active: razor, size: 25) { razor = true }; ProCheck(title: "Snap", value: $snapping); ProIcon(symbol: "minus.magnifyingglass", help: "Zoom out", size: 25) { pixelsPerSecond = max(5, pixelsPerSecond / 1.4) }; ProIcon(symbol: "plus.magnifyingglass", help: "Zoom in", size: 25) { pixelsPerSecond = min(500, pixelsPerSecond * 1.4) } }.padding(.horizontal, 10).frame(height: 31).background(ProTheme.header)
            GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        Text(frameTimecode(session.playhead, fps: 30)).font(.system(size: 15)).foregroundStyle(ProTheme.blue).frame(height: 34)
                        ForEach(Array((0..<tracks).reversed()), id: \.self) { track in trackHeader(track, audio: false) }
                        Rectangle().fill(Color(hex: "777777")).frame(height: 4)
                        ForEach(0..<tracks, id: \.self) { track in trackHeader(track, audio: true) }
                    }.frame(width: 118)
                    VStack(spacing: 0) {
                        timelineRuler
                        ForEach(Array((0..<tracks).reversed()), id: \.self) { track in trackRow(track, audio: false) }
                        Rectangle().fill(Color(hex: "777777")).frame(height: 4)
                        ForEach(0..<tracks, id: \.self) { track in trackRow(track, audio: true) }
                    }.frame(width: timelineWidth)
                }.frame(minWidth: geometry.size.width, minHeight: geometry.size.height, alignment: .topLeading)
            }.background(Color(hex: "202020"))
            }
            HStack { Text("Drag clips to move. Drag edges to trim. Drop project media onto a track."); Spacer(); Text("30 fps") }.font(.system(size: 9)).foregroundStyle(ProTheme.secondary).padding(.horizontal, 10).frame(height: 23).background(ProTheme.header)
        }
    }
    var timelineWidth: Double { max(700, (duration + 3) * pixelsPerSecond) }
    var timelineRuler: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: "292929")
            ForEach(0...min(1000, Int(timelineWidth / pixelsPerSecond)), id: \.self) { second in
                VStack(spacing: 4) { Text(frameTimecode(Double(second), fps: 30)).font(.system(size: 8)).foregroundStyle(ProTheme.secondary); Rectangle().fill(ProTheme.secondary).frame(width: 1, height: 8) }.offset(x: Double(second) * pixelsPerSecond)
            }
            Rectangle().fill(ProTheme.blue).frame(width: 1).offset(x: session.playhead * pixelsPerSecond)
        }.frame(height: 34).contentShape(Rectangle()).gesture(DragGesture(minimumDistance: 0).onChanged { seek(max(0, min(duration, $0.location.x / pixelsPerSecond))) })
    }
    func trackHeader(_ track: Int, audio: Bool) -> some View {
        HStack(spacing: 8) {
            Text("\(audio ? "A" : "V")\(track + 1)").font(.system(size: 11, weight: .medium)).foregroundStyle(ProTheme.blue).frame(width: 28, height: 27).background(Color(hex: "374552"))
            Image(systemName: audio ? "waveform" : "film").font(.system(size: 10)).foregroundStyle(ProTheme.secondary)
            Spacer()
        }.padding(.horizontal, 9).frame(height: 43).background(ProTheme.panel).overlay(alignment: .bottom) { Rectangle().fill(ProTheme.border).frame(height: 1) }
    }
    func trackRow(_ track: Int, audio: Bool) -> some View {
        ZStack(alignment: .leading) {
            Color(hex: "242424")
            ForEach(entries.filter { $0.track == track && (audio ? ($0.clip.audioOnly == true || state.waveforms[$0.clip.url]?.isEmpty == false) : $0.clip.audioOnly != true) }) { entry in
                timelineClip(entry, audio: audio).offset(x: entry.position * pixelsPerSecond)
            }
            Rectangle().fill(ProTheme.blue).frame(width: 1).offset(x: session.playhead * pixelsPerSecond).allowsHitTesting(false)
        }.frame(height: 43).overlay(alignment: .bottom) { Rectangle().fill(Color.black).frame(height: 1) }
            .onDrop(of: [.text], isTargeted: nil) { providers, location in
                guard let first = providers.first else { return false }
                _ = first.loadObject(ofClass: String.self) { value, _ in
                    guard let value, value.hasPrefix("asset:"), let id = UUID(uuidString: String(value.dropFirst(6))) else { return }
                    DispatchQueue.main.async {
                        guard var asset = session.document.mediaAssets.first(where: { $0.id == id }) else { return }
                        if audio { asset.hasVideo = false }
                        session.insertAsset(asset, at: max(0, location.x / pixelsPerSecond), track: track)
                    }
                }
                return true
            }
    }
    func timelineClip(_ entry: SequenceEntry, audio: Bool) -> some View {
        let clip = entry.clip, width = max(5, clip.duration * pixelsPerSecond)
        return ZStack(alignment: .topLeading) {
            Rectangle().fill(audio ? Color(hex: "448F75") : Color(hex: "9292C5"))
            VStack(alignment: .leading, spacing: 1) {
                Text(clip.name).font(.system(size: 9)).foregroundStyle(Color(hex: "15151C")).lineLimit(1).padding(.horizontal, 4)
                if audio { WaveformView(peaks: state.waveforms[clip.url] ?? [], color: Color(hex: "173E2E")).frame(height: 16) }
            }.padding(.top, 3)
            HStack { Rectangle().fill(.white.opacity(0.12)).frame(width: 6).gesture(trimGesture(entry, start: true)); Spacer(minLength: 0); Rectangle().fill(.white.opacity(0.12)).frame(width: 6).gesture(trimGesture(entry, start: false)) }
        }.frame(width: width, height: 35).clipped().overlay(Rectangle().stroke(session.selectedID == clip.id ? .white : .black.opacity(0.4), lineWidth: 1))
            .simultaneousGesture(SpatialTapGesture().onEnded { value in
                session.select(clip.id)
                if razor { seek(entry.position + min(clip.duration - 0.001, max(0.001, value.location.x / pixelsPerSecond))); session.splitSelectedClip() }
            })
            .gesture(DragGesture(minimumDistance: 4).onChanged { value in
                beginClipGesture(entry)
                guard let i = session.document.clips.firstIndex(where: { $0.id == clip.id }) else { return }
                let position = max(0, originalPosition + value.translation.width / pixelsPerSecond)
                session.document.clips[i].timelineStart = snapping ? (position * 30).rounded() / 30 : position
            }.onEnded { _ in endClipGesture() })
            .contextMenu { Button("Split at Playhead") { session.select(clip.id); session.splitSelectedClip() }; Button("Remove") { session.select(clip.id); session.deleteSelection() } }
    }
    func trimGesture(_ entry: SequenceEntry, start: Bool) -> some Gesture {
        DragGesture(minimumDistance: 1).onChanged { value in
            beginClipGesture(entry)
            guard let old = clipOriginal, let i = session.document.clips.firstIndex(where: { $0.id == old.id }) else { return }
            let delta = value.translation.width / pixelsPerSecond
            let minimumLength = min(1 / 30, old.duration / 2)
            if start {
                let minimumStart = max(0, old.start - originalPosition)
                let newStart = min(old.end - minimumLength, max(minimumStart, old.start + delta))
                session.document.clips[i].start = newStart
                session.document.clips[i].timelineStart = max(0, originalPosition + newStart - old.start)
            } else { session.document.clips[i].end = max(old.start + minimumLength, min(old.sourceDuration, old.end + delta)) }
        }.onEnded { _ in endClipGesture() }
    }
    func beginClipGesture(_ entry: SequenceEntry) {
        if clipOriginal == nil { clipOriginal = entry.clip; originalPosition = entry.position; session.select(entry.id); session.beginTransaction() }
    }
    func endClipGesture() { session.endTransaction(); clipOriginal = nil }
    func seek(_ time: Double) { session.playhead = time; session.player.seek(to: CMTime(seconds: time, preferredTimescale: 60000), toleranceBefore: .zero, toleranceAfter: .zero) }
    func clipBinding(_ key: WritableKeyPath<MediaClip, Double>) -> Binding<Double> {
        Binding(get: { selectedClip?[keyPath: key] ?? 0 }, set: { value in
            guard let i = session.document.clips.firstIndex(where: { $0.id == session.selectedID }) else { return }
            session.mutate { $0.clips[i][keyPath: key] = value }
        })
    }
    func transformBinding(_ key: WritableKeyPath<VideoTransform, Double>) -> Binding<Double> {
        let offset = key == \VideoTransform.x ? 960.0 : key == \VideoTransform.y ? 540.0 : 0.0
        let factor = key == \VideoTransform.scale || key == \VideoTransform.opacity ? 100.0 : 1.0
        return Binding(get: { (selectedClip?.videoTransform ?? VideoTransform())[keyPath: key] * factor + offset }, set: { value in
            guard let i = session.document.clips.firstIndex(where: { $0.id == session.selectedID }) else { return }
            session.mutate { var transform = $0.clips[i].videoTransform ?? VideoTransform(); transform[keyPath: key] = (value - offset) / factor; $0.clips[i].videoTransform = transform }
        })
    }
    func generateSample() {
        session.busy = true
        Task { @MainActor in
            defer { session.busy = false }
            do {
                let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("DevinCreative/Samples")
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let url = folder.appendingPathComponent("Motion study-" + UUID().uuidString.prefix(8) + ".mp4")
                var sample = Samples.document(for: .motion); sample.width = 1280; sample.height = 720
                try await ExportService.renderMotion(sample, to: url, progress: { _ in })
                let asset = MediaAsset(url: url, duration: sample.duration, hasVideo: true)
                let existing = session.document.mediaAssets
                session.mutate { $0.assets = existing + [asset] }
                state.openSource(asset); session.insertAsset(asset)
            } catch { session.error = error.localizedDescription }
        }
    }
}
