import SpriteKit
import SwiftUI

let ink = Color(red: 0.02, green: 0.045, blue: 0.09)
let cream = Color(red: 0.985, green: 0.95, blue: 0.86)
let muted = Color(red: 0.64, green: 0.72, blue: 0.76)
let mint = Color(red: 0.72, green: 0.93, blue: 0.78)
let orange = Color(red: 1, green: 0.66, blue: 0.36)
let gold = Color(red: 0.87, green: 0.72, blue: 0.44)

@main
struct VelvetSliceApp: App {
    @StateObject private var store = GameStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .preferredColorScheme(.dark)
                .statusBarHidden()
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active {
                        store.pause()
                    }
                }
        }
    }
}

struct LacquerBackground: View {
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                LinearGradient(colors: [Color(red: 0.05, green: 0.13, blue: 0.2), ink, Color(red: 0.05, green: 0.03, blue: 0.07)], startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [Color(red: 0.11, green: 0.25, blue: 0.3), .clear], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: size.height * 0.55)
                RadialGradient(colors: [orange.opacity(0.14), .clear], center: UnitPoint(x: 1.05, y: -0.05), startRadius: 0, endRadius: size.width * 0.8)
                RadialGradient(colors: [mint.opacity(0.09), .clear], center: UnitPoint(x: -0.1, y: 1.02), startRadius: 0, endRadius: size.width * 0.75)
                Canvas { context, size in
                    for index in 0 ..< 140 {
                        let x = CGFloat((index * 127 + 53) % 991) / 991 * size.width
                        let y = CGFloat((index * 263 + 19) % 997) / 997 * size.height
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)), with: .color(.white.opacity(index % 4 == 0 ? 0.11 : 0.05)))
                    }
                    for index in 0 ..< 14 {
                        var path = Path()
                        let offset = CGFloat(index) * 96 - 260
                        path.move(to: CGPoint(x: offset, y: size.height))
                        path.addLine(to: CGPoint(x: offset + size.height * 0.55, y: 0))
                        context.stroke(path, with: .color(.white.opacity(index % 3 == 0 ? 0.035 : 0.018)), lineWidth: 1)
                    }
                }
                RoundedRectangle(cornerRadius: 34)
                    .stroke(gold.opacity(0.22), lineWidth: 1)
                    .padding(.horizontal, 12)
                    .padding(.top, geometry.safeAreaInsets.top + 6)
                    .padding(.bottom, max(10, geometry.safeAreaInsets.bottom + 2))
                    .blendMode(.screen)
            }
        }
        .ignoresSafeArea()
    }
}

