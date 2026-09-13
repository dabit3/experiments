import AVFoundation
import SwiftUI
import UIKit

@main
struct TransitAtelierApp: App {
  var body: some Scene {
    WindowGroup {
      AtelierView()
        .preferredColorScheme(.light)
    }
  }
}

@MainActor
final class SoundDesk {
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private var ready = false

  func play(delivery: Bool = false) {
    if !ready {
      guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else {
        return
      }
      engine.attach(player)
      engine.connect(player, to: engine.mainMixerNode, format: format)
      do {
        try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try engine.start()
        ready = true
      } catch { return }
    }
    guard
      let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1),
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 5_292),
      let samples = buffer.floatChannelData
    else { return }
    buffer.frameLength = 5_292
    let notes = delivery ? [523.25, 659.25, 783.99] : [392.0, 523.25]
    for index in 0..<Int(buffer.frameLength) {
      let time = Double(index) / 44_100
      let note = notes[min(notes.count - 1, Int(time / 0.04))]
      let square: Double = sin(time * note * 2 * .pi) >= 0 ? 1 : -1
      samples[0][index] = Float(square * exp(-time * 22) * 0.05)
    }
    player.scheduleBuffer(buffer)
    player.play()
  }
}

@MainActor
final class GameDesk: ObservableObject {
  @Published var game: TransitSimulation?
  @Published var selectedCity: City = .harbour
  @Published var selectedLine = 0
  @Published var paused = false
  @Published var speed = 1
  @Published var showGuide = false
  @Published var sound = UserDefaults.standard.object(forKey: "sound") as? Bool ?? true
  @Published var savedGame: TransitSimulation?
  private let audio = SoundDesk()
  private var lastSave = 0.0
  private var lastSound = 0.0

  init() {
    if let data = UserDefaults.standard.data(forKey: "transit-run"),
      let game = try? JSONDecoder().decode(TransitSimulation.self, from: data), !game.isOver
    {
      savedGame = game
    }
  }

  func best(_ city: City) -> Int { UserDefaults.standard.integer(forKey: "best-\(city.rawValue)") }

  var planning: Bool {
    guard let game else { return false }
    return game.elapsed == 0 && game.trains.isEmpty
  }

  func start() {
    game = TransitSimulation(city: selectedCity)
    selectedLine = 0
    paused = false
    speed = 1
    lastSave = 0
    lastSound = 0
    feedback()
    save()
  }

  func resumeSaved() {
    game = savedGame
    selectedCity = savedGame?.city ?? .harbour
    paused = true
    selectedLine = 0
  }

  func tick() {
    guard var current = game, !paused, !showGuide, !planning, !current.isOver else { return }
    let delivered = current.delivered
    current.tick(Double(speed) / 30)
    game = current
    if current.delivered > delivered, current.elapsed - lastSound > 0.7 {
      lastSound = current.elapsed
      if sound { audio.play(delivery: true) }
    }
    if current.elapsed - lastSave > 3 || current.isOver {
      lastSave = current.elapsed
      save()
    }
  }

  func station(_ id: Int) {
    guard game != nil, game?.isOver == false else { return }
    if game?.append(id, to: selectedLine) == true { feedback() }
    save()
  }

  func undo() {
    guard let stops = game?.routes[selectedLine].stops, !stops.isEmpty else { return }
    game?.setRoute(selectedLine, stops: Array(stops.dropLast()))
    feedback()
    save()
  }

  func clear() {
    game?.setRoute(selectedLine, stops: [])
    feedback()
    save()
  }

  func choose(_ upgrade: Upgrade) {
    game?.choose(upgrade)
    feedback()
    save()
  }

  func toggleSound() {
    sound.toggle()
    UserDefaults.standard.set(sound, forKey: "sound")
    if sound { audio.play() }
  }

  func feedback() {
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    if sound { audio.play() }
  }

  func save() {
    guard let game else { return }
    if game.delivered > best(game.city) {
      UserDefaults.standard.set(game.delivered, forKey: "best-\(game.city.rawValue)")
    }
    if game.isOver {
      UserDefaults.standard.removeObject(forKey: "transit-run")
      savedGame = nil
    } else if let data = try? JSONEncoder().encode(game) {
      UserDefaults.standard.set(data, forKey: "transit-run")
      savedGame = game
    }
  }

  func background() {
    if game != nil { paused = true }
    save()
  }

