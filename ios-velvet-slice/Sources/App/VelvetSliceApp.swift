import SpriteKit
import SwiftUI

let pxWhite = Color(uiColor: Pixel.white)
let pxNavy = Color(uiColor: Pixel.navy)
let pxIndigo = Color(uiColor: Pixel.indigo)
let pxSky = Color(uiColor: Pixel.sky)
let pxRed = Color(uiColor: Pixel.red)
let pxOrange = Color(uiColor: Pixel.orange)
let pxYellow = Color(uiColor: Pixel.yellow)
let pxCream = Color(uiColor: Pixel.cream)
let pxGreen = Color(uiColor: Pixel.green)
let pxDarkGreen = Color(uiColor: Pixel.darkGreen)
let pxPink = Color(uiColor: Pixel.pink)
let pxBrick = Color(uiColor: Pixel.brick)
let pxGray = Color(uiColor: Pixel.gray)

func px(_ size: CGFloat) -> Font {
    .custom("PressStart2P-Regular", size: size)
}

func pad(_ value: Int, _ width: Int = 6) -> String {
    String(format: "%0\(width)d", max(0, value))
}

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

/// Night-sky level backdrop: twinkling 2px stars, a pixel moon, stepped hills
/// and a brick floor, all snapped to a 4pt grid.
struct PixelBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let bottomInset = geometry.safeAreaInsets.bottom
            TimelineView(.periodic(from: .now, by: 0.7)) { timeline in
                let frame = reduceMotion ? 0 : Int(timeline.date.timeIntervalSinceReferenceDate / 0.7) % 2
                Canvas(rendersAsynchronously: false) { context, size in
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(pxNavy))
                    for index in 0 ..< 70 {
                        let x = CGFloat((index * 127 + 53) % 97) / 97 * size.width
                        let y = CGFloat((index * 263 + 19) % 89) / 89 * size.height * 0.7
                        let bright = (index + frame) % 3 == 0
                        let side: CGFloat = index % 7 == 0 ? 4 : 2
                        let color = bright ? pxWhite : (index % 5 == 0 ? pxSky : pxIndigo)
                        context.fill(Path(CGRect(x: (x / 4).rounded() * 4, y: (y / 4).rounded() * 4, width: side, height: side)), with: .color(color))
                    }
                    let moonX: CGFloat = 26
                    let moonY = geometry.safeAreaInsets.top + 150
                    for row in 0 ..< 8 {
                        for col in 0 ..< 8 {
                            let dx = Double(col) - 3.5, dy = Double(row) - 3.5
                            let d = (dx * dx + dy * dy).squareRoot()
                            guard d < 4 else { continue }
                            let crater = [(2, 3), (5, 2), (4, 5), (5, 6)].contains { $0 == (col, row) }
                            let color = crater ? pxOrange : (d > 3.3 && dx + dy > 0 ? pxOrange : pxYellow)
                            context.fill(Path(CGRect(x: moonX + CGFloat(col) * 6, y: moonY + CGFloat(row) * 6, width: 6, height: 6)), with: .color(color))
                        }
                    }
                    let floor = size.height - bottomInset - 20
                    for hill in [(0.12, 88.0, 36.0), (0.55, 140.0, 52.0), (0.9, 96.0, 40.0)] {
                        let center = size.width * hill.0
                        let width = hill.1, height = hill.2
                        var y: CGFloat = 0
                        while y < height {
                            let progress = y / height
                            let half = width / 2 * (1 - progress * progress)
                            let x0 = ((center - half) / 4).rounded() * 4
                            let x1 = ((center + half) / 4).rounded() * 4
                            let color = y > height - 12 ? pxGreen : (Int(y / 4) % 5 == 0 ? pxDarkGreen : pxGreen)
                            context.fill(Path(CGRect(x: x0, y: floor - y - 4, width: x1 - x0, height: 4)), with: .color(color))
                            y += 4
                        }
                    }
                    context.fill(Path(CGRect(x: 0, y: floor, width: size.width, height: size.height - floor)), with: .color(pxBrick))
                    var row = 0
                    var y = floor
                    while y < size.height {
                        context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 2)), with: .color(.black))
                        var x: CGFloat = row % 2 == 0 ? 0 : -18
                        while x < size.width {
                            context.fill(Path(CGRect(x: x, y: y, width: 2, height: 18)), with: .color(.black))
                            context.fill(Path(CGRect(x: x + 2, y: y + 2, width: 32, height: 2)), with: .color(pxOrange))
                            x += 36
                        }
                        y += 18
                        row += 1
                    }
                }
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
            PixelBackground()
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
        .foregroundStyle(pxWhite)
        .font(px(10))
        .dynamicTypeSize(.xSmall ... .large)
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                PixelText("TOP SCORE", size: 8, color: pxYellow)
                PixelText(pad(store.best), size: 12)
            }
            Spacer()
            PixelIconButton(store.soundOn ? "SND ON" : "SND OFF", label: store.soundOn ? "Mute sound" : "Enable sound") { store.toggleSound() }
        }
        .padding(.top, 4)
    }

    private var home: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 10)
                TitleLogo()
                    .accessibilityLabel("Velvet Slice")
                Spacer(minLength: 8)
                FruitParade()
                    .frame(height: max(110, min(160, geometry.size.height * 0.2)))
                    .accessibilityHidden(true)
                Spacer(minLength: 14)
                PixelPanel {
                    VStack(spacing: 4) {
                        MenuRow("ARCADE", detail: "60 SEC", cursor: true) { store.begin(.arcade) }
                        MenuRow("PRACTICE", detail: "NO CLOCK", cursor: false) { store.begin(.practice) }
                        MenuRow("HOW TO PLAY", detail: "", cursor: false) { store.showRules = true }
                    }
                }
                Spacer(minLength: 12)
                PixelText("© 2026 POCKET ORCHARD", size: 7, color: pxGray, shadow: false)
                    .padding(.bottom, 44)
            }
            .padding(.horizontal, 24)
        }
    }

    private var gameplay: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                hudColumn("SCORE", value: pad(store.round.score))
                Spacer()
                hudColumn("BEST", value: pad(store.mode == .arcade ? store.best : store.practiceBest))
                Spacer()
                hudColumn(store.mode == .arcade ? "TIME" : "FREE", value: store.mode == .arcade ? pad(Int(ceil(store.round.remaining)), 3) : "PLAY", color: store.mode == .arcade && store.round.remaining <= 10 ? pxRed : pxWhite)
                Spacer()
                PixelIconButton("II", label: "Pause game") { store.pause() }
            }
            .padding(.horizontal, 24).padding(.top, 4)
            HStack {
                if store.mode == .arcade {
                    HStack(spacing: 3) {
                        ForEach(0 ..< 3) { index in
                            Image(uiImage: FruitArt.bomb).interpolation(.none).resizable()
                                .frame(width: 21, height: 24)
                                .opacity(index < store.round.bombs ? 0.25 : 1)
                        }
                    }
                    .accessibilityLabel("\(3 - store.round.bombs) bombs remaining")
                    Spacer()
                    TimeBar(fraction: store.round.remaining / 60)
                        .frame(width: 168, height: 12)
                        .accessibilityLabel("\(Int(ceil(store.round.remaining))) seconds remaining")
                } else {
                    PixelText("NO BOMBS  NO CLOCK", size: 8, color: pxSky)
                    Spacer()
                }
            }
            .padding(.horizontal, 24).padding(.top, 10)
            ZStack {
                Playfield(store: store)
                if store.countdown > 0 {
                    PixelPanel {
                        VStack(spacing: 14) {
                            PixelText("READY?", size: 16, color: pxYellow)
                            PixelText("\(store.countdown)", size: 40)
                            PixelText(store.mode == .arcade ? "SWIPE FRUIT. DODGE BOMBS." : "SWIPE FRUIT. RELAX.", size: 8, color: pxSky)
                        }
                        .padding(.horizontal, 10)
                    }
                    .allowsHitTesting(false)
                }
            }
            HStack {
                PixelText("SLICED \(pad(store.round.sliced, 3))", size: 8)
                Spacer()
                PixelText(store.round.bestCombo >= 3 ? "COMBO x\(store.round.bestCombo)" : "COMBO x-", size: 8, color: pxYellow)
            }
            .padding(.horizontal, 24).padding(.bottom, 14).padding(.top, 8)
        }
    }

    private var results: some View {
        let ended = store.round.bombs >= 3
        let quit = store.mode == .arcade && !ended && store.round.remaining > 0
        let title = store.mode == .practice ? "PRACTICE" : (ended ? "GAME OVER" : (quit ? "RUN OVER" : "TIME UP!"))
        return VStack(spacing: 0) {
            topBar
            Spacer(minLength: 10)
            PixelPanel {
                VStack(spacing: 18) {
                    PixelText(title, size: 22, color: ended ? pxRed : pxYellow)
                    PixelText(ended ? "THREE BOMBS. OUCH." : (store.round.score == 0 ? "SWIPE AS THEY RISE." : "NICE SLICING!"), size: 8, color: pxSky)
                    VStack(spacing: 10) {
                        PixelText("SCORE", size: 8, color: pxYellow)
                        PixelText(pad(store.round.score), size: 30)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    VStack(spacing: 12) {
                        statRow("FRUIT", pad(store.round.sliced, 3))
                        statRow("COMBO", store.round.bestCombo >= 3 ? "x\(store.round.bestCombo)" : "---")
                        statRow(store.mode == .practice ? "TIME" : "MISSED", store.mode == .practice ? clockText(store.round.elapsed) : pad(store.round.missed, 3))
                        Rectangle().fill(pxWhite).frame(height: 2).padding(.vertical, 2)
                        statRow("TOP", pad(store.mode == .arcade ? store.best : store.practiceBest), color: pxYellow)
                    }
                    .padding(.horizontal, 6)
                    if store.newBest {
                        Blink { PixelText("NEW RECORD!", size: 12, color: pxYellow) }
                            .frame(height: 16)
                            .accessibilityLabel("New record")
                    }
                }
            }
            .accessibilityElement(children: .contain)
            PixelButton("PLAY AGAIN", color: pxRed) { store.begin(store.mode) }
                .padding(.top, 26)
            PixelButton("TITLE", color: pxIndigo) { store.screen = .home }
                .padding(.top, 14)
            Spacer(minLength: 16)
        }
        .padding(.horizontal, 24)
    }

    private var pauseOverlay: some View {
        overlayCard {
            PixelText("PAUSE", size: 24, color: pxYellow)
            PixelText("THE FRUIT CAN WAIT.", size: 8, color: pxSky)
            PixelButton("RESUME", color: pxGreen) { store.paused = false }
                .padding(.top, 6)
            HStack(spacing: 12) {
                PixelButton("RESTART", color: pxIndigo) { store.begin(store.mode) }
                PixelButton("FINISH", color: pxIndigo) { store.finish() }
            }
            Button { store.toggleSound() } label: {
                PixelText(store.soundOn ? "SOUND: ON" : "SOUND: OFF", size: 8, color: pxGray, shadow: false)
                    .frame(height: 44)
            }.buttonStyle(.plain).accessibilityLabel(store.soundOn ? "Mute sound" : "Enable sound")
        }
    }

    private var rulesOverlay: some View {
        overlayCard {
            PixelText("HOW TO PLAY", size: 16, color: pxYellow)
            VStack(alignment: .leading, spacing: 16) {
                ruleRow(FruitArt.image(.citrus), text: "SWIPE THROUGH FRUIT.\nEACH SLICE +10.")
                ruleRow(FruitArt.image(.kiwi), text: "3+ IN ONE SWIPE IS\nA COMBO. +5 EACH.")
                ruleRow(FruitArt.bomb, text: "BOMBS -25. THREE\nBOMBS END THE RUN.")
                ruleRow(FruitArt.image(.dragon), text: "MISSED FRUIT -2.\nPRACTICE: NO RULES.")
            }.padding(.vertical, 6)
            PixelButton("START", color: pxRed) {
                store.showRules = false
                store.begin(.arcade)
            }
            Button { store.showRules = false } label: {
                PixelText("BACK", size: 8, color: pxGray, shadow: false).frame(height: 44)
            }.buttonStyle(.plain)
        }
    }

    private func ruleRow(_ sprite: UIImage, text: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(uiImage: sprite).interpolation(.none).resizable()
                .frame(width: 42, height: 48)
                .accessibilityHidden(true)
            PixelText(text, size: 8, lineSpacing: 6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func overlayCard(@ViewBuilder content: () -> some View) -> some View {
        let body = VStack(spacing: 16, content: content)
        return ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            PixelPanel(accent: pxSky) { body }
                .padding(.horizontal, 22)
        }
    }

    private func hudColumn(_ label: String, value: String, color: Color = pxWhite) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            PixelText(label, size: 8, color: pxYellow)
            PixelText(value, size: 12, color: color)
        }
        .accessibilityElement(children: .combine)
    }

    private func statRow(_ label: String, _ value: String, color: Color = pxWhite) -> some View {
        HStack {
            PixelText(label, size: 10)
            Spacer(minLength: 8)
            PixelText(value, size: 10, color: color)
        }
        .accessibilityElement(children: .combine)
    }

    private func clockText(_ seconds: Double) -> String {
        let whole = max(0, Int(ceil(seconds)))
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }
}

