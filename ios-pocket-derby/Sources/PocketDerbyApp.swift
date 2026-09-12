import SpriteKit
import SwiftUI

@main
struct PocketDerbyApp: App {
    @StateObject private var store = GameStore()
    var body: some Scene {
        WindowGroup {
            DerbyView(store: store)
                .preferredColorScheme(.dark)
                .statusBarHidden()
        }
    }
}

struct DerbyView: View {
    @ObservedObject var store: GameStore
    @State private var scene: ArenaScene?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CityBackdrop()
                if let scene {
                    if store.screen == .title {
                        TitleScreen(store: store, scene: scene, compact: geometry.size.height < 350)
                            .transition(.opacity)
                    } else {
                        MatchScreen(store: store, scene: scene)
                            .transition(.opacity)
                    }
                }
                if store.engine.paused, store.screen == .match {
                    PausePanel(store: store).transition(.scale(scale: 0.94).combined(with: .opacity))
                }
                if store.screen == .results {
                    ResultsPanel(store: store).transition(.scale(scale: 0.92).combined(with: .opacity))
                }
                if store.showHelp {
                    HelpPanel(store: store).transition(.scale(scale: 0.94).combined(with: .opacity))
                }
            }
            .foregroundStyle(Theme.cream)
            .animation(store.reducedMotion ? nil : .spring(response: 0.42, dampingFraction: 0.8), value: store.screen)
            .animation(store.reducedMotion ? nil : .spring(response: 0.42, dampingFraction: 0.8), value: store.showHelp)
            .animation(
                store.reducedMotion ? nil : .spring(response: 0.36, dampingFraction: 0.8),
                value: store.engine.paused
            )
            .onAppear {
                store.reducedMotion = reducedMotion
                scene = ArenaScene(store: store)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    store.pause()
                }
            }
            .onChange(of: reducedMotion) { _, value in store.reducedMotion = value }
        }
    }
}

// MARK: - Title

private struct TitleScreen: View {
    @ObservedObject var store: GameStore
    let scene: ArenaScene
    let compact: Bool
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: compact ? 10 : 16) {
                HStack(spacing: 9) {
                    SpeedLines(height: 12)
                    Text("THE ROOFTOP SERIES").tracking(3.2).font(Theme.label(10))
                }
                .foregroundStyle(Theme.cyan)
                Wordmark(size: compact ? 50 : 62)
                Text("Toy cars. Rooftop football. Ninety frantic seconds.")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: store.start) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill").font(.system(size: 15, weight: .black))
                        Text("KICK OFF").tracking(1.6)
                        Spacer()
                        Text("90 s").font(Theme.label(12, weight: .bold)).opacity(0.7)
                    }
                    .font(Theme.display(16))
                    .padding(.horizontal, 22).frame(height: 56)
                }
                .buttonStyle(ArcadeButtonStyle(radius: 18))
                .accessibilityIdentifier("play")
                HStack(spacing: 18) {
                    Button { store.showHelp = true } label: {
                        Label("How to play", systemImage: "gamecontroller.fill")
                    }
                    SoundButton(store: store)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.muted)
            }
            .frame(width: compact ? 250 : 290)
            VStack(spacing: 4) {
                HStack {
                    eyebrow("01 · SKYLINE COURT", color: Theme.muted)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(Theme.cyan).frame(width: 6, height: 6)
                        eyebrow("CPU RIVAL READY", color: Theme.cyan)
                    }
                }.padding(.horizontal, 26)
                ArenaView(scene: scene)
                    .allowsHitTesting(false)
                    .frame(maxHeight: compact ? 200 : 240)
                    .rotationEffect(.degrees(-4))
                    .shadow(color: Theme.cyan.opacity(0.18), radius: 40, y: 20)
                HStack(spacing: 12) {
                    StatChip(title: "WINS", value: "\(store.record.wins)")
                    StatChip(title: "BEST DIFF", value: difference(store.record.bestDifference))
                    StatChip(title: "MATCHES", value: "\(store.record.played)")
                }
            }.frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }
}