  func home() {
    save()
    game = nil
    paused = false
  }
}

struct AtelierView: View {
  @StateObject private var desk = GameDesk()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var confirmClear = false
  @State private var showInvestment = false
  @State private var showNetwork = false
  @State private var width: CGFloat = 375
  private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Ink.night.ignoresSafeArea()
        if let game = desk.game {
          gameView(game, compact: geometry.size.height < 700)
        } else {
          titleView
        }
        if desk.showGuide {
          PaperModal(title: "HOW TO PLAY", dismiss: { desk.showGuide = false }) { guide }
        } else if let game = desk.game {
          if game.isOver, !showNetwork {
            PaperModal { result(game, compact: geometry.size.height < 700) }
          } else if game.upgradePending, showInvestment {
            PaperModal(title: "POWER UP", dismiss: { showInvestment = false }) {
              upgrade(game)
            }
          }
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .onAppear { width = geometry.size.width }
      .onChange(of: geometry.size.width) { _, value in width = value }
    }
    .onReceive(timer) { _ in desk.tick() }
    .onChange(of: desk.game?.isOver) { _, _ in showNetwork = false }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active { desk.background() }
    }
    .confirmationDialog("Redraw this line?", isPresented: $confirmClear, titleVisibility: .visible)
    {
      Button("Clear line", role: .destructive) { desk.clear() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Passengers aboard return to their last station. Other lines keep running.")
    }
  }

  /// Characters per line of bitmap text inside a modal at the given pixel scale.
  private func modalColumns(_ scale: Double) -> Int {
    Int((min(420, width - 28) - 54) / (6 * scale))
  }

  private func screenColumns(_ scale: Double, inset: Double = 40) -> Int {
    Int((width - inset) / (6 * scale))
  }

  // MARK: Title

  private var titleView: some View {
    GeometryReader { geometry in
      let compact = geometry.size.height < 700
      ZStack(alignment: .bottom) {
        Starfield().ignoresSafeArea()
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            HStack {
              PixelText("1 PLAYER · 5 MINUTE STAGE", scale: 1.5, color: Ink.grey)
              Spacer()
              soundToggle
            }
            .frame(minHeight: 44)
            VStack(alignment: .leading, spacing: compact ? 6 : 10) {
              PixelText("TRANSIT", scale: compact ? 5 : 6, color: Ink.sun, outline: Ink.outline)
              PixelText("ATELIER", scale: compact ? 5 : 6, color: Ink.white, outline: Ink.outline)
            }
            .padding(.top, compact ? 6 : 14)
            .accessibilityElement(children: .combine)
            PixelText(
              "TURN A GROWING COAST INTO A LIVING RAIL MAP", scale: 1.5, color: Ink.grey,
              columns: screenColumns(1.5, inset: 48)
            )
            .padding(.top, 12)
            Panel(fill: Ink.outline, border: Ink.outline, inset: 0) {
              VStack(spacing: 0) {
                MapDrawing(game: demoMap, selected: 0, decorative: true)
                  .frame(height: compact ? 112 : min(200, geometry.size.height * 0.25))
                  .clipped()
                HStack {
                  Loco(color: Ink.routes[0], scale: 1.5)
                  PixelText("DEMO PLAY", scale: 1.5, color: Ink.sun)
                  Spacer()
                  PixelText(desk.selectedCity.title, scale: 1.5, color: Ink.white)
                }
                .padding(.horizontal, 12).frame(height: 30)
                .background(Ink.night)
              }
            }
            .padding(.top, compact ? 14 : 20)
            .padding(.bottom, compact ? 14 : 20)
            .accessibilityHidden(true)
            PixelText("SELECT STAGE", scale: 2, color: Ink.sun, shadow: Ink.outline)
              .padding(.bottom, 10)
            HStack(spacing: 12) {
              ForEach(City.allCases, id: \.self) { city in
                stageCard(city)
              }
            }
            Button {
              desk.start()
            } label: {
              HStack(spacing: 14) {
                Cursor(color: Ink.white, scale: 3)
                PixelText("START", scale: 3, color: Ink.white, shadow: Ink.outline)
                Cursor(color: Ink.white, scale: 3).scaleEffect(x: -1)
              }
            }
            .buttonStyle(PixelButton(fill: Ink.ember, height: 56))
            .padding(.top, 18)
            .accessibilityLabel("Start")
            HStack(spacing: 12) {
              Button {
                desk.showGuide = true
              } label: {
                PixelText("HOW TO PLAY", scale: 1.5, color: Ink.white)
              }
              .buttonStyle(PixelButton(fill: Ink.skyLight, height: 42))
              if desk.savedGame != nil {
                Button {
                  desk.resumeSaved()
                } label: {
                  PixelText("CONTINUE", scale: 1.5, color: Ink.outline)
                }
                .buttonStyle(PixelButton(fill: Ink.sun, height: 42))
              }
            }
            .padding(.top, 6)
            .padding(.bottom, 96)
          }
          .padding(.horizontal, 22)
          .padding(.top, 4)
        }
        Ground(reduceMotion: reduceMotion).frame(height: 78).ignoresSafeArea(edges: .bottom)
          .allowsHitTesting(false)
      }
    }
  }

  private var soundToggle: some View {
    Button {
      desk.toggleSound()
    } label: {
      HStack(spacing: 6) {
        SpeakerGlyph(on: desk.sound)
        PixelText(desk.sound ? "ON" : "OFF", scale: 1.5, color: desk.sound ? Ink.sun : Ink.grey)
      }
      .padding(.horizontal, 10)
      .frame(height: 30)
      .background(Ink.sky)
      .clipShape(PixelFrame(cut: 2))
      .overlay(PixelFrame(cut: 2).stroke(Ink.outline, lineWidth: 2))
    }
    .frame(minWidth: 44, minHeight: 44)
    .accessibilityLabel(desk.sound ? "Mute sound" : "Enable sound")
  }

  private func stageCard(_ city: City) -> some View {
    let selected = desk.selectedCity == city
    return Button {
      desk.selectedCity = city
      desk.feedback()
    } label: {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
          if selected { Cursor(scale: 1.5) }
          PixelText("STAGE \(city.number)", scale: 1.5, color: selected ? Ink.sun : Ink.grey)
        }
        PixelText(city.title, scale: 1.5, color: Ink.white, columns: 9)
        PixelText(
          desk.best(city) == 0 ? "BEST ----" : String(format: "BEST %04d", desk.best(city)),
          scale: 1.5, color: selected ? Ink.white : Ink.grey)
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(selected ? Ink.skyLight : Ink.sky)
      .clipShape(PixelFrame())
      .overlay(
        PixelFrame(cut: 2).stroke(selected ? Ink.sun : Ink.white.opacity(0.25), lineWidth: 2)
          .padding(4)
      )
      .overlay(PixelFrame().stroke(Ink.outline, lineWidth: 3))
    }
    .accessibilityLabel("\(city.title), best \(desk.best(city))")
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private var demoMap: TransitSimulation {
    var game = TransitSimulation(city: desk.selectedCity, seed: 1)
    game.stations += [
      Station(id: 4, point: desk.selectedCity.stations[4], kind: .square),
      Station(id: 5, point: desk.selectedCity.stations[5], kind: .triangle),
    ]
    game.setRoute(0, stops: [0, 1, 2, 3])
    game.setRoute(1, stops: [4, 1, 5])
    game.trains[0].progress = 0.55
    game.trains[1].progress = 0.40
    return game
  }

  // MARK: Gameplay

  private func gameView(_ game: TransitSimulation, compact: Bool) -> some View {
    VStack(spacing: 0) {
      hud(game, compact: compact)
      statusRibbon(game)
      ZStack(alignment: .topLeading) {
        InteractiveMap(game: game, selected: desk.selectedLine, tap: desk.station)
        HStack(spacing: 6) {
          if !(game.isOver || desk.planning || desk.paused || game.upgradePending) {
            Blink(period: 0.5) { Rectangle().fill(Ink.ember).frame(width: 6, height: 6) }
          }
          PixelText(
            game.isOver
              ? "FINAL MAP"
              : (desk.planning || desk.paused || game.upgradePending ? "PAUSED" : "LIVE"),
            scale: 1.5, color: Ink.outline)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(Ink.cream)
        .overlay(Rectangle().stroke(Ink.outline, lineWidth: 2))
        .padding(.leading, 12).padding(.top, 10)
        .allowsHitTesting(false)
      }
      .overlay(Rectangle().stroke(Ink.outline, lineWidth: 4))
      HStack {
        PixelText("TUNNELS \(game.tunnels - game.usedTunnels)", scale: 1.5, color: Ink.water)
        Spacer()
        PixelText(
          "WAITING \(game.waitingCount)   ABOARD \(game.aboardCount)", scale: 1.5, color: Ink.grey)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 8)
      .background(Ink.night)
      if game.isOver {
        Button {
          showNetwork = false
        } label: {
          PixelText("BACK TO RESULTS", scale: 2, color: Ink.white)
        }
        .buttonStyle(PixelButton(fill: Ink.ember))
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(Ink.sky)
      } else {
        controlPanel(game)
      }
    }
  }

  private func hud(_ game: TransitSimulation, compact: Bool) -> some View {
    VStack(spacing: compact ? 6 : 10) {
      HStack(spacing: 10) {
        PixelText("STAGE \(game.city.number)  \(game.city.title)", scale: 1.5, color: Ink.grey)
        Spacer()
        Menu {
          Button("How to play", systemImage: "questionmark.circle") { desk.showGuide = true }
          Button(desk.sound ? "Mute sound" : "Enable sound", systemImage: "speaker.wave.2") {
            desk.toggleSound()
          }
          Button("Save & leave", systemImage: "square.and.arrow.up") { desk.home() }
        } label: {
          hudChip("MENU", fill: Ink.sky, text: Ink.white)
        }.accessibilityLabel("Journey menu")
        if game.isOver {
          hudChip(game.completed ? "END" : "OVER", fill: Ink.grey, text: Ink.outline)
            .accessibilityLabel("Journey finished")
        } else {
          Button {
            desk.paused.toggle()
            desk.feedback()
          } label: {
            hudChip(
              desk.paused ? "PLAY" : "PAUSE", fill: desk.paused ? Ink.sun : Ink.cream,
              text: Ink.outline)
          }
          .accessibilityLabel(desk.paused ? "Resume journey" : "Pause journey")
          .disabled(game.upgradePending)
        }
      }
      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 5) {
          PixelText("SCORE", scale: 1.5, color: Ink.grey)
          PixelText(
            String(format: "%04d", game.delivered), scale: compact ? 3 : 4, color: Ink.sun,
            shadow: Ink.outline
          )
          .accessibilityLabel("\(game.delivered) delivered")
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 5) {
          PixelText(
            game.isOver ? "TIME" : (desk.planning ? "CONNECT TO START" : "TIME LEFT"),
            scale: 1.5, color: Ink.grey)
          PixelText(
            game.isOver ? elapsed(game.elapsed) : time(game.elapsed), scale: compact ? 3 : 4,
            color: Ink.white, shadow: Ink.outline)
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 6)
    .padding(.bottom, compact ? 8 : 12)
  }

  private func hudChip(_ text: String, fill: Color, text color: Color) -> some View {
    PixelText(text, scale: 1.5, color: color)
      .padding(.horizontal, 10)
      .frame(height: 32)
      .background(fill)
      .clipShape(PixelFrame(cut: 2))
      .overlay(PixelFrame(cut: 2).stroke(Ink.outline, lineWidth: 2))
      .frame(minWidth: 44, minHeight: 44)
  }

  private func statusRibbon(_ game: TransitSimulation) -> some View {
    HStack(spacing: 10) {
      if game.isOver {
        PixelText(
          game.completed
            ? "STAGE CLEAR! THE CITY IS CONNECTED"
            : "STATION \(String(format: "%02d", (game.failedStation?.id ?? 0) + 1)) OVERFLOWED",
          scale: 1.5, color: Ink.white, columns: screenColumns(1.5, inset: 120))
        Spacer()
        ribbonAction("RESULTS") { showNetwork = false }
      } else if game.upgradePending {
        Blink(period: 0.8) { PixelText("POWER UP READY!", scale: 1.5, color: Ink.sun) }
        Spacer()
        ribbonAction("OPEN") { showInvestment = true }
      } else if desk.paused {
        PixelText("PAUSED. EDIT YOUR LINES FREELY", scale: 1.5, color: Ink.white)
        Spacer()
      } else {
        PixelText(
          desk.planning
            ? "TAP OR DRAG BETWEEN TWO STATIONS" : "EXTEND LINES. MATCH THE SHAPES!",
          scale: 1.5, color: Ink.white)
        Spacer()
      }
    }
    .padding(.horizontal, 20)
    .frame(height: 44)
    .background(game.upgradePending ? Ink.leaf : Ink.sky)
    .overlay(alignment: .top) { Rectangle().fill(Ink.outline).frame(height: 3) }
  }

  private func ribbonAction(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      PixelText(title, scale: 1.5, color: Ink.outline)
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(Ink.sun)
        .clipShape(PixelFrame(cut: 2))
        .overlay(PixelFrame(cut: 2).stroke(Ink.outline, lineWidth: 2))
    }
    .frame(minWidth: 52, minHeight: 44)
  }

  private func controlPanel(_ game: TransitSimulation) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        PixelText("LINES", scale: 1.5, color: Ink.sun)
        Spacer()
        Button {
          desk.undo()
        } label: {
          PixelText("UNDO", scale: 1.5, color: Ink.white)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Ink.skyLight)
            .clipShape(PixelFrame(cut: 2))
            .overlay(PixelFrame(cut: 2).stroke(Ink.outline, lineWidth: 2))
        }
        .disabled(game.routes[desk.selectedLine].stops.isEmpty)
        Button {
          confirmClear = true
        } label: {
          PixelText("CLEAR", scale: 1.5, color: Ink.white)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Ink.ember)
            .clipShape(PixelFrame(cut: 2))
            .overlay(PixelFrame(cut: 2).stroke(Ink.outline, lineWidth: 2))
        }.disabled(game.routes[desk.selectedLine].stops.isEmpty)
          .accessibilityLabel("Redraw selected line")
      }
      .frame(height: 30)
      HStack(spacing: 10) {
        ForEach(game.routes) { route in
          lineButton(route)
        }
        Button {
          desk.speed = desk.speed == 1 ? 2 : 1
        } label: {
          PixelText(
            desk.speed == 2 ? ">>" : ">", scale: 2, color: desk.speed == 2 ? Ink.outline : Ink.white
          )
          .frame(width: 50, height: 44)
          .background(desk.speed == 2 ? Ink.sun : Ink.skyLight)
          .clipShape(PixelFrame(cut: 2))
          .overlay(PixelFrame(cut: 2).stroke(Ink.outline, lineWidth: 2))
        }.accessibilityLabel("Speed \(desk.speed) times")
      }
      PixelText(game.notice, scale: 1.5, color: Ink.cream, columns: screenColumns(1.5))
        .frame(height: 28, alignment: .topLeading)
        .accessibilityIdentifier("network-notice")
    }
    .padding(.horizontal, 20)
    .padding(.top, 10)
    .padding(.bottom, 6)
    .background(Ink.sky)
  }

  private func lineButton(_ route: Route) -> some View {
    let active = desk.selectedLine == route.id
    return Button {
      desk.selectedLine = route.id
      desk.feedback()
    } label: {
      HStack(spacing: 6) {
        Roundel(number: route.id + 1, color: Ink.routes[route.id], filled: true, size: 24)
        PixelText("\(route.capacity)P", scale: 1.5, color: active ? Ink.outline : Ink.white)
      }
      .frame(maxWidth: .infinity, minHeight: 44)
      .background(active ? Ink.routes[route.id] : Ink.night)
      .clipShape(PixelFrame(cut: 2))
      .overlay(PixelFrame(cut: 2).stroke(active ? Ink.white : Ink.outline, lineWidth: 2))
      .overlay(PixelFrame(cut: 2).stroke(Ink.outline, lineWidth: 2).padding(-2))
    }
    .accessibilityLabel("Select line \(route.id + 1), \(route.capacity) seats")
    .accessibilityAddTraits(active ? .isSelected : [])
  }

  // MARK: Guide

  private var guide: some View {
    VStack(alignment: .leading, spacing: 18) {
      PixelText(
        "EVERY SHAPE HAS A HOME", scale: 2.5, color: Ink.white, shadow: Ink.outline,
        columns: modalColumns(2.5))
      HStack(spacing: 10) {
        VStack(spacing: 6) {
          HStack(spacing: 3) {
            SpriteGlyph(kind: .circle, scale: 3)
            SpriteGlyph(kind: .triangle, scale: 1.5, fill: Ink.routes[1])
          }
          PixelText("WAITING", scale: 1, color: Ink.grey)
        }
        Rectangle().fill(Ink.routes[0]).frame(height: 4).overlay(
          Rectangle().stroke(Ink.outline, lineWidth: 1))
        Loco(color: Ink.routes[0], scale: 2.5)
        Rectangle().fill(Ink.routes[0]).frame(height: 4).overlay(
          Rectangle().stroke(Ink.outline, lineWidth: 1))
        VStack(spacing: 6) {
          SpriteGlyph(kind: .triangle, scale: 3)
          PixelText("HOME", scale: 1, color: Ink.grey)
        }
      }
      .padding(14)
      .background(Ink.night)
      .clipShape(PixelFrame())
      .overlay(PixelFrame().stroke(Ink.outline, lineWidth: 3))
      guideRow(
        1, title: "DRAW A LINE",
        detail:
          "Pick a colored line. Tap stations in order or drag from one to the next. Trains start by themselves."
      )
      guideRow(
        2, title: "READ THE QUEUE",
        detail:
          "Small shapes beside a station are waiting riders. Trains carry them to a matching station and can transfer between lines."
      )
      guideRow(
        3, title: "GIVE THEM ROOM",
        detail:
          "New stations keep arriving. River crossings cost tunnels. At 12 waiting a red meter fills: clear it within 24 seconds or lose."
      )
      guideRow(
        4, title: "REACH THE BELL",
        detail:
          "Pick a power up every 50 seconds. Deliver as many riders as you can in five minutes. Pause to plan, UNDO or CLEAR to edit."
      )
      Button {
        desk.showGuide = false
      } label: {
        PixelText("LET'S GO!", scale: 2, color: Ink.white, shadow: Ink.outline)
      }.buttonStyle(PixelButton(fill: Ink.ember))
    }
  }

  private func guideRow(_ number: Int, title: String, detail: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Roundel(number: number, color: Ink.routes[(number - 1) % 4], size: 26)
      VStack(alignment: .leading, spacing: 6) {
        PixelText(title, scale: 1.5, color: Ink.sun)
        PixelText(detail, scale: 1.5, color: Ink.cream, columns: modalColumns(1.5) - 5)
      }
    }
  }

  // MARK: Investment

  private func upgrade(_ game: TransitSimulation) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      PixelText("ROUND \(Int(game.elapsed / 50))", scale: 1.5, color: Ink.grey)
      PixelText(
        "PICK ONE POWER UP", scale: 2.5, color: Ink.white, shadow: Ink.outline,
        columns: modalColumns(2.5))
      PixelText(
        "THE CLOCK IS STOPPED WHILE YOU CHOOSE.", scale: 1.5, color: Ink.cream,
        columns: modalColumns(1.5))
      ForEach(
        Array(Upgrade.allCases.filter { $0 != .line || game.canAddLine }.enumerated()),
        id: \.element
      ) { index, item in
        Button {
          desk.choose(item)
          showInvestment = false
        } label: {
          HStack(spacing: 14) {
            PixelText(item.badge, scale: 2, color: Ink.white, shadow: Ink.outline)
              .frame(width: 48, height: 44)
              .background(Ink.routes[(index + 1) % 4])
              .clipShape(PixelFrame(cut: 2))
              .overlay(PixelFrame(cut: 2).stroke(Ink.outline, lineWidth: 2))
            VStack(alignment: .leading, spacing: 6) {
              PixelText(item.title, scale: 1.5, color: Ink.sun)
              PixelText(item.detail, scale: 1.5, color: Ink.cream, columns: modalColumns(1.5) - 8)
            }
            Spacer()
            Cursor(scale: 1.5).opacity(0.9)
          }
          .padding(12)
          .background(Ink.night)
          .clipShape(PixelFrame())
          .overlay(PixelFrame().stroke(Ink.outline, lineWidth: 3))
        }
        .accessibilityLabel("\(item.title), \(item.detail)")
      }
      Button {
        showInvestment = false
      } label: {
        PixelText("BACK TO MAP", scale: 1.5, color: Ink.white)
      }
      .frame(maxWidth: .infinity, minHeight: 44)
    }
  }

  // MARK: Results

  private func result(_ game: TransitSimulation, compact: Bool) -> some View {
    VStack(alignment: .leading, spacing: compact ? 10 : 14) {
      MapDrawing(game: game, selected: 0, decorative: true)
        .frame(height: compact ? 78 : 110)
        .clipped()
        .overlay(Rectangle().stroke(Ink.outline, lineWidth: 3))
        .accessibilityHidden(true)
      Blink(period: 0.8) {
        PixelText(
          game.completed ? "STAGE CLEAR!" : "GAME OVER", scale: compact ? 3 : 3.5,
          color: game.completed ? Ink.sun : Ink.ember, outline: Ink.outline)
      }
      PixelText(
        game.completed
          ? "FIVE MINUTES. COUNTLESS RIDERS HOME."
          : "STATION \(String(format: "%02d", (game.failedStation?.id ?? 0) + 1)) OVERFLOWED. TRY SHORTER LINES AND MORE TRANSFERS.",
        scale: 1.5, color: Ink.cream, columns: modalColumns(1.5))
      HStack(alignment: .bottom, spacing: 14) {
        VStack(alignment: .leading, spacing: 6) {
          PixelText("DELIVERED", scale: 1.5, color: Ink.grey)
          PixelText(
            String(format: "%04d", game.delivered), scale: compact ? 4 : 5, color: Ink.sun,
            shadow: Ink.outline
          )
          .accessibilityLabel("\(game.delivered) delivered")
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 6) {
          if game.delivered >= desk.best(game.city), game.delivered > 0 {
            Blink(period: 0.5) { PixelText("NEW BEST!", scale: 1.5, color: Ink.ember) }
          }
          PixelText(String(format: "BEST %04d", desk.best(game.city)), scale: 1.5, color: Ink.white)
          PixelText(
            "\(game.stations.count) STATIONS  \(elapsed(game.elapsed))", scale: 1.5, color: Ink.grey
          )
        }
      }
      .padding(12)
      .background(Ink.night)
      .clipShape(PixelFrame())
      .overlay(PixelFrame().stroke(Ink.outline, lineWidth: 3))
      Button {
        desk.start()
      } label: {
        PixelText("PLAY AGAIN", scale: 2.5, color: Ink.white, shadow: Ink.outline)
      }.buttonStyle(PixelButton(fill: Ink.ember, height: 54))
      HStack {
        Button {
          desk.home()
        } label: {
          PixelText("STAGES", scale: 1.5, color: Ink.white)
        }
        Spacer()
        Button {
          showNetwork = true
        } label: {
          PixelText("VIEW MAP", scale: 1.5, color: Ink.white)
        }
        Spacer()
        ShareJourneyButton(game: game, best: desk.best(game.city))
      }
      .frame(minHeight: 44)
    }
  }

  private func time(_ seconds: Double) -> String {
    let left = max(0, Int(ceil(TransitSimulation.duration - seconds)))
    return String(format: "%d:%02d", left / 60, left % 60)
  }

  private func elapsed(_ seconds: Double) -> String {
    String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
  }
}

