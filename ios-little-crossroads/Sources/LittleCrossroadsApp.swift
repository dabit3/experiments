import SceneKit
import SwiftUI

@main
struct LittleCrossroadsApp: App {
    var body: some Scene {
        WindowGroup { CrossroadsView() }
    }
}

private enum Palette {
    static let ink = Color(uiColor: ToyColor.dark)
    static let navy = Color(uiColor: ToyColor.navy)
    static let royal = Color(uiColor: ToyColor.royal)
    static let sky = Color(uiColor: ToyColor.sky)
    static let white = Color(uiColor: ToyColor.cream)
    static let yellow = Color(uiColor: ToyColor.yellow)
    static let honey = Color(red: 0.72, green: 0.50, blue: 0.02)
    static let coral = Color(uiColor: ToyColor.coral)
    static let brick = Color(red: 0.55, green: 0.10, blue: 0.02)
    static let mint = Color(uiColor: ToyColor.mint)
    static let gray = Color(uiColor: ToyColor.curb)
    static let slate = Color(red: 0.36, green: 0.36, blue: 0.40)
    static let steel = Color(red: 0.16, green: 0.16, blue: 0.20)
}

private extension Font {
    static func body(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

struct CrossroadsView: View {
    @StateObject private var store = GameStore()
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 380
            ZStack {
                NativeWorld(store: store).ignoresSafeArea()
                    .accessibilityLabel("Little Crossroads countryside")
                VStack(spacing: 0) {
                    if store.state == .ready {
                        titleHeader(compact: compact)
                    } else {
                        gameHeader
                    }
                    Spacer(minLength: 0)
                    if store.state == .ready {
                        startPanel
                    } else if store.state == .playing {
                        controls(compact: compact)
                    }
                }
                .padding(.horizontal, compact ? 14 : 18)
                .padding(.top, 6)
                .padding(.bottom, 8)
                if store.state == .paused {
                    pauseCard
                }
                if store.state == .finished, store.showResults {
                    resultCard
                }
            }
            .sheet(isPresented: $store.showWardrobe) { wardrobe }
            .sheet(isPresented: $store.showGuide) { guide }
            .onChange(of: phase) { _, new in
                if new != .active {
                    store.pause()
                }
            }
            .onChange(of: reducedMotion, initial: true) { _, value in store.reducedMotion = value }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Title

    private func titleHeader(compact: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 18) {
                    PixelText("BEST \(pad(store.best))", scale: 2, shadow: nil)
                    PixelText("COINS \(pad(store.bank))", scale: 2, color: Palette.yellow, shadow: nil)
                }
                .padding(.horizontal, 12).frame(height: 40)
                .background(Palette.ink)
                Spacer()
                soundButton
            }
            .frame(minHeight: 44)
            Spacer().frame(height: compact ? 18 : 34)
            VStack(spacing: 14) {
                PixelText("LITTLE", scale: 3, color: Palette.white, alignment: .center)
                PixelText(
                    "CROSSROADS",
                    scale: compact ? 4 : 5,
                    color: Palette.yellow,
                    shadow: Palette.brick,
                    alignment: .center
                )
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 20)
            .background(
                Palette.navy
                    .overlay(alignment: .bottom) { CheckerStrip().frame(height: 12) }
            )
            .overlay(Rectangle().strokeBorder(Palette.yellow, lineWidth: 3).padding(3))
            .overlay(Rectangle().strokeBorder(Palette.ink, lineWidth: 3))
            .background(Palette.ink.opacity(0.35).offset(x: 6, y: 6))
            PixelText("SMALL HOPS. BIG ADVENTURES.", scale: 2, color: Palette.white)
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
    }