private struct Wordmark: View {
    let size: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: -size * 0.16) {
            Text("POCKET")
                .foregroundStyle(Theme.cream)
                .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: 3)
            Text("DERBY")
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Theme.cyan, Color(hex: 0x21B6DA)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Theme.cyan.opacity(0.55), radius: 18, y: 4)
        }
        .font(Theme.display(size))
        .italic()
        .kerning(-1)
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Match

private struct MatchScreen: View {
    @ObservedObject var store: GameStore
    let scene: ArenaScene
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    SpeedLines(height: 11)
                    Text("POCKET DERBY").tracking(2.4).font(Theme.label(10))
                }
                .foregroundStyle(Theme.cyan)
                Spacer()
                Scoreboard(store: store)
                Spacer()
                Button(action: store.pause) {
                    Image(systemName: "pause.fill").font(.system(size: 15, weight: .black))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(ArcadeButtonStyle(primary: false, radius: 14))
                .accessibilityLabel("Pause match").accessibilityIdentifier("pause")
            }
            .padding(.horizontal, 22)
            .frame(height: 50)
            ZStack {
                ArenaView(scene: scene)
                    .accessibilityLabel("Arena. Tap a location to drive there.")
                    .accessibilityIdentifier("arena")
                if store.engine.phase == .kickoff {
                    Callout(
                        headline: store.engine.phaseTime > 1.2 ? "READY?" : "GO!",
                        caption: "YOU’RE BLUE  ·  SCORE IN THE RIGHT GOAL",
                        tint: Theme.cyan
                    )
                    .id(store.engine.phaseTime > 1.2)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                }
                if store.engine.phase == .goal {
                    Callout(
                        headline: store.engine.lastScorerIsPlayer ? "GOAL!" : "CONCEDED",
                        caption: store.engine.lastScorerIsPlayer ? "SKYLINE BLUE STRIKES" : "SUNSET ORANGE SCORES",
                        tint: store.engine.lastScorerIsPlayer ? Theme.cyan : Theme.coral
                    )
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .animation(
                store.reducedMotion ? nil : .spring(response: 0.38, dampingFraction: 0.62),
                value: store.engine.phase
            )
            ControlDeck(store: store)
        }
        .padding(.bottom, 4)
    }
}

private struct Callout: View {
    let headline: String
    let caption: String
    let tint: Color
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 14) {
                SpeedLines(color: tint, height: 26)
                Text(headline)
                    .font(Theme.display(44)).italic().kerning(-1)
                    .foregroundStyle(LinearGradient(colors: [.white, tint], startPoint: .top, endPoint: .bottom))
                    .shadow(color: tint.opacity(0.6), radius: 16, y: 2)
                SpeedLines(color: tint, height: 26).scaleEffect(x: -1)
            }
            Text(caption).font(Theme.label(10)).tracking(2.2).foregroundStyle(Theme.cream.opacity(0.85))
        }
        .padding(.horizontal, 30).padding(.vertical, 16)
        .glass(radius: 24, tint: tint)
        .allowsHitTesting(false)
    }
}

