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
    static let mint = Color(uiColor: ToyColor.mint)
    static let yellow = Color(uiColor: ToyColor.yellow)
    static let coral = Color(uiColor: ToyColor.coral)
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
                    .frame(height: geometry.size.height * (store.state == .ready ? 0.43 : 0.17))
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
                .padding(.top, 12)
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

    private var titleHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("A POCKET-SIZED ADVENTURE", systemImage: "sun.max.fill")
                    .font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1.8)
                Spacer()
                soundButton
            }
            Text("little").font(.system(size: 36, weight: .semibold, design: .serif))
                .padding(.top, 10)
            Text("crossroads").font(.system(size: 47, weight: .black, design: .rounded))
                .tracking(-2.6).minimumScaleFactor(0.7).lineLimit(1).padding(.top, -10)
            HStack(spacing: 6) {
                Capsule().fill(Palette.coral).frame(width: 23, height: 3)
                Text("Small hops. Big adventures.").font(.system(size: 13, weight: .medium))
            }
            .padding(.top, 4)
            HStack(spacing: 14) {
                Label("\(store.best) best", systemImage: "flag.checkered")
                Label("\(store.bank) coins", systemImage: "circle.inset.filled")
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .padding(.vertical, 9).padding(.horizontal, 13)
            .background(.white.opacity(0.58), in: Capsule())
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var startCard: some View {
        VStack(spacing: 15) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("The other side is calling.")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                    Text("Dodge traffic. Catch a log. Keep hopping.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.ink.opacity(0.7))
                }
                Spacer(minLength: 6)
                Image(systemName: "arrow.up.right").font(.system(size: 20, weight: .medium))
                    .padding(.top, 3)
            }
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
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .buttonStyle(SoftPress())
            .frame(minHeight: 36)
        }
        .padding(21)
        .background(Palette.cream, in: RoundedRectangle(cornerRadius: 29))
        .overlay(RoundedRectangle(cornerRadius: 29).stroke(.white.opacity(0.7), lineWidth: 1))
        .shadow(color: Palette.ink.opacity(0.10), radius: 20, x: 0, y: 9)
    }

    private var gameHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("COINS").font(.system(size: 11, weight: .heavy)).tracking(1)
                Label("\(store.runCoins)", systemImage: "circle.inset.filled")
                    .font(.system(size: 18, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: -1) {
                Text("\(store.score)").font(.system(size: 49, weight: .black, design: .rounded))
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("scoreValue")
                Text("HOPS").font(.system(size: 11, weight: .black)).tracking(2)
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 5) {
                Button { store.pause() } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(Palette.mint.opacity(0.45), in: Circle())
                }
                .accessibilityLabel("Pause game").accessibilityIdentifier("pauseGame").buttonStyle(SoftPress())
                Text("BEST \(store.best)").font(.system(size: 11, weight: .bold))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 17).padding(.vertical, 12)
        .background(Palette.cream.opacity(0.97), in: RoundedRectangle(cornerRadius: 25))
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Text(store.score < 6 ? "TAP TO HOP · SWIPE TO STEER" : "TAKE YOUR TIME. FIND YOUR GAP.")
                .font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1.2)
                .padding(.vertical, 9).padding(.horizontal, 14)
                .background(Palette.cream.opacity(0.93), in: Capsule())
            HStack(spacing: 12) {
                arrow("arrow.left", label: "Hop left", id: "hopLeft", direction: .left)
                Button { store.move(.forward) } label: {
                    HStack(spacing: 13) {
                        Text("HOP").font(.system(size: 16, weight: .black, design: .rounded)).tracking(2)
                        Image(systemName: "arrow.up").font(.system(size: 21, weight: .bold))
                    }
                    .frame(width: 136, height: 58)
                    .background(Palette.yellow, in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.65), lineWidth: 1))
                }
                .accessibilityLabel("Hop forward").accessibilityIdentifier("hopForward").buttonStyle(SoftPress())
                arrow("arrow.right", label: "Hop right", id: "hopRight", direction: .right)
            }
            Button { store.move(.backward) } label: {
                Label("Step back", systemImage: "arrow.down")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 115, height: 40)
                    .background(Palette.cream.opacity(0.9), in: Capsule())
            }
            .accessibilityIdentifier("hopBackward").buttonStyle(SoftPress())
        }
        .padding(.bottom, 1)
    }

    private func arrow(_ symbol: String, label: String, id: String, direction: Direction) -> some View {
        Button { store.move(direction) } label: {
            Image(systemName: symbol).font(.system(size: 20, weight: .bold))
                .frame(width: 54, height: 54)
                .background(Palette.cream, in: RoundedRectangle(cornerRadius: 20))
        }
        .accessibilityLabel(label).accessibilityIdentifier(id).buttonStyle(SoftPress())
    }

    private var pauseCard: some View {
        modal {
            VStack(spacing: 19) {
                Image(systemName: "leaf.fill").font(.system(size: 35)).foregroundStyle(Palette.mint)
                VStack(spacing: 6) {
                    Text("A little breather.").font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Your adventure will wait right here.")
                        .font(.system(size: 13, weight: .medium))
                }
                primary("Keep hopping", symbol: "play.fill") { store.resume() }
                    .accessibilityIdentifier("resumeGame")
                HStack {
                    soundButton
                    Spacer()
                    Button("How to play") { store.showGuide = true }
                    Spacer()
                    Button("End run") { store.game.endRun() }
                }.font(.system(size: 12, weight: .bold))
            }
        }
    }

    private var resultCard: some View {
        modal {
            VStack(spacing: 17) {
                HStack {
                    Text(store.newBest ? "A NEW PERSONAL BEST" : "UNTIL THE NEXT ADVENTURE")
                        .font(.system(size: 9, weight: .black)).tracking(1.5)
                    Spacer()
                    Image(systemName: store.newBest ? "sparkles" : "sun.max.fill")
                        .foregroundStyle(Palette.coral)
                }
                VStack(spacing: 0) {
                    Text(store.reason).font(.system(size: 23, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7).lineLimit(1)
                    Text("\(store.score)").font(.system(size: 88, weight: .black, design: .rounded))
                        .tracking(-4).accessibilityIdentifier("resultScore")
                    Text("HOPS INTO THE COUNTRYSIDE")
                        .font(.system(size: 9, weight: .heavy)).tracking(1.2)
                }
                HStack(spacing: 0) {
                    resultStat("PERSONAL BEST", value: "\(store.best)", symbol: "flag.checkered")
                    Rectangle().fill(Palette.ink.opacity(0.1)).frame(width: 1, height: 35)
                    resultStat("COINS FOUND", value: "+\(store.runCoins)", symbol: "circle.inset.filled")
                }
                .padding(.vertical, 13)
                .background(Palette.mint.opacity(0.24), in: RoundedRectangle(cornerRadius: 18))
                if !store.unlockedNames.isEmpty {
                    Text("\(store.unlockedNames.joined(separator: " & ")) joined your flock!")
                        .font(.system(size: 12, weight: .bold)).multilineTextAlignment(.center)
                        .foregroundStyle(Palette.ink)
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
                .font(.system(size: 12, weight: .bold)).frame(minHeight: 40)
            }
        }
    }

    private func resultStat(_ title: String, value: String, symbol: String) -> some View {
        VStack(spacing: 5) {
            Label(value, systemImage: symbol).font(.system(size: 21, weight: .black, design: .rounded))
            Text(title).font(.system(size: 8, weight: .heavy)).tracking(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Palette.ink.opacity(0.22).ignoresSafeArea()
            content()
                .padding(25)
                .background(Palette.cream, in: RoundedRectangle(cornerRadius: 31))
                .shadow(color: Palette.ink.opacity(0.17), radius: 30, y: 16)
                .padding(.horizontal, 25)
        }
    }

    private var soundButton: some View {
        Button { store.sound.toggle() } label: {
            Image(systemName: store.sound ? "speaker.wave.2" : "speaker.slash")
                .font(.system(size: 16, weight: .semibold)).frame(width: 44, height: 44)
        }
        .accessibilityLabel(store.sound ? "Mute sound" : "Enable sound").buttonStyle(SoftPress())
    }

    private func primary(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title).font(.system(size: 17, weight: .heavy, design: .rounded))
                Spacer()
                Image(systemName: symbol).font(.system(size: 19, weight: .bold))
            }
            .padding(.horizontal, 19).frame(height: 56)
            .background(Palette.yellow, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(SoftPress())
    }

    private var wardrobe: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    Text("Good company.\nGreat plumage.")
                        .font(.system(size: 33, weight: .bold, design: .rounded)).tracking(-1)
                    Text("Collect coins or reach a personal best to welcome new friends. Coins are never spent.")
                        .font(.system(size: 14)).foregroundStyle(Palette.ink.opacity(0.7))
                    HStack {
                        Label("\(store.bank) lifetime coins", systemImage: "circle.inset.filled")
                        Spacer()
                        Label("\(store.best) best", systemImage: "flag.checkered")
                    }.font(.system(size: 12, weight: .bold))
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
                        ForEach(Plumage.allCases) { duck in
                            let unlocked = duck.unlocked(coins: store.bank, best: store.best)
                            Button {
                                if unlocked {
                                    store.selected = duck
                                }
                            } label: {
                                VStack(spacing: 10) {
                                    DuckPortrait(color: Color(uiColor: ToyColor.duck(duck)))
                                        .frame(width: 78, height: 82).padding(.top, 4)
                                    Text(duck.name).font(.system(size: 16, weight: .bold, design: .rounded))
                                    if unlocked {
                                        Label(
                                            store.selected == duck ? "Your companion" : "Choose",
                                            systemImage: store.selected == duck ? "checkmark.circle.fill" : "circle"
                                        )
                                        .font(.system(size: 10, weight: .bold))
                                    } else {
                                        Text("\(duck.price) coins or \(duck.milestone) hops")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 15)
                                .background(
                                    unlocked ? .white.opacity(0.7) : Palette.mint.opacity(0.27),
                                    in: RoundedRectangle(cornerRadius: 23)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 23).stroke(
                                    store.selected == duck ? Palette.ink : .clear, lineWidth: 2
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
                    Text("One hop at a time.")
                        .font(.system(size: 31, weight: .bold, design: .rounded)).tracking(-1)
                    instruction(
                        "01",
                        title: "Follow your beak.",
                        text: "Tap the countryside or HOP to move forward. Swipe or use the arrows to step left, right or back.",
                        icon: "hand.tap"
                    )
                    instruction(
                        "02",
                        title: "Find a little opening.",
                        text: "Cars never stop. Wait on a grassy verge, then hop through a clear gap. There is no timer rushing you.",
                        icon: "car.side"
                    )
                    instruction(
                        "03",
                        title: "Go with the flow.",
                        text: "Land on a floating log to cross water. It carries you sideways, so hop off before it reaches the edge.",
                        icon: "water.waves"
                    )
                    instruction(
                        "04",
                        title: "Grow your flock.",
                        text: "Your farthest row is your score. Golden coins and personal bests unlock three new companions, saved on this device.",
                        icon: "sparkles"
                    )
                    primary("Got it", symbol: "checkmark") { store.showGuide = false }
                }.padding(26)
            }
            .background(Palette.cream).foregroundStyle(Palette.ink)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { store.showGuide = false } } }
        }
        .tint(Palette.ink)
    }

    private func instruction(_ number: String, title: String, text: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon).font(.system(size: 23, weight: .medium))
                .frame(width: 49, height: 49).background(Palette.mint, in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 8) {
                Text("\(number) / \(title)").font(.system(size: 16, weight: .bold, design: .rounded))
                Text(text).font(.system(size: 14)).foregroundStyle(Palette.ink.opacity(0.75)).lineSpacing(4)
            }
        }
    }
}

private struct DuckPortrait: View {
    let color: Color
    var body: some View {
        ZStack {
            Ellipse().fill(Palette.ink.opacity(0.10)).frame(width: 71, height: 16).offset(y: 32)
            RoundedRectangle(cornerRadius: 12).fill(color).frame(width: 56, height: 40).offset(y: 11)
            RoundedRectangle(cornerRadius: 11).fill(color).frame(width: 43, height: 39).offset(x: 7, y: -14)
            RoundedRectangle(cornerRadius: 4).fill(Palette.coral).frame(width: 24, height: 11).offset(x: 30, y: -7)
            Circle().fill(Palette.ink).frame(width: 5, height: 5).offset(x: 17, y: -19)
            RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.22)).frame(width: 26, height: 19).offset(
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
        view.backgroundColor = ToyColor.mint
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
