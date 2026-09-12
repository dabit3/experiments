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
    let frequency = delivery ? 660.0 : 440.0
    for index in 0..<Int(buffer.frameLength) {
      let time = Double(index) / 44_100
      samples[0][index] = Float(sin(time * frequency * 2 * .pi) * exp(-time * 38) * 0.12)
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
    guard game != nil, game?.isOver == false, game?.upgradePending == false else { return }
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

enum Ink {
  static let paper = Color(red: 0.97, green: 0.955, blue: 0.918)
  static let navy = Color(red: 0.10, green: 0.18, blue: 0.23)
  static let muted = Color(red: 0.43, green: 0.47, blue: 0.45)
  static let rule = Color(red: 0.84, green: 0.84, blue: 0.78)
  static let routes: [Color] = [
    Color(red: 0.86, green: 0.31, blue: 0.20),
    Color(red: 0.08, green: 0.49, blue: 0.48),
    Color(red: 0.78, green: 0.58, blue: 0.13),
    Color(red: 0.44, green: 0.38, blue: 0.66),
  ]
}

struct PaperButton: ButtonStyle {
  var filled = true
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 15, weight: .semibold))
      .frame(maxWidth: .infinity, minHeight: 52)
      .background(filled ? Ink.navy : Ink.rule.opacity(0.35))
      .foregroundStyle(filled ? Ink.paper : Ink.navy)
      .clipShape(RoundedRectangle(cornerRadius: 15))
      .opacity(configuration.isPressed ? 0.7 : 1)
  }
}

struct AtelierView: View {
  @StateObject private var desk = GameDesk()
  @Environment(\.scenePhase) private var scenePhase
  @State private var confirmClear = false
  private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