private struct Scoreboard: View {
    @ObservedObject var store: GameStore
    var body: some View {
        let closing = store.engine.remaining < 15
        HStack(spacing: 12) {
            TeamCrest(color: Theme.cyan, number: "01", size: 24)
            Text("\(store.engine.playerGoals)")
                .foregroundStyle(Theme.cyan).font(Theme.display(30)).monospacedDigit()
                .contentTransition(.numericText())
            VStack(spacing: 4) {
                Text(timeLabel)
                    .font(.system(size: 19, weight: .heavy, design: .rounded)).monospacedDigit()
                    .foregroundStyle(closing ? Theme.coral : Theme.cream)
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.1))
                        Capsule().fill(closing ? Theme.coral : Theme.cyan)
                            .frame(width: proxy.size.width * store.engine.remaining / 90)
                    }
                }.frame(width: 64, height: 3)
            }
            Text("\(store.engine.opponentGoals)")
                .foregroundStyle(Theme.coral).font(Theme.display(30)).monospacedDigit()
                .contentTransition(.numericText())
            TeamCrest(color: Theme.coral, number: "02", size: 24)
        }
        .padding(.horizontal, 14).padding(.vertical, 5)
        .glass(radius: 18)
        .animation(.default, value: store.engine.playerGoals + store.engine.opponentGoals)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Score: you \(store.engine.playerGoals), CPU \(store.engine.opponentGoals). \(timeLabel) remaining."
        )
        .accessibilityIdentifier("scoreboard")
    }

    private var timeLabel: String {
        let seconds = Int(ceil(store.engine.remaining))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct ControlDeck: View {
    @ObservedObject var store: GameStore
    var body: some View {
        HStack(spacing: 16) {
            Joystick(store: store).frame(width: 78, height: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text("STEER").font(Theme.label(10)).tracking(2).foregroundStyle(Theme.cyan)
                Text("Drag the stick or tap the pitch.").font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
            Button { store.engine.brake() } label: {
                VStack(spacing: 4) {
                    Image(systemName: "hand.raised.fill").font(.system(size: 16, weight: .bold))
                    Text(store.engine.brakeRemaining > 0 ? "STOPPING" : "BRAKE")
                        .font(Theme.label(8)).tracking(0.8)
                }
                .frame(width: 62, height: 60)
                .foregroundStyle(store.engine.brakeRemaining > 0 ? Theme.cyan : Theme.cream)
            }
            .buttonStyle(ArcadeButtonStyle(primary: false, radius: 18))
            .accessibilityLabel("Brake").accessibilityIdentifier("brake")
            Button { store.engine.burst() } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.fill").font(.system(size: 24, weight: .black))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("BOOST").font(Theme.display(14)).tracking(1.4)
                        HStack(spacing: 3) {
                            ForEach(0 ..< 6, id: \.self) { index in
                                Parallelogram()
                                    .fill(Theme.ink
                                        .opacity(store.engine.player.boost * 6 > Double(index) + 0.5 ? 0.85 : 0.22))
                                    .frame(width: 11, height: 6)
                            }
                        }
                    }
                }
                .frame(width: 156, height: 60)
            }
            .buttonStyle(ArcadeButtonStyle(radius: 20))
            .opacity(store.engine.player.boost > 0.12 ? 1 : 0.55)
            .accessibilityLabel("Boost").accessibilityIdentifier("boost")
        }
        .padding(.horizontal, 26)
        .frame(height: 76)
    }
}

// MARK: - Panels

private struct PausePanel: View {
    @ObservedObject var store: GameStore
    var body: some View {
        Modal {
            VStack(spacing: 16) {
                eyebrow("TAKE A BREATHER", color: Theme.cyan)
                Headline("PIT STOP", size: 40)
                Text("Your match is right where you left it.").font(.system(size: 13)).foregroundStyle(Theme.muted)
                HStack(spacing: 12) {
                    ActionButton("RESUME", icon: "play.fill", primary: true, run: store.resume)
                    ActionButton("HOW TO PLAY", icon: "gamecontroller.fill", primary: false) { store.showHelp = true }
                }
                HStack(spacing: 30) {
                    SoundButton(store: store)
                    Button("End match") { store.home() }
                }.font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted).frame(height: 38)
            }.frame(width: 430)
        }
    }
}