extension Upgrade {
  var badge: String {
    switch self {
    case .carriage: "+3"
    case .tunnel: "+2"
    case .line: "+1"
    }
  }
}

/// Renders the journey postcard once, off the layout pass, then offers it through the native share sheet.
struct ShareJourneyButton: View {
  let game: TransitSimulation
  let best: Int
  @State private var export: (preview: Image, file: JourneyExport)?

  var body: some View {
    Group {
      if let export {
        ShareLink(
          item: export.file,
          preview: SharePreview(
            "Transit Atelier · \(game.delivered) delivered", image: export.preview)
        ) {
          PixelText("SHARE", scale: 1.5, color: Ink.sun)
        }
      } else {
        PixelText("SHARE", scale: 1.5, color: Ink.sun).opacity(0.4)
      }
    }
    .task(id: game.delivered) {
      let renderer = ImageRenderer(content: JourneyPostcard(game: game, best: best))
      renderer.scale = 2
      guard let image = renderer.uiImage, let data = image.pngData() else { return }
      let name =
        "Transit-Atelier-\(game.city.title.replacingOccurrences(of: " ", with: "-"))-\(game.delivered).png"
      export = (Image(uiImage: image), JourneyExport(png: data, filename: name))
    }
  }
}

/// Deterministic night sky of twinkling pixel stars behind the title.
struct Starfield: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
      Canvas { context, size in
        let tick = reduceMotion ? 0 : Int(timeline.date.timeIntervalSinceReferenceDate * 2)
        var generator = SeededGenerator(state: 42)
        for index in 0..<90 {
          let x = Double(generator.next() % 1_000) / 1_000 * size.width
          let y = Double(generator.next() % 1_000) / 1_000 * size.height * 0.8
          let big = generator.next() % 5 == 0
          let twinkle = (index + tick) % 7 == 0
          let cell = big ? 3.0 : 2.0
          context.fill(
            Path(
              CGRect(x: (x / 2).rounded() * 2, y: (y / 2).rounded() * 2, width: cell, height: cell)),
            with: .color(twinkle ? Ink.sun : Ink.white.opacity(big ? 0.9 : 0.45)))
        }
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}