    private var startPanel: some View {
        VStack(spacing: 14) {
            Blink(reducedMotion: reducedMotion) {
                PixelText("> PRESS START <", scale: 3, color: Palette.yellow)
            }
            .frame(height: 24)
            Button { store.start() } label: {
                PixelText("START", scale: 4, color: Palette.ink, shadow: nil, alignment: .center)
                    .frame(maxWidth: .infinity).frame(height: 54)
            }
            .buttonStyle(BlockPress(fill: Palette.yellow, shade: Palette.honey))
            .accessibilityIdentifier("startGame")
            HStack(spacing: 12) {
                Button { store.showWardrobe = true } label: {
                    PixelText("FLOCK", scale: 2, shadow: nil, alignment: .center)
                        .frame(maxWidth: .infinity).frame(height: 44)
                }
                .buttonStyle(BlockPress(fill: Palette.royal, shade: Palette.navy))
                Button { store.showGuide = true } label: {
                    PixelText("HOW TO PLAY", scale: 2, shadow: nil, alignment: .center)
                        .frame(maxWidth: .infinity).frame(height: 44)
                }
                .buttonStyle(BlockPress(fill: Palette.royal, shade: Palette.navy))
            }
            PixelText("(C) 2026 LITTLE CROSSROADS", scale: 2, color: Palette.gray, shadow: nil)
                .padding(.top, 2)
        }
        .padding(18)
        .background(Palette.ink)
        .overlay(Rectangle().strokeBorder(Palette.white, lineWidth: 3).padding(3))
        .overlay(Rectangle().strokeBorder(Palette.ink, lineWidth: 3))
    }

    // MARK: Gameplay