private struct ResultsPanel: View {
    @ObservedObject var store: GameStore
    var body: some View {
        let win = store.engine.playerGoals > store.engine.opponentGoals
        let draw = store.engine.playerGoals == store.engine.opponentGoals
        let tint = win ? Theme.gold : draw ? Theme.cyan : Theme.coral
        Modal(tint: tint) {
            HStack(spacing: 34) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: win ? "trophy.fill" : draw ? "equal.circle.fill" : "flag.checkered")
                        eyebrow(win ? "ROOFTOP CHAMPION" : "FULL TIME · ROOFTOP 01", color: tint)
                    }.foregroundStyle(tint)
                    Headline(win ? "ROOFTOP\nROYALTY." : draw ? "EVEN\nSTEVENS." : "NEXT ONE\nIS YOURS.", size: 40)
                    Text(win ? "The skyline belongs to you." : draw ? "A rivalry worth running back." :
                        "Find the angle. Make the comeback.")
                        .font(.system(size: 12)).foregroundStyle(Theme.muted)
                    HStack(spacing: 10) {
                        StatChip(title: "BEST DIFF", value: difference(store.record.bestDifference))
                        StatChip(title: "CAREER WINS", value: "\(store.record.wins)")
                    }
                }
                VStack(spacing: 14) {
                    HStack(alignment: .center, spacing: 16) {
                        ScoreColumn(color: Theme.cyan, number: "01", goals: store.engine.playerGoals, name: "YOU")
                        Text(":").foregroundStyle(Theme.muted).font(.system(size: 34, weight: .light))
                        ScoreColumn(color: Theme.coral, number: "02", goals: store.engine.opponentGoals, name: "CPU")
                    }
                    ActionButton("REMATCH", icon: "arrow.clockwise", primary: true, run: store.start)
                    Button("Back to clubhouse", action: store.home)
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted).frame(height: 36)
                }.frame(width: 220)
            }
        }
    }
}

private struct ScoreColumn: View {
    let color: Color
    let number: String
    let goals: Int
    let name: String
    var body: some View {
        VStack(spacing: 4) {
            TeamCrest(color: color, number: number, size: 22)
            Text("\(goals)").foregroundStyle(color).font(Theme.display(62)).monospacedDigit()
                .shadow(color: color.opacity(0.45), radius: 14, y: 4)
            Text(name).font(Theme.label(10)).tracking(2).foregroundStyle(color)
        }
    }
}

private struct HelpPanel: View {
    @ObservedObject var store: GameStore
    var body: some View {
        Modal {
            VStack(alignment: .leading, spacing: 15) {
                eyebrow("YOUR FIRST KICKOFF", color: Theme.cyan)
                Headline("DRIVE. BUMP. CELEBRATE.", size: 27)
                HStack(alignment: .top, spacing: 22) {
                    HelpItem(
                        number: "01",
                        icon: "dot.arrowtriangles.up.right.down.left.circle",
                        title: "Find your line",
                        text: "Drag the left stick to steer.\nOr tap the pitch to drive there."
                    )
                    HelpItem(
                        number: "02",
                        icon: "bolt.fill",
                        title: "Bring the boost",
                        text: "Tap BOOST for a speed burst.\nIt recharges while you drive."
                    )
                    HelpItem(
                        number: "03",
                        icon: "soccerball",
                        title: "Own the rooftop",
                        text: "Bump the ball into the right goal.\nMost goals in 90 seconds wins."
                    )
                }
                HStack {
                    Text("You’re BLUE. Turn behind the ball for a clean shot.")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.cyan)
                    Spacer()
                    ActionButton("GOT IT", icon: "checkmark", primary: true) { store.showHelp = false }
                        .frame(width: 125)
                }
            }.frame(maxWidth: 620)
        }
    }
}

private struct HelpItem: View {
    let number: String
    let icon: String
    let title: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.coral)
                    .frame(width: 30, height: 30)
                    .background(Theme.coral.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(number).font(Theme.display(16)).foregroundStyle(Theme.coral)
            }
            Text(title).font(.system(size: 14, weight: .bold))
            Text(text).font(.system(size: 11)).foregroundStyle(Theme.muted).lineSpacing(4)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Modal<Content: View>: View {
    var tint: Color = .white
    @ViewBuilder let content: Content
    var body: some View {
        ZStack {
            Color(hex: 0x03101A).opacity(0.82).ignoresSafeArea()
            content.padding(26)
                .glass(radius: 28, tint: tint)
                .padding(18)
        }
    }
}