struct RootView: View {
    @ObservedObject var store: GameStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LacquerBackground()
            switch store.screen {
            case .home: home.transition(.opacity)
            case .playing: gameplay.transition(.opacity)
            case .results: results.transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            if store.paused {
                pauseOverlay.transition(.opacity)
            }
            if store.showRules {
                rulesOverlay.transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.32), value: store.screen)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: store.paused)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: store.showRules)
        .foregroundStyle(cream)
        .font(.custom("AvenirNext-Medium", size: 15))
        .dynamicTypeSize(.xSmall ... .xxxLarge)
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "diamond.fill").font(.system(size: 7)).foregroundStyle(gold)
                Text("THE POCKET ORCHARD").font(.custom("AvenirNext-DemiBold", size: 10)).tracking(2.4).foregroundStyle(gold.opacity(0.9))
            }
            Spacer()
            iconButton(store.soundOn ? "speaker.wave.2" : "speaker.slash", label: store.soundOn ? "Mute sound" : "Enable sound") { store.toggleSound() }
        }
    }

    private var home: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 4)
                ZStack {
                    Text("Velvet")
                        .font(.custom("Baskerville", size: 70))
                        .offset(y: -34)
                    Text("Slice")
                        .font(.custom("Baskerville-Italic", size: 82))
                        .foregroundStyle(LinearGradient(colors: [orange, Color(red: 1, green: 0.8, blue: 0.5)], startPoint: .leading, endPoint: .trailing))
                        .offset(y: 38)
                    BladeStroke().frame(width: 230, height: 22).offset(y: 3).accessibilityHidden(true)
                }
                .frame(height: 158)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Velvet Slice")
                Text("A little edge. A lot of juice.")
                    .font(.custom("Baskerville-Italic", size: 17))
                    .foregroundStyle(muted)
                    .padding(.top, 8)
                FruitComposition()
                    .frame(height: max(160, min(240, geometry.size.height * 0.29)))
                    .padding(.vertical, 6)
                    .accessibilityHidden(true)
                HStack(spacing: 9) {
                    Image(systemName: "crown.fill").font(.system(size: 11)).foregroundStyle(gold)
                    Text("ARCADE BEST").tracking(1.9).font(.custom("AvenirNext-DemiBold", size: 10)).foregroundStyle(muted)
                    Text("\(store.best)").foregroundStyle(cream).font(.custom("Baskerville", size: 18)).monospacedDigit()
                }
                .padding(.horizontal, 16).frame(height: 36)
                .overlay(Capsule().stroke(gold.opacity(0.35), lineWidth: 1))
                .padding(.bottom, 20)
                actionButton("Play arcade", subtitle: "60 SECONDS · FIND YOUR FLOW", system: "arrow.up.right", primary: true) { store.begin(.arcade) }
                actionButton("Practice", subtitle: "NO CLOCK. NO BOMBS. JUST FLOW.", system: "leaf", primary: false) { store.begin(.practice) }
                    .padding(.top, 10)
                Spacer(minLength: 8)
                Button { store.showRules = true } label: {
                    Label("The art of the slice", systemImage: "hand.draw")
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(muted)
                        .frame(height: 44)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 10)
        }
    }

    private var gameplay: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    eyebrow("SCORE")
                    Text("\(store.round.score)")
                        .font(.custom("Baskerville", size: 46))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .shadow(color: mint.opacity(0.35), radius: 14)
                }
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: store.mode == .arcade ? "timer" : "infinity").font(.system(size: 12, weight: .medium)).foregroundStyle(gold)
                    Text(store.mode == .arcade ? clockText(store.round.remaining) : "Free flow")
                        .font(.custom("AvenirNext-DemiBold", size: 15))
                        .monospacedDigit()
                        .foregroundStyle(store.round.remaining <= 10 && store.mode == .arcade ? orange : cream)
                }
                .padding(.horizontal, 14).frame(height: 36)
                .background(.white.opacity(0.05), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.1)))
                Spacer()
                iconButton("pause", label: "Pause game") { store.pause() }
            }.padding(.horizontal, 30).padding(.top, 4)
            if store.mode == .arcade {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.07))
                        Capsule()
                            .fill(LinearGradient(colors: store.round.remaining <= 10 ? [orange, Color(red: 1, green: 0.5, blue: 0.4)] : [mint, gold], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, geometry.size.width * store.round.remaining / 60))
                    }
                }.frame(height: 3).padding(.horizontal, 30).padding(.top, 10)
            }
            ZStack {
                Playfield(store: store)
                if store.countdown > 0 {
                    VStack(spacing: 14) {
                        eyebrow("FIND YOUR FLOW")
                        Text("\(store.countdown)")
                            .font(.custom("Baskerville", size: 118))
                            .foregroundStyle(LinearGradient(colors: [cream, orange], startPoint: .top, endPoint: .bottom))
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.snappy(duration: 0.3), value: store.countdown)
                            .shadow(color: orange.opacity(0.45), radius: 30)
                        Text("Swipe through the fruit")
                            .font(.custom("Baskerville-Italic", size: 25))
                        Text(store.mode == .arcade ? "Avoid bombs. Slice 3+ for a combo." : "Nothing to lose. Everything to slice.")
                            .font(.custom("AvenirNext-Medium", size: 12)).foregroundStyle(muted)
                    }.allowsHitTesting(false)
                }
            }
            HStack(spacing: 0) {
                statusChip("sparkle", text: "\(store.round.sliced) SLICED")
                Spacer()
                if store.mode == .arcade {
                    HStack(spacing: 8) {
                        statusChip("bolt.fill", text: store.round.bestCombo >= 3 ? "\(store.round.bestCombo)× COMBO" : "COMBO —")
                        HStack(spacing: 6) {
                            ForEach(0 ..< 3) { index in
                                Circle()
                                    .fill(index < store.round.bombs ? Color(red: 1, green: 0.42, blue: 0.36) : .white.opacity(0.14))
                                    .frame(width: 8, height: 8)
                                    .overlay(Circle().stroke(index < store.round.bombs ? Color(red: 1, green: 0.42, blue: 0.36).opacity(0.5) : .clear, lineWidth: 3).blur(radius: 2))
                            }
                        }
                        .padding(.leading, 4)
                        .accessibilityLabel("\(store.round.bombs) of 3 bombs hit")
                    }
                } else {
                    statusChip("crown.fill", text: "BEST \(store.practiceBest)")
                }
            }
            .padding(.horizontal, 30).padding(.bottom, 16).padding(.top, 6)
        }
    }

    private var results: some View {
        let ended = store.round.bombs >= 3
        return VStack(spacing: 0) {
            topBar
            Spacer(minLength: 8)
            eyebrow(store.mode == .practice ? "PRACTICE COMPLETE" : "ARCADE COMPLETE")
            Text(ended ? "A sharp lesson." : (store.round.score == 0 ? "Find your rhythm." : "Beautifully sliced."))
                .font(.custom("Baskerville-Italic", size: 36))
                .padding(.top, 12)
                .minimumScaleFactor(0.7).lineLimit(1)
            Text(ended ? "Three bombs. Breathe, then try again." : (store.round.score == 0 ? "Try a long swipe as the fruit rises." : "A moment of focus. A splash of color."))
                .font(.custom("AvenirNext-Medium", size: 12)).foregroundStyle(muted).padding(.top, 6)
            ZStack {
                Circle().fill(RadialGradient(colors: [(store.newBest ? gold : mint).opacity(0.22), .clear], center: .center, startRadius: 20, endRadius: 130))
                Circle().stroke(gold.opacity(0.4), lineWidth: 1).padding(14)
                Circle().stroke(.white.opacity(0.08), lineWidth: 1).padding(4)
                ForEach(0 ..< 12) { index in
                    Capsule().fill(gold.opacity(index % 3 == 0 ? 0.7 : 0.3)).frame(width: 1, height: index % 3 == 0 ? 9 : 5)
                        .offset(y: -102)
                        .rotationEffect(.degrees(Double(index) * 30))
                }
                VStack(spacing: -4) {
                    Text("\(store.round.score)")
                        .font(.custom("Baskerville", size: store.round.score >= 1000 ? 78 : 92)).monospacedDigit()
                        .shadow(color: (store.newBest ? gold : mint).opacity(0.35), radius: 18)
                    eyebrow("POINTS")
                }
                if store.newBest {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill").font(.system(size: 10))
                        Text("NEW BEST").tracking(1.8).font(.custom("AvenirNext-DemiBold", size: 10))
                    }
                    .foregroundStyle(ink).padding(.horizontal, 12).frame(height: 26)
                    .background(LinearGradient(colors: [gold, Color(red: 0.98, green: 0.87, blue: 0.62)], startPoint: .leading, endPoint: .trailing), in: Capsule())
                    .offset(y: 112)
                }
            }
            .frame(width: 236, height: 236)
            .padding(.top, 14)
            .accessibilityElement(children: .combine)
            HStack(spacing: 0) {
                resultStat("\(store.round.sliced)", label: "FRUIT SLICED")
                hairline
                resultStat(store.round.bestCombo >= 3 ? "\(store.round.bestCombo)×" : "—", label: "BEST COMBO")
                hairline
                resultStat(store.mode == .practice ? clockText(store.round.elapsed) : "\(store.round.missed)", label: store.mode == .practice ? "IN THE FLOW" : "MISSED")
            }
            .padding(.vertical, 20)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(gold.opacity(0.22)))
            .padding(.top, 22)
            HStack(spacing: 7) {
                Image(systemName: "crown.fill").font(.system(size: 10)).foregroundStyle(gold)
                Text("\(store.mode == .arcade ? "Arcade" : "Practice") best \(store.mode == .arcade ? store.best : store.practiceBest)")
            }.font(.custom("AvenirNext-Medium", size: 12)).foregroundStyle(muted).padding(.top, 16)
            Spacer(minLength: 16)
            actionButton("Slice again", subtitle: store.mode == .arcade ? "A FRESH 60 SECONDS" : "BACK INTO THE FLOW", system: "arrow.clockwise", primary: true) { store.begin(store.mode) }
            Button("Back to the orchard") { store.screen = .home }
                .font(.custom("AvenirNext-Medium", size: 13)).foregroundStyle(muted)
                .frame(height: 52).buttonStyle(.plain)
        }.padding(.horizontal, 30).padding(.bottom, 10)
    }

    private var hairline: some View {
        Rectangle().fill(gold.opacity(0.25)).frame(width: 1, height: 34)
    }

    private var pauseOverlay: some View {
        overlayCard {
            Image(systemName: "pause").font(.system(size: 26, weight: .ultraLight)).foregroundStyle(gold)
            eyebrow("TAKE A BREATH")
            Text("Stay in the flow.").font(.custom("Baskerville-Italic", size: 34))
            Text("Your fruit and clock will wait.")
                .font(.custom("AvenirNext-Medium", size: 13)).foregroundStyle(muted)
            actionButton("Resume", subtitle: "RIGHT WHERE YOU LEFT OFF", system: "play", primary: true) { store.paused = false }
                .padding(.top, 8)
            HStack(spacing: 12) {
                secondaryButton("Restart") { store.begin(store.mode) }
                secondaryButton("Finish run") { store.finish() }
            }
            Button { store.toggleSound() } label: {
                Label(store.soundOn ? "Sound on" : "Sound off", systemImage: store.soundOn ? "speaker.wave.2" : "speaker.slash")
                    .foregroundStyle(muted).frame(height: 44)
            }.buttonStyle(.plain)
        }
    }

    private var rulesOverlay: some View {
        overlayCard {
            eyebrow("THE ART OF THE SLICE")
            Text("Follow the fruit.").font(.custom("Baskerville-Italic", size: 34))
            VStack(alignment: .leading, spacing: 20) {
                ruleRow("hand.draw", title: "Make your move", text: "Drag a finger through airborne fruit. Each slice earns 10 points.")
                ruleRow("sparkles", title: "Find a beautiful line", text: "Slice 3 or more fruit quickly in one swipe for a bonus of 5 per fruit.")
                ruleRow("xmark.circle", title: "Keep your edge", text: "Avoid red-ringed bombs: −25 points. Three end your run. Missed fruit: −2.", showBomb: true)
                ruleRow("leaf", title: "Or, just unwind", text: "Practice has no bombs, timer or penalties. Finish from the pause menu.")
            }.padding(.vertical, 10)
            actionButton("Let’s slice", subtitle: "YOU HAVE 60 SECONDS", system: "arrow.up.right", primary: true) {
                store.showRules = false
                store.begin(.arcade)
            }
            Button("Back") { store.showRules = false }.foregroundStyle(muted).frame(height: 44).buttonStyle(.plain)
        }
    }

    private func ruleRow(_ icon: String, title: String, text: String, showBomb: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Group {
                if showBomb {
                    Image(uiImage: FruitArt.bomb).resizable().scaledToFit().frame(height: 42)
                } else {
                    Image(systemName: icon).font(.system(size: 19, weight: .light)).foregroundStyle(gold)
                }
            }
            .frame(width: 40, height: 40)
            .background(.white.opacity(0.04), in: Circle())
            .overlay(Circle().stroke(gold.opacity(0.25)))
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.custom("AvenirNext-DemiBold", size: 14))
                Text(text).font(.custom("AvenirNext-Regular", size: 12)).foregroundStyle(muted).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func overlayCard(@ViewBuilder content: () -> some View) -> some View {
        ZStack {
            ink.opacity(0.9).ignoresSafeArea()
            VStack(spacing: 16, content: content)
                .padding(25)
                .background(
                    LinearGradient(colors: [Color(red: 0.07, green: 0.15, blue: 0.21), Color(red: 0.035, green: 0.08, blue: 0.13)], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 30)
                )
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(gold.opacity(0.3)))
                .shadow(color: .black.opacity(0.5), radius: 40, y: 20)
                .padding(.horizontal, 22)
        }
    }

    private func resultStat(_ value: String, label: String) -> some View {
        VStack(spacing: 7) {
            Text(value).font(.custom("Baskerville", size: 30)).foregroundStyle(cream)
            Text(label).font(.custom("AvenirNext-DemiBold", size: 10)).tracking(0.6).foregroundStyle(muted)
        }.frame(maxWidth: .infinity)
    }

    private func statusChip(_ icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 9)).foregroundStyle(gold)
            Text(text).tracking(1.2)
        }
        .font(.custom("AvenirNext-DemiBold", size: 11)).foregroundStyle(muted)
    }

    private func eyebrow(_ text: String) -> some View {
        HStack(spacing: 9) {
            Rectangle().fill(gold.opacity(0.45)).frame(width: 14, height: 1)
            Text(text).font(.custom("AvenirNext-DemiBold", size: 11)).tracking(2).foregroundStyle(muted)
            Rectangle().fill(gold.opacity(0.45)).frame(width: 14, height: 1)
        }.fixedSize()
    }

    private func iconButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 16, weight: .light))
                .foregroundStyle(cream).frame(width: 44, height: 44)
                .background(.white.opacity(0.05), in: Circle())
                .overlay(Circle().stroke(gold.opacity(0.28)))
        }.buttonStyle(.plain).accessibilityLabel(label)
    }

    private func actionButton(_ title: String, subtitle: String, system: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.custom("Baskerville", size: 24))
                    Text(subtitle).font(.custom("AvenirNext-DemiBold", size: 10)).tracking(0.9).opacity(0.72)
                }
                Spacer()
                Image(systemName: system).font(.system(size: 16, weight: .medium))
                    .frame(width: 40, height: 40)
                    .background(primary ? ink.opacity(0.12) : .white.opacity(0.06), in: Circle())
                    .overlay(Circle().stroke(primary ? ink.opacity(0.1) : gold.opacity(0.35)))
            }
            .foregroundStyle(primary ? ink : cream)
            .padding(.horizontal, 20)
            .frame(height: 74)
            .background(
                LinearGradient(
                    colors: primary ? [Color(red: 0.82, green: 0.97, blue: 0.85), mint, Color(red: 0.6, green: 0.86, blue: 0.72)] : [.white.opacity(0.07), .white.opacity(0.025)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(primary ? .white.opacity(0.5) : gold.opacity(0.35), lineWidth: 1))
            .shadow(color: primary ? mint.opacity(0.3) : .clear, radius: 22, y: 8)
        }.buttonStyle(SliceButtonStyle()).accessibilityLabel(title).accessibilityHint(subtitle)
    }

    private func clockText(_ seconds: Double) -> String {
        let whole = max(0, Int(ceil(seconds)))
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action).font(.custom("AvenirNext-DemiBold", size: 13))
            .frame(maxWidth: .infinity).frame(height: 48)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(gold.opacity(0.25)))
            .buttonStyle(.plain)
    }
}

