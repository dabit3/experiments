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
    static let cream = Color(uiColor: ToyColor.cream)
    static let paper = Color(red: 1, green: 0.985, blue: 0.94)
    static let mint = Color(uiColor: ToyColor.mint)
    static let yellow = Color(uiColor: ToyColor.yellow)
    static let honey = Color(red: 0.84, green: 0.58, blue: 0.09)
    static let coral = Color(uiColor: ToyColor.coral)
    static let shade = Color(red: 0.80, green: 0.79, blue: 0.68)
    static let hairline = ink.opacity(0.09)
}

private extension Font {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .serif).italic()
    }

    static func numeral(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func eyebrow(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}

struct CrossroadsView: View {
    @StateObject private var store = GameStore()
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                NativeWorld(store: store).ignoresSafeArea()
                    .accessibilityLabel("Little Crossroads countryside")
                VStack {
                    LinearGradient(
                        stops: [
                            .init(color: Palette.cream, location: 0),
                            .init(color: Palette.cream.opacity(0.98), location: 0.60),
                            .init(color: Palette.cream.opacity(0.78), location: 0.78),
                            .init(color: Palette.cream.opacity(0), location: 1),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * (store.state == .ready ? 0.44 : 0.19))
                    Spacer()
                }
                .ignoresSafeArea().allowsHitTesting(false)
                VStack(spacing: 0) {
                    if store.state == .ready {
                        titleHeader
                    } else {
                        gameHeader
                    }
                    Spacer(minLength: 0)
                    if store.state == .ready {
                        startCard
                    } else if store.state == .playing {
                        controls
                    }
                }
                .padding(.horizontal, geometry.size.width < 380 ? 20 : 26)
                .padding(.top, 10)
                .padding(.bottom, 12)
                if store.state == .paused {
                    pauseCard
                }
                if store.state == .finished, store.showResults {
                    resultCard
                }
            }
            .foregroundStyle(Palette.ink)
            .sheet(isPresented: $store.showWardrobe) { wardrobe }
            .sheet(isPresented: $store.showGuide) { guide }
            .onChange(of: phase) { _, new in
                if new != .active {
                    store.pause()
                }
            }
            .onChange(of: reducedMotion, initial: true) { _, value in store.reducedMotion = value }
        }
        .preferredColorScheme(.light)
    }

    // MARK: Title

    private var titleHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Circle().fill(Palette.coral).frame(width: 6, height: 6)
                Text("A POCKET-SIZED ADVENTURE").font(.eyebrow(9.5)).tracking(2.2)
                    .foregroundStyle(Palette.ink.opacity(0.72))
                Spacer()
                soundButton
            }
            Text("Little").font(.display(42)).padding(.top, 8)
            Text("Crossroads").font(.numeral(54)).tracking(-2.8)
                .minimumScaleFactor(0.7).lineLimit(1).padding(.top, -14)
            RoadRule().frame(width: 132).padding(.top, 10)
            Text("Small hops. Big adventures.").font(.display(16))
                .foregroundStyle(Palette.ink.opacity(0.78)).padding(.top, 10)
            HStack(spacing: 0) {
                titleStat("BEST", value: "\(store.best)", symbol: "flag.checkered")
                Rectangle().fill(Palette.ink.opacity(0.14)).frame(width: 1, height: 22)
                titleStat("COINS", value: "\(store.bank)", symbol: "circle.inset.filled")
            }
            .padding(.vertical, 8).padding(.horizontal, 6)
            .background(.white.opacity(0.55), in: Capsule())
            .overlay(Capsule().stroke(Palette.hairline, lineWidth: 1))
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func titleStat(_ title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol).font(.system(size: 12, weight: .bold))
            Text(value).font(.numeral(15))
            Text(title).font(.eyebrow(9)).tracking(1.4).foregroundStyle(Palette.ink.opacity(0.62))
        }
        .padding(.horizontal, 12)
    }

    private var startCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("READY WHEN YOU ARE").font(.eyebrow(9)).tracking(2)
                        .foregroundStyle(Palette.ink.opacity(0.6))
                    Text("The other side is calling.").font(.display(24))
                    Text("Dodge traffic. Catch a log. Keep hopping.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.ink.opacity(0.68))
                }
                Spacer(minLength: 8)
                Signpost().frame(width: 46, height: 52)
            }
            RoadRule().padding(.vertical, 2)
            primary("Let's hop", symbol: "arrow.up") { store.start() }
                .accessibilityIdentifier("startGame")
            HStack {
                Button { store.showWardrobe = true } label: {
                    Label("Meet the flock", systemImage: "square.grid.2x2.fill")
                }
                Spacer()
                Button { store.showGuide = true } label: {
                    Label("How to play", systemImage: "questionmark.circle")
                }
            }
            .font(.system(size: 12.5, weight: .bold, design: .rounded))
            .buttonStyle(SoftPress())
            .frame(minHeight: 36)
        }
        .padding(22)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Palette.hairline, lineWidth: 1))
        .shadow(color: Palette.ink.opacity(0.13), radius: 24, x: 0, y: 12)
    }

    // MARK: Gameplay

    private var gameHeader: some View {
        HStack(alignment: .top) {
            chip {
                Image(systemName: "circle.inset.filled").font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.honey)
                Text("\(store.runCoins)").font(.numeral(17)).contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(Palette.paper)
                    Circle().stroke(Palette.ink, lineWidth: 2.5).padding(4)
                    VStack(spacing: -3) {
                        Text("\(store.score)").font(.numeral(34)).tracking(-1)
                            .minimumScaleFactor(0.6).lineLimit(1)
                            .contentTransition(.numericText())
                            .accessibilityIdentifier("scoreValue")
                        Text("HOPS").font(.eyebrow(7.5)).tracking(1.8)
                    }
                    .padding(.horizontal, 10)
                }
                .frame(width: 84, height: 84)
                .shadow(color: Palette.ink.opacity(0.14), radius: 10, y: 5)
                .animation(reducedMotion ? nil : .snappy(duration: 0.25), value: store.score)
                chip {
                    Text("BEST \(store.best)").font(.eyebrow(9.5)).tracking(1.4)
                }
            }
            .frame(maxWidth: .infinity)
            Button { store.pause() } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(Palette.paper, in: Circle())
                    .overlay(Circle().stroke(Palette.hairline, lineWidth: 1))
            }
            .accessibilityLabel("Pause game").accessibilityIdentifier("pauseGame").buttonStyle(SoftPress())
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.top, 2)
    }

    private func chip<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 6) { content() }
            .padding(.horizontal, 13).frame(height: 34)
            .background(Palette.paper.opacity(0.96), in: Capsule())
            .overlay(Capsule().stroke(Palette.hairline, lineWidth: 1))
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Text(store.score < 6 ? "TAP TO HOP · SWIPE TO STEER" : "TAKE YOUR TIME. FIND YOUR GAP.")
                .font(.eyebrow(9)).tracking(1.6)
                .padding(.vertical, 8).padding(.horizontal, 13)
                .background(Palette.paper.opacity(0.92), in: Capsule())
            HStack(spacing: 14) {
                arrow("arrow.left", label: "Hop left", id: "hopLeft", direction: .left)
                Button { store.move(.forward) } label: {
                    HStack(spacing: 12) {
                        Text("HOP").font(.numeral(17)).tracking(2.4)
                        Image(systemName: "arrow.up").font(.system(size: 20, weight: .bold))
                    }
                    .frame(width: 148, height: 60)
                }
                .buttonStyle(ToyPress(fill: Palette.yellow, shade: Palette.honey, radius: 30))
                .accessibilityLabel("Hop forward").accessibilityIdentifier("hopForward")
                arrow("arrow.right", label: "Hop right", id: "hopRight", direction: .right)
            }
            Button { store.move(.backward) } label: {
                Label("Step back", systemImage: "arrow.down")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .frame(width: 118, height: 38)
            }
            .buttonStyle(ToyPress(fill: Palette.paper, shade: Palette.shade, radius: 19, depth: 3))
            .accessibilityIdentifier("hopBackward")
        }
        .padding(.bottom, 4)
    }

    private func arrow(_ symbol: String, label: String, id: String, direction: Direction) -> some View {
        Button { store.move(direction) } label: {
            Image(systemName: symbol).font(.system(size: 20, weight: .bold))
                .frame(width: 58, height: 58)
        }
        .buttonStyle(ToyPress(fill: Palette.paper, shade: Palette.shade, radius: 29))
        .accessibilityLabel(label).accessibilityIdentifier(id)
    }

    // MARK: Overlays

    private var pauseCard: some View {
        modal {
            VStack(spacing: 18) {
                ZStack {
                    Circle().fill(Palette.mint.opacity(0.55)).frame(width: 66, height: 66)
                    Image(systemName: "leaf.fill").font(.system(size: 28))
                }
                VStack(spacing: 6) {
                    Text("A little breather.").font(.display(30))
                    Text("Your adventure will wait right here.")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(Palette.ink.opacity(0.7))
                }
                RoadRule()
                primary("Keep hopping", symbol: "play.fill") { store.resume() }
                    .accessibilityIdentifier("resumeGame")
                HStack {
                    soundButton
                    Spacer()
                    Button("How to play") { store.showGuide = true }
                    Spacer()
                    Button("End run") { store.game.endRun() }
                }.font(.system(size: 12.5, weight: .bold, design: .rounded))
            }
        }
    }

    private var resultCard: some View {
        modal {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Circle().fill(Palette.coral).frame(width: 6, height: 6)
                    Text(store.newBest ? "A NEW PERSONAL BEST" : "UNTIL THE NEXT ADVENTURE")
                        .font(.eyebrow(9)).tracking(2).foregroundStyle(Palette.ink.opacity(0.7))
                    Spacer()
                    Image(systemName: store.newBest ? "sparkles" : "sun.max.fill")
                        .font(.system(size: 15)).foregroundStyle(Palette.coral)
                }
                VStack(spacing: 0) {
                    Text(store.reason).font(.display(24)).minimumScaleFactor(0.7).lineLimit(1)
                    Text("\(store.score)").font(.numeral(94)).tracking(-5)
                        .accessibilityIdentifier("resultScore")
                        .padding(.top, -6)
                    Text("HOPS INTO THE COUNTRYSIDE").font(.eyebrow(9)).tracking(1.8)
                        .foregroundStyle(Palette.ink.opacity(0.7)).padding(.top, -6)
                }
                RoadRule()
                HStack(spacing: 0) {
                    resultStat("PERSONAL BEST", value: "\(store.best)", symbol: "flag.checkered")
                    Rectangle().fill(Palette.ink.opacity(0.12)).frame(width: 1, height: 36)
                    resultStat("COINS FOUND", value: "+\(store.runCoins)", symbol: "circle.inset.filled")
                }
                if !store.unlockedNames.isEmpty {
                    Text("\(store.unlockedNames.joined(separator: " & ")) joined your flock!")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
                        .foregroundStyle(Palette.coral)
                }
                primary("One more hop", symbol: "arrow.clockwise") { store.start() }
                    .accessibilityIdentifier("retryGame")
                HStack {
                    Button { store.home() } label: { Label("Home", systemImage: "house") }
                    Spacer()
                    ShareLink(
                        item: "I hopped \(store.score) rows in Little Crossroads! My personal best is \(store.best). Small hops. Big adventures."
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Spacer()
                    Button { store.showWardrobe = true } label: { Label("Flock", systemImage: "square.grid.2x2") }
                }
                .font(.system(size: 12.5, weight: .bold, design: .rounded)).frame(minHeight: 40)
            }
        }
    }

    private func resultStat(_ title: String, value: String, symbol: String) -> some View {
        VStack(spacing: 4) {
            Label(value, systemImage: symbol).font(.numeral(22))
            Text(title).font(.eyebrow(8)).tracking(1.2).foregroundStyle(Palette.ink.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
    }

    private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Palette.ink.opacity(0.26).ignoresSafeArea()
            content()
                .padding(26)
                .background(Palette.paper, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(Palette.hairline, lineWidth: 1))
                .shadow(color: Palette.ink.opacity(0.22), radius: 34, y: 18)
                .padding(.horizontal, 24)
        }
    }

    private var soundButton: some View {
        Button { store.sound.toggle() } label: {
            Image(systemName: store.sound ? "speaker.wave.2" : "speaker.slash")
                .font(.system(size: 15, weight: .semibold)).frame(width: 44, height: 44)
        }
        .accessibilityLabel(store.sound ? "Mute sound" : "Enable sound").buttonStyle(SoftPress())
    }

    private func primary(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title).font(.system(size: 17, weight: .heavy, design: .rounded))
                Spacer()
                Image(systemName: symbol).font(.system(size: 18, weight: .bold))
            }
            .padding(.horizontal, 20).frame(height: 58)
        }
        .buttonStyle(ToyPress(fill: Palette.yellow, shade: Palette.honey, radius: 29))
    }

    // MARK: Sheets

    private var wardrobe: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("MEET THE FLOCK").font(.eyebrow(9.5)).tracking(2.2)
                        .foregroundStyle(Palette.ink.opacity(0.62))
                    Text("Good company.\nGreat plumage.").font(.display(34)).padding(.top, -8)
                    Text("Collect coins or reach a personal best to welcome new friends. Coins are never spent.")
                        .font(.system(size: 14)).foregroundStyle(Palette.ink.opacity(0.7))
                    RoadRule()
                    HStack {
                        Label("\(store.bank) lifetime coins", systemImage: "circle.inset.filled")
                        Spacer()
                        Label("\(store.best) best", systemImage: "flag.checkered")
                    }.font(.system(size: 12.5, weight: .bold, design: .rounded))
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(Plumage.allCases) { duck in
                            let unlocked = duck.unlocked(coins: store.bank, best: store.best)
                            let tint = Color(uiColor: ToyColor.duck(duck))
                            Button {
                                if unlocked {
                                    store.selected = duck
                                }
                            } label: {
                                VStack(spacing: 10) {
                                    ZStack {
                                        Circle().fill(tint.opacity(unlocked ? 0.28 : 0.12)).frame(width: 96, height: 96)
                                        DuckPortrait(color: tint).frame(width: 78, height: 82)
                                            .saturation(unlocked ? 1 : 0.15).opacity(unlocked ? 1 : 0.55)
                                    }
                                    Text(duck.name).font(.system(size: 16, weight: .bold, design: .rounded))
                                    if unlocked {
                                        Label(
                                            store.selected == duck ? "Your companion" : "Choose",
                                            systemImage: store.selected == duck ? "checkmark.circle.fill" : "circle"
                                        )
                                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                    } else {
                                        Text("\(duck.price) coins or \(duck.milestone) hops")
                                            .font(.system(size: 10.5, weight: .semibold))
                                            .foregroundStyle(Palette.ink.opacity(0.7))
                                    }
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(
                                    unlocked ? .white.opacity(0.75) : Palette.ink.opacity(0.03),
                                    in: RoundedRectangle(cornerRadius: 26, style: .continuous)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(
                                    store.selected == duck ? Palette.ink : Palette.ink.opacity(unlocked ? 0.08 : 0.28),
                                    style: StrokeStyle(
                                        lineWidth: store.selected == duck ? 2 : 1,
                                        dash: unlocked ? [] : [6, 5]
                                    )
                                ))
                            }
                            .disabled(!unlocked).buttonStyle(SoftPress())
                            .accessibilityIdentifier("plumage\(duck.rawValue)")
                        }
                    }
                }.padding(25)
            }
            .background(Palette.cream).foregroundStyle(Palette.ink)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { store.showWardrobe = false } } }
        }
        .tint(Palette.ink)
    }

    private var guide: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("HOW TO PLAY").font(.eyebrow(9.5)).tracking(2.2)
                        .foregroundStyle(Palette.ink.opacity(0.62))
                    Text("One hop at a time.").font(.display(34)).padding(.top, -14)
                    RoadRule()
                    instruction(
                        "01",
                        title: "Follow your beak.",
                        text: "Tap the countryside or HOP to move forward. Swipe or use the arrows to step left, right or back."
                    )
                    instruction(
                        "02",
                        title: "Find a little opening.",
                        text: "Cars never stop. Wait on a grassy verge, then hop through a clear gap. There is no timer rushing you."
                    )
                    instruction(
                        "03",
                        title: "Go with the flow.",
                        text: "Land on a floating log to cross water. It carries you sideways, so hop off before it reaches the edge."
                    )
                    instruction(
                        "04",
                        title: "Grow your flock.",
                        text: "Your farthest row is your score. Golden coins and personal bests unlock three new companions, saved on this device."
                    )
                    primary("Got it", symbol: "checkmark") { store.showGuide = false }
                }.padding(26)
            }
            .background(Palette.cream).foregroundStyle(Palette.ink)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { store.showGuide = false } } }
        }
        .tint(Palette.ink)
    }

    private func instruction(_ number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle().fill(Palette.paper)
                Circle().stroke(Palette.ink, lineWidth: 2).padding(3)
                Text(number).font(.numeral(15))
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.display(19))
                Text(text).font(.system(size: 14)).foregroundStyle(Palette.ink.opacity(0.75)).lineSpacing(4)
            }
        }
    }
}