  var body: some View {
    ZStack {
      Ink.paper.ignoresSafeArea()
      if let game = desk.game {
        gameView(game)
      } else {
        titleView
      }
      if desk.showGuide {
        modal { guide }
      } else if let game = desk.game {
        if game.isOver {
          modal { result(game) }
        } else if game.upgradePending {
          modal { upgrade(game) }
        } else if desk.paused {
          modal { pause }
        }
      }
    }
    .foregroundStyle(Ink.navy)
    .onReceive(timer) { _ in desk.tick() }
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

  private var titleView: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            eyebrow("A SMALL STUDY IN CONNECTION")
            Spacer()
            Button {
              desk.toggleSound()
            } label: {
              Image(systemName: desk.sound ? "speaker.wave.2" : "speaker.slash")
                .frame(width: 44, height: 44)
            }.accessibilityLabel(desk.sound ? "Mute sound" : "Enable sound")
          }
          Text("Transit\nAtelier")
            .font(.system(size: 58, weight: .regular, design: .serif))
            .tracking(-2.5)
            .lineSpacing(-8)
            .padding(.top, 12)
          HStack(spacing: 10) {
            Rectangle().fill(Ink.routes[0]).frame(width: 28, height: 2)
            Text("Make room for a city in motion.")
              .font(.system(size: 13))
              .foregroundStyle(Ink.muted)
          }.padding(.top, 14)
          MapDrawing(game: demoMap, selected: 0, decorative: true)
            .frame(height: max(170, min(245, geometry.size.height * 0.30)))
            .padding(.vertical, 16)
            .accessibilityHidden(true)
          HStack {
            eyebrow("CHOOSE YOUR CITY")
            Spacer()
            eyebrow("5 MIN / LOCAL BEST")
          }.padding(.bottom, 10)
          HStack(spacing: 10) {
            ForEach(City.allCases, id: \.self) { city in
              Button {
                desk.selectedCity = city
                desk.feedback()
              } label: {
                VStack(alignment: .leading, spacing: 9) {
                  HStack {
                    Text(city.number).font(.system(size: 11, design: .monospaced))
                    Spacer()
                    Image(
                      systemName: desk.selectedCity == city ? "checkmark.circle.fill" : "circle")
                  }
                  Text(city.title).font(.system(size: 16, weight: .medium, design: .serif))
                  Text(
                    desk.best(city) == 0
                      ? "An unwritten journey" : "Best: \(desk.best(city)) delivered"
                  )
                  .font(.system(size: 10))
                  .foregroundStyle(Ink.muted)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(desk.selectedCity == city ? Color.white.opacity(0.55) : .clear)
                .overlay(
                  RoundedRectangle(cornerRadius: 13).stroke(
                    desk.selectedCity == city ? Ink.navy : Ink.rule, lineWidth: 1))
              }.accessibilityLabel("\(city.title), best \(desk.best(city))")
            }
          }
          Button {
            desk.start()
          } label: {
            HStack {
              Text("Begin a new journey")
              Spacer()
              Image(systemName: "arrow.right")
            }.padding(.horizontal, 20)
          }
          .buttonStyle(PaperButton())
          .padding(.top, 18)
          HStack {
            Button("How to play") { desk.showGuide = true }
            Spacer()
            if desk.savedGame != nil {
              Button("Continue journey") { desk.resumeSaved() }
            } else {
              Text("DESIGNED TO KEEP YOU MOVING")
                .font(.system(size: 8, weight: .medium))
                .tracking(1)
            }
          }
          .font(.system(size: 12, weight: .medium))
          .frame(minHeight: 48)
        }
        .padding(.horizontal, 26)
        .padding(.top, 6)
      }
    }
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

  private func gameView(_ game: TransitSimulation) -> some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          eyebrow("TRANSIT ATELIER / \(game.city.number)")
          Text(game.city.title)
            .font(.system(size: 25, design: .serif))
            .tracking(-0.5)
        }
        Spacer()
        Button {
          desk.showGuide = true
        } label: {
          Image(systemName: "questionmark").frame(width: 42, height: 44)
        }.accessibilityLabel("How to play")
        Button {
          desk.paused = true
        } label: {
          Image(systemName: "pause.fill")
            .font(.system(size: 17))
            .frame(width: 44, height: 44)
            .background(Ink.rule.opacity(0.35), in: Circle())
        }.accessibilityLabel("Pause journey")
      }.padding(.horizontal, 24).padding(.top, 8)
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        Text("\(game.delivered)")
          .font(.system(size: 48, weight: .light, design: .rounded))
          .monospacedDigit()
        Text("  DELIVERED")
          .font(.system(size: 9, weight: .semibold))
          .tracking(1.4)
          .foregroundStyle(Ink.muted)
        Spacer()
        VStack(alignment: .trailing, spacing: 5) {
          Text(time(game.elapsed))
            .font(.system(size: 22, weight: .light, design: .monospaced))
          eyebrow(desk.planning ? "CONNECT TO BEGIN" : "UNTIL CLOSING")
        }
      }.padding(.horizontal, 24).padding(.top, 18).padding(.bottom, 14)
      Rectangle().fill(Ink.rule).frame(height: 1).padding(.horizontal, 24)
      ZStack(alignment: .topLeading) {
        InteractiveMap(game: game, selected: desk.selectedLine, tap: desk.station)
        HStack(spacing: 5) {
          Circle().fill(desk.planning ? Ink.muted : Ink.routes[1]).frame(width: 5, height: 5)
          Text(desk.planning ? "PLANNING TABLE" : "LIVE NETWORK")
            .font(.system(size: 8, weight: .medium))
            .tracking(1.5)
        }.padding(.leading, 24).padding(.top, 12).allowsHitTesting(false)
      }
      HStack {
        Label("\(game.tunnels - game.usedTunnels) tunnels", systemImage: "water.waves")
        Spacer()
        Text("\(game.waitingCount) waiting · \(game.aboardCount) aboard")
      }
      .font(.system(size: 10, weight: .medium))
      .foregroundStyle(Ink.muted)
      .padding(.horizontal, 24)
      .padding(.bottom, 12)
      Rectangle().fill(Ink.rule).frame(height: 1).padding(.horizontal, 24)
      controlPanel(game)
    }
  }

  private func controlPanel(_ game: TransitSimulation) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        eyebrow("YOUR LINES")
        Spacer()
        Button {
          desk.undo()
        } label: {
          Label("Undo", systemImage: "arrow.uturn.backward")
        }
        .disabled(game.routes[desk.selectedLine].stops.isEmpty)
        Button {
          confirmClear = true
        } label: {
          Image(systemName: "eraser").frame(width: 38, height: 36)
        }.disabled(game.routes[desk.selectedLine].stops.isEmpty)
          .accessibilityLabel("Redraw selected line")
      }.font(.system(size: 11, weight: .medium)).frame(height: 30)
      HStack(spacing: 8) {
        ForEach(game.routes) { route in
          Button {
            desk.selectedLine = route.id
            desk.feedback()
          } label: {
            HStack(spacing: 8) {
              Text("\(route.id + 1)").font(.system(size: 14, weight: .bold, design: .rounded))
              Image(systemName: "tram.fill").font(.system(size: 12))
              Text("\(route.capacity)").font(.system(size: 10, design: .monospaced))
            }
            .frame(maxWidth: .infinity, minHeight: 45)
            .background(
              desk.selectedLine == route.id
                ? Ink.routes[route.id] : Ink.routes[route.id].opacity(0.10)
            )
            .foregroundStyle(desk.selectedLine == route.id ? Ink.paper : Ink.routes[route.id])
            .clipShape(RoundedRectangle(cornerRadius: 13))
          }.accessibilityLabel("Select line \(route.id + 1), \(route.capacity) seats")
        }
        Button {
          desk.speed = desk.speed == 1 ? 2 : 1
        } label: {
          Text("\(desk.speed)×")
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .frame(width: 48, height: 45)
            .background(Ink.rule.opacity(0.3), in: RoundedRectangle(cornerRadius: 13))
        }.accessibilityLabel("Speed \(desk.speed) times")
      }
      Text(game.notice)
        .font(.system(size: 11))
        .foregroundStyle(Ink.muted)
        .lineLimit(2)
        .frame(height: 32, alignment: .topLeading)
        .accessibilityIdentifier("network-notice")
    }
    .padding(.horizontal, 24)
    .padding(.top, 10)
    .padding(.bottom, 8)
  }

  private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Ink.navy.opacity(0.45).ignoresSafeArea()
      ScrollView {
        content()
          .padding(26)
      }
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: 420)
      .background(Ink.paper, in: RoundedRectangle(cornerRadius: 26))
      .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.white.opacity(0.6), lineWidth: 1))
      .padding(20)
    }.accessibilityAddTraits(.isModal)
  }

  private var guide: some View {
    VStack(alignment: .leading, spacing: 20) {
      eyebrow("THE ART OF GETTING THERE")
      Text("Every shape\nhas a destination.")
        .font(.system(size: 34, design: .serif))
        .tracking(-1)
      guideRow(
        "01", title: "Draw a connection",
        detail:
          "Choose a colored line. Tap stations in order, or drag from one station to the next. Trains start automatically."
      )
      guideRow(
        "02", title: "Read your passengers",
        detail:
          "Tiny shapes beside stations are waiting passengers. Trains take them to a matching station, transferring between connected lines."
      )
      guideRow(
        "03", title: "Give the city room",
        detail:
          "Add new stations to your routes. River crossings use tunnels. At 12 waiting, a red ring fills: relieve it before 24 seconds pass."
      )
      guideRow(
        "04", title: "Make it to closing",
        detail:
          "Choose an upgrade every 50 seconds. Deliver as many as possible in five minutes. Pause to plan; Undo or the eraser edits a line."
      )
      Button("Let’s make connections") { desk.showGuide = false }.buttonStyle(PaperButton())
    }
  }

  private func guideRow(_ number: String, title: String, detail: String) -> some View {
    HStack(alignment: .top, spacing: 14) {
      Text(number).font(.system(size: 11, design: .monospaced)).foregroundStyle(Ink.routes[0])
        .padding(.top, 3)
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.system(size: 15, weight: .semibold))
        Text(detail).font(.system(size: 12)).foregroundStyle(Ink.muted).fixedSize(
          horizontal: false, vertical: true)
      }
    }
  }

  private var pause: some View {
    VStack(alignment: .leading, spacing: 20) {
      eyebrow("A MOMENT OF STILLNESS")
      Text("The city can wait.")
        .font(.system(size: 34, design: .serif)).tracking(-1)
      Text("Your trains and passengers are paused.\nTake a breath. Find the next connection.")
        .font(.system(size: 13)).foregroundStyle(Ink.muted)
      Button("Resume journey") { desk.paused = false }.buttonStyle(PaperButton())
      HStack {
        Button {
          desk.toggleSound()
        } label: {
          Label(
            desk.sound ? "Sound on" : "Sound off",
            systemImage: desk.sound ? "speaker.wave.2" : "speaker.slash")
        }
        Spacer()
        Button("Save & leave") { desk.home() }
      }.font(.system(size: 13, weight: .medium)).frame(minHeight: 44)
    }
  }

  private func upgrade(_ game: TransitSimulation) -> some View {
    VStack(alignment: .leading, spacing: 17) {
      eyebrow("CITY INVESTMENT / \(Int(game.elapsed / 50))")
      Text("A little room\nto grow.")
        .font(.system(size: 38, design: .serif)).tracking(-1)
      Text("Choose one improvement. The network is paused.")
        .font(.system(size: 12)).foregroundStyle(Ink.muted)
      ForEach(Upgrade.allCases.filter { $0 != .line || game.canAddLine }, id: \.self) { item in
        Button {
          desk.choose(item)
        } label: {
          HStack(spacing: 16) {
            Image(systemName: item.symbol)
              .font(.system(size: 22, weight: .light))
              .frame(width: 38)
              .foregroundStyle(Ink.routes[1])
            VStack(alignment: .leading, spacing: 4) {
              Text(item.title).font(.system(size: 16, weight: .semibold))
              Text(item.detail).font(.system(size: 11)).foregroundStyle(Ink.muted)
            }
            Spacer()
            Image(systemName: "arrow.up.right").font(.system(size: 12))
          }
          .padding(16)
          .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 15))
          .overlay(RoundedRectangle(cornerRadius: 15).stroke(Ink.rule, lineWidth: 1))
        }
      }
    }
  }

  private func result(_ game: TransitSimulation) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        eyebrow(game.completed ? "THE LAST TRAIN HOME" : "TIME TO REDRAW")
        Spacer()
        Image(systemName: game.completed ? "sun.horizon" : "arrow.triangle.branch")
          .foregroundStyle(Ink.routes[0])
      }
      Text(game.completed ? "A city in motion." : "Every city\nis a lesson.")
        .font(.system(size: 38, design: .serif)).tracking(-1)
      Text(
        game.completed
          ? "Five minutes. Countless connections."
          : "A station filled faster than its trains could carry.\nTry shorter lines and more connections."
      )
      .font(.system(size: 12)).foregroundStyle(Ink.muted)
      Rectangle().fill(Ink.rule).frame(height: 1).padding(.top, 5)
      HStack(alignment: .firstTextBaseline) {
        Text("\(game.delivered)").font(.system(size: 76, weight: .light, design: .rounded))
          .tracking(-3)
        eyebrow("PASSENGERS\nDELIVERED")
      }
      HStack {
        resultStat("LOCAL BEST", value: "\(desk.best(game.city))")
        Spacer()
        resultStat("NETWORK", value: "\(game.stations.count) stations")
        Spacer()
        resultStat("TIME", value: elapsed(game.elapsed))
      }
      Rectangle().fill(Ink.rule).frame(height: 1).padding(.bottom, 5)
      Button("Draw another journey") { desk.start() }.buttonStyle(PaperButton())
      HStack {
        Button("Choose city") { desk.home() }
        Spacer()
        ShareLink(
          item:
            "I delivered \(game.delivered) passengers in \(game.city.title) with Transit Atelier. My local best is \(desk.best(game.city))."
        ) {
          Label("Share journey", systemImage: "square.and.arrow.up")
        }
      }.font(.system(size: 12, weight: .medium)).frame(minHeight: 44)
    }
  }

  private func resultStat(_ label: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 7) {
      eyebrow(label)
      Text(value).font(.system(size: 13, weight: .medium, design: .monospaced))
    }
  }

  private func eyebrow(_ text: String) -> some View {
    Text(text).font(.system(size: 8, weight: .semibold)).tracking(1.3).foregroundStyle(Ink.muted)
  }

  private func time(_ seconds: Double) -> String {
    let left = max(0, Int(ceil(TransitSimulation.duration - seconds)))
    return String(format: "%d:%02d", left / 60, left % 60)
  }

  private func elapsed(_ seconds: Double) -> String {
    String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
  }
}