/// Grass strip along the bottom of the title with a locomotive rolling across it.
struct Ground: View {
  let reduceMotion: Bool

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1.0 / 15)) { timeline in
      Canvas { context, size in
        let ground = size.height - 38
        let t =
          reduceMotion
          ? 0.5
          : (timeline.date.timeIntervalSinceReferenceDate / 9).truncatingRemainder(dividingBy: 1)
        context.fill(
          Path(CGRect(x: 0, y: ground, width: size.width, height: size.height)),
          with: .color(Ink.grass)
        )
        context.fill(
          Path(CGRect(x: 0, y: ground, width: size.width, height: 3)), with: .color(Ink.outline))
        context.fill(
          Path(CGRect(x: 0, y: ground - 3, width: size.width, height: 3)), with: .color(Ink.grey))
        var checker = Path()
        for column in 0..<(Int(size.width / 12) + 1) where column % 2 == 0 {
          checker.addRect(CGRect(x: Double(column) * 12, y: ground + 15, width: 12, height: 12))
        }
        context.fill(checker, with: .color(Ink.grassDeep.opacity(0.55)))
        context.fill(
          Path(CGRect(x: 0, y: ground + 10, width: size.width, height: 2)),
          with: .color(Ink.outline))
        let x = ((-60 + (size.width + 120) * t) / 2).rounded() * 2
        let bob = Int(timeline.date.timeIntervalSinceReferenceDate * 6) % 2 == 0 ? 0.0 : 1.0
        var layer = context
        layer.translateBy(x: x, y: bob)
        func px(_ px: Int, _ py: Int, _ w: Int, _ h: Int, _ c: Color) {
          layer.fill(
            Path(
              CGRect(
                x: Double(px) * 3, y: Double(py) * 3 + ground - 26, width: Double(w) * 3,
                height: Double(h) * 3)),
            with: .color(c))
        }
        px(0, 1, 12, 6, Ink.outline)
        px(1, 2, 10, 4, Ink.routes[0])
        px(9, 0, 3, 3, Ink.outline)
        px(10, 1, 1, 1, Ink.sun)
        px(2, 3, 2, 2, Ink.white)
        px(5, 3, 2, 2, Ink.white)
        px(1, 7, 3, 2, Ink.grey)
        px(8, 7, 3, 2, Ink.grey)
        px(-4, 2, 3, 1, Ink.grey.opacity(0.7))
        px(-8, 1, 3, 1, Ink.grey.opacity(0.4))
      }
    }
    .accessibilityHidden(true)
  }
}