/// Press Start 2P text with a one-step hard drop shadow.
struct PixelText: View {
    let text: String
    let size: CGFloat
    var color: Color = pxWhite
    var shadow = true
    var lineSpacing: CGFloat = 0

    init(_ text: String, size: CGFloat, color: Color = pxWhite, shadow: Bool = true, lineSpacing: CGFloat = 0) {
        self.text = text
        self.size = size
        self.color = color
        self.shadow = shadow
        self.lineSpacing = lineSpacing
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if shadow {
                Text(text).foregroundStyle(.black).offset(x: size / 6, y: size / 6).accessibilityHidden(true)
            }
            Text(text).foregroundStyle(color)
        }
        .font(px(size))
        .lineSpacing(lineSpacing)
        .monospacedDigit()
    }
}

/// Toggles its content twice a second, like a title-screen prompt.
struct Blink<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ViewBuilder var content: () -> Content

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.45)) { timeline in
            let on = reduceMotion || Int(timeline.date.timeIntervalSinceReferenceDate / 0.45) % 2 == 0
            content().opacity(on ? 1 : 0)
        }
    }
}

/// RPG-style window: black fill, white frame, coloured outer frame.
struct PixelPanel<Content: View>: View {
    var accent: Color = pxSky
    @ViewBuilder var content: () -> Content

