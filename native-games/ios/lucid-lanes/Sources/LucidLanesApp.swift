import LinkPresentation
import SwiftUI
import UIKit

@main
struct LucidLanesApp: App {
    @StateObject private var model = GameModel()
    var body: some Scene {
        WindowGroup { ContentView(model: model).preferredColorScheme(.dark) }
    }
}

struct ContentView: View {
    @ObservedObject var model: GameModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showRooms = false
    @State private var showSettings = false
    @State private var sharePayload: SharePayload?
    @State private var shareFailed = false
    private let timer = Timer.publish(every: 1.0 / 60, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Dream.ink.ignoresSafeArea()
                if model.screen != "result" {
                    LaneArtwork(model: model, hero: model.screen == "home").ignoresSafeArea()
                }
                if model.screen == "home" { home(compact: geometry.size.height < 700) }
                if model.screen == "play" { play(size: geometry.size) }
                if model.screen == "result" { result }
                if model.screen == "play" && model.tutorial { tutorial }
                if model.screen == "play" && model.paused && !model.tutorial { pause }
            }
        }
        .tint(Dream.mint)
        .foregroundStyle(Dream.cream)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .onReceive(timer) { model.tick($0, reduceMotion: reduceMotion) }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active && model.screen == "play" { model.paused = true }
        }
        .sheet(isPresented: $showRooms) { rooms }
        .sheet(isPresented: $showSettings) { settings }
        .sheet(item: $sharePayload) { payload in
            NativeShare(payload: payload).presentationDetents([.large])
        }
        .alert("Your dream couldn't be prepared", isPresented: $shareFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try sharing again.")
        }
    }

    private func home(compact: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("THE DREAM HOTEL").font(.system(size: 10, weight: .semibold)).tracking(3)
                Spacer()
                iconButton("slider.horizontal.3", label: "Settings", id: "settings") { showSettings = true }
            }
            .padding(.horizontal, 26)
            VStack(spacing: 1) {
                Text("Lucid").font(.system(size: compact ? 46 : 65, weight: .regular, design: .serif)).tracking(-3)
                Text("LANES").font(.system(size: compact ? 20 : 26, weight: .light)).tracking(13).padding(.leading, 13)
                Text("BOWLING, SOMEWHERE ELSE.").font(.system(size: 9, weight: .medium))
                    .tracking(2.5).foregroundStyle(Dream.lavender).padding(.top, compact ? 8 : 15)
            }
            .padding(.top, compact ? 0 : 8)
            Spacer()
            VStack(spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 5) {
                        eyebrow("YOUR NEXT DREAM · \(String(format: "%02d", model.unlocked + 1))")
                        Text(Lane.all[model.unlocked].name).font(.system(size: 25, design: .serif))
                    }
                    Spacer()
                    Text("\(model.best.filter { $0 > 0 }.count)/8")
                        .font(.system(size: 15, design: .monospaced)).foregroundStyle(Dream.lavender)
                }
                primary("Enter the lanes", symbol: "arrow.up.right", id: "enter-lanes") {
                    model.start(lane: model.unlocked)
                }
                HStack(spacing: 12) {
                    secondary("The eight rooms", id: "rooms") { showRooms = true }
                    secondary("Practice", id: "practice") { model.start(lane: 0, practice: true) }
                }
                Text("THREE FRAMES. A LITTLE MAGIC.").font(.system(size: 9)).tracking(2)
                    .foregroundStyle(Dream.muted).padding(.top, 3)
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [.clear, Dream.ink.opacity(0.95), Dream.ink],
                    startPoint: .top, endPoint: .bottom))
        }
    }

    private func play(size: CGSize) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { value in
                            guard model.phase == "ready", !model.paused, !model.tutorial else { return }
                            model.dragging = true
                            model.aim = max(-1, min(1, value.translation.width / (size.width * 0.42)))
                            model.power = max(0.1, min(1, -value.translation.height / 210))
                        }
                        .onEnded { value in
                            if value.translation.height < -25 { model.launch() }
                            model.dragging = false
                        }
                )
                .accessibilityLabel("Bowling aim")
                .accessibilityValue("\(Int(model.aim * 100)) percent \(model.aim < 0 ? "left" : "right")")
                .accessibilityHint("Swipe up or down to adjust aim, then use the Bowl button")
                .accessibilityAdjustableAction { direction in
                    guard model.phase == "ready" else { return }
                    model.aim = max(-1, min(1, model.aim + (direction == .increment ? 0.1 : -0.1)))
                }
                .accessibilityIdentifier("bowling-playfield")
                .padding(.top, 140).padding(.bottom, 170)
            VStack(spacing: 0) {
                HStack {
                    iconButton("arrow.left", label: "Pause and exit options", id: "back") { model.paused = true }
                    Spacer()
                    VStack(spacing: 5) {
                        eyebrow(
                            model.practice
                                ? "PRACTICE · NO PRESSURE" : "ROOM \(String(format: "%02d", model.selectedLane + 1))")
                        Text(model.lane.name).font(.system(size: 23, design: .serif))
                    }
                    Spacer()
                    iconButton("pause", label: "Pause", id: "pause") { model.paused = true }
                }
                .padding(.horizontal, 17)
                HStack(spacing: 0) {
                    ForEach(0..<3) { i in
                        VStack(spacing: 6) {
                            Text("FRAME \(i + 1)").font(.system(size: 10, weight: .medium)).tracking(1)
                                .foregroundStyle(Dream.muted)
                            Text(model.game.symbols(for: i)).font(
                                .system(size: 20, weight: .medium, design: .monospaced)
                            )
                            .foregroundStyle(i == model.game.frames.count - 1 ? Dream.mint : Dream.cream)
                        }.frame(maxWidth: .infinity)
                    }
                    Rectangle().fill(Dream.lavender.opacity(0.25)).frame(width: 1, height: 36)
                    VStack(spacing: 2) {
                        Text("\(model.game.score)").font(.system(size: 29, weight: .light, design: .serif))
                        Text("SCORE").font(.system(size: 10)).tracking(1).foregroundStyle(Dream.muted)
                    }.frame(maxWidth: .infinity)
                }
                .padding(.vertical, 13).padding(.horizontal, 20)
                .background(Dream.ink.opacity(0.78))
                HStack {
                    Text(model.lane.bumper ? "BUMPER RAILS" : "OPEN GUTTERS")
                    Spacer()
                    Text("BRONZE \(model.lane.bronze) · GOLD \(model.lane.gold)")
                }
                .font(.system(size: 10, weight: .medium)).tracking(0.5)
                .foregroundStyle(Dream.lavender).padding(.horizontal, 27).padding(.top, 10)
                Spacer()
                VStack(spacing: 12) {
                    Text(model.dragging ? "POWER \(Int(model.power * 100))%" : model.message.uppercased())
                        .font(
                            .system(
                                size: model.phase == "settling" ? 25 : 11, weight: .medium,
                                design: model.phase == "settling" ? .serif : .default)
                        )
                        .tracking(model.phase == "settling" ? 5 : 2)
                        .foregroundStyle(model.phase == "settling" ? Dream.peach : Dream.mint)
                        .accessibilityIdentifier("shot-status")
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("CURVE").tracking(2)
                                Spacer()
                                Text(model.curve < -0.1 ? "LEFT" : model.curve > 0.1 ? "RIGHT" : "STRAIGHT").tracking(1)
                            }.font(.system(size: 9, weight: .medium)).foregroundStyle(Dream.lavender)
                            Slider(value: $model.curve, in: -1...1, step: 0.1)
                                .accessibilityLabel("Curve").accessibilityIdentifier("curve")
                                .disabled(model.phase != "ready")
                        }
                        Button {
                            model.curve = 0
                        } label: {
                            Image(systemName: "scope").font(.system(size: 20))
                                .frame(width: 44, height: 44)
                                .background(Dream.velvet, in: Circle())
                                .foregroundStyle(Dream.lavender)
                        }
                        .accessibilityLabel("Reset curve to straight").accessibilityIdentifier("curve-reset")
                        .disabled(model.phase != "ready")
                        Button {
                            model.launch()
                        } label: {
                            Image(systemName: "arrow.up").font(.system(size: 22))
                                .frame(width: 52, height: 52).background(Dream.mint, in: Circle())
                                .foregroundStyle(Dream.ink)
                        }
                        .accessibilityLabel("Bowl with current aim and power").accessibilityIdentifier("bowl")
                        .disabled(model.phase != "ready")
                    }
                    Text(
                        model.phase == "ready"
                            ? "Drag up to aim & bowl · longer drag, more power" : "Let the corridor do its work"
                    )
                    .font(.system(size: 11)).foregroundStyle(Dream.lavender)
                }
                .padding(.horizontal, 27).padding(.bottom, 16).padding(.top, 16)
                .background(
                    LinearGradient(colors: [.clear, Dream.ink, Dream.ink], startPoint: .top, endPoint: .bottom))
            }
        }
    }

    private var result: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    eyebrow("THE DREAM HOTEL")
                    Spacer()
                    iconButton("xmark", label: "Return home", id: "result-home") { model.screen = "home" }
                }
                ResultCard(lane: model.lane, score: model.game.score, medal: model.medal, frames: model.game)
                Text(
                    model.medal == "NO MEDAL"
                        ? "The corridor has another dream for you." : "Some dreams are worth keeping."
                )
                .font(.system(size: 18, design: .serif)).foregroundStyle(Dream.lavender)
                .multilineTextAlignment(.center)
                HStack {
                    Text(model.practice ? "PRACTICE COMPLETE" : "PERSONAL BEST")
                    Spacer()
                    Text(model.practice ? "TRY A CHALLENGE" : "\(model.best[model.selectedLane]) POINTS")
                }.font(.system(size: 9, weight: .medium)).tracking(1.2).foregroundStyle(Dream.muted)
                primary("Share this dream", symbol: "square.and.arrow.up", id: "share") {
                    let card = ResultCard(
                        lane: model.lane, score: model.game.score, medal: model.medal, frames: model.game
                    )
                    .frame(width: 390).padding(30).background(Dream.ink).environment(\.colorScheme, .dark)
                    let renderer = ImageRenderer(content: card)
                    renderer.scale = 3
                    if let image = renderer.uiImage {
                        sharePayload = SharePayload(
                            image: image,
                            text: "Lucid Lanes · \(model.lane.name) · \(model.game.score) points · \(model.medal)"
                        )
                    } else {
                        shareFailed = true
                    }
                }
                HStack(spacing: 12) {
                    secondary("Dream again", id: "replay") {
                        model.start(lane: model.selectedLane, practice: model.practice)
                    }
                    if !model.practice && model.medal != "NO MEDAL" && model.selectedLane < 7 {
                        secondary("Next room →", id: "next-room") { model.start(lane: model.selectedLane + 1) }
                    } else {
                        secondary("All rooms", id: "result-rooms") { showRooms = true }
                    }
                }
            }.padding(25)
        }.background(Dream.ink)
    }

    private var tutorial: some View {
        overlayPanel {
            VStack(alignment: .leading, spacing: 22) {
                eyebrow("A NOTE FROM THE CONCIERGE")
                Text("Stay a little.\nRoll a dream.").font(.system(size: 37, design: .serif))
                tutorialRow(
                    "hand.draw", title: "Draw your line",
                    text: "Drag upward on the lane. Move left or right to aim; drag longer for power.")
                tutorialRow(
                    "arrow.turn.up.right", title: "Give it a curve",
                    text: "Set the curve before each roll. The dotted line shows your opening path.")
                tutorialRow(
                    "sparkle", title: "Three frames, ten pins",
                    text:
                        "Two rolls per frame. Strikes add your next two rolls; spares add the next. Earn bronze to open a room."
                )
                primary("I'm ready to dream", symbol: "arrow.up.right", id: "tutorial-done") { model.dismissTutorial() }
            }
        }
    }

    private var pause: some View {
        overlayPanel {
            VStack(alignment: .leading, spacing: 20) {
                eyebrow("DO NOT DISTURB")
                Text("Dream on hold.").font(.system(size: 36, design: .serif))
                Text(model.lane.advice).font(.system(size: 15)).foregroundStyle(Dream.lavender)
                primary("Resume", symbol: "play", id: "resume") { model.paused = false }
                secondary("Restart three frames", id: "restart") {
                    model.start(lane: model.selectedLane, practice: model.practice)
                }
                secondary("Return to the lobby", id: "exit") {
                    model.screen = "home"
                    model.paused = false
                }
            }
        }
    }

    private var rooms: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Eight rooms.\nInfinite possibilities.").font(.system(size: 33, design: .serif)).padding(
                        .bottom, 12)
                    Text("Earn a bronze medal to unlock the next corridor.")
                        .font(.system(size: 12)).foregroundStyle(Dream.lavender).padding(.bottom, 28)
                    ForEach(Lane.all) { lane in
                        Button {
                            showRooms = false
                            model.start(lane: lane.id)
                        } label: {
                            HStack(spacing: 18) {
                                Text(String(format: "%02d", lane.id + 1)).font(
                                    .system(size: 29, weight: .light, design: .serif)
                                )
                                .foregroundStyle(lane.id <= model.unlocked ? Dream.peach : Dream.muted)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(lane.name).font(.system(size: 20, design: .serif))
                                    Text(lane.subtitle).font(.system(size: 11)).foregroundStyle(Dream.muted)
                                    if model.best[lane.id] > 0 {
                                        Text("\(lane.medal(score: model.best[lane.id])) · BEST \(model.best[lane.id])")
                                            .font(.system(size: 8, weight: .medium)).tracking(1).foregroundStyle(
                                                Dream.mint)
                                    }
                                }
                                Spacer()
                                Image(systemName: lane.id <= model.unlocked ? "arrow.up.right" : "lock")
                                    .font(.system(size: 14)).foregroundStyle(Dream.lavender)
                            }.padding(.vertical, 20)
                        }
                        .disabled(lane.id > model.unlocked)
                        .accessibilityLabel(
                            "\(lane.name), \(lane.id <= model.unlocked ? "available" : "locked"), best \(model.best[lane.id])"
                        )
                        .accessibilityIdentifier("lane-\(lane.id)")
                        Rectangle().fill(Dream.lavender.opacity(0.17)).frame(height: 1)
                    }
                }.padding(25)
            }
            .background(Dream.ink)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showRooms = false }.accessibilityIdentifier("rooms-done")
                }
            }
        }.tint(Dream.mint).preferredColorScheme(.dark)
    }

    private var settings: some View {
        NavigationStack {
            Form {
                Section("THE ATMOSPHERE") {
                    Toggle("Sound", isOn: $model.sound).accessibilityIdentifier("sound")
                    Toggle("Haptics", isOn: $model.haptics).accessibilityIdentifier("haptics")
                }
                Section("HOW TO PLAY") {
                    Text(
                        "Three frames use standard ten-pin scoring, including bonus rolls in the last frame. A perfect game is 90."
                    )
                    Text("Strike: 10 + next two rolls. Spare: 10 + next roll. Open frame: pins knocked down.")
                    Text(
                        "Aim by dragging upward. Set one curve per roll with the slider. The arrow button bowls with your current aim and power."
                    )
                    Button("Show the welcome lesson") {
                        showSettings = false
                        model.tutorial = true
                        model.start(lane: 0, practice: true)
                    }.accessibilityIdentifier("show-tutorial")
                }
                Section("YOUR STAY") {
                    Text("Progress stays on this device. No accounts, ads or online leaderboards.")
                    Text("Lucid Lanes · 1.0").foregroundStyle(Dream.muted)
                }
            }
            .navigationTitle("Room service")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showSettings = false }.accessibilityIdentifier("settings-done")
                }
            }
        }.tint(Dream.mint).preferredColorScheme(.dark)
    }

    private func overlayPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Dream.ink.opacity(0.9).ignoresSafeArea()
            ScrollView {
                content().padding(28)
                    .background(Dream.velvet, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Dream.peach.opacity(0.3), lineWidth: 1))
                    .padding(22)
            }.defaultScrollAnchor(.center)
        }
    }

    private func tutorialRow(_ symbol: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol).foregroundStyle(Dream.peach).font(.system(size: 22)).frame(width: 27)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 16, weight: .medium))
                Text(text).font(.system(size: 12)).lineSpacing(3).foregroundStyle(Dream.lavender)
            }
        }
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text).font(.system(size: 9, weight: .medium)).tracking(2).foregroundStyle(Dream.lavender)
    }

    private func primary(_ title: String, symbol: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(size: 16, weight: .medium))
                Spacer()
                Image(systemName: symbol).font(.system(size: 17))
            }.padding(.horizontal, 20).frame(minHeight: 56)
                .background(Dream.peach, in: RoundedRectangle(cornerRadius: 4)).foregroundStyle(Dream.ink)
        }.accessibilityIdentifier(id)
    }

    private func secondary(_ title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 12, weight: .medium)).frame(maxWidth: .infinity, minHeight: 48)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Dream.lavender.opacity(0.3), lineWidth: 1))
        }.accessibilityIdentifier(id)
    }

    private func iconButton(_ symbol: String, label: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 17)).frame(width: 44, height: 44) }
            .accessibilityLabel(label).accessibilityIdentifier(id)
    }
}