/// Pixel speaker icon for the sound toggle.
struct SpeakerGlyph: View {
  let on: Bool

  var body: some View {
    Canvas { context, _ in
      var speaker = Path()
      speaker.addRect(CGRect(x: 0, y: 4, width: 4, height: 6))
      speaker.addRect(CGRect(x: 4, y: 2, width: 2, height: 10))
      speaker.addRect(CGRect(x: 6, y: 0, width: 2, height: 14))
      context.fill(speaker, with: .color(Ink.white))
      if on {
        var waves = Path()
        waves.addRect(CGRect(x: 10, y: 4, width: 2, height: 6))
        waves.addRect(CGRect(x: 13, y: 2, width: 2, height: 10))
        context.fill(waves, with: .color(Ink.sun))
      } else {
        var cross = Path()
        cross.addRect(CGRect(x: 10, y: 3, width: 2, height: 2))
        cross.addRect(CGRect(x: 12, y: 5, width: 2, height: 2))
        cross.addRect(CGRect(x: 14, y: 7, width: 2, height: 2))
        cross.addRect(CGRect(x: 14, y: 3, width: 2, height: 2))
        cross.addRect(CGRect(x: 10, y: 7, width: 2, height: 2))
        context.fill(cross, with: .color(Ink.grey))
      }
    }
    .frame(width: 16, height: 14)
    .accessibilityHidden(true)
  }
}
