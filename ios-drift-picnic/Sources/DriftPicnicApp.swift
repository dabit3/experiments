import CoreText
import SceneKit
import SwiftUI

@main
struct DriftPicnicApp: App {
  init() {
    if let url = Bundle.main.url(forResource: "PressStart2P-Regular", withExtension: "ttf") {
      CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
  }
  var body: some Scene {
    WindowGroup { PicnicView() }
  }
}

let ink = Color(uiColor: Palette.ink)
let navy = Color(uiColor: Palette.deepGreen)
let navyLight = Color(red: 0.14, green: 0.22, blue: 0.52)
let coin = Color(uiColor: Palette.butter)
let coinDeep = Color(red: 0.86, green: 0.50, blue: 0.04)
let paper = Color(uiColor: Palette.cream)
let cherry = Color(uiColor: Palette.pink)
let cherryDeep = Color(red: 0.58, green: 0.05, blue: 0.10)
let royal = Color(uiColor: Palette.blue)
let leaf = Color(uiColor: Palette.green)
let skyBlue = Color(uiColor: Palette.sky)
let slate = Color(red: 0.45, green: 0.47, blue: 0.58)

func raceTime(_ seconds: Double) -> String {
  guard seconds > 0 else { return "-'--\"--" }
  let whole = Int(seconds)
  let hundredths = Int((seconds - Double(whole)) * 100)
  return String(format: "%d'%02d\"%02d", whole / 60, whole % 60, hundredths)
}

func pixel(_ size: CGFloat) -> Font { .custom("PressStart2P-Regular", size: size) }

func ordinal(_ position: Int) -> String {
  ["", "1ST", "2ND", "3RD", "4TH"][position]
}

/// Hard 8-direction outline built from zero-radius shadows, like sprite text on a console.
struct Outlined: ViewModifier {
  var color: Color
  var width: CGFloat
  func body(content: Content) -> some View {
    content
      .shadow(color: color, radius: 0, x: width, y: 0)
      .shadow(color: color, radius: 0, x: -width, y: 0)
      .shadow(color: color, radius: 0, x: 0, y: width)
      .shadow(color: color, radius: 0, x: 0, y: -width)
  }
}

extension View {
  func outlined(_ color: Color = ink, _ width: CGFloat = 2) -> some View {
    modifier(Outlined(color: color, width: width))
  }
  func hardShadow(_ color: Color = ink, _ offset: CGFloat = 3) -> some View {
    shadow(color: color, radius: 0, x: offset, y: offset)
  }
  func retroPanel(_ fill: Color = navy, border: Color = paper) -> some View {
    modifier(RetroPanel(fill: fill, border: border))
  }
}

/// Pixel-font text with an ink outline. `size / 9` keeps the outline one "pixel" wide at any size.
struct RetroText: View {
  var text: String
  var size: CGFloat
  var color: Color = paper
  var outline: Color = ink
  init(_ text: String, _ size: CGFloat, _ color: Color = paper, outline: Color = ink) {
    self.text = text
    self.size = size
    self.color = color
    self.outline = outline
  }
  var body: some View {
    Text(text).font(pixel(size)).foregroundStyle(color)
      .outlined(outline, max(1.5, size / 9))
  }
}

/// A dialog box in the style of a 16-bit RPG: ink frame, fill, then a bright inner frame.
struct RetroPanel: ViewModifier {
  var fill: Color
  var border: Color
  func body(content: Content) -> some View {
    content.background {
      ZStack {
        Rectangle().fill(ink).offset(x: 5, y: 5)
        Rectangle().fill(fill)
        Rectangle().strokeBorder(border, lineWidth: 3).padding(5)
        Rectangle().strokeBorder(ink, lineWidth: 3)
      }
    }
  }
}

/// A chunky bevelled arcade button. Pressing snaps it down onto its hard shadow; no easing.
struct RetroButtonStyle: ButtonStyle {
  var fill: Color = coin
  var text: Color = ink
  var height: CGFloat = 50
  var size: CGFloat = 11
  func makeBody(configuration: Configuration) -> some View {
    let pressed = configuration.isPressed
    return configuration.label
      .font(pixel(size)).foregroundStyle(text)
      .frame(maxWidth: .infinity).frame(height: height)
      .background {
        ZStack {
          Rectangle().fill(fill)
          VStack(spacing: 0) {
            Rectangle().fill(.white.opacity(0.5)).frame(height: 4)
            Spacer()
            Rectangle().fill(.black.opacity(0.3)).frame(height: 6)
          }.padding(3)
          Rectangle().strokeBorder(ink, lineWidth: 3)
        }
      }
      .background { Rectangle().fill(ink).offset(y: pressed ? 0 : 5) }
      .offset(y: pressed ? 5 : 0)
      .animation(nil, value: pressed)
  }
}

struct RetroIconButtonStyle: ButtonStyle {
  var fill: Color = navy
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(width: 44, height: 44)
      .background {
        ZStack {
          Rectangle().fill(fill)
          Rectangle().strokeBorder(paper, lineWidth: 2).padding(3)
          Rectangle().strokeBorder(ink, lineWidth: 3)
        }
      }
      .background { Rectangle().fill(ink).offset(y: configuration.isPressed ? 0 : 4) }
      .offset(y: configuration.isPressed ? 4 : 0)
      .animation(nil, value: configuration.isPressed)
  }
}