struct ResultCard: View {
    let lane: Lane
    let score: Int
    let medal: String
    let frames: BowlingGame

    var body: some View {
        VStack(spacing: 20) {
            Text("LUCID  /  LANES").font(.system(size: 10, weight: .medium)).tracking(4).foregroundStyle(Dream.lavender)
            ZStack {
                ForEach(0..<4) { i in
                    RoundedRectangle(cornerRadius: 100)
                        .stroke(Dream.peach.opacity(0.12 + Double(i) * 0.1), lineWidth: 1)
                        .frame(width: 160 + Double(i) * 24, height: 185 + Double(i) * 23)
                }
                VStack(spacing: 3) {
                    Image(systemName: score >= lane.bronze ? "sparkle" : "moon")
                        .font(.system(size: 22)).foregroundStyle(Dream.peach).padding(.bottom, 5)
                    Text("\(score)").font(.system(size: 88, weight: .regular, design: .serif)).tracking(-5)
                    Text("POINTS").font(.system(size: 9)).tracking(4).foregroundStyle(Dream.lavender)
                }
            }.frame(height: 270)
            Text(medal == "NO MEDAL" ? "A DREAM IN PROGRESS" : "\(medal) REVERIE")
                .font(.system(size: 11, weight: .medium)).tracking(3).foregroundStyle(Dream.mint)
            VStack(spacing: 8) {
                Text(lane.name).font(.system(size: 30, design: .serif))
                Text("ROOM \(String(format: "%02d", lane.id + 1))  ·  \(lane.subtitle.uppercased())")
                    .font(.system(size: 8)).tracking(1).foregroundStyle(Dream.muted).multilineTextAlignment(.center)
            }
            HStack {
                ForEach(0..<3) { i in
                    VStack(spacing: 8) {
                        Text("FRAME \(i + 1)").font(.system(size: 8)).tracking(1).foregroundStyle(Dream.muted)
                        Text(frames.symbols(for: i)).font(.system(size: 19, design: .monospaced))
                    }.frame(maxWidth: .infinity)
                }
            }.padding(.vertical, 18)
                .overlay(alignment: .top) { Rectangle().fill(Dream.lavender.opacity(0.2)).frame(height: 1) }
            if medal == "NO MEDAL" {
                Text("\(lane.bronze) points earns bronze. Stay for another round.")
                    .font(.system(size: 11)).foregroundStyle(Dream.lavender)
            }
        }.foregroundStyle(Dream.cream).padding(.top, 10)
    }
}

struct SharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
    let text: String
}

final class ShareImage: NSObject, UIActivityItemSource {
    let payload: SharePayload

    init(payload: SharePayload) {
        self.payload = payload
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        payload.image
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        payload.image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = payload.text
        metadata.imageProvider = NSItemProvider(object: payload.image)
        metadata.iconProvider = NSItemProvider(object: payload.image)
        return metadata
    }
}

struct NativeShare: UIViewControllerRepresentable {
    let payload: SharePayload
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [ShareImage(payload: payload), payload.text], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