    init(accent: Color = pxSky, @ViewBuilder content: @escaping () -> Content) {
        self.accent = accent
        self.content = content
    }

    var body: some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(.black)
            .overlay(Rectangle().strokeBorder(pxWhite, lineWidth: 3))
            .padding(3)
            .background(.black)
            .overlay(Rectangle().strokeBorder(accent, lineWidth: 3))
    }
}

/// Chunky arcade button with a hard 8-bit shadow that collapses when pressed.
struct PixelButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    init(_ title: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            PixelText(title, size: 12)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(color)
                .overlay(Rectangle().strokeBorder(.black, lineWidth: 3))
                .overlay(alignment: .top) { Rectangle().fill(pxWhite.opacity(0.35)).frame(height: 3).padding(3) }
        }
        .buttonStyle(PixelButtonStyle())
        .accessibilityLabel(title.capitalized)
    }
}

struct PixelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(alignment: .bottom) {
                Rectangle().fill(.black).offset(y: configuration.isPressed ? 0 : 5)
            }
            .offset(y: configuration.isPressed ? 5 : 0)
    }
}

struct PixelIconButton: View {
    let text: String
    let label: String
    let action: () -> Void

    init(_ text: String, label: String, action: @escaping () -> Void) {
        self.text = text
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            PixelText(text, size: 8)
                .padding(.horizontal, 8)
                .frame(minWidth: 44)
                .frame(height: 36)
                .background(pxIndigo)
                .overlay(Rectangle().strokeBorder(pxWhite, lineWidth: 2))
        }
        .buttonStyle(PixelButtonStyle())
        .accessibilityLabel(label)
    }
}