/// Toggles visibility on a fixed clock, the classic "PRESS START" cadence.
struct Blink<Content: View>: View {
  var period = 0.5
  var animated = true
  @ViewBuilder var content: () -> Content
  var body: some View {
    TimelineView(.periodic(from: .now, by: period)) { context in
      let on = !animated || Int(context.date.timeIntervalSinceReferenceDate / period) % 2 == 0
      content().opacity(on ? 1 : 0)
    }
  }
}

/// Letters ride a stepped wave, advancing one frame every tenth of a second.
struct WaveText: View {
  var text: String
  var size: CGFloat
  var color: Color
  var animated = true
  private let lifts: [CGFloat] = [0, -2, -5, -8, -10, -8, -5, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  var body: some View {
    TimelineView(.periodic(from: .now, by: 0.1)) { context in
      let frame = Int(context.date.timeIntervalSinceReferenceDate * 10)
      HStack(spacing: 0) {
        ForEach(Array(text.enumerated()), id: \.offset) { index, letter in
          let phase = (frame + index * 2) % lifts.count
          Text(String(letter)).font(pixel(size)).foregroundStyle(color)
            .offset(y: animated ? lifts[phase] : 0)
        }
      }
      .outlined(ink, size / 10)
      .hardShadow(cherryDeep, size / 10)
    }
  }
}

/// Tiny sprites drawn from character rows; one character is one pixel.
struct PixelArt: View {
  let rows: [String]
  var body: some View {
    Canvas { context, size in
      let columns = rows.map(\.count).max() ?? 1
      let cell = floor(min(size.width / CGFloat(columns), size.height / CGFloat(rows.count)))
      let ox = (size.width - cell * CGFloat(columns)) / 2
      let oy = (size.height - cell * CGFloat(rows.count)) / 2
      for (y, row) in rows.enumerated() {
        for (x, character) in row.enumerated() {
          guard let color = Sprites.palette[character] else { continue }
          context.fill(
            Path(
              CGRect(
                x: ox + CGFloat(x) * cell, y: oy + CGFloat(y) * cell, width: cell, height: cell)),
            with: .color(color))
        }
      }
    }
  }
}

enum Sprites {
  static let palette: [Character: Color] = [
    "k": ink, "w": paper, "y": coin, "r": cherry, "b": royal, "g": leaf,
    "o": Color(red: 0.93, green: 0.52, blue: 0.20),
    "p": Color(red: 1, green: 0.62, blue: 0.72), "s": Color(red: 0.55, green: 0.55, blue: 0.64),
    "t": Color(red: 0.80, green: 0.80, blue: 0.86), "c": skyBlue,
  ]
  static let arrowLeft = [
    "....kk...", "...kwk...", "..kwwk...", ".kwwwkkkk", "kwwwwwwwk", ".kwwwkkkk", "..kwwk...",
    "...kwk...", "....kk...",
  ]
  static let arrowRight = arrowLeft.map { String($0.reversed()) }
  static let cursor = [
    "k....", "kk...", "kyk..", "kyyk.", "kyyyk", "kyyk.", "kyk..", "kk...", "k....",
  ]
  static let lemonade = [
    "......kk..", ".....krk..", "....krk...", ".kkkkrkkk.", "kwwwwrwwwk", "kwyyyyyyyk",
    "kwyyyyyyyk", "kwyywwyyyk", "kwyyyyyyyk", ".kwyyyyyk.", ".kwyyyyyk.", "..kkkkkk..",
  ]
  static let bolt = [
    "....kkk.", "...kyyk.", "..kyyk..", ".kyyk...", "kyyyykkk", "kkkyyyyk", "..kyyyk.", "...kyyk.",
    "....kyk.", "...kyk..", "..kyk...", "..kk....",
  ]
  static let speaker = [
    "....k.....", "...kk..k..", "..kwk...k.", "kkkwk.k.k.", "kwwwk.k.k.", "kkkwk.k.k.",
    "..kwk...k.",
    "...kk..k..", "....k.....",
  ]
  static let muted = [
    "....k.....", "...kk.....", "..kwk.r.r.", "kkkwk..r..", "kwwwk.r.r.", "kkkwk.....",
    "..kwk.....",
    "...kk.....", "....k.....",
  ]
  static let trophy = [
    "kkkkkkkkkk", "kyyyyyyyyk", "kkyyyyyykk", ".kyyyyyyk.", "..kyyyyk..", "...kyyk...",
    "....kk....",
    "...kyyk...", "..kyyyyk..", ".kkkkkkkk.",
  ]
  static let stopwatch = [
    "...kkk...", "....k....", "..kkkkk..", ".kwwwwwk.", "kwwwkwwwk", "kwwwkwwwk", "kwwwkkkwk",
    ".kwwwwwk.", "..kkkkk..",
  ]
  static let flag = [
    "k.........", "kkkkkkkkk.", "kwkwkwkwk.", "kkwkwkwkk.", "kwkwkwkwk.", "kkkkkkkkk.",
    "k.........",
    "k.........", "k.........",
  ]
  static let home = [
    "....kk....", "...kwwk...", "..kwwwwk..", ".kwwwwwwk.", "kkkwwwwkkk", "..kwwwwk..",
    "..kwkkwk..",
    "..kwkkwk..", "..kkkkkk..",
  ]
  static let steer = [
    "...kkkkk...", "..kwwwwwk..", ".kwkkkkkwk.", "kwk.....kwk", "kwk.....kwk", "kwk..k..kwk",
    ".kwkkkkkwk.", "..kwwwwwk..", "...kkkkk...",
  ]
  static let animals: [[String]] = [
    [
      "..kk....kk..", ".kwwk..kwwk.", ".kwpk..kpwk.", ".kwpk..kpwk.", ".kwwkkkkwwk.",
      ".kwwwwwwwwk.",
      "kwwwwwwwwwwk", "kwwkwwwwkwwk", "kwwwwwwwwwwk", "kwwwwrrwwwwk", ".kwwwwwwwwk.",
      "..kkkkkkkk..",
    ],
    [
      ".kk......kk.", "kookkkkkkook", "kooooooooook", "koookoookook", "kooooooooook",
      "koowwwwwwook",
      "koowwkkwwook", "koowwwwwwook", "kooooooooook", ".kooooooook.", "..kkkkkkkk..",
      "............",
    ],
    [
      "kk........kk", "ksk......ksk", "kssk....kssk", "kssskkkksssk", "kssssssssssk",
      "kssksssskssk",
      "kssssssssssk", "ksssskpksssk", "kssssssssssk", ".kssssssssk.", "..kkkkkkkk..",
      "............",
    ],
    [
      "..kkkkkkkk..", ".kwwwwwwwwk.", "kwwwwwwwwwwk", "kwwkkkkkkwwk", "kwkttttttkwk",
      "kwktkttktkwk",
      "kwkttttttkwk", "kwkttkkttkwk", "kwkttttttkwk", ".kwkkkkkkwk.", "..kkkkkkkk..",
      "............",
    ],
  ]
}

struct PicnicView: View {
  @StateObject private var game = GameController()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        NativeScene(game: game).ignoresSafeArea()
        if game.phase == .title {
          title(geometry.size)
        } else if game.phase == .results {
          results(geometry.size)
        } else {
          hud(geometry.size)
          if game.phase == .countdown { countdownView }
          if game.phase == .paused { pausePanel }
        }
        if game.showGuide { guide(geometry.size) }
      }
      .foregroundStyle(paper)
      .onAppear { game.reducedMotion = reduceMotion }
      .onChange(of: reduceMotion) { _, value in game.reducedMotion = value }
      .onChange(of: scenePhase) { _, phase in
        if phase != .active { game.pause() }
      }
    }
    .persistentSystemOverlays(.hidden)
  }

  // MARK: Countdown

  private var countdownView: some View {
    VStack(spacing: 14) {
      HStack(spacing: 10) {
        ForEach(0..<3, id: \.self) { lamp in
          let lit = lamp <= 3 - game.countdown
          Circle()
            .fill(game.countdown == 0 ? leaf : (lit ? cherry : cherryDeep.opacity(0.5)))
            .overlay { Circle().strokeBorder(ink, lineWidth: 3) }
            .frame(width: 30, height: 30)
        }
      }
      .padding(.horizontal, 14).padding(.vertical, 10)
      .retroPanel()
      RetroText(
        game.countdown == 0 ? "GO!!" : "\(game.countdown)", game.countdown == 0 ? 64 : 80, coin
      )
      .hardShadow(cherryDeep, 6)
      .id(game.countdown)
      .transition(.scale(scale: 1.6))
    }
    .animation(reduceMotion ? nil : .linear(duration: 0.08), value: game.countdown)
    .allowsHitTesting(false)
  }

  // MARK: Title

  private func title(_ size: CGSize) -> some View {
    let compact = size.height < 420
    return ZStack {
      navy.opacity(0.42).ignoresSafeArea()
      VStack(spacing: 0) {
        HStack(alignment: .top) {
          RetroText("PICNIC GAMES PRESENTS", 8, paper)
          Spacer()
          Button(action: game.toggleSound) {
            PixelArt(rows: game.sound ? Sprites.speaker : Sprites.muted).frame(
              width: 26, height: 26)
          }
          .buttonStyle(RetroIconButtonStyle())
          .accessibilityLabel(game.sound ? "Mute sound" : "Enable sound")
        }
        Spacer(minLength: 0)
        HStack(alignment: .center, spacing: compact ? 22 : 34) {
          VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            VStack(alignment: .leading, spacing: compact ? 6 : 10) {
              WaveText(text: "DRIFT", size: compact ? 40 : 48, color: coin, animated: !reduceMotion)
              WaveText(
                text: "PICNIC", size: compact ? 40 : 48, color: paper, animated: !reduceMotion)
            }
            RetroText("TOY-SIZED KART RACING", compact ? 8 : 9, skyBlue)
            recordsPanel.padding(.top, compact ? 2 : 8)
          }
          Spacer(minLength: 0)
          menuPanel(compact)
        }
        .frame(maxWidth: 720)
        Spacer(minLength: 0)
        HStack {
          RetroText("© 2026 PICNIC GAMES", 7, paper.opacity(0.85))
          Spacer()
          Blink(animated: !reduceMotion) { RetroText("PRESS START!", 8, coin) }
        }
      }
      .padding(.horizontal, compact ? 18 : 28).padding(.vertical, compact ? 10 : 16)
    }
  }

  private var recordsPanel: some View {
    HStack(spacing: 14) {
      record(Sprites.stopwatch, "BEST LAP", raceTime(game.bestLap))
      if game.mode == .picnic {
        record(Sprites.trophy, "WINS", "\(game.wins)")
        record(Sprites.flag, "BEST CUP", raceTime(game.bestCup))
      } else {
        record(Sprites.flag, "BEST TRIAL", raceTime(game.bestTrial))
      }
    }
    .padding(.horizontal, 14).padding(.vertical, 10)
    .retroPanel()
  }

  private func record(_ icon: [String], _ label: String, _ value: String) -> some View {
    HStack(spacing: 7) {
      PixelArt(rows: icon).frame(width: 18, height: 18)
      VStack(alignment: .leading, spacing: 4) {
        Text(label).font(pixel(6)).foregroundStyle(coin)
        Text(value).font(pixel(8)).foregroundStyle(paper)
      }
    }
  }

  private func menuPanel(_ compact: Bool) -> some View {
    VStack(spacing: compact ? 8 : 12) {
      RetroText("SELECT MODE", 8, coin)
      VStack(spacing: 4) {
        ForEach([RaceMode.picnic, RaceMode.trial], id: \.self) { mode in
          Button {
            game.mode = mode
          } label: {
            HStack(spacing: 8) {
              PixelArt(rows: Sprites.cursor).frame(width: 10, height: 18)
                .opacity(game.mode == mode ? 1 : 0)
              Text(mode.rawValue.uppercased()).font(pixel(9))
              Spacer()
              Text(mode == .picnic ? "VS 3 RIVALS" : "SOLO LAPS").font(pixel(6))
                .foregroundStyle(paper.opacity(0.7))
            }
            .foregroundStyle(game.mode == mode ? paper : paper.opacity(0.55))
            .padding(.horizontal, 10).frame(height: 32)
            .background(game.mode == mode ? navyLight : .clear)
          }
          .accessibilityAddTraits(game.mode == mode ? .isSelected : [])
        }
      }
      Button("START!", action: game.begin)
        .buttonStyle(RetroButtonStyle(height: compact ? 44 : 50, size: 12))
        .accessibilityIdentifier("startRace")
      Button("HOW TO PLAY") { game.showGuide = true }
        .buttonStyle(RetroButtonStyle(fill: royal, text: paper, height: 36, size: 8))
    }
    .padding(compact ? 12 : 16)
    .frame(width: compact ? 262 : 292)
    .retroPanel()
  }

  // MARK: HUD

  private var ready: Bool { game.race.player.driftCharge >= 0.65 }

  private func hud(_ size: CGSize) -> some View {
    let compact = size.height < 370
    return VStack(spacing: 0) {
      HStack(alignment: .top, spacing: 12) {
        positionBadge
        Spacer()
        VStack(spacing: 6) {
          HStack(spacing: 10) {
            Text("LAP").font(pixel(8)).foregroundStyle(coin)
            HStack(spacing: 3) {
              ForEach(0..<3, id: \.self) { lap in
                Rectangle()
                  .fill(
                    lap < game.race.player.tracker.laps
                      ? coin : paper.opacity(lap == game.race.player.tracker.laps ? 1 : 0.3)
                  )
                  .frame(width: 10, height: 8)
              }
            }
            Text("\(min(3, game.race.player.tracker.laps + 1))/3").font(pixel(10))
          }
          Text(raceTime(game.race.elapsed)).font(pixel(15)).foregroundStyle(paper)
            .contentTransition(.identity)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .retroPanel()
        Spacer()
        HStack(spacing: 10) {
          Button(action: game.toggleSound) {
            PixelArt(rows: game.sound ? Sprites.speaker : Sprites.muted).frame(
              width: 24, height: 24)
          }
          .buttonStyle(RetroIconButtonStyle())
          .accessibilityLabel(game.sound ? "Mute sound" : "Enable sound")
          Button(action: game.pause) {
            HStack(spacing: 4) {
              Rectangle().fill(paper).frame(width: 6, height: 18)
              Rectangle().fill(paper).frame(width: 6, height: 18)
            }
          }
          .buttonStyle(RetroIconButtonStyle())
          .accessibilityLabel("Pause race").accessibilityIdentifier("pauseRace")
        }
      }
      ZStack {
        if game.race.feedbackRemaining > 0 && game.phase == .racing {
          RetroText(game.race.feedback, 13, coin)
            .hardShadow(cherryDeep, 3)
            .transition(.scale(scale: 1.4))
            .accessibilityIdentifier("raceFeedback")
        }
      }
      .frame(height: 40).padding(.top, 10)
      .animation(
        reduceMotion ? nil : .linear(duration: 0.08), value: game.race.feedbackRemaining > 0)
      Spacer()
      HStack(alignment: .bottom, spacing: 12) {
        steeringButton(-1, icon: Sprites.arrowLeft, label: "Steer left")
        steeringButton(1, icon: Sprites.arrowRight, label: "Steer right")
        speedometer.padding(.leading, 4)
        Spacer()
        MiniMap(circuit: game.race.circuit, drivers: game.race.drivers, onCard: false)
          .frame(width: 100, height: 66)
          .padding(.horizontal, 8).padding(.vertical, 6)
          .background {
            ZStack {
              Rectangle().fill(navy.opacity(0.75))
              Rectangle().strokeBorder(ink, lineWidth: 3)
            }
          }
          .padding(.trailing, 4).padding(.bottom, 4)
        itemButton
        driftButton
      }
    }
    .padding(.horizontal, 18).padding(.vertical, compact ? 10 : 14)
  }

  private var positionBadge: some View {
    HStack(alignment: .firstTextBaseline, spacing: 4) {
      if game.mode == .trial {
        VStack(alignment: .leading, spacing: 4) {
          RetroText("TIME", 16, coin).hardShadow(cherryDeep, 3)
          RetroText("TRIAL", 10, paper)
        }
        .fixedSize()
      } else {
        RetroText("\(game.race.position)", 40, coin).hardShadow(cherryDeep, 4)
          .contentTransition(.identity)
        RetroText(String(ordinal(game.race.position).dropFirst()), 14, paper)
      }
    }
    .frame(width: 96, alignment: .leading)
    .padding(.top, 4)
    .accessibilityLabel(game.mode == .trial ? "Time trial" : "Position \(game.race.position) of 4")
  }

  private var speedometer: some View {
    let boosting = game.race.player.boost > 0
    let segments = Int((game.race.player.speed / 26) * 10)
    return VStack(alignment: .leading, spacing: 5) {
      Text(boosting ? "BOOST!" : "SPEED").font(pixel(7)).foregroundStyle(boosting ? coin : paper)
        .outlined(ink, 1.5)
      HStack(spacing: 2) {
        ForEach(0..<10, id: \.self) { index in
          Rectangle()
            .fill(
              index < segments
                ? (index < 5 ? leaf : (index < 8 ? coin : cherry)) : navy.opacity(0.7)
            )
            .frame(width: 8, height: 12 + CGFloat(index) * 1.2)
            .overlay { Rectangle().strokeBorder(ink, lineWidth: 1.5) }
        }
      }
    }
    .padding(.bottom, 4)
    .accessibilityLabel("Speed \(Int(game.race.player.speed * 3.6)) kilometres per hour")
  }

  private var itemButton: some View {
    let has = game.race.hasItem
    return Button(action: game.item) {
      VStack(spacing: 6) {
        PixelArt(rows: Sprites.lemonade).frame(width: 30, height: 36)
          .saturation(has ? 1 : 0).opacity(has ? 1 : 0.35)
        Text(has ? "LEMONADE" : "NO ITEM").font(pixel(6))
      }
      .frame(width: 82, height: 80)
      .foregroundStyle(has ? ink : paper.opacity(0.6))
    }
    .buttonStyle(ControlPadStyle(fill: has ? leaf : slate, active: has))
    .disabled(!has)
    .accessibilityLabel(has ? "Use lemonade boost" : "No item collected")
    .accessibilityIdentifier("useItem")
  }

  private var driftButton: some View {
    let drifting = game.race.drifting
    let charge = min(1, game.race.player.driftCharge / 0.65)
    return Button(action: game.drift) {
      VStack(spacing: 5) {
        PixelArt(rows: Sprites.bolt).frame(width: 26, height: 36)
        HStack(spacing: 2) {
          ForEach(0..<6, id: \.self) { index in
            Rectangle()
              .fill(
                Double(index) < charge * 6 - 0.01 ? (ready ? coin : skyBlue) : ink.opacity(0.35)
              )
              .frame(width: 9, height: 6)
          }
        }
        if ready {
          Blink(period: 0.25, animated: !reduceMotion) { Text("BOOST!").font(pixel(7)) }
        } else {
          Text(drifting ? "CHARGE" : "DRIFT").font(pixel(7))
        }
      }
      .frame(width: 92, height: 92)
      .foregroundStyle(ready ? ink : paper)
    }
    .buttonStyle(ControlPadStyle(fill: ready ? coin : (drifting ? royal : cherry), active: true))
    .accessibilityLabel(drifting ? "Release drift boost" : "Start drift")
    .accessibilityIdentifier("drift")
  }

  private func steeringButton(_ direction: Double, icon: [String], label: String) -> some View {
    let held = game.race.steering == direction
    return PixelArt(rows: icon)
      .frame(width: 40, height: 40)
      .frame(width: 80, height: 80)
      .background {
        ZStack {
          Rectangle().fill(held ? coin : royal)
          VStack(spacing: 0) {
            Rectangle().fill(.white.opacity(0.45)).frame(height: 5)
            Spacer()
            Rectangle().fill(.black.opacity(0.3)).frame(height: 7)
          }.padding(3)
          Rectangle().strokeBorder(ink, lineWidth: 3)
        }
      }
      .background { Rectangle().fill(ink).offset(y: held ? 0 : 5) }
      .offset(y: held ? 5 : 0)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in game.steer(direction) }
          .onEnded { _ in game.steer(0) }
      )
      .accessibilityElement()
      .accessibilityLabel(label)
      .accessibilityAddTraits(.isButton)
      .accessibilityAction {
        game.steer(direction)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { game.steer(0) }
      }
  }

  // MARK: Guide

  private func guide(_ size: CGSize) -> some View {
    ZStack {
      ink.opacity(0.7).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 14) {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 8) {
            RetroText("HOW TO PLAY", 16, coin).hardShadow(cherryDeep, 3)
            Text("THREE TRICKS FOR A SWEET FIRST RACE").font(pixel(7)).foregroundStyle(skyBlue)
          }
          Spacer()
          Button {
            game.showGuide = false
          } label: {
            Text("X").font(pixel(12)).foregroundStyle(paper)
          }
          .buttonStyle(RetroIconButtonStyle(fill: cherry))
          .accessibilityLabel("Close instructions")
        }
        HStack(alignment: .top, spacing: 12) {
          tip(
            Sprites.steer, "STEER",
            "HOLD THE ARROWS TO TURN. HUG THE INSIDE CURB FOR THE FASTEST LINE.")
          tip(
            Sprites.bolt, "DRIFT + BOOST",
            "TAP DRIFT INTO A BEND. TAP AGAIN WHEN THE BOLT FLASHES BOOST!")
          tip(
            Sprites.lemonade, "LEMONADE",
            "DRIVE THROUGH A GLASS, THEN TAP IT FOR A BIG SPEED BURST.")
        }
        Button("GOT IT! LET'S RACE", action: game.start)
          .buttonStyle(RetroButtonStyle(height: 46, size: 10))
          .accessibilityIdentifier("confirmGuide")
      }
      .padding(20).frame(maxWidth: min(size.width - 40, 680))
      .retroPanel()
    }
  }

  private func tip(_ icon: [String], _ title: String, _ text: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        PixelArt(rows: icon).frame(width: 26, height: 26)
        Text(title).font(pixel(8)).foregroundStyle(coin)
      }
      Text(text).font(pixel(6)).lineSpacing(5).foregroundStyle(paper)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      Rectangle().fill(navyLight).overlay { Rectangle().strokeBorder(ink, lineWidth: 2) }
    }
  }

  // MARK: Pause

  private var pausePanel: some View {
    ZStack {
      ink.opacity(0.6).ignoresSafeArea()
      VStack(spacing: 14) {
        Blink(animated: !reduceMotion) { RetroText("PAUSE", 26, coin).hardShadow(cherryDeep, 4) }
        Text("TIME  \(raceTime(game.race.elapsed))").font(pixel(8)).foregroundStyle(skyBlue)
        Button("CONTINUE", action: game.resume).buttonStyle(RetroButtonStyle(height: 46, size: 10))
          .accessibilityIdentifier("resumeRace")
        HStack(spacing: 10) {
          Button("RESTART", action: game.start)
          Button("QUIT", action: game.home)
        }
        .buttonStyle(RetroButtonStyle(fill: royal, text: paper, height: 38, size: 8))
      }
      .padding(22)
      .frame(width: 320)
      .retroPanel()
    }
  }

  // MARK: Results

  private func results(_ size: CGSize) -> some View {
    let won = game.mode == .picnic && game.race.position == 1
    let personal = game.mode == .picnic ? game.bestCup : game.bestTrial
    let newBest = abs(personal - game.race.elapsed) < 0.001
    let compact = size.height < 390
    return ZStack {
      navy.opacity(0.55).ignoresSafeArea()
      if won && !reduceMotion { Confetti().ignoresSafeArea().allowsHitTesting(false) }
      HStack(spacing: compact ? 18 : 28) {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
          RetroText(game.mode == .trial ? "TIME TRIAL" : "PICNIC CUP", 8, skyBlue)
          WaveText(
            text: won || game.mode == .trial ? "FINISH!" : "GOAL!", size: compact ? 30 : 36,
            color: coin, animated: !reduceMotion)
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            if game.mode == .trial {
              RetroText("3", 44, paper).hardShadow(cherryDeep, 4)
              RetroText("LAPS", 10, paper)
            } else {
              RetroText("\(game.race.position)", 44, paper).hardShadow(cherryDeep, 4)
              RetroText(String(ordinal(game.race.position).dropFirst()), 14, paper)
              RetroText("PLACE", 10, coin).padding(.leading, 6)
            }
          }
          HStack(spacing: 10) {
            resultChip(Sprites.bolt, "\(game.race.driftBoosts) DRIFTS")
            resultChip(Sprites.lemonade, "\(game.race.itemsCollected) DRINKS")
          }
          HStack(spacing: 10) {
            Button("RETRY", action: game.start).buttonStyle(RetroButtonStyle(height: 46, size: 11))
              .accessibilityIdentifier("raceAgain")
            Button(action: game.home) {
              PixelArt(rows: Sprites.home).frame(width: 24, height: 24)
            }
            .buttonStyle(RetroIconButtonStyle(fill: royal))
            .accessibilityLabel("Back to title")
          }.padding(.top, 4)
        }.frame(maxWidth: 290, alignment: .leading)
        VStack(spacing: 10) {
          if game.mode == .picnic { podium }
          VStack(spacing: 8) {
            resultRow("RACE TIME", raceTime(game.race.elapsed), paper)
            resultRow("BEST LAP", raceTime(game.race.player.lapTimes.min() ?? 0), paper)
            resultRow(
              newBest ? "NEW RECORD!" : "YOUR RECORD", raceTime(personal), coin, blink: newBest)
          }
          .padding(.horizontal, 16).padding(.vertical, 12)
          .retroPanel()
          Text("SAVED ON THIS DEVICE").font(pixel(6)).foregroundStyle(paper.opacity(0.6))
        }.frame(maxWidth: 320)
      }.padding(24)
    }
  }

  private func resultRow(_ label: String, _ value: String, _ color: Color, blink: Bool = false)
    -> some View
  {
    HStack {
      if blink {
        Blink(animated: !reduceMotion) { Text(label).font(pixel(7)).foregroundStyle(color) }
      } else {
        Text(label).font(pixel(7)).foregroundStyle(color)
      }
      Spacer()
      Text(value).font(pixel(9)).foregroundStyle(color)
    }
  }

  private func resultChip(_ icon: [String], _ text: String) -> some View {
    HStack(spacing: 6) {
      PixelArt(rows: icon).frame(width: 14, height: 16)
      Text(text).font(pixel(7))
    }
    .foregroundStyle(paper)
    .padding(.horizontal, 10).padding(.vertical, 7)
    .background {
      Rectangle().fill(navyLight).overlay { Rectangle().strokeBorder(ink, lineWidth: 2) }
    }
  }

  private var podium: some View {
    let sorted = game.race.drivers.indices.sorted {
      let a = game.race.drivers[$0]
      let b = game.race.drivers[$1]
      if let at = a.finishTime, let bt = b.finishTime { return at < bt }
      if a.finishTime != nil { return true }
      if b.finishTime != nil { return false }
      return a.tracker.progress > b.tracker.progress
    }
    let names = ["CLOVER", "MAPLE", "MOCHI", "PEPPER"]
    return HStack(alignment: .bottom, spacing: 6) {
      ForEach([1, 0, 2], id: \.self) { rank in
        let driver = sorted[rank]
        let height: CGFloat = rank == 0 ? 62 : (rank == 1 ? 46 : 36)
        VStack(spacing: 5) {
          PixelArt(rows: Sprites.animals[driver]).frame(width: 36, height: 36)
          Text(names[driver] + (driver == 0 ? "★" : "")).font(pixel(6))
            .foregroundStyle(driver == 0 ? coin : paper)
          ZStack(alignment: .top) {
            Rectangle().fill(
              rank == 0 ? coin : (rank == 1 ? Color(red: 0.75, green: 0.76, blue: 0.82) : coinDeep)
            )
            .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.5)).frame(height: 4) }
            .overlay { Rectangle().strokeBorder(ink, lineWidth: 3) }
            Text("\(rank + 1)").font(pixel(rank == 0 ? 18 : 13))
              .foregroundStyle(ink).padding(.top, rank == 0 ? 10 : 8)
          }
          .frame(maxWidth: .infinity).frame(height: height)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
          "\(rank + 1). \(names[driver].capitalized)\(driver == 0 ? ", you" : "")")
      }
    }
  }
}

