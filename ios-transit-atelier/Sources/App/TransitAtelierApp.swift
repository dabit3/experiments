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
  @State private var confirmClear = false
  @State private var showInvestment = false
  @State private var showNetwork = false
  private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Ink.header.ignoresSafeArea()
        if let game = desk.game {
          gameView(game)
        } else {
          titleView
        }
        if desk.showGuide {
          PaperModal(title: "FIELD GUIDE", dismiss: { desk.showGuide = false }) { guide }
        } else if let game = desk.game {
          if game.isOver, !showNetwork {
            PaperModal { result(game, compact: geometry.size.height < 700) }
          } else if game.upgradePending, showInvestment {
            PaperModal(title: "CITY INVESTMENT", dismiss: { showInvestment = false }) {
              upgrade(game)
            }
          }
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .foregroundStyle(Ink.navy)
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

  // MARK: Title

  private var titleView: some View {
    GeometryReader { geometry in
      let compact = geometry.size.height < 700
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            Eyebrow("A SMALL STUDY IN CONNECTION", tone: Ink.gold)
            Spacer()
            Button {
              desk.toggleSound()
            } label: {
              Image(systemName: desk.sound ? "speaker.wave.2" : "speaker.slash")
                .font(.system(size: 14))
                .frame(width: 44, height: 44)
                .foregroundStyle(Ink.paper)
            }.accessibilityLabel(desk.sound ? "Mute sound" : "Enable sound")
          }
          VStack(alignment: .leading, spacing: compact ? -12 : -16) {
            Text("Transit")
              .font(.system(size: compact ? 50 : 62, weight: .regular, design: .serif))
            Text("Atelier")
              .font(.system(size: compact ? 50 : 62, weight: .regular, design: .serif).italic())
              .foregroundStyle(Ink.gold)
          }
          .tracking(-2)
          .foregroundStyle(Ink.paperLight)
          .padding(.top, 4)
          HStack(spacing: 10) {
            Rectangle().fill(Ink.routes[0]).frame(width: 26, height: 2)
            Text("Turn a growing coast into a living diagram.")
              .font(.system(size: 13, design: .serif).italic())
              .foregroundStyle(Ink.paper.opacity(0.78))
          }.padding(.top, 12)
          ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18)
              .fill(Ink.paperDeep.opacity(0.35))
              .rotationEffect(.degrees(-2.5))
              .padding(.horizontal, 10)
              .offset(y: 8)
            Sheet(radius: 18) {
              VStack(spacing: 0) {
                MapDrawing(game: demoMap, selected: 0, decorative: true)
                  .frame(height: compact ? 124 : min(220, geometry.size.height * 0.27))
                  .clipped()
                HStack(spacing: 6) {
                  CompassRose().frame(width: 12, height: 12)
                  Eyebrow("THE COASTAL COLLECTION", size: 7)
                  Spacer()
                  Eyebrow(desk.selectedCity.title.uppercased(), tone: Ink.routes[0], size: 7)
                }
                .padding(.horizontal, 14).frame(height: 28)
                .background(Ink.paperLight)
                .overlay(alignment: .top) { Rectangle().fill(Ink.rule).frame(height: 1) }
              }
            }
          }
          .padding(.top, compact ? 16 : 22)
          .padding(.bottom, compact ? 16 : 22)
          .accessibilityHidden(true)
          HStack {
            Eyebrow("CHOOSE YOUR CITY", tone: Ink.paper.opacity(0.7))
            Spacer()
            Eyebrow("FIVE MINUTES · LOCAL BEST", tone: Ink.paper.opacity(0.7))
          }.padding(.bottom, 10)
          HStack(spacing: 12) {
            ForEach(City.allCases, id: \.self) { city in
              cityTicket(city)
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
          .buttonStyle(PaperButton(tone: .coral))
          .padding(.top, 18)
          HStack {
            Button("How to play") { desk.showGuide = true }
            Spacer()
            if desk.savedGame != nil {
              Button {
                desk.resumeSaved()
              } label: {
                Label("Continue journey", systemImage: "arrow.counterclockwise")
              }
            } else {
              Eyebrow("DESIGNED TO KEEP YOU MOVING", tone: Ink.paper.opacity(0.45))
            }
          }
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(Ink.paper)
          .frame(minHeight: 48)
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
      }
    }
  }

  private func cityTicket(_ city: City) -> some View {
    let selected = desk.selectedCity == city
    return Button {
      withAnimation(.spring(duration: 0.3)) { desk.selectedCity = city }
      desk.feedback()
    } label: {
      VStack(alignment: .leading, spacing: 0) {
        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Eyebrow("SHEET \(city.number)", tone: selected ? Ink.routes[0] : Ink.muted)
            Spacer()
            Circle()
              .fill(selected ? Ink.routes[0] : .clear)
              .overlay(Circle().strokeBorder(selected ? Ink.routes[0] : Ink.rule, lineWidth: 1.5))
              .frame(width: 14, height: 14)
              .overlay {
                if selected {
                  Image(systemName: "checkmark").font(.system(size: 7, weight: .black))
                    .foregroundStyle(Ink.paperLight)
                }
              }
          }
          Text(city.title).font(.system(size: 16, weight: .medium, design: .serif))
            .lineLimit(1).minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 13).padding(.top, 13).padding(.bottom, 12)
        Line().stroke(Ink.rule, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
          .frame(height: 1).padding(.horizontal, 6)
        Text(desk.best(city) == 0 ? "An unwritten journey" : "Best \(desk.best(city)) delivered")
          .font(.system(size: 10, weight: .medium, design: .monospaced))
          .foregroundStyle(selected ? Ink.navy : Ink.muted)
          .padding(.horizontal, 13).padding(.vertical, 9)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(selected ? Ink.paperLight : Ink.paperDeep)
      .overlay(PaperGrain().clipShape(TicketShape()))
      .clipShape(TicketShape())
      .overlay(TicketShape().stroke(selected ? Ink.routes[0] : Color.clear, lineWidth: 1.5))
      .shadow(color: Ink.navyDeep.opacity(selected ? 0.35 : 0.15), radius: 10, y: 6)
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

  private func gameView(_ game: TransitSimulation) -> some View {
    VStack(spacing: 0) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Eyebrow("TRANSIT ATELIER · SHEET \(game.city.number)", tone: Ink.gold)
          Text(game.city.title)
            .font(.system(size: 24, design: .serif))
            .tracking(-0.5)
            .foregroundStyle(Ink.paperLight)
        }
        Spacer()
        Menu {
          Button("How to play", systemImage: "questionmark.circle") { desk.showGuide = true }
          Button(desk.sound ? "Mute sound" : "Enable sound", systemImage: "speaker.wave.2") {
            desk.toggleSound()
          }
          Button("Save & leave", systemImage: "square.and.arrow.up") { desk.home() }
        } label: {
          Image(systemName: "ellipsis")
            .frame(width: 42, height: 42)
            .foregroundStyle(Ink.paper)
            .background(Color.white.opacity(0.08), in: Circle())
        }.accessibilityLabel("Journey menu")
        if game.isOver {
          Image(systemName: game.completed ? "checkmark" : "stop.fill")
            .font(.system(size: 15, weight: .semibold))
            .frame(width: 42, height: 42)
            .foregroundStyle(Ink.navy)
            .background(Ink.paperLight, in: Circle())
            .accessibilityLabel("Journey finished")
        } else {
          Button {
            withAnimation(.spring(duration: 0.3)) { desk.paused.toggle() }
            desk.feedback()
          } label: {
            Image(systemName: desk.paused ? "play.fill" : "pause.fill")
              .font(.system(size: 15, weight: .semibold))
              .frame(width: 42, height: 42)
              .foregroundStyle(desk.paused ? Ink.paperLight : Ink.navy)
              .background(desk.paused ? Ink.routes[0] : Ink.paperLight, in: Circle())
          }.accessibilityLabel(desk.paused ? "Resume journey" : "Pause journey")
            .disabled(game.upgradePending)
        }
      }.padding(.horizontal, 22).padding(.top, 6)
      HStack(alignment: .lastTextBaseline, spacing: 0) {
        Text("\(game.delivered)")
          .font(.system(size: 46, weight: .regular, design: .serif))
          .monospacedDigit()
          .tracking(-1.5)
          .foregroundStyle(Ink.paperLight)
          .contentTransition(.numericText())
          .animation(.snappy, value: game.delivered)
        Eyebrow("  DELIVERED", tone: Ink.paper.opacity(0.65), size: 9)
        Spacer()
        VStack(alignment: .trailing, spacing: 4) {
          Text(game.isOver ? elapsed(game.elapsed) : time(game.elapsed))
            .font(.system(size: 24, weight: .light, design: .monospaced))
            .foregroundStyle(Ink.paperLight)
          Eyebrow(
            game.isOver ? "JOURNEY TIME" : (desk.planning ? "CONNECT TO BEGIN" : "UNTIL CLOSING"),
            tone: Ink.paper.opacity(0.65))
        }
      }.padding(.horizontal, 22).padding(.top, 10).padding(.bottom, 12)
      statusRibbon(game)
      ZStack(alignment: .topLeading) {
        Ink.paper
        PaperGrain()
        InteractiveMap(game: game, selected: desk.selectedLine, tap: desk.station)
        HStack(spacing: 6) {
          Circle()
            .fill(game.isOver || desk.planning || desk.paused ? Ink.muted : Ink.routes[1])
            .frame(width: 6, height: 6)
          Eyebrow(
            game.isOver
              ? "FINISHED NETWORK"
              : (desk.planning || desk.paused || game.upgradePending
                ? "PLANNING TABLE" : "LIVE NETWORK"))
        }
        .padding(.horizontal, 9).padding(.vertical, 6)
        .background(Ink.paperLight.opacity(0.9), in: Capsule())
        .overlay(Capsule().strokeBorder(Ink.rule, lineWidth: 0.8))
        .padding(.leading, 14).padding(.top, 12)
        .allowsHitTesting(false)
      }
      .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
      .shadow(color: Ink.navyDeep.opacity(0.4), radius: 16, y: -4)
      HStack {
        Label("\(game.tunnels - game.usedTunnels) tunnels", systemImage: "water.waves")
        Spacer()
        Text("\(game.waitingCount) waiting  ·  \(game.aboardCount) aboard")
          .monospacedDigit()
      }
      .font(.system(size: 11, weight: .medium))
      .foregroundStyle(Ink.muted)
      .padding(.horizontal, 22)
      .padding(.vertical, 10)
      .background(Ink.paperDeep)
      if game.isOver {
        Button("Return to results") { showNetwork = false }
          .buttonStyle(PaperButton())
          .padding(.horizontal, 22).padding(.vertical, 16)
          .background(Ink.paper)
      } else {
        controlPanel(game)
      }
    }
  }

  private func statusRibbon(_ game: TransitSimulation) -> some View {
    HStack(spacing: 9) {
      Image(
        systemName: game.upgradePending
          ? "sparkles"
          : (desk.paused ? "pause.circle" : "point.topleft.down.to.point.bottomright.curvepath")
      )
      .font(.system(size: 12))
      .foregroundStyle(game.upgradePending ? Ink.gold : Ink.paper.opacity(0.8))
      if game.isOver {
        Text(
          game.completed
            ? "Closing bell · a city connected"
            : "Overcrowding · station \(String(format: "%02d", (game.failedStation?.id ?? 0) + 1))")
        Spacer()
        ribbonAction("Results") { showNetwork = false }
      } else if game.upgradePending {
        Text("Investment ready · time paused")
        Spacer()
        ribbonAction("Review") { showInvestment = true }
      } else if desk.paused {
        Text("Time paused. Your map is free to edit.")
        Spacer()
      } else {
        Text(
          desk.planning
            ? "Tap or drag between two stations to begin."
            : "Extend lines. Connect shapes. Keep moving.")
        Spacer()
      }
    }
    .font(.system(size: 12, design: .serif).italic())
    .foregroundStyle(Ink.paper.opacity(0.9))
    .padding(.horizontal, 22)
    .frame(height: 44)
    .background(Color.white.opacity(game.upgradePending ? 0.12 : 0.06))
  }

  private func ribbonAction(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 11, weight: .bold))
        .tracking(0.5)
        .foregroundStyle(Ink.navy)
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(Ink.gold, in: Capsule())
    }
    .frame(minWidth: 52, minHeight: 44)
  }

  private func controlPanel(_ game: TransitSimulation) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Eyebrow("YOUR LINES")
        Spacer()
        Button {
          desk.undo()
        } label: {
          Label("Undo", systemImage: "arrow.uturn.backward")
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Ink.paperDeep, in: Capsule())
        }
        .disabled(game.routes[desk.selectedLine].stops.isEmpty)
        Button {
          confirmClear = true
        } label: {
          Image(systemName: "eraser").frame(width: 38, height: 30)
            .background(Ink.paperDeep, in: Capsule())
        }.disabled(game.routes[desk.selectedLine].stops.isEmpty)
          .accessibilityLabel("Redraw selected line")
      }.font(.system(size: 11, weight: .semibold)).frame(height: 30)
      HStack(spacing: 10) {
        ForEach(game.routes) { route in
          let active = desk.selectedLine == route.id
          Button {
            withAnimation(.spring(duration: 0.3)) { desk.selectedLine = route.id }
            desk.feedback()
          } label: {
            HStack(spacing: 7) {
              Roundel(number: route.id + 1, color: Ink.routes[route.id], filled: active, size: 26)
              HStack(spacing: 2) {
                Image(systemName: "person.fill").font(.system(size: 8))
                Text("\(route.capacity)")
                  .font(.system(size: 12, weight: .bold, design: .monospaced))
              }
              .foregroundStyle(active ? Ink.routes[route.id] : Ink.muted)
            }
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(active ? Ink.paperLight : Ink.paper.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
              RoundedRectangle(cornerRadius: 14)
                .strokeBorder(active ? Ink.routes[route.id] : Ink.rule, lineWidth: active ? 1.5 : 1)
            )
            .shadow(color: Ink.navyDeep.opacity(active ? 0.14 : 0), radius: 6, y: 3)
          }.accessibilityLabel("Select line \(route.id + 1), \(route.capacity) seats")
        }
        Button {
          withAnimation(.snappy) { desk.speed = desk.speed == 1 ? 2 : 1 }
        } label: {
          HStack(spacing: 2) {
            Image(systemName: desk.speed == 2 ? "forward.fill" : "play.fill")
              .font(.system(size: 8))
            Text("\(desk.speed)×")
              .font(.system(size: 13, weight: .bold, design: .monospaced))
          }
          .frame(width: 54, height: 46)
          .foregroundStyle(desk.speed == 2 ? Ink.paperLight : Ink.navy)
          .background(
            desk.speed == 2 ? Ink.navy : Ink.paperDeep, in: RoundedRectangle(cornerRadius: 14))
        }.accessibilityLabel("Speed \(desk.speed) times")
      }
      Text(game.notice)
        .font(.system(size: 12, design: .serif).italic())
        .foregroundStyle(Ink.muted)
        .lineLimit(2)
        .frame(height: 32, alignment: .topLeading)
        .accessibilityIdentifier("network-notice")
    }
    .padding(.horizontal, 22)
    .padding(.top, 10)
    .padding(.bottom, 6)
    .background(Ink.paper)
  }

  // MARK: Guide

  private var guide: some View {
    VStack(alignment: .leading, spacing: 20) {
      Eyebrow("THE ART OF GETTING THERE", tone: Ink.routes[0])
      Text("Every shape\nhas a destination.")
        .font(.system(size: 32, design: .serif))
        .tracking(-1)
      HStack(spacing: 14) {
        VStack(spacing: 7) {
          HStack(spacing: 5) {
            StationGlyph(kind: .circle).stroke(Ink.navy, lineWidth: 2.5).frame(
              width: 23, height: 23)
            StationGlyph(kind: .triangle).fill(Ink.navy).frame(width: 8, height: 8)
          }
          Eyebrow("WAITING", size: 7)
        }
        Rectangle().fill(Ink.routes[0]).frame(height: 4).clipShape(Capsule())
        Image(systemName: "tram.fill").foregroundStyle(Ink.routes[0])
        Rectangle().fill(Ink.routes[0]).frame(height: 4).clipShape(Capsule())
        VStack(spacing: 7) {
          StationGlyph(kind: .triangle).stroke(Ink.navy, lineWidth: 2.5).frame(
            width: 25, height: 23)
          Eyebrow("HOME", size: 7)
        }
      }
      .padding(16)
      .background(Ink.paperLight, in: RoundedRectangle(cornerRadius: 14))
      .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Ink.rule, lineWidth: 1))
      guideRow(
        1, title: "Draw a connection",
        detail:
          "Choose a colored line. Tap stations in order, or drag from one station to the next. Trains start automatically."
      )
      guideRow(
        2, title: "Read your passengers",
        detail:
          "Tiny shapes beside stations are waiting passengers. Trains take them to a matching station, transferring between connected lines."
      )
      guideRow(
        3, title: "Give the city room",
        detail:
          "Add new stations to your routes. River crossings use tunnels. At 12 waiting, a red ring fills: relieve it before 24 seconds pass."
      )
      guideRow(
        4, title: "Make it to closing",
        detail:
          "Choose an upgrade every 50 seconds. Deliver as many as possible in five minutes. Pause to plan; Undo or the eraser edits a line."
      )
      Button("Let’s make connections") { desk.showGuide = false }.buttonStyle(PaperButton())
    }
  }

  private func guideRow(_ number: Int, title: String, detail: String) -> some View {
    HStack(alignment: .top, spacing: 14) {
      Roundel(number: number, color: Ink.routes[(number - 1) % 4], size: 24).padding(.top, 1)
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.system(size: 15, weight: .semibold))
        Text(detail).font(.system(size: 12)).foregroundStyle(Ink.muted).fixedSize(
          horizontal: false, vertical: true)
      }
    }
  }

  // MARK: Investment

  private func upgrade(_ game: TransitSimulation) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Eyebrow("INVESTMENT ROUND \(Int(game.elapsed / 50))", tone: Ink.routes[0])
      Text("A little room\nto grow.")
        .font(.system(size: 36, design: .serif)).tracking(-1)
      Text("Choose one improvement. The network is paused.")
        .font(.system(size: 13, design: .serif).italic()).foregroundStyle(Ink.muted)
      ForEach(
        Array(Upgrade.allCases.filter { $0 != .line || game.canAddLine }.enumerated()),
        id: \.element
      ) { index, item in
        Button {
          desk.choose(item)
          showInvestment = false
        } label: {
          HStack(spacing: 16) {
            Image(systemName: item.symbol)
              .font(.system(size: 18, weight: .medium))
              .frame(width: 44, height: 44)
              .foregroundStyle(Ink.paperLight)
              .background(Ink.routes[(index + 1) % 4], in: Circle())
            VStack(alignment: .leading, spacing: 4) {
              Text(item.title).font(.system(size: 16, weight: .semibold))
              Text(item.detail).font(.system(size: 11, design: .monospaced)).foregroundStyle(
                Ink.muted)
            }
            Spacer()
            Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .semibold))
              .foregroundStyle(Ink.muted)
          }
          .padding(14)
          .background(Ink.paperLight, in: RoundedRectangle(cornerRadius: 16))
          .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Ink.rule, lineWidth: 1))
          .shadow(color: Ink.navyDeep.opacity(0.08), radius: 8, y: 4)
        }
      }
      Button("Back to the network") { showInvestment = false }
        .font(.system(size: 12, weight: .medium))
        .frame(maxWidth: .infinity, minHeight: 44)
    }
  }

  // MARK: Results

  private func result(_ game: TransitSimulation, compact: Bool) -> some View {
    VStack(alignment: .leading, spacing: compact ? 12 : 16) {
      ZStack(alignment: .topTrailing) {
        MapDrawing(game: game, selected: 0, decorative: true)
          .frame(height: compact ? 82 : 118)
          .background(Ink.paper)
          .clipShape(RoundedRectangle(cornerRadius: 14))
          .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Ink.rule, lineWidth: 1))
          .accessibilityHidden(true)
        Image(systemName: game.completed ? "sun.horizon.fill" : "exclamationmark.triangle.fill")
          .font(.system(size: 12))
          .foregroundStyle(game.completed ? Ink.gold : Ink.routes[0])
          .padding(7)
          .background(Ink.paperLight, in: Circle())
          .padding(8)
      }
      Eyebrow(game.completed ? "THE LAST TRAIN HOME" : "TIME TO REDRAW", tone: Ink.routes[0])
      Text(game.completed ? "A city in motion." : "Every city is a lesson.")
        .font(.system(size: compact ? 28 : 34, design: .serif)).tracking(-1)
        .lineLimit(2).minimumScaleFactor(0.8)
      Text(
        game.completed
          ? "Five minutes. Countless connections."
          : "Station \(String(format: "%02d", (game.failedStation?.id ?? 0) + 1)) (\(game.failedStation?.kind.name ?? "station")) became overcrowded. Try shorter lines and more connections."
      )
      .font(.system(size: 13, design: .serif).italic()).foregroundStyle(Ink.muted)
      .fixedSize(horizontal: false, vertical: true)
      Line().stroke(Ink.rule, style: StrokeStyle(lineWidth: 1, dash: [3, 3])).frame(height: 1)
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text("\(game.delivered)")
          .font(.system(size: compact ? 54 : 68, design: .serif))
          .tracking(-3)
        VStack(alignment: .leading, spacing: 4) {
          Eyebrow("PASSENGERS\nDELIVERED")
          if game.delivered >= desk.best(game.city), game.delivered > 0 {
            Eyebrow("NEW LOCAL BEST", tone: Ink.gold, size: 7)
          }
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 6) {
          resultStat("LOCAL BEST", value: "\(desk.best(game.city))")
          resultStat("NETWORK", value: "\(game.stations.count) stations · \(elapsed(game.elapsed))")
        }
      }
      Line().stroke(Ink.rule, style: StrokeStyle(lineWidth: 1, dash: [3, 3])).frame(height: 1)
      Button("Draw another journey") { desk.start() }.buttonStyle(PaperButton(tone: .coral))
      HStack {
        Button("Choose city") { desk.home() }
        Spacer()
        Button {
          showNetwork = true
        } label: {
          Label("Admire network", systemImage: "map")
        }
        Spacer()
        if let image = postcard(game) {
          ShareLink(
            item: image.file,
            preview: SharePreview(
              "Transit Atelier · \(game.delivered) delivered", image: image.preview)
          ) {
            Label("Share", systemImage: "square.and.arrow.up")
          }
        }
      }
      .font(.system(size: 12, weight: .medium))
      .frame(minHeight: 44)
    }
  }

  private func postcard(_ game: TransitSimulation) -> (preview: Image, file: JourneyExport)? {
    let renderer = ImageRenderer(content: JourneyPostcard(game: game, best: desk.best(game.city)))
    renderer.scale = 2
    guard let image = renderer.uiImage, let data = image.pngData() else { return nil }
    let name =
      "Transit-Atelier-\(game.city.title.replacingOccurrences(of: " ", with: "-"))-\(game.delivered).png"
    return (Image(uiImage: image), JourneyExport(png: data, filename: name))
  }

  private func resultStat(_ label: String, value: String) -> some View {
    VStack(alignment: .trailing, spacing: 3) {
      Eyebrow(label, size: 7)
      Text(value).font(.system(size: 12, weight: .semibold, design: .monospaced))
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

struct Line: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    return path
  }
}
