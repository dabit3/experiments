import AVFoundation
import SwiftUI

@main
struct BloomguardApp: App {
  var body: some Scene {
    WindowGroup {
      BloomguardView()
        .preferredColorScheme(.light)
    }
  }
}

@MainActor @Observable
final class GardenStore {
  var garden = Garden()
  var screen = "home"
  var selected: Seed = .peashooter
  var shovel = false
  var guide = false
  var unlocked: Int
  var best: Int
  var bestWave: Int
  var medals: [Int]
  var sound: Bool
  var savedResult = false
  private var player: AVAudioPlayer?

  init() {
    let defaults = UserDefaults.standard
    unlocked = max(0, defaults.integer(forKey: "unlocked"))
    best = defaults.integer(forKey: "best")
    bestWave = defaults.integer(forKey: "bestWave")
    medals = defaults.array(forKey: "medals") as? [Int] ?? [0, 0, 0, 0]
    sound = defaults.object(forKey: "sound") as? Bool ?? true
  }

  func start(level: Int = 0, endless: Bool = false) {
    garden = Garden(level: level, endless: endless)
    selected = .peashooter
    shovel = false
    screen = "game"
    savedResult = false
    tone(523)
  }

  func tick() {
    guard screen == "game" else { return }
    garden.tick(1.0 / 30)
    if garden.finished && !savedResult {
      savedResult = true
      if garden.phase == .won {
        unlocked = max(unlocked, min(3, garden.level + 1))
        medals[garden.level] = max(
          medals[garden.level], garden.rescuers.count >= 4 ? 3 : garden.rescuers.count >= 2 ? 2 : 1)
      }
      if garden.endless {
        best = max(best, garden.score)
        bestWave = max(bestWave, garden.wavesCleared)
      }
      let defaults = UserDefaults.standard
      defaults.set(unlocked, forKey: "unlocked")
      defaults.set(medals, forKey: "medals")
      defaults.set(best, forKey: "best")
      defaults.set(bestWave, forKey: "bestWave")
      tone(garden.phase == .won ? 784 : 220)
    }
  }