/// Square control pad with the same bevel language as the menu buttons.
struct ControlPadStyle: ButtonStyle {
  var fill: Color
  var active: Bool
  func makeBody(configuration: Configuration) -> some View {
    let pressed = configuration.isPressed && active
    return configuration.label
      .background {
        ZStack {
          Rectangle().fill(fill)
          VStack(spacing: 0) {
            Rectangle().fill(.white.opacity(0.45)).frame(height: 5)
            Spacer()
            Rectangle().fill(.black.opacity(0.3)).frame(height: 7)
          }.padding(3)
          Rectangle().strokeBorder(ink, lineWidth: 3)
        }
      }
      .background { Rectangle().fill(ink).offset(y: pressed ? 0 : 5) }
      .offset(y: pressed ? 5 : 0)
      .animation(nil, value: pressed)
  }
}

/// Square confetti that falls in quantised steps at twelve frames a second.
struct Confetti: View {
  private let start = Date()
  var body: some View {
    TimelineView(.periodic(from: .now, by: 1.0 / 12)) { timeline in
      let t = floor(timeline.date.timeIntervalSince(start) * 12) / 12
      Canvas { context, size in
        let colors = [coin, cherry, paper, royal, leaf]
        for i in 0..<40 {
          let seed = Double(i)
          let speed = 60 + (seed * 37).truncatingRemainder(dividingBy: 50)
          let x =
            (seed * 97.3).truncatingRemainder(dividingBy: size.width)
            + (Int(t * 4 + seed) % 2 == 0 ? 0 : 6)
          let y = (t * speed + seed * 61).truncatingRemainder(dividingBy: size.height + 40) - 20
          let fade = max(0, 1 - t / 8)
          var piece = context
          piece.opacity = fade
          let side: CGFloat = i % 3 == 0 ? 8 : 6
          piece.fill(
            Path(CGRect(x: x, y: y, width: side, height: side)),
            with: .color(colors[i % colors.count]))
        }
      }
    }
  }
}

