import SpriteKit
import SwiftUI

private let ink = Color(red: 0.025, green: 0.055, blue: 0.105)
private let cream = Color(red: 0.98, green: 0.94, blue: 0.84)
private let muted = Color(red: 0.63, green: 0.71, blue: 0.75)
private let mint = Color(red: 0.73, green: 0.92, blue: 0.76)
private let orange = Color(red: 1, green: 0.66, blue: 0.36)

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
            ZStack {
                ink
                RadialGradient(colors: [Color(red: 0.085, green: 0.19, blue: 0.24), ink], center: UnitPoint(x: 0.5, y: 0.43), startRadius: 0, endRadius: geometry.size.height * 0.66)
                Canvas { context, size in
                    for index in 0 ..< 80 {
                        let x = CGFloat((index * 127 + 53) % 991) / 991 * size.width
                        let y = CGFloat((index * 263 + 19) % 997) / 997 * size.height
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)), with: .color(.white.opacity(0.065)))
                    }
                    for index in 0 ..< 6 {
                        var path = Path()
                        let y = size.height * 0.25 + CGFloat(index) * 85
                        path.move(to: CGPoint(x: -40, y: y))
                        path.addCurve(to: CGPoint(x: size.width + 40, y: y - 50), control1: CGPoint(x: size.width * 0.3, y: y - 100), control2: CGPoint(x: size.width * 0.65, y: y + 60))
                        context.stroke(path, with: .color(.white.opacity(0.023)), lineWidth: 1)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct RootView: View {
    @ObservedObject var store: GameStore

    var body: some View {
        ZStack {
            LacquerBackground()
            switch store.screen {
            case .home: home
            case .playing: gameplay
            case .results: results
            }
            if store.paused {
                pauseOverlay
            }
            if store.showRules {
                rulesOverlay
            }
        }
        .foregroundStyle(cream)
        .font(.custom("AvenirNext-Medium", size: 15))
        .dynamicTypeSize(.xSmall ... .xxxLarge)
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 7) {
                Image(systemName: "sparkle").foregroundStyle(orange)
                Text("THE POCKET ORCHARD").font(.custom("AvenirNext-DemiBold", size: 10)).tracking(2)
            }
            Spacer()
            iconButton(store.soundOn ? "speaker.wave.2" : "speaker.slash", label: store.soundOn ? "Mute sound" : "Enable sound") { store.toggleSound() }
        }
    }

    private var home: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 6)
                VStack(spacing: -9) {
                    Text("Velvet").font(.custom("Baskerville", size: 68))
                    Text("Slice").font(.custom("Baskerville-Italic", size: 76)).foregroundStyle(orange)
                }
                .accessibilityElement(children: .combine)
                Text("A little edge. A lot of juice.")
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundStyle(muted)
                    .padding(.top, 13)
                FruitComposition()
                    .frame(height: max(160, min(240, geometry.size.height * 0.29)))
                    .padding(.vertical, 7)
                    .accessibilityHidden(true)
                HStack(spacing: 8) {
                    Image(systemName: "crown").foregroundStyle(orange)
                    Text("PERSONAL BEST").tracking(1.7)
                    Text("\(store.best)").foregroundStyle(cream).font(.custom("AvenirNext-DemiBold", size: 14))
                }
                .font(.custom("AvenirNext-Medium", size: 10))
                .foregroundStyle(muted)
                .padding(.bottom, 23)
                actionButton("Play arcade", subtitle: "60 SECONDS · FIND YOUR FLOW", system: "arrow.up.right", primary: true) { store.begin(.arcade) }
                actionButton("Practice", subtitle: "NO CLOCK. NO BOMBS. JUST FLOW.", system: "leaf", primary: false) { store.begin(.practice) }
                    .padding(.top, 10)
                Spacer(minLength: 10)
                Button { store.showRules = true } label: {
                    Label("The art of the slice", systemImage: "hand.draw")
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(muted)
                        .frame(height: 44)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 8)
        }
    }

    private var gameplay: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    eyebrow("SCORE")
                    Text("\(store.round.score)")
                        .font(.custom("Baskerville", size: 48))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                Spacer()
                VStack(spacing: 5) {
                    eyebrow(store.mode == .arcade ? "TIME LEFT" : "FREE FLOW")
                    Text(store.mode == .arcade ? clockText(store.round.remaining) : "∞")
                        .font(.custom("AvenirNext-Medium", size: store.mode == .arcade ? 24 : 32))
                        .monospacedDigit()
                        .foregroundStyle(store.round.remaining <= 10 && store.mode == .arcade ? orange : cream)
                }.padding(.top, 5)
                Spacer()
                iconButton("pause", label: "Pause game") { store.pause() }.padding(.top, 3)
            }.padding(.horizontal, 27)
            if store.mode == .arcade {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.08))
                        Capsule().fill(store.round.remaining <= 10 ? orange : mint).frame(width: geometry.size.width * store.round.remaining / 60)
                    }
                }.frame(height: 2).padding(.horizontal, 28).padding(.top, 9)
            }
            ZStack {
                SpriteView(scene: store.scene, isPaused: store.paused, options: [.allowsTransparency])
                    .accessibilityLabel("Fruit slicing playfield. Swipe across airborne fruit. Avoid red-ringed bombs.")
                    .accessibilityIdentifier("playfield")
                if store.countdown > 0 {
                    VStack(spacing: 14) {
                        eyebrow("FIND YOUR FLOW")
                        Text("\(store.countdown)").font(.custom("Baskerville", size: 104)).foregroundStyle(orange)
                        Text("Swipe through the fruit")
                            .font(.custom("Baskerville-Italic", size: 24))
                        Text(store.mode == .arcade ? "Avoid bombs. Slice 3+ for a combo." : "Nothing to lose. Everything to slice.")
                            .font(.custom("AvenirNext-Medium", size: 12)).foregroundStyle(muted)
                    }.allowsHitTesting(false)
                }
            }
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle").foregroundStyle(orange)
                        Text("\(store.round.sliced) SLICED").tracking(1)
                    }
                    Spacer()
                    if store.mode == .arcade {
                        HStack(spacing: 7) {
                            Text("BOMBS").tracking(1)
                            ForEach(0 ..< 3) { index in
                                Circle().fill(index < store.round.bombs ? Color(red: 1, green: 0.4, blue: 0.35) : .white.opacity(0.15)).frame(width: 7, height: 7)
                            }
                        }
                        .accessibilityLabel("\(store.round.bombs) of 3 bombs hit")
                    } else {
                        Text("BEST \(store.practiceBest)").tracking(1)
                    }
                }.font(.custom("AvenirNext-DemiBold", size: 11)).foregroundStyle(muted)
                Text(store.mode == .arcade ? "3+ fruit = combo · Miss −2 · Bomb −25" : "Slice freely. Pause to finish your session.")
                    .font(.custom("AvenirNext-Medium", size: 11)).foregroundStyle(muted)
            }.padding(.horizontal, 28).padding(.bottom, 18).padding(.top, 8)
        }
    }

    private var results: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 12)
            Image(systemName: store.newBest ? "crown" : "sparkles")
                .font(.system(size: 27, weight: .light)).foregroundStyle(orange)
                .padding(.bottom, 18)
            eyebrow(store.newBest ? "A NEW PERSONAL BEST" : (store.mode == .practice ? "PRACTICE COMPLETE" : "ARCADE COMPLETE"))
            Text(store.round.bombs >= 3 ? "A sharp lesson." : (store.round.score == 0 ? "Find your rhythm." : "Beautifully sliced."))
                .font(.custom("Baskerville-Italic", size: 36))
                .padding(.top, 16)
                .minimumScaleFactor(0.7).lineLimit(1)
            Text(store.round.bombs >= 3 ? "Three bombs. Breathe, then try again." : (store.round.score == 0 ? "Try a long swipe as the fruit rises." : "A moment of focus. A splash of color."))
                .font(.custom("AvenirNext-Medium", size: 12)).foregroundStyle(muted).padding(.top, 8)
            Text("\(store.round.score)")
                .font(.custom("Baskerville", size: 102)).monospacedDigit()
                .padding(.top, 24)
            eyebrow("POINTS").padding(.top, -9)
            HStack(spacing: 0) {
                resultStat("\(store.round.sliced)", label: "FRUIT SLICED")
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 35)
                resultStat(store.round.bestCombo >= 3 ? "\(store.round.bestCombo)×" : "—", label: "BEST COMBO")
                Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 35)
                resultStat(store.mode == .practice ? clockText(store.round.elapsed) : "\(store.round.missed)", label: store.mode == .practice ? "IN THE FLOW" : "MISSED")
            }
            .padding(.vertical, 24)
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.08)))
            .padding(.top, 27)
            HStack(spacing: 7) {
                Image(systemName: "crown").foregroundStyle(orange)
                Text("\(store.mode == .arcade ? "Arcade" : "Practice") best: \(store.mode == .arcade ? store.best : store.practiceBest)")
            }.font(.custom("AvenirNext-Medium", size: 12)).foregroundStyle(muted).padding(.top, 20)
            Spacer(minLength: 20)
            actionButton("Slice again", subtitle: store.mode == .arcade ? "A FRESH 60 SECONDS" : "BACK INTO THE FLOW", system: "arrow.clockwise", primary: true) { store.begin(store.mode) }
            Button("Back to the orchard") { store.screen = .home }
                .font(.custom("AvenirNext-Medium", size: 13)).foregroundStyle(muted)
                .frame(height: 54).buttonStyle(.plain)
        }.padding(.horizontal, 28).padding(.bottom, 9)
    }

    private var pauseOverlay: some View {
        overlayCard {
            Image(systemName: "pause").font(.system(size: 28, weight: .ultraLight)).foregroundStyle(orange)
            eyebrow("TAKE A BREATH")
            Text("Stay in the flow.").font(.custom("Baskerville-Italic", size: 34))
            Text("Your fruit and clock will wait.")
                .font(.custom("AvenirNext-Medium", size: 13)).foregroundStyle(muted)
            actionButton("Resume", subtitle: "RIGHT WHERE YOU LEFT OFF", system: "play", primary: true) { store.paused = false }
                .padding(.top, 10)
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
            VStack(alignment: .leading, spacing: 22) {
                ruleRow("hand.draw", title: "Make your move", text: "Drag a finger through airborne fruit. Each slice earns 10 points.")
                ruleRow("sparkles", title: "Find a beautiful line", text: "Slice 3 or more fruit quickly in one swipe for a bonus of 5 per fruit.")
                ruleRow("xmark.circle", title: "Keep your edge", text: "Bombs cost 25 points. Three end your run. Missed fruit cost 2 points.")
                ruleRow("leaf", title: "Or, just unwind", text: "Practice has no bombs, timer or penalties. Finish from the pause menu.")
            }.padding(.vertical, 12)
            actionButton("Let’s slice", subtitle: "YOU HAVE 60 SECONDS", system: "arrow.up.right", primary: true) {
                store.showRules = false
                store.begin(.arcade)
            }
            Button("Back") { store.showRules = false }.foregroundStyle(muted).frame(height: 44).buttonStyle(.plain)
        }
    }

    private func ruleRow(_ icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon).font(.system(size: 21, weight: .light)).foregroundStyle(orange).frame(width: 26)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.custom("AvenirNext-DemiBold", size: 14))
                Text(text).font(.custom("AvenirNext-Regular", size: 12)).foregroundStyle(muted).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func overlayCard(@ViewBuilder content: () -> some View) -> some View {
        ZStack {
            ink.opacity(0.93).ignoresSafeArea()
            VStack(spacing: 17, content: content)
                .padding(25)
                .background(Color(red: 0.045, green: 0.105, blue: 0.16), in: RoundedRectangle(cornerRadius: 28))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.1)))
                .padding(.horizontal, 22)
        }
    }

    private func resultStat(_ value: String, label: String) -> some View {
        VStack(spacing: 7) {
            Text(value).font(.custom("Baskerville", size: 30)).foregroundStyle(cream)
            Text(label).font(.custom("AvenirNext-DemiBold", size: 10)).tracking(0.4).foregroundStyle(muted)
        }.frame(maxWidth: .infinity)
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text).font(.custom("AvenirNext-DemiBold", size: 11)).tracking(1.8).foregroundStyle(muted)
    }

    private func iconButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 17, weight: .light))
                .foregroundStyle(cream).frame(width: 44, height: 44)
                .background(.white.opacity(0.04), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.09)))
        }.buttonStyle(.plain).accessibilityLabel(label)
    }

    private func actionButton(_ title: String, subtitle: String, system: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.custom("AvenirNext-DemiBold", size: 19))
                    Text(subtitle).font(.custom("AvenirNext-DemiBold", size: 10)).tracking(0.3).opacity(0.75)
                }
                Spacer()
                Image(systemName: system).font(.system(size: 23, weight: .light))
            }
            .foregroundStyle(primary ? ink : cream)
            .padding(.horizontal, 22)
            .frame(height: 73)
            .background(primary ? mint : .white.opacity(0.035), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(primary ? .clear : .white.opacity(0.13)))
        }.buttonStyle(SliceButtonStyle()).accessibilityLabel(title).accessibilityHint(subtitle)
    }

    private func clockText(_ seconds: Double) -> String {
        let whole = max(0, Int(ceil(seconds)))
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action).font(.custom("AvenirNext-DemiBold", size: 13))
            .frame(maxWidth: .infinity).frame(height: 48)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 13)).buttonStyle(.plain)
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

struct FruitComposition: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            ZStack {
                Ellipse().fill(Color.black.opacity(0.3)).frame(width: w * 0.74, height: 38).blur(radius: 16).position(x: w / 2, y: h * 0.86)
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
                    context.addFilter(.shadow(color: mint.opacity(0.6), radius: 6))
                    context.stroke(line, with: .linearGradient(Gradient(colors: [mint.opacity(0), mint, cream]), startPoint: CGPoint(x: 0, y: size.height), endPoint: CGPoint(x: size.width, y: 0)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    for index in 0 ..< 9 {
                        let x = CGFloat((index * 37 + 11) % 100) / 100 * size.width
                        let y = CGFloat((index * 61 + 5) % 100) / 100 * size.height
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: index % 3 == 0 ? 4 : 2, height: index % 3 == 0 ? 6 : 3)), with: .color(index % 2 == 0 ? orange.opacity(0.65) : mint.opacity(0.6)))
                    }
                }
            }
        }
    }
}