/// Title-screen menu line with a blinking cursor on the default choice.
struct MenuRow: View {
    let title: String
    let detail: String
    let cursor: Bool
    let action: () -> Void

    init(_ title: String, detail: String, cursor: Bool, action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.cursor = cursor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Group {
                    if cursor {
                        Blink { PixelArrow() }
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 14, height: 14)
                PixelText(title, size: 12, color: cursor ? pxYellow : pxWhite)
                Spacer()
                PixelText(detail, size: 8, color: pxSky)
            }
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(detail.isEmpty ? title.capitalized : "\(title.capitalized), \(detail.lowercased())")
    }
}

/// Menu cursor drawn as 2pt blocks so it matches the font's pixel grid.
struct PixelArrow: View {
    var body: some View {
        Canvas { context, _ in
            for col in 0 ..< 7 {
                let half = CGFloat(col) * 0.5
                let y0 = (half * 2).rounded(.down) * 1
                let height = 14 - CGFloat(col) * 2
                context.fill(Path(CGRect(x: CGFloat(col) * 2, y: y0, width: 2, height: max(2, height))), with: .color(pxYellow))
            }
        }
        .frame(width: 14, height: 14)
    }
}

struct TitleLogo: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Text("VELVET").foregroundStyle(pxIndigo).offset(x: 4, y: 4)
                Text("VELVET").foregroundStyle(.black).offset(x: 2, y: 2)
                Text("VELVET").foregroundStyle(pxSky)
            }.font(px(30))
            ZStack {
                Text("SLICE").foregroundStyle(.black).offset(x: 6, y: 6)
                Text("SLICE").foregroundStyle(pxRed).offset(x: 3, y: 3)
                Text("SLICE").foregroundStyle(pxYellow)
            }.font(px(46))
            PixelText("FRUIT SLICING ARCADE", size: 8, color: pxWhite, shadow: false)
                .padding(.top, 4)
        }
        .accessibilityElement(children: .ignore)
    }
}