struct MiniMap: View {
  let circuit: Circuit
  let drivers: [Driver]
  var onCard: Bool
  var body: some View {
    Canvas { context, size in
      func point(_ p: Point) -> CGPoint {
        CGPoint(x: (p.x + 68) / 136 * size.width, y: (p.z + 50) / 100 * size.height)
      }
      var path = Path()
      path.addLines(circuit.points.map(point))
      path.closeSubpath()
      context.stroke(path, with: .color(ink), lineWidth: 8)
      context.stroke(path, with: .color(paper), lineWidth: 3.5)
      let start = point(circuit.points[0])
      context.fill(
        Path(CGRect(x: start.x - 2, y: start.y - 5, width: 4, height: 10)), with: .color(coin))
      let colors = [cherry, royal, leaf, coin]
      for index in drivers.indices.reversed() {
        let p = point(drivers[index].point)
        let half: CGFloat = index == 0 ? 5 : 3.5
        let rect = CGRect(x: p.x - half, y: p.y - half, width: half * 2, height: half * 2)
        context.fill(Path(rect.insetBy(dx: -1.5, dy: -1.5)), with: .color(index == 0 ? paper : ink))
        context.fill(Path(rect), with: .color(colors[index]))
      }
    }.accessibilityLabel("Circuit map")
  }
}

