import SwiftUI
import AVKit
import DevinCore

struct NativePlayer: NSViewRepresentable {
    let player: AVPlayer
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView(); view.player = player; view.controlsStyle = .none; view.videoGravity = .resizeAspect
        return view
    }
    func updateNSView(_ view: AVPlayerView, context: Context) { view.player = player }
}

struct WaveformView: View {
    var peaks: [Float]
    var color: Color = Theme.accent
    var body: some View {
        Canvas { context, size in
            guard !peaks.isEmpty else { return }
            let step = size.width / CGFloat(peaks.count)
            var path = Path()
            for (index, peak) in peaks.enumerated() {
                let height = max(1, CGFloat(peak) * size.height * 0.9)
                path.move(to: CGPoint(x: CGFloat(index) * step, y: (size.height - height) / 2))
                path.addLine(to: CGPoint(x: CGFloat(index) * step, y: (size.height + height) / 2))
            }
            context.stroke(path, with: .color(color), lineWidth: max(1, step * 0.65))
        }
    }
}

struct MediaWorkspace: View {
    @ObservedObject var session: StudioSession
    @State private var waveforms: [URL: [Float]] = [:]
    @State private var preparing = false
    @State private var generation = UUID()
    @State private var previewTask: Task<Void, Never>?
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    var isAudio: Bool { session.tool == .sound }
    var duration: Double { session.document.sequenceDuration }
    var selected: MediaClip? { session.document.clips.first { $0.id == session.selectedID } }
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack { Text(isAudio ? "Audio files" : "Media bin").font(.system(size: 12, weight: .semibold)); Spacer(); IconButton(symbol: "plus", help: "Import media") { session.importFiles() } }.padding(.horizontal, 14).frame(height: 46)
                ScrollView {
                    VStack(spacing: 7) {
                        ForEach(session.document.clips) { clip in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack { Image(systemName: isAudio ? "waveform" : "film").foregroundStyle(Color(hex: session.tool.color)); Text(clip.name).font(.system(size: 11, weight: .medium)).lineLimit(1); Spacer() }
                                if isAudio { WaveformView(peaks: waveforms[clip.url] ?? []).frame(height: 34) }
                                HStack { Text(timecode(clip.duration)); Spacer(); Text(clip.url.pathExtension.uppercased()) }.font(.system(size: 9, design: .monospaced)).foregroundStyle(Theme.muted)
                            }.padding(12).background(session.selectedID == clip.id ? Theme.accent.opacity(0.08) : Theme.panel, in: RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(session.selectedID == clip.id ? Theme.accent.opacity(0.3) : Theme.line))
                                .onTapGesture { session.selectedID = clip.id }
                                .contextMenu { Button("Remove clip") { session.selectedID = clip.id; session.deleteSelection() } }
                        }
                    }.padding(10)
                }
                if isAudio {
                    Button("Generate demo audio") { generateDemo() }.buttonStyle(StudioButtonStyle()).padding(12)
                }
                Text("Source files stay in their original locations. Keep them with your project.").font(.system(size: 10)).foregroundStyle(Theme.muted).lineSpacing(3).padding(14)
            }.frame(width: 210).background(Theme.sidebar)
            VStack(spacing: 0) {
                if session.document.clips.isEmpty {
                    EmptyWorkspace(symbol: isAudio ? "waveform" : "film.stack", title: isAudio ? "Every sound starts somewhere." : "Your story starts here.", description: isAudio ? "Import an audio file, or generate demo audio to try trimming, gain, fades, and WAV export." : "Import video clips, arrange your sequence, and shape the story. Export a 1080p H.264 movie.", button: isAudio ? "Import audio" : "Import video") { session.importFiles() }
                } else {
                    ZStack {
                        Color(hex: "0C0E0D")
                        if isAudio {
                            VStack(spacing: 24) {
                                HStack { Text(selected?.name ?? "Sequence").font(.system(size: 16, weight: .medium)); Spacer(); Text("SOURCE WAVEFORM").font(.system(size: 9)).tracking(1.5).foregroundStyle(Theme.muted) }
                                GeometryReader { geo in
                                    if let clip = selected {
                                        ZStack(alignment: .leading) {
                                            WaveformView(peaks: waveforms[clip.url] ?? [], color: Theme.accent.opacity(0.75))
                                            Rectangle().fill(Color.black.opacity(0.6)).frame(width: geo.size.width * clip.start / clip.sourceDuration)
                                            Rectangle().fill(Color.black.opacity(0.6)).frame(width: geo.size.width * (1 - clip.end / clip.sourceDuration)).frame(maxWidth: .infinity, alignment: .trailing)
                                            Rectangle().fill(Theme.accent).frame(width: 1).offset(x: geo.size.width * clip.start / clip.sourceDuration)
                                            Rectangle().fill(Theme.accent).frame(width: 1).offset(x: geo.size.width * clip.end / clip.sourceDuration)
                                        }
                                    }
                                }.frame(height: 190)
                                HStack { Text("IN  \(timecode(selected?.start ?? 0))"); Spacer(); Text("OUT  \(timecode(selected?.end ?? 0))") }.font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.muted)
                            }.padding(35)
                        } else { NativePlayer(player: session.player) }
                        if preparing { ProgressView().padding(16).background(Theme.panel, in: RoundedRectangle(cornerRadius: 8)) }
                    }
                }
                transport
                timeline
            }
            inspector.frame(width: 246).background(Theme.sidebar)
        }
        .onAppear { if session.selectedID == nil { session.selectedID = session.document.clips.first?.id }; rebuild() }
        .onChange(of: session.document.clips) { _, _ in rebuild() }
        .onChange(of: session.isPlaying) { _, playing in if playing { session.player.play() } else { session.player.pause() } }
        .onReceive(timer) { _ in
            if session.isPlaying {
                let time = session.player.currentTime().seconds
                if time.isFinite { session.playhead = time }
                if session.playhead >= duration - 0.03 { session.isPlaying = false }
            }
        }
        .onDisappear { previewTask?.cancel(); session.player.pause(); session.isPlaying = false }
    }
    var transport: some View {
        HStack(spacing: 12) {
            Text(timecode(session.playhead)).font(.system(size: 13, design: .monospaced)).foregroundStyle(Theme.accent).frame(width: 94)
            Spacer()
            IconButton(symbol: "backward.end.fill", help: "Return to start") { seek(0) }
            IconButton(symbol: session.isPlaying ? "pause.fill" : "play.fill", help: "Play / pause") {
                if session.playhead >= duration - 0.05 { seek(0) }
                session.isPlaying.toggle()
            }.disabled(session.document.clips.isEmpty || preparing)
            IconButton(symbol: "scissors", help: "Split selected clip at playhead") { split() }.disabled(selected == nil)
            Spacer()
            Text("\(timecode(duration))  /  \(isAudio ? "48 kHz" : "1080p · 30 fps")").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.muted)
        }.padding(.horizontal, 18).frame(height: 50).background(Theme.panel)
    }
    var timeline: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text("SEQUENCE").font(.system(size: 9, weight: .semibold)).tracking(1.6); Spacer(); Text("\(session.document.clips.count) CLIPS").font(.system(size: 9, design: .monospaced)) }.foregroundStyle(Theme.muted)
            Slider(value: Binding(get: { min(session.playhead, max(0.1, duration)) }, set: { seek($0) }), in: 0...max(0.1, duration)).tint(Theme.accent).disabled(duration == 0)
            ScrollView([.horizontal, .vertical]) {
                let entries = SequenceLayout.entries(session.document.clips)
                let tracks = max(2, (entries.map(\.track).max() ?? 0) + 1)
                VStack(spacing: 3) {
                    ForEach(0..<tracks, id: \.self) { track in
                        HStack(spacing: 8) {
                            Text("A\(track + 1)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.muted).frame(width: 28)
                            ZStack(alignment: .leading) {
                                Theme.panel
                                ForEach(entries.filter { $0.track == track }) { entry in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.clip.name).font(.system(size: 9)).lineLimit(1)
                                        WaveformView(peaks: waveforms[entry.clip.url] ?? [], color: Theme.accent).frame(height: 22)
                                    }.padding(4).frame(width: max(12, entry.clip.duration * 45), height: 43).clipped()
                                        .background(Theme.accent.opacity(0.15)).border(session.selectedID == entry.id ? Theme.accent : .clear)
                                        .offset(x: entry.position * 45).onTapGesture { session.select(entry.id); seek(entry.position) }
                                }
                                Rectangle().fill(Theme.accent).frame(width: 1).offset(x: session.playhead * 45)
                            }.frame(width: max(650, (duration + 1) * 45), height: 45)
                        }
                    }
                }
            }
            HStack { Text("Use the inspector to position clips and assign audio tracks."); Spacer(); Text("NON-DESTRUCTIVE") }.font(.system(size: 9)).foregroundStyle(Theme.muted)
        }.padding(18).frame(height: 205).background(Theme.background)
    }
    var inspector: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack { Text("Clip properties").font(.system(size: 12, weight: .semibold)); Spacer() }.padding(18).frame(height: 46)
                if let clip = selected {
                    InspectorSection(title: "Source") {
                        Text(clip.name).font(.system(size: 12, weight: .medium))
                        Text(clip.url.lastPathComponent).font(.system(size: 10)).foregroundStyle(Theme.muted).textSelection(.enabled)
                        Text("Source duration  \(timecode(clip.sourceDuration))").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.muted)
                    }
                    InspectorSection(title: "Trim") {
                        NumberField(label: "In (s)", value: clipBinding(\.start), range: 0...max(0, clip.end - 0.01))
                        NumberField(label: "Out (s)", value: clipBinding(\.end), range: min(clip.sourceDuration, clip.start + 0.01)...clip.sourceDuration)
                        LabeledSlider(title: "In point", value: clipBinding(\.start), range: 0...max(0.001, clip.end - 0.01))
                        LabeledSlider(title: "Out point", value: clipBinding(\.end), range: min(clip.sourceDuration - 0.001, clip.start + 0.01)...clip.sourceDuration)
                        Text("Selection  \(timecode(clip.duration))").font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.accent)
                    }
                    InspectorSection(title: "Audio") {
                        LabeledSlider(title: "Gain", value: clipBinding(\.gain), range: 0...2)
                        LabeledSlider(title: "Fade in (s)", value: clipBinding(\.fadeIn), range: 0...max(0.01, clip.duration / 2))
                        LabeledSlider(title: "Fade out (s)", value: clipBinding(\.fadeOut), range: 0...max(0.01, clip.duration / 2))
                    }
                    InspectorSection(title: "Sequence") {
                        NumberField(label: "Start (s)", value: Binding(get: { offset(of: clip) }, set: { value in position(clip.id, at: value) }), range: 0...86400)
                        Picker("Track", selection: Binding(get: { clip.trackIndex ?? 0 }, set: { value in if let i = session.document.clips.firstIndex(where: { $0.id == clip.id }) { session.mutate { $0.clips[i].trackIndex = value } } })) { ForEach(0..<8, id: \.self) { Text("A\($0 + 1)").tag($0) } }
                        Toggle("Mute", isOn: Binding(get: { clip.muted ?? false }, set: { value in if let i = session.document.clips.firstIndex(where: { $0.id == clip.id }) { session.mutate { $0.clips[i].muted = value } } })).toggleStyle(.checkbox)
                        HStack {
                            Button("Earlier") { move(-1) }.buttonStyle(StudioButtonStyle())
                            Button("Later") { move(1) }.buttonStyle(StudioButtonStyle())
                        }
                        Button("Split at playhead") { split() }.buttonStyle(StudioButtonStyle())
                        Button("Remove clip") { session.deleteSelection() }.buttonStyle(StudioButtonStyle())
                    }
                } else {
                    InspectorSection(title: "No clip selected") { Text("Import media and select a clip to edit its properties.").font(.system(size: 11)).foregroundStyle(Theme.muted) }
                }
            }
        }
    }
    func clipBinding(_ key: WritableKeyPath<MediaClip, Double>) -> Binding<Double> {
        Binding(get: { selected?[keyPath: key] ?? 0 }, set: { value in
            guard let index = session.document.clips.firstIndex(where: { $0.id == session.selectedID }), value.isFinite else { return }
            session.mutate { d in
                d.clips[index][keyPath: key] = value
                d.clips[index].start = max(0, min(d.clips[index].start, d.clips[index].sourceDuration - 0.01))
                d.clips[index].end = min(d.clips[index].sourceDuration, max(d.clips[index].start + 0.01, d.clips[index].end))
                d.clips[index].fadeIn = min(d.clips[index].fadeIn, d.clips[index].duration / 2)
                d.clips[index].fadeOut = min(d.clips[index].fadeOut, d.clips[index].duration / 2)
            }
        })
    }
    func offset(of clip: MediaClip) -> Double { SequenceLayout.entries(session.document.clips).first { $0.id == clip.id }?.position ?? 0 }
    func seek(_ time: Double) { session.playhead = time; session.player.seek(to: CMTime(seconds: time, preferredTimescale: 60000), toleranceBefore: .zero, toleranceAfter: .zero) }
    func position(_ id: UUID, at time: Double) {
        let entries = SequenceLayout.entries(session.document.clips)
        session.mutate { d in
            for i in d.clips.indices { d.clips[i].timelineStart = d.clips[i].id == id ? max(0, time) : entries[i].position }
        }
    }
    func move(_ direction: Int) { if let clip = selected { position(clip.id, at: offset(of: clip) + Double(direction) * 0.5) } }
    func split() { session.splitSelectedClip() }
    func rebuild() {
        previewTask?.cancel(); session.player.pause(); session.isPlaying = false
        let token = UUID(); generation = token
        let clips = session.document.clips
        guard !clips.isEmpty else { session.player.replaceCurrentItem(with: nil); preparing = false; return }
        preparing = true
        previewTask = Task { @MainActor in
            do {
                let media = try await MediaEngine.compose(clips, video: !isAudio)
                try Task.checkCancellation()
                guard generation == token else { return }
                let item = AVPlayerItem(asset: media.composition); item.videoComposition = media.video; item.audioMix = media.audio
                session.player.replaceCurrentItem(with: item); seek(min(session.playhead, duration)); preparing = false
                for clip in clips where isAudio && waveforms[clip.url] == nil {
                    let peaks = try await MediaEngine.waveform(url: clip.url)
                    try Task.checkCancellation(); waveforms[clip.url] = peaks
                }
            } catch is CancellationError { }
            catch { if generation == token { preparing = false; session.error = error.localizedDescription } }
        }
    }
    func generateDemo() {
        do {
            let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("DevinCreative/Samples")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent("Sundown study.wav")
            if !FileManager.default.fileExists(atPath: url.path) { try MediaEngine.createTone(at: url) }
            session.importURLs([url])
        } catch { session.error = error.localizedDescription }
    }
}