/// Three fruit sprites hopping in a stepped 4-frame cycle behind a pixel slash.
struct FruitParade: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.12)) { timeline in
            let frame = reduceMotion ? 0 : Int(timeline.date.timeIntervalSinceReferenceDate / 0.12) % 8
            GeometryReader { geometry in
                let w = geometry.size.width
                let h = geometry.size.height
                let hop: [CGFloat] = [0, -6, -12, -14, -12, -6, 0, 0]
                ZStack {
                    Canvas { context, size in
                        var x: CGFloat = size.width * 0.08
                        var y: CGFloat = size.height * 0.85
                        while x < size.width * 0.92 {
                            context.fill(Path(CGRect(x: x, y: y, width: 12, height: 6)), with: .color(pxWhite))
                            x += 12
                            y -= 6 * size.height / size.width * 1.4
                        }
                    }
                    ForEach(Array(FruitKind.allCases.enumerated()), id: \.offset) { index, kind in
                        let sprite = min(w * 0.26, h * 0.7)
                        Image(uiImage: FruitArt.image(kind)).interpolation(.none).resizable()
                            .frame(width: sprite, height: sprite * 32 / 28)
                            .position(x: w * (0.2 + 0.3 * CGFloat(index)), y: h * 0.52 + hop[(frame + index * 3) % 8])
                    }
                }
            }
        }
    }
}

/// Segmented block timer that empties from the right and turns red at 10 seconds.
struct TimeBar: View {
    let fraction: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 20) { index in
                Rectangle()
                    .fill(Double(index) / 20 < fraction ? (fraction <= 10 / 60 ? pxRed : pxYellow) : pxIndigo)
            }
        }
        .padding(2)
        .background(.black)
        .overlay(Rectangle().strokeBorder(pxWhite, lineWidth: 2))
    }
}

struct Playfield: View {
    @ObservedObject var store: GameStore
    @State private var revealed = false

    var body: some View {
        SpriteView(scene: store.scene, isPaused: store.paused, options: [.allowsTransparency])
            .opacity(revealed ? 1 : 0)
            .task {
                try? await Task.sleep(for: .milliseconds(150))
                revealed = true
            }
            .accessibilityLabel("Fruit slicing playfield. Swipe across airborne fruit. Avoid red-ringed bombs.")
            .accessibilityIdentifier("playfield")
    }
}