struct Playfield: View {
    @ObservedObject var store: GameStore
    @State private var revealed = false

    var body: some View {
        SpriteView(scene: store.scene, isPaused: store.paused, options: [.allowsTransparency])
            .opacity(revealed ? 1 : 0)
            .onAppear { withAnimation(.easeIn(duration: 0.4).delay(0.15)) { revealed = true } }
            .accessibilityLabel("Fruit slicing playfield. Swipe across airborne fruit. Avoid red-ringed bombs.")
            .accessibilityIdentifier("playfield")
    }
}

struct SliceButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.13), value: configuration.isPressed)
    }
}

struct BladeStroke: View {
    var body: some View {
        Canvas { context, size in
            var line = Path()
            line.move(to: CGPoint(x: 0, y: size.height * 0.8))
            line.addQuadCurve(to: CGPoint(x: size.width, y: size.height * 0.2), control: CGPoint(x: size.width * 0.5, y: size.height * 0.15))
            context.addFilter(.shadow(color: mint.opacity(0.7), radius: 6))
            context.stroke(line, with: .linearGradient(Gradient(colors: [mint.opacity(0), cream, mint.opacity(0)]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
    }
}

struct FruitComposition: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            ZStack {
                Circle().fill(RadialGradient(colors: [orange.opacity(0.28), .clear], center: .center, startRadius: 0, endRadius: w * 0.34)).frame(width: w * 0.7, height: w * 0.7).position(x: w / 2, y: h * 0.48)
                Ellipse().stroke(gold.opacity(0.3), lineWidth: 1).frame(width: w * 0.8, height: 26).position(x: w / 2, y: h * 0.9)
                Ellipse().fill(Color.black.opacity(0.35)).frame(width: w * 0.7, height: 32).blur(radius: 14).position(x: w / 2, y: h * 0.88)
                Image(uiImage: FruitArt.image(.kiwi)).resizable().scaledToFit()
                    .frame(width: w * 0.47).rotationEffect(.degrees(-24)).position(x: w * 0.21, y: h * 0.55)
                Image(uiImage: FruitArt.image(.dragon)).resizable().scaledToFit()
                    .frame(width: w * 0.48).rotationEffect(.degrees(24)).position(x: w * 0.79, y: h * 0.48)
                Image(uiImage: FruitArt.image(.citrus)).resizable().scaledToFit()
                    .frame(width: w * 0.62).rotationEffect(.degrees(-12)).position(x: w * 0.49, y: h * 0.49)
                Canvas { context, size in
                    var line = Path()
                    line.move(to: CGPoint(x: size.width * 0.03, y: size.height * 0.86))
                    line.addQuadCurve(to: CGPoint(x: size.width * 0.96, y: size.height * 0.08), control: CGPoint(x: size.width * 0.68, y: size.height * 0.67))
                    context.addFilter(.shadow(color: mint.opacity(0.7), radius: 8))
                    context.stroke(line, with: .linearGradient(Gradient(colors: [mint.opacity(0), mint, cream]), startPoint: CGPoint(x: 0, y: size.height), endPoint: CGPoint(x: size.width, y: 0)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    for index in 0 ..< 11 {
                        let x = CGFloat((index * 37 + 11) % 100) / 100 * size.width
                        let y = CGFloat((index * 61 + 5) % 100) / 100 * size.height
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: index % 3 == 0 ? 4 : 2, height: index % 3 == 0 ? 6 : 3)), with: .color(index % 2 == 0 ? orange.opacity(0.7) : mint.opacity(0.65)))
                    }
                }
            }
        }
    }
}