private struct Headline: View {
    let text: String
    let size: CGFloat
    init(_ text: String, size: CGFloat) {
        self.text = text
        self.size = size
    }

    var body: some View {
        Text(text).font(Theme.display(size)).italic().kerning(-0.8).lineSpacing(-size * 0.18)
            .shadow(color: .black.opacity(0.3), radius: 0, y: 2)
    }
}

private struct ActionButton: View {
    let title: String
    let icon: String
    let primary: Bool
    let run: () -> Void
    init(_ title: String, icon: String, primary: Bool, run: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.primary = primary
        self.run = run
    }

    var body: some View {
        Button(action: run) {
            HStack(spacing: 9) {
                Text(title).tracking(1)
                Image(systemName: icon)
            }
            .font(Theme.display(12))
            .frame(maxWidth: .infinity).frame(height: 48)
        }
        .buttonStyle(ArcadeButtonStyle(primary: primary, radius: 15))
    }
}

private struct SoundButton: View {
    @ObservedObject var store: GameStore
    var body: some View {
        Button(action: store.toggleSound) {
            Label(
                store.sound ? "Sound on" : "Sound off",
                systemImage: store.sound ? "speaker.wave.2.fill" : "speaker.slash.fill"
            )
            .frame(minHeight: 38)
        }.accessibilityIdentifier("sound")
    }
}

private struct StatChip: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(Theme.display(22, weight: .heavy)).foregroundStyle(Theme.cream).monospacedDigit()
            Text(title).font(Theme.label(8)).tracking(1.4).foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .frame(minWidth: 88, alignment: .leading)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(
            .white.opacity(0.08),
            lineWidth: 1
        ))
    }
}

private func eyebrow(_ text: String, color: Color) -> some View {
    Text(text).font(Theme.label(9)).tracking(1.8).foregroundStyle(color)
}

private func difference(_ value: Int?) -> String {
    guard let value else { return "—" }
    return value > 0 ? "+\(value)" : "\(value)"
}

private struct Joystick: View {
    @ObservedObject var store: GameStore
    @State private var knob = CGSize.zero
    var body: some View {
        ZStack {
            Circle().fill(
                RadialGradient(
                    colors: [Color(hex: 0x0B1F2B), Color(hex: 0x17343F)],
                    center: .center,
                    startRadius: 6,
                    endRadius: 40
                )
            )
            .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 1))
            .shadow(color: Theme.cyan.opacity(knob == .zero ? 0.12 : 0.4), radius: 12)
            Circle().stroke(Theme.cyan.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [3, 5])).padding(10)
            ForEach(0 ..< 4, id: \.self) { index in
                Capsule().fill(Theme.cyan.opacity(0.35)).frame(width: 2, height: 6)
                    .offset(y: -30).rotationEffect(.degrees(Double(index) * 90))
            }
            Circle().fill(LinearGradient(
                colors: [Color(hex: 0x6F94A4), Color(hex: 0x2B4B58)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
            .overlay(Circle().fill(.white.opacity(0.18)).frame(width: 12, height: 6).offset(y: -9))
            .frame(width: 38, height: 38).shadow(color: .black.opacity(0.45), radius: 5, y: 4)
            .offset(knob)
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
            let vector = Vector(x: value.translation.width, y: -value.translation.height)
            let normalized = vector.length > 28 ? vector.unit : vector / 28
            knob = CGSize(width: normalized.x * 24, height: -normalized.y * 24)
            store.engine.driveTarget = nil
            store.engine.steering = normalized
        }.onEnded { _ in
            knob = .zero
            store.engine.steering = .zero
        })
        .accessibilityLabel("Steering joystick. Drag in the direction you want to drive.")
        .accessibilityIdentifier("joystick")
    }
}

private struct ArenaView: UIViewRepresentable {
    let scene: ArenaScene

    func makeUIView(context _: Context) -> SKView {
        let view = SKView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.allowsTransparency = true
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context _: Context) {
        if uiView.scene !== scene {
            uiView.presentScene(scene)
        }
    }
}