// MARK: Design elements

private struct RoadRule: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Palette.ink.opacity(0.22)).frame(height: 1)
            Circle().fill(Palette.coral).frame(width: 6, height: 6)
            Rectangle().fill(Palette.ink.opacity(0.22)).frame(height: 1)
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

private struct Signpost: View {
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 2).fill(Palette.ink.opacity(0.35)).frame(width: 4).padding(.top, 8)
            VStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 5).fill(Palette.coral).frame(height: 14)
                RoundedRectangle(cornerRadius: 5).fill(Palette.mint).frame(height: 14).padding(.leading, 10)
            }
            .padding(.top, 3)
        }
        .accessibilityHidden(true)
    }
}

private struct DuckPortrait: View {
    let color: Color
    var body: some View {
        ZStack {
            Ellipse().fill(Palette.ink.opacity(0.10)).frame(width: 71, height: 16).offset(y: 32)
            RoundedRectangle(cornerRadius: 14).fill(color).frame(width: 56, height: 40).offset(y: 11)
            RoundedRectangle(cornerRadius: 12).fill(color).frame(width: 43, height: 39).offset(x: 7, y: -14)
            RoundedRectangle(cornerRadius: 4).fill(Palette.coral).frame(width: 24, height: 11).offset(x: 30, y: -7)
            Circle().fill(Palette.ink).frame(width: 5.5, height: 5.5).offset(x: 17, y: -19)
            Circle().fill(.white).frame(width: 2, height: 2).offset(x: 18.5, y: -20.5)
            RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.24)).frame(width: 26, height: 19).offset(
                x: -10,
                y: 8
            )
            RoundedRectangle(cornerRadius: 3).fill(Palette.coral).frame(width: 16, height: 6).offset(x: 8, y: 32)
        }
        .accessibilityHidden(true)
    }
}

private struct SoftPress: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Palette.ink)
            .scaleEffect(configuration.isPressed && !reducedMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(reducedMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ToyPress: ButtonStyle {
    let fill: Color
    let shade: Color
    let radius: CGFloat
    var depth: CGFloat = 5
    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let travel = configuration.isPressed ? depth - 1 : 0
        return configuration.label
            .foregroundStyle(Palette.ink)
            .background(fill, in: shape)
            .overlay(shape.stroke(.white.opacity(0.45), lineWidth: 1))
            .offset(y: travel)
            .background(shape.fill(shade).offset(y: depth))
            .padding(.bottom, depth)
            .animation(reducedMotion ? nil : .easeOut(duration: 0.08), value: configuration.isPressed)
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
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.isPlaying = true
        view.backgroundColor = ToyColor.haze
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