    private var gameHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                PixelText("COINS", scale: 2, color: Palette.yellow)
                PixelText("x\(pad(store.runCoins, 2))", scale: 3)
                    .contentTransition(.identity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 5) {
                PixelText("HOPS", scale: 2, color: Palette.yellow)
                PixelText(pad(store.score), scale: 4)
                    .accessibilityIdentifier("scoreValue")
            }
            .frame(maxWidth: .infinity)
            VStack(alignment: .trailing, spacing: 5) {
                PixelText("BEST", scale: 2, color: Palette.yellow)
                PixelText(pad(store.best), scale: 3)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            Button { store.pause() } label: {
                PixelText("II", scale: 3, shadow: nil).frame(width: 44, height: 44)
            }
            .buttonStyle(BlockPress(fill: Palette.slate, shade: Palette.steel, depth: 3))
            .accessibilityLabel("Pause game").accessibilityIdentifier("pauseGame")
            .padding(.leading, 6)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Palette.ink.opacity(0.82))
        .overlay(Rectangle().strokeBorder(Palette.white, lineWidth: 3))
        .padding(.top, 4)
    }

    private func controls(compact: Bool) -> some View {
        VStack(spacing: 14) {
            PixelText(store.score < 6 ? "TAP TO HOP - SWIPE TO STEER" : "WAIT FOR THE GAP", scale: 2)
                .padding(.vertical, 8).padding(.horizontal, 12)
                .background(Palette.ink.opacity(0.85))
            HStack(alignment: .center) {
                dpad(size: compact ? 46 : 52)
                Spacer()
                VStack(spacing: 8) {
                    Button { store.move(.forward) } label: {
                        PixelText("A", scale: 5, color: Palette.white, shadow: Palette.brick)
                            .frame(width: compact ? 88 : 96, height: compact ? 88 : 96)
                    }
                    .buttonStyle(RoundPress())
                    .accessibilityLabel("Hop forward").accessibilityIdentifier("hopForward")
                    PixelText("HOP", scale: 2)
                }
            }
            .padding(.horizontal, 6)
        }
        .padding(.bottom, 2)
    }

    private func dpad(size: CGFloat) -> some View {
        let gap: CGFloat = 2
        return VStack(spacing: gap) {
            dpadKey("^", label: "Hop forward", id: "dpadUp", direction: .forward, size: size)
            HStack(spacing: gap) {
                dpadKey("<", label: "Hop left", id: "hopLeft", direction: .left, size: size)
                Rectangle().fill(Palette.steel).frame(width: size, height: size)
                    .overlay(Circle().fill(Palette.slate).padding(size * 0.3))
                dpadKey(">", label: "Hop right", id: "hopRight", direction: .right, size: size)
            }
            dpadKey("_", label: "Step back", id: "hopBackward", direction: .backward, size: size)
        }
        .accessibilityElement(children: .contain)
    }

    private func dpadKey(_ glyph: String, label: String, id: String, direction: Direction, size: CGFloat) -> some View {
        Button { store.move(direction) } label: {
            PixelText(glyph, scale: 3, shadow: nil).frame(width: size, height: size)
        }
        .buttonStyle(BlockPress(fill: Palette.slate, shade: Palette.steel, depth: 4))
        .accessibilityLabel(label).accessibilityIdentifier(id)
    }

    // MARK: Overlays

    private var pauseCard: some View {
        modal {
            VStack(spacing: 20) {
                PixelText("PAUSED", scale: 5, color: Palette.yellow, shadow: Palette.brick, alignment: .center)
                PixelText("TAKE FIVE. THE ROAD WAITS.", scale: 2)
                Button { store.resume() } label: {
                    PixelText("> CONTINUE", scale: 3, color: Palette.ink, shadow: nil, alignment: .center)
                        .frame(maxWidth: .infinity).frame(height: 54)
                }
                .buttonStyle(BlockPress(fill: Palette.yellow, shade: Palette.honey))
                .accessibilityIdentifier("resumeGame")
                HStack(spacing: 10) {
                    soundButton
                    Spacer()
                    smallButton("GUIDE") { store.showGuide = true }
                    smallButton("QUIT") { store.game.endRun() }
                }
            }
        }
    }

    private var resultCard: some View {
        modal {
            VStack(spacing: 16) {
                PixelText("GAME OVER", scale: 5, color: Palette.coral, shadow: Palette.brick, alignment: .center)
                PixelText(headline(store.reason), scale: 2)
                VStack(spacing: 6) {
                    PixelText("SCORE", scale: 2, color: Palette.yellow)
                    PixelText(pad(store.score), scale: 7, alignment: .center)
                        .accessibilityIdentifier("resultScore")
                }
                if store.newBest {
                    Blink(reducedMotion: reducedMotion) {
                        PixelText("* NEW RECORD! *", scale: 3, color: Palette.yellow)
                    }
                    .frame(height: 24)
                }
                HStack {
                    PixelText("BEST \(pad(store.best))", scale: 2)
                    Spacer()
                    PixelText("COINS +\(pad(store.runCoins, 2))", scale: 2, color: Palette.yellow)
                }
                if !store.unlockedNames.isEmpty {
                    PixelText("\(store.unlockedNames.joined(separator: " & ")) JOINED!", scale: 2, color: Palette.mint)
                }
                Button { store.start() } label: {
                    PixelText("> PLAY AGAIN", scale: 3, color: Palette.ink, shadow: nil, alignment: .center)
                        .frame(maxWidth: .infinity).frame(height: 54)
                }
                .buttonStyle(BlockPress(fill: Palette.yellow, shade: Palette.honey))
                .accessibilityIdentifier("retryGame")
                HStack(spacing: 10) {
                    smallButton("HOME") { store.home() }
                    ShareLink(
                        item: "I hopped \(store.score) rows in Little Crossroads! My personal best is \(store.best). Small hops. Big adventures."
                    ) {
                        PixelText("SHARE", scale: 2, shadow: nil, alignment: .center)
                            .frame(maxWidth: .infinity).frame(height: 44)
                    }
                    .buttonStyle(BlockPress(fill: Palette.royal, shade: Palette.navy))
                    smallButton("FLOCK") { store.showWardrobe = true }
                }
            }
        }
    }

    private func headline(_ reason: String) -> String {
        if reason.contains("traffic") {
            return "BONKED BY TRAFFIC"
        }
        if reason.contains("splash") {
            return "SPLASH! INTO THE RIVER"
        }
        if reason.contains("Swept") {
            return "SWEPT DOWNSTREAM"
        }
        return "TOOK A BREATHER"
    }

    private func doneButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            PixelText("DONE", scale: 2, color: Palette.ink, shadow: nil, alignment: .center)
                .frame(width: 72, height: 32)
        }
        .buttonStyle(BlockPress(fill: Palette.yellow, shade: Palette.honey, depth: 3))
        .accessibilityLabel("Done")
    }

    private func smallButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            PixelText(title, scale: 2, shadow: nil, alignment: .center)
                .frame(maxWidth: .infinity).frame(height: 44)
        }
        .buttonStyle(BlockPress(fill: Palette.royal, shade: Palette.navy))
    }

    private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Palette.ink.opacity(0.55).ignoresSafeArea()
            content()
                .padding(22)
                .background(Palette.navy)
                .overlay(Rectangle().strokeBorder(Palette.white, lineWidth: 3).padding(3))
                .overlay(Rectangle().strokeBorder(Palette.ink, lineWidth: 3))
                .background(Palette.ink.opacity(0.5).offset(x: 6, y: 6))
                .padding(.horizontal, 20)
        }
    }

    private var soundButton: some View {
        Button { store.sound.toggle() } label: {
            PixelText(store.sound ? "SND ON" : "SND OFF", scale: 2, shadow: nil)
                .frame(width: 86, height: 40)
        }
        .buttonStyle(BlockPress(fill: Palette.slate, shade: Palette.steel, depth: 3))
        .accessibilityLabel(store.sound ? "Mute sound" : "Enable sound")
    }

    private func pad(_ value: Int, _ digits: Int = 4) -> String {
        let text = String(value)
        return String(repeating: "0", count: max(0, digits - text.count)) + text
    }

    // MARK: Sheets

    private var wardrobe: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    PixelText("MEET THE FLOCK", scale: 4, color: Palette.yellow, shadow: Palette.brick)
                    Text("Collect coins or set a new best to welcome new companions. Coins are never spent.")
                        .font(.body()).foregroundStyle(Palette.gray)
                    HStack {
                        PixelText("COINS \(pad(store.bank))", scale: 3, color: Palette.yellow)
                        Spacer()
                        PixelText("BEST \(pad(store.best))", scale: 3)
                    }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(Plumage.allCases) { duck in
                            let unlocked = duck.unlocked(coins: store.bank, best: store.best)
                            let chosen = store.selected == duck
                            Button {
                                if unlocked {
                                    store.selected = duck
                                }
                            } label: {
                                VStack(spacing: 10) {
                                    DuckSpriteView(plumage: ToyColor.duck(duck))
                                        .frame(width: 96, height: 96)
                                        .saturation(unlocked ? 1 : 0).opacity(unlocked ? 1 : 0.45)
                                    PixelText(duck.name, scale: 2, shadow: nil)
                                    if unlocked {
                                        PixelText(
                                            chosen ? "> SELECTED" : "SELECT",
                                            scale: 2,
                                            color: chosen ? Palette.yellow : Palette.gray,
                                            shadow: nil
                                        )
                                    } else {
                                        PixelText(
                                            "\(duck.price) COINS OR\n\(duck.milestone) HOPS",
                                            scale: 2,
                                            color: Palette.gray,
                                            shadow: nil,
                                            alignment: .center
                                        )
                                    }
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(chosen ? Palette.royal : Palette.ink)
                                .overlay(Rectangle().strokeBorder(
                                    chosen ? Palette.yellow : Palette.white.opacity(unlocked ? 0.8 : 0.3),
                                    lineWidth: 3
                                ))
                            }
                            .disabled(!unlocked).buttonStyle(FlatPress())
                            .accessibilityIdentifier("plumage\(duck.rawValue)")
                        }
                    }
                }.padding(22).padding(.top, 44)
            }
            .background(Palette.navy)
            .overlay(alignment: .topTrailing) {
                doneButton { store.showWardrobe = false }.padding(.top, 16).padding(.trailing, 22)
            }
        }
    }

    private var guide: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    PixelText("HOW TO PLAY", scale: 4, color: Palette.yellow, shadow: Palette.brick)
                    instruction(
                        "1",
                        title: "HOP FORWARD",
                        text: "Tap the countryside, the A button or the D-pad up to move forward one row."
                    )
                    instruction(
                        "2",
                        title: "STEER",
                        text: "Swipe or use the D-pad to step left, right or back. Cars never stop, so wait on grass for a gap. There is no timer."
                    )
                    instruction(
                        "3",
                        title: "RIDE THE LOGS",
                        text: "Land on a floating log to cross water. It carries you sideways, so hop off before it reaches the edge."
                    )
                    instruction(
                        "4",
                        title: "GROW YOUR FLOCK",
                        text: "Your farthest row is your score. Coins and personal bests unlock three new companions, saved on this device."
                    )
                    Button { store.showGuide = false } label: {
                        PixelText("> GOT IT", scale: 3, color: Palette.ink, shadow: nil, alignment: .center)
                            .frame(maxWidth: .infinity).frame(height: 54)
                    }
                    .buttonStyle(BlockPress(fill: Palette.yellow, shade: Palette.honey))
                }.padding(22).padding(.top, 44)
            }
            .background(Palette.navy)
            .overlay(alignment: .topTrailing) {
                doneButton { store.showGuide = false }.padding(.top, 16).padding(.trailing, 22)
            }
        }
    }

    private func instruction(_ number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            PixelText(number, scale: 3, color: Palette.ink, shadow: nil)
                .frame(width: 40, height: 40)
                .background(Palette.yellow)
                .overlay(Rectangle().strokeBorder(Palette.ink, lineWidth: 3))
            VStack(alignment: .leading, spacing: 8) {
                PixelText(title, scale: 3)
                Text(text).font(.body()).foregroundStyle(Palette.gray).lineSpacing(3)
            }
        }
    }
}