  func place(lane: Int, column: Int) {
    if shovel {
      garden.remove(lane: lane, column: column)
      tone(294)
      return
    }
    let success = garden.plant(selected, lane: lane, column: column)
    if success { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    tone(success ? 440 : 180)
  }

  func collect(_ id: Int? = nil) {
    guard !garden.drops.isEmpty else { return }
    garden.collect(id)
    tone(880)
  }

  func toggleSound() {
    sound.toggle()
    UserDefaults.standard.set(sound, forKey: "sound")
    if sound { tone(659) }
  }

  func tone(_ frequency: Double) {
    guard sound else { return }
    let rate = 22050
    let count = 2205
    var data = Data()
    func bytes(_ value: UInt32, _ length: Int) {
      for index in 0..<length { data.append(UInt8((value >> (index * 8)) & 255)) }
    }
    data.append(contentsOf: "RIFF".utf8)
    bytes(UInt32(36 + count * 2), 4)
    data.append(contentsOf: "WAVEfmt ".utf8)
    bytes(16, 4)
    bytes(1, 2)
    bytes(1, 2)
    bytes(UInt32(rate), 4)
    bytes(UInt32(rate * 2), 4)
    bytes(2, 2)
    bytes(16, 2)
    data.append(contentsOf: "data".utf8)
    bytes(UInt32(count * 2), 4)
    for index in 0..<count {
      let envelope = sin(Double(index) / Double(count) * .pi) * 0.18
      let sample = Int16(sin(Double(index) * frequency * 2 * .pi / Double(rate)) * envelope * 32767)
      bytes(UInt32(UInt16(bitPattern: sample)), 2)
    }
    player = try? AVAudioPlayer(data: data)
    player?.play()
  }
}

struct BloomguardView: View {
  @State private var store = GardenStore()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        PaperBackground(dark: store.screen == "game")
        if store.screen == "home" {
          home
        } else if store.screen == "chapters" {
          chapters
        } else {
          game
        }
        if store.guide { guide }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: store.screen)
    }
    .fontDesign(.rounded)
    .foregroundStyle(Color.ink)
    .onReceive(timer) { _ in store.tick() }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active && store.garden.phase == .playing && store.screen == "game" {
        store.garden.phase = .paused
      }
    }
  }

  private var home: some View {
    HStack(spacing: 30) {
      VStack(alignment: .leading, spacing: 10) {
        Text("A LITTLE GARDEN. A GRAND DEFENSE.")
          .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2)
          .foregroundStyle(Color.moss)
        Text("Bloomguard").font(.system(size: 49, weight: .bold, design: .serif)).tracking(-2)
          .minimumScaleFactor(0.6).lineLimit(1)
        Text("Grow a little courage.")
          .font(.system(size: 19, weight: .regular, design: .serif)).italic()
        Text("Gather sunshine. Plant your guardians.\nKeep the clockworks out of your cottage.")
          .font(.system(size: 12)).foregroundStyle(Color.ink.opacity(0.7)).lineSpacing(4)
          .padding(.vertical, 6)
        HStack(spacing: 10) {
          action("Enter the garden", icon: "arrow.right") { store.screen = "chapters" }
          circleButton("How to play", icon: "questionmark") { store.guide = true }
        }
        HStack(spacing: 14) {
          Button {
            store.start(endless: true)
          } label: {
            Label("Endless garden", systemImage: "infinity").font(.system(size: 12, weight: .bold))
          }.accessibilityIdentifier("endless")
          Text("BEST \(store.best.formatted())").font(.system(size: 10, design: .monospaced))
            .foregroundStyle(Color.moss)
        }.padding(.top, 5)
      }.frame(maxWidth: .infinity, alignment: .leading)
      VStack(spacing: 0) {
        HStack {
          Text("EST. THIS MORNING").font(.system(size: 9, weight: .semibold, design: .monospaced))
            .tracking(2)
          Spacer()
          circleButton("Toggle sound", icon: store.sound ? "speaker.wave.2" : "speaker.slash") {
            store.toggleSound()
          }
        }
        ZStack(alignment: .bottom) {
          Circle().fill(Color.gold.opacity(0.13)).frame(width: 235, height: 235)
          Cottage().frame(height: 195).offset(y: -33)
          HStack(spacing: -15) {
            GardenArt(seed: .marigold).frame(width: 110, height: 110).rotationEffect(.degrees(-9))
            GardenArt(seed: .peashooter).frame(width: 125, height: 125)
            GardenArt(seed: .bramble).frame(width: 95, height: 95).rotationEffect(.degrees(8))
          }.offset(y: 8)
        }.frame(height: 232)
        Text("FIVE GUARDIANS · ONE PRECIOUS PATCH")
          .font(.system(size: 8, weight: .semibold, design: .monospaced)).tracking(1.6).padding(
            .top, 14)
      }.frame(maxWidth: .infinity)
    }.padding(.horizontal, 23).padding(.vertical, 18)
  }

  private var chapters: some View {
    VStack(alignment: .leading, spacing: 15) {
      HStack {
        circleButton("Back", icon: "arrow.left") { store.screen = "home" }
        VStack(alignment: .leading, spacing: 2) {
          Text("The garden journal").font(.system(size: 29, weight: .semibold, design: .serif))
          Text("Four small chapters. A growing adventure.").font(.system(size: 11)).foregroundStyle(
            Color.moss)
        }
        Spacer()
        Button {
          store.start(endless: true)
        } label: {
          Label("Endless", systemImage: "infinity").font(.system(size: 12, weight: .bold))
        }
      }
      HStack(spacing: 12) {
        ForEach(0..<4) { index in
          Button {
            if index <= store.unlocked { store.start(level: index) }
          } label: {
            VStack(alignment: .leading, spacing: 6) {
              HStack {
                Text("0\(index + 1)").font(.system(size: 12, weight: .bold, design: .monospaced))
                Spacer()
                Image(systemName: index <= store.unlocked ? "arrow.up.right" : "lock.fill")
              }.foregroundStyle(Color.moss)
              GardenArt(seed: Seed.allCases[index]).frame(height: 78).frame(maxWidth: .infinity)
              Text(Chapter.all[index].subtitle).font(
                .system(size: 8, weight: .bold, design: .monospaced)
              ).tracking(1)
              Text(Chapter.all[index].title).font(
                .system(size: 17, weight: .semibold, design: .serif)
              ).lineLimit(1).minimumScaleFactor(0.7)
              Text(
                index > store.unlocked
                  ? "Clear chapter \(index) to unlock" : Chapter.all[index].lesson
              )
              .font(.system(size: 10)).lineSpacing(2).frame(height: 32, alignment: .topLeading)
              HStack(spacing: 4) {
                ForEach(0..<3) { star in
                  Image(systemName: star < store.medals[index] ? "star.fill" : "star")
                    .foregroundStyle(Color.moss)
                }
                Spacer()
                Text(index <= store.unlocked ? "PLAY" : "LOCKED").font(
                  .system(size: 8, weight: .bold, design: .monospaced))
              }.font(.system(size: 10)).padding(.top, 4)
            }.padding(14).background(
              .white.opacity(index <= store.unlocked ? 0.63 : 0.23),
              in: RoundedRectangle(cornerRadius: 17)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 17).stroke(Color.moss.opacity(0.2), lineWidth: 1))
          }.buttonStyle(.plain).disabled(index > store.unlocked)
        }
      }
      Text("Keep 4 robins for 3 stars · 2 robins for 2 stars · every victory earns a star")
        .font(.system(size: 10)).foregroundStyle(Color.moss)
    }.padding(22)
  }

  private var game: some View {
    ZStack {
      VStack(spacing: 5) {
        HStack(spacing: 12) {
          Button {
            store.collect()
          } label: {
            HStack(spacing: 7) {
              Image(systemName: "sun.max.fill").foregroundStyle(Color.gold)
              Text("\(store.garden.sunshine)").font(
                .system(size: 21, weight: .bold, design: .serif)
              ).monospacedDigit()
              VStack(alignment: .leading, spacing: 0) {
                Text("SUNSHINE").font(.system(size: 7, weight: .bold)).tracking(1)
                Text(store.garden.drops.isEmpty ? "tap gold drops" : "TAP TO GATHER").font(
                  .system(size: 7, weight: .bold)
                ).foregroundStyle(Color.gold)
              }
            }.padding(.horizontal, 10).frame(height: 38)
              .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 11))
          }.accessibilityLabel("Gather sunshine, \(store.garden.sunshine) available")
            .accessibilityIdentifier("collect")
          VStack(alignment: .leading, spacing: 1) {
            Text(store.garden.title).font(.system(size: 16, weight: .semibold, design: .serif))
            Text(store.garden.waveLabel + "  ·  \(store.garden.score) PTS")
              .font(.system(size: 8, weight: .semibold, design: .monospaced)).tracking(1)
              .foregroundStyle(Color.cream.opacity(0.65))
          }
          Spacer(minLength: 0)
          Text(
            store.garden.nextWave > 0
              ? "A breath between waves"
              : store.garden.pests.isEmpty && store.garden.waveTime < 17
                ? "Plant your first guardians" : "\(store.garden.pests.count) CLOCKWORKS"
          )
          .font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundStyle(
            Color.cream.opacity(0.7)
          )
          .lineLimit(1).minimumScaleFactor(0.7)
          circleButton("Pause", icon: "pause.fill", light: true) { store.garden.togglePause() }
            .accessibilityIdentifier("pause")
        }.foregroundStyle(Color.cream)
        GardenBoard(store: store)
        HStack(spacing: 6) {
          ForEach(Seed.allCases, id: \.self) { seed in seedPacket(seed) }
          Button {
            store.shovel.toggle()
          } label: {
            VStack(spacing: 3) {
              Image(systemName: "trowel.fill").font(.system(size: 22))
              Text("SHOVEL").font(.system(size: 7, weight: .bold, design: .monospaced))
              Text("½ refund").font(.system(size: 7))
            }.frame(width: 57, height: 60).background(
              store.shovel ? Color.gold : Color.cream.opacity(0.1),
              in: RoundedRectangle(cornerRadius: 10)
            )
            .foregroundStyle(store.shovel ? Color.ink : Color.cream)
          }.accessibilityIdentifier("shovel")
        }
        HStack {
          Text(
            store.garden.noticeTime > 0
              ? store.garden.notice
              : store.shovel
                ? "Tap a guardian to compost it for half its cost."
                : "\(store.selected.name) · \(store.selected.detail). Tap an empty plot."
          )
          .lineLimit(1).minimumScaleFactor(0.7)
          Spacer(minLength: 0)
          Text("← COTTAGE     PESTS ←").tracking(1).foregroundStyle(Color.cream.opacity(0.45))
        }.font(.system(size: 9)).foregroundStyle(Color.cream.opacity(0.85)).frame(height: 13)
      }.padding(.horizontal, 5).padding(.vertical, 5)
      if store.garden.phase == .paused { pause }
      if store.garden.finished { results }
    }
  }

  private func seedPacket(_ seed: Seed) -> some View {
    let selected = store.selected == seed && !store.shovel
    let cooldown = store.garden.cooldowns[seed] ?? 0
    return Button {
      store.selected = seed
      store.shovel = false
      if store.garden.sunshine < seed.cost {
        store.garden.notify(
          "Need \(seed.cost - store.garden.sunshine) more sunshine for \(seed.name).")
      } else if cooldown > 0 {
        store.garden.notify("\(seed.name) is resting for \(Int(ceil(cooldown)))s.")
      } else {
        store.garden.notify("\(seed.name) · \(seed.detail). Choose an empty plot.")
      }
    } label: {
      HStack(spacing: 1) {
        GardenArt(seed: seed).frame(width: 44, height: 47)
        VStack(alignment: .leading, spacing: 3) {
          Text(seed.name).font(.system(size: 11, weight: .bold, design: .serif)).lineLimit(1)
            .minimumScaleFactor(0.75)
          Label("\(seed.cost)", systemImage: "sun.max.fill").font(.system(size: 10, weight: .bold))
          Text(
            cooldown > 0
              ? "\(Int(ceil(cooldown)))s rest"
              : store.garden.sunshine < seed.cost ? "Need sun" : "READY"
          )
          .font(.system(size: 7, weight: .semibold, design: .monospaced))
          .foregroundStyle(
            cooldown > 0 || store.garden.sunshine < seed.cost
              ? Color(red: 0.63, green: 0.24, blue: 0.16) : Color.moss)
        }
        Spacer(minLength: 0)
      }.padding(.horizontal, 4).frame(maxWidth: .infinity).frame(height: 60)
        .background(
          selected ? Color.cream : Color.cream.opacity(0.85), in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 10).stroke(
            selected ? Color.gold : Color.clear, lineWidth: 3)
        )
        .foregroundStyle(Color.ink)
    }.buttonStyle(.plain).accessibilityLabel("\(seed.name), \(seed.cost) sunshine, \(seed.detail)")
      .accessibilityIdentifier("seed-\(seed.rawValue)")
  }

  private var pause: some View {
    modal {
      Text("A moment of stillness").font(.system(size: 31, weight: .semibold, design: .serif))
      Text("Your garden will wait for you.").font(.system(size: 13)).foregroundStyle(Color.moss)
      HStack {
        action("Keep growing", icon: "play.fill") { store.garden.togglePause() }
        action("Field guide", icon: "book", secondary: true) { store.guide = true }
      }.padding(.top, 12)
      HStack(spacing: 26) {
        Button {
          store.toggleSound()
        } label: {
          Label(
            store.sound ? "Sound on" : "Sound off",
            systemImage: store.sound ? "speaker.wave.2" : "speaker.slash")
        }
        Button("Leave garden") { store.screen = "home" }
      }.font(.system(size: 12, weight: .semibold)).padding(.top, 10)
      Text("Leaving ends this attempt. Your completed chapters stay saved.")
        .font(.system(size: 9)).foregroundStyle(Color.moss)
    }
  }

  private var results: some View {
    let won = store.garden.phase == .won
    return modal {
      HStack(spacing: 14) {
        GardenArt(seed: won ? .marigold : .bramble).frame(width: 79, height: 79)
        VStack(alignment: .leading, spacing: 4) {
          Text(won ? "THE GARDEN IS YOURS" : "EVERY GARDENER GROWS")
            .font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(2).foregroundStyle(
              Color.moss)
          Text(won ? "Beautifully defended." : "A little overgrown.")
            .font(.system(size: 31, weight: .semibold, design: .serif))
          Text(
            won
              ? "The cottage is safe. Another morning awaits."
              : "Try Sunbells early, then cover all five lanes."
          )
          .font(.system(size: 12)).foregroundStyle(Color.moss)
        }
      }
      HStack(spacing: 40) {
        resultStat("\(store.garden.score)", "GARDEN POINTS")
        resultStat("\(store.garden.wavesCleared)", "WAVES SECURED")
        resultStat(
          store.garden.endless ? "\(store.best)" : "\(store.garden.rescuers.count) / 5",
          store.garden.endless ? "PERSONAL BEST" : "ROBINS KEPT")
      }.padding(.vertical, 10)
      HStack {
        action(won && store.garden.level < 3 ? "Next chapter" : "Grow again", icon: "arrow.right") {
          store.start(
            level: won && store.garden.level < 3 ? store.garden.level + 1 : store.garden.level,
            endless: store.garden.endless)
        }
        action("Garden journal", icon: "book", secondary: true) { store.screen = "chapters" }
      }
    }
  }

  private func resultStat(_ value: String, _ label: String) -> some View {
    VStack(spacing: 3) {
      Text(value).font(.system(size: 27, weight: .bold, design: .serif))
      Text(label).font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(1)
        .foregroundStyle(Color.moss)
    }
  }

  private var guide: some View {
    ZStack {
      Color.ink.opacity(0.8).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text("The little field guide").font(
              .system(size: 28, weight: .semibold, design: .serif))
            Text("Five lanes. Seven plots. A home worth protecting.").font(.system(size: 11))
              .foregroundStyle(Color.moss)
          }
          Spacer()
          circleButton("Close guide", icon: "xmark") { store.guide = false }
        }
        HStack(spacing: 10) {
          ForEach(Seed.allCases, id: \.self) { seed in
            VStack(spacing: 4) {
              GardenArt(seed: seed).frame(height: 58)
              Text(seed.name).font(.system(size: 13, weight: .bold, design: .serif))
              Text(seed.detail).font(.system(size: 9)).multilineTextAlignment(.center)
            }.frame(maxWidth: .infinity).frame(height: 109).background(
              Color.moss.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
          }
        }
        Text(
          "1  Gather gold drops — or tap the sunshine counter to gather all.\n2  Pick a seed packet, then tap a plot. Defenders fire to the right.\n3  Keep every lane covered. Shovel returns half a plant’s cost."
        )
        .font(.system(size: 11, weight: .medium)).lineSpacing(5)
        Text(
          "Each lane has one last-chance robin. A second breach ends the run.\nEmberbuds burst in 1.5s across nearby plots and adjacent lanes. Frost slows armor."
        )
        .font(.system(size: 10)).foregroundStyle(Color.moss).lineSpacing(3)
      }.padding(20).frame(maxWidth: 650).background(
        Color.cream, in: RoundedRectangle(cornerRadius: 24)
      ).padding(15)
    }
  }

  private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Color.ink.opacity(0.78).ignoresSafeArea()
      VStack(spacing: 10, content: content).padding(25)
        .background { PaperBackground() }
        .clipShape(RoundedRectangle(cornerRadius: 25)).padding(20)
    }
  }

  private func action(
    _ text: String, icon: String, secondary: Bool = false, perform: @escaping () -> Void
  ) -> some View {
    Button(action: perform) {
      HStack(spacing: 14) {
        Text(text)
        Image(systemName: icon)
      }.font(.system(size: 13, weight: .semibold))
        .padding(.horizontal, 18).frame(height: 45)
        .background(secondary ? Color.moss.opacity(0.12) : Color.ink, in: Capsule())
        .foregroundStyle(secondary ? Color.ink : Color.cream)
    }.buttonStyle(.plain)
  }

  private func circleButton(
    _ label: String, icon: String, light: Bool = false, perform: @escaping () -> Void
  ) -> some View {
    Button(action: perform) {
      Image(systemName: icon).font(.system(size: 14, weight: .medium)).frame(width: 42, height: 42)
        .background((light ? Color.cream : Color.moss).opacity(0.12), in: Circle())
        .foregroundStyle(light ? Color.cream : Color.ink)
    }.buttonStyle(.plain).accessibilityLabel(label)
  }
}
