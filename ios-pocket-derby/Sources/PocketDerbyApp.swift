import SpriteKit
import SwiftUI

private let cream = Color(red: 0.96, green: 0.97, blue: 0.90)
private let cyan = Color(red: 0.39, green: 0.89, blue: 1.0)
private let coral = Color(red: 1.0, green: 0.53, blue: 0.40)
private let muted = Color(red: 0.55, green: 0.68, blue: 0.72)

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
                LinearGradient(
                    colors: [Color(hex: 0x173B4A), Color(hex: 0x081C2B)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                skyline
                if let scene {
                    if store.screen == .title {
                        title(scene: scene, compact: geometry.size.height < 350)
                    } else {
                        match(scene: scene, compact: geometry.size.height < 350)
                    }
                }
                if store.engine.paused, store.screen == .match {
                    pausePanel
                }
                if store.screen == .results {
                    results
                }
                if store.showHelp {
                    help
                }
            }
            .foregroundStyle(cream)
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

    private var skyline: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(0 ..< 18, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: 0x254E5D).opacity(0.22))
                        .frame(width: geo.size.width / 22, height: CGFloat(34 + (index * 37) % 100))
                        .overlay(alignment: .top) {
                            Rectangle().fill(cyan.opacity(0.04)).frame(height: 2).padding(.top, 10)
                        }
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func title(scene: ArenaScene, compact: Bool) -> some View {
        HStack(spacing: 5) {
            VStack(alignment: .leading, spacing: compact ? 12 : 19) {
                HStack(spacing: 7) {
                    Image(systemName: "flag.checkered.2.crossed").foregroundStyle(cyan)
                    Text("THE ROOFTOP SERIES").tracking(3)
                }
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                VStack(alignment: .leading, spacing: -9) {
                    Text("POCKET")
                    Text("DERBY").foregroundStyle(cyan)
                }
                .font(.system(size: compact ? 48 : 59, weight: .black, design: .rounded))
                .italic()
                .fixedSize()
                Text("Little cars. Big match energy.")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(muted)
                Button(action: store.start) {
                    HStack {
                        Text("LET’S PLAY").tracking(1)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0x0C2A36))
                    .padding(.horizontal, 21).frame(height: 52)
                    .background(cyan, in: RoundedRectangle(cornerRadius: 16))
                }
                .accessibilityIdentifier("play")
                HStack(spacing: 16) {
                    Button { store.showHelp = true } label: {
                        Label("How to play", systemImage: "gamecontroller")
                    }
                    soundButton
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(muted)
            }
            .frame(width: compact ? 245 : 275)
            VStack(spacing: 0) {
                HStack {
                    capsule("01 / SKYLINE COURT", color: muted)
                    Spacer()
                    capsule("90 SEC", color: cyan)
                }.padding(.horizontal, 22)
                ArenaView(scene: scene)
                    .allowsHitTesting(false)
                    .frame(maxHeight: 235)
                    .rotationEffect(.degrees(-5))
                HStack(spacing: 27) {
                    stat("WINS", value: "\(store.record.wins)")
                    stat("BEST DIFF", value: difference(store.record.bestDifference))
                    stat("MATCHES", value: "\(store.record.played)")
                }.padding(.top, 2)
            }.frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 15)
    }

    private func match(scene: ArenaScene, compact _: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "flag.checkered").foregroundStyle(cyan)
                    Text("POCKET DERBY").tracking(2)
                }.font(.system(size: 10, weight: .heavy, design: .rounded))
                Spacer()
                scoreboard
                Spacer()
                Button(action: store.pause) {
                    Image(systemName: "pause.fill").font(.system(size: 16, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 13))
                }.accessibilityLabel("Pause match").accessibilityIdentifier("pause")
            }
            .padding(.horizontal, 22)
            .frame(height: 45)
            ZStack {
                ArenaView(scene: scene)
                    .accessibilityLabel("Arena. Tap a location to drive there.")
                    .accessibilityIdentifier("arena")
                if store.engine.phase == .kickoff {
                    VStack(spacing: 5) {
                        Text(store.engine.phaseTime > 1.2 ? "READY?" : "GO!")
                            .font(.system(size: 38, weight: .black, design: .rounded)).italic()
                        Text("BLUE CAR  •  SCORE ON THE RIGHT →")
                            .font(.system(size: 10, weight: .heavy)).tracking(1)
                    }
                    .padding(18).background(Color(hex: 0x0A2735).opacity(0.9), in: RoundedRectangle(cornerRadius: 20))
                    .allowsHitTesting(false)
                }
                if store.engine.phase == .goal {
                    VStack(spacing: 2) {
                        Text(store.engine.lastScorerIsPlayer ? "WHAT A GOAL!" : "THEY SCORED")
                            .font(.system(size: 35, weight: .black, design: .rounded)).italic()
                            .foregroundStyle(store.engine.lastScorerIsPlayer ? cyan : coral)
                        Text(store.engine.lastScorerIsPlayer ? "SKYLINE BLUE" : "SUNSET ORANGE")
                            .font(.system(size: 11, weight: .heavy)).tracking(3)
                    }
                    .padding(19).background(Color(hex: 0x092632).opacity(0.94), in: RoundedRectangle(cornerRadius: 20))
                    .allowsHitTesting(false)
                }
            }
            HStack(spacing: 18) {
                Joystick(store: store).frame(width: 78, height: 70)
                VStack(alignment: .leading, spacing: 5) {
                    Text("STEER & DRIVE").font(.system(size: 10, weight: .heavy)).tracking(1.2)
                    Text("Drag the stick, or tap the pitch.").font(.system(size: 11)).foregroundStyle(muted)
                }
                Spacer(minLength: 0)
                Button {
                    store.engine.brake()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill").font(.system(size: 17))
                        Text(store.engine.brakeRemaining > 0 ? "STOPPING" : "BRAKE")
                            .font(.system(size: 8, weight: .heavy)).tracking(0.7)
                    }.frame(width: 57, height: 58)
                        .background(
                            store.engine.brakeRemaining > 0 ? cyan.opacity(0.2) : .white.opacity(0.05),
                            in: RoundedRectangle(cornerRadius: 15)
                        )
                }.accessibilityLabel("Brake").accessibilityIdentifier("brake")
                Button { store.engine.burst() } label: {
                    HStack(spacing: 11) {
                        Image(systemName: "bolt.fill").font(.system(size: 25, weight: .black))
                        VStack(alignment: .leading, spacing: 6) {
                            Text("BOOST").font(.system(size: 13, weight: .black, design: .rounded)).tracking(1)
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(.black.opacity(0.14))
                                    Capsule().fill(Color(hex: 0x123B48))
                                        .frame(width: proxy.size.width * store.engine.player.boost)
                                }
                            }.frame(width: 73, height: 4)
                        }
                    }
                    .foregroundStyle(Color(hex: 0x102D39))
                    .frame(width: 149, height: 58)
                    .background(
                        cyan.opacity(store.engine.player.boost > 0.12 ? 1 : 0.45),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                }
                .accessibilityLabel("Boost").accessibilityIdentifier("boost")
            }
            .padding(.horizontal, 28)
            .frame(height: 73)
        }.padding(.bottom, 3)
    }

    private var scoreboard: some View {
        HStack(spacing: 14) {
            Text("YOU").foregroundStyle(cyan).font(.system(size: 9, weight: .black)).tracking(1)
            Text("\(store.engine.playerGoals)").foregroundStyle(cyan)
                .font(.system(size: 27, weight: .heavy, design: .rounded))
            VStack(spacing: 1) {
                Text(timeLabel).font(.system(size: 18, weight: .bold, design: .rounded)).monospacedDigit()
                    .foregroundStyle(store.engine.remaining < 15 ? coral : cream)
                Text("ROOFTOP 01").font(.system(size: 7, weight: .heavy)).tracking(1.8).foregroundStyle(muted)
            }.frame(width: 74)
            Text("\(store.engine.opponentGoals)").foregroundStyle(coral)
                .font(.system(size: 27, weight: .heavy, design: .rounded))
            Text("CPU").foregroundStyle(coral).font(.system(size: 9, weight: .black)).tracking(1)
        }
        .padding(.horizontal, 18).padding(.vertical, 5)
        .background(Color(hex: 0x071C2A).opacity(0.7), in: RoundedRectangle(cornerRadius: 15))
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

    private var pausePanel: some View {
        modal {
            VStack(spacing: 16) {
                capsule("TAKE A BREATHER", color: cyan)
                Text("PIT STOP").font(.system(size: 38, weight: .black, design: .rounded)).italic()
                Text("Your match is right where you left it.").font(.system(size: 13)).foregroundStyle(muted)
                HStack(spacing: 12) {
                    action("RESUME", icon: "play.fill", primary: true, run: store.resume)
                    action("HOW TO PLAY", icon: "gamecontroller", primary: false) { store.showHelp = true }
                }
                HStack(spacing: 30) {
                    soundButton
                    Button("End match") { store.home() }
                }.font(.system(size: 12, weight: .semibold)).foregroundStyle(muted).frame(height: 38)
            }.frame(width: 430)
        }
    }

    private var results: some View {
        let win = store.engine.playerGoals > store.engine.opponentGoals
        let draw = store.engine.playerGoals == store.engine.opponentGoals
        return modal {
            HStack(spacing: 35) {
                VStack(alignment: .leading, spacing: 13) {
                    capsule("FULL TIME / ROOFTOP 01", color: cyan)
                    Text(win ? "ROOFTOP\nROYALTY." : draw ? "EVEN\nSTEVENS." : "NEXT ONE\nIS YOURS.")
                        .font(.system(size: 39, weight: .black, design: .rounded)).italic().lineSpacing(-7)
                    Text(win ? "The skyline belongs to you." : draw ? "A rivalry worth running back." :
                        "Find the angle. Make the comeback.")
                        .font(.system(size: 12)).foregroundStyle(muted)
                    HStack(spacing: 20) {
                        stat("BEST DIFF", value: difference(store.record.bestDifference))
                        stat("CAREER WINS", value: "\(store.record.wins)")
                    }
                }
                VStack(spacing: 14) {
                    HStack(alignment: .center, spacing: 18) {
                        VStack(spacing: 0) {
                            Text("\(store.engine.playerGoals)").foregroundStyle(cyan)
                            Text("YOU").font(.system(size: 10, weight: .heavy)).tracking(2).foregroundStyle(cyan)
                        }
                        Text(":").foregroundStyle(muted).font(.system(size: 35, weight: .light))
                        VStack(spacing: 0) {
                            Text("\(store.engine.opponentGoals)").foregroundStyle(coral)
                            Text("CPU").font(.system(size: 10, weight: .heavy)).tracking(2).foregroundStyle(coral)
                        }
                    }.font(.system(size: 65, weight: .heavy, design: .rounded))
                    action("REMATCH", icon: "arrow.clockwise", primary: true, run: store.start)
                    Button("Back to clubhouse", action: store.home)
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(muted).frame(height: 38)
                }.frame(width: 210)
            }
        }
    }

    private var help: some View {
        modal {
            VStack(alignment: .leading, spacing: 15) {
                capsule("YOUR FIRST KICKOFF", color: cyan)
                Text("DRIVE. BUMP. CELEBRATE.")
                    .font(.system(size: 27, weight: .black, design: .rounded)).italic()
                HStack(alignment: .top, spacing: 22) {
                    helpItem(
                        "01",
                        title: "Find your line",
                        text: "Drag the left stick to steer.\nOr tap the pitch to drive there."
                    )
                    helpItem(
                        "02",
                        title: "Bring the boost",
                        text: "Tap BOOST for a speed burst.\nIt recharges while you drive."
                    )
                    helpItem(
                        "03",
                        title: "Own the rooftop",
                        text: "Bump the ball into the right goal.\nMost goals in 90 seconds wins."
                    )
                }
                HStack {
                    Text("You’re BLUE. Turn behind the ball for a clean shot.")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(cyan)
                    Spacer()
                    action("GOT IT", icon: "checkmark", primary: true) { store.showHelp = false }.frame(width: 125)
                }
            }.frame(maxWidth: 620)
        }
    }

    private func helpItem(_ number: String, title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(number).font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(coral)
            Text(title).font(.system(size: 14, weight: .bold))
            Text(text).font(.system(size: 11)).foregroundStyle(muted).lineSpacing(4)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color(hex: 0x051823).opacity(0.87).ignoresSafeArea()
            content().padding(27)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0x1B3E4C), Color(hex: 0x102D3D)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 27)
                )
                .overlay(RoundedRectangle(cornerRadius: 27).stroke(.white.opacity(0.12), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 30, y: 15)
                .padding(18)
        }
    }

    private var soundButton: some View {
        Button(action: store.toggleSound) {
            Label(
                store.sound ? "Sound on" : "Sound off",
                systemImage: store.sound ? "speaker.wave.2" : "speaker.slash"
            )
            .frame(minHeight: 38)
        }.accessibilityIdentifier("sound")
    }

    private func action(_ title: String, icon: String, primary: Bool, run: @escaping () -> Void) -> some View {
        Button(action: run) {
            HStack(spacing: 9) {
                Text(title).tracking(0.8)
                Image(systemName: icon)
            }
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .frame(maxWidth: .infinity).frame(height: 47)
            .foregroundStyle(primary ? Color(hex: 0x102D39) : cream)
            .background(primary ? cyan : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func capsule(_ text: String, color: Color) -> some View {
        Text(text).font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1.4)
            .foregroundStyle(color)
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.system(size: 23, weight: .bold, design: .rounded)).foregroundStyle(cream)
            Text(title).font(.system(size: 8, weight: .heavy)).tracking(1.3).foregroundStyle(muted)
        }
    }

    private func difference(_ value: Int?) -> String {
        guard let value else { return "—" }
        return value > 0 ? "+\(value)" : "\(value)"
    }
}

private struct Joystick: View {
    @ObservedObject var store: GameStore
    @State private var knob = CGSize.zero
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0x102D3C)).overlay(Circle().stroke(cyan.opacity(0.16), lineWidth: 1))
            Circle().stroke(.white.opacity(0.06), lineWidth: 1).padding(13)
            Image(systemName: "plus").font(.system(size: 30, weight: .ultraLight)).foregroundStyle(cyan.opacity(0.14))
            Circle().fill(LinearGradient(
                colors: [Color(hex: 0x476775), Color(hex: 0x294955)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
            .frame(width: 39, height: 39).shadow(color: .black.opacity(0.3), radius: 5, y: 4)
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

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
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