// MARK: Design elements

private struct CheckerStrip: View {
    var body: some View {
        Canvas { context, size in
            let unit = size.height / 2
            var column = 0
            var x: CGFloat = 0
            while x < size.width {
                for row in 0 ..< 2 where (row + column) % 2 == 0 {
                    context.fill(
                        Path(CGRect(x: x, y: CGFloat(row) * unit, width: unit, height: unit)),
                        with: .color(Palette.coral)
                    )
                }
                x += unit
                column += 1
            }
        }
        .accessibilityHidden(true)
    }
}

private struct Blink<Content: View>: View {
    let reducedMotion: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.45)) { timeline in
            let on = reducedMotion || Int(timeline.date.timeIntervalSinceReferenceDate / 0.45) % 2 == 0
            content().opacity(on ? 1 : 0)
        }
    }
}

private struct FlatPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.7 : 1)
    }
}

private struct BlockPress: ButtonStyle {
    let fill: Color
    let shade: Color
    var depth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Palette.white)
            .background(fill)
            .overlay(Rectangle().strokeBorder(Palette.ink, lineWidth: 3))
            .offset(y: configuration.isPressed ? depth : 0)
            .background(alignment: .bottom) {
                Rectangle().fill(shade).overlay(Rectangle().strokeBorder(Palette.ink, lineWidth: 3))
                    .offset(y: depth)
            }
            .padding(.bottom, depth)
    }
}