struct NativeScene: UIViewRepresentable {
  let game: GameController
  func makeUIView(context: Context) -> KeyboardSceneView {
    let view = KeyboardSceneView()
    view.scene = game.world.scene
    view.pointOfView = game.world.camera
    #if targetEnvironment(simulator)
      view.antialiasingMode = .multisampling2X
    #else
      view.antialiasingMode = .multisampling4X
    #endif
    view.preferredFramesPerSecond = 60
    view.isPlaying = true
    view.game = game
    view.becomeFirstResponder()
    return view
  }
  func updateUIView(_ uiView: KeyboardSceneView, context: Context) {}
}

final class KeyboardSceneView: SCNView {
  weak var game: GameController?
  override var canBecomeFirstResponder: Bool { true }
  override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    for press in presses {
      switch press.key?.keyCode {
      case .keyboardLeftArrow: game?.steer(-1)
      case .keyboardRightArrow: game?.steer(1)
      case .keyboardSpacebar: game?.drift()
      case .keyboardB: game?.item()
      case .keyboardP:
        if game?.phase == .paused { game?.resume() } else { game?.pause() }
      default: super.pressesBegan(presses, with: event)
      }
    }
  }
  override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    for press in presses {
      if press.key?.keyCode == .keyboardLeftArrow || press.key?.keyCode == .keyboardRightArrow {
        game?.steer(0)
      }
    }
    super.pressesEnded(presses, with: event)
  }
}