private struct RoundPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Circle().fill(Palette.coral))
            .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 3))
            .offset(y: configuration.isPressed ? 5 : 0)
            .background(Circle().fill(Palette.brick).overlay(Circle().strokeBorder(Palette.ink, lineWidth: 3))
                .offset(y: 5))
            .padding(.bottom, 5)
    }
}

private struct NativeWorld: UIViewRepresentable {
    let store: GameStore
    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = store.world.scene
        view.pointOfView = store.world.camera
        view.antialiasingMode = .none
        view.contentScaleFactor = 1.5
        view.layer.magnificationFilter = .nearest
        view.preferredFramesPerSecond = 60
        view.isPlaying = true
        view.backgroundColor = ToyColor.sky
        view.addGestureRecognizer(UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.tap)
        ))
        for direction: UISwipeGestureRecognizer.Direction in [.up, .down, .left, .right] {
            let swipe = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.swipe(_:)))
            swipe.direction = direction
            view.addGestureRecognizer(swipe)
        }
        return view
    }

    func updateUIView(_: SCNView, context _: Context) {}

    @MainActor
    final class Coordinator: NSObject {
        let store: GameStore
        init(store: GameStore) {
            self.store = store
        }

        @objc func tap() {
            store.move(.forward)
        }

        @objc func swipe(_ gesture: UISwipeGestureRecognizer) {
            switch gesture.direction {
            case .up: store.move(.forward)
            case .down: store.move(.backward)
            case .left: store.move(.left)
            default: store.move(.right)
            }
        }
    }
}
