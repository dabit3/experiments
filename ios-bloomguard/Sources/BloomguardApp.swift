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
  struct Plot: Equatable {
    let lane: Int
    let column: Int
  }
  var garden = Garden()
  var screen = "home"
  var selected: Seed = .peashooter
  var shovel = false
  var emberTarget: Plot?
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
    emberTarget = nil
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
    if selected == .ember {
      if let reason = garden.unavailable(.ember, lane: lane, column: column) {
        garden.notify(reason, error: true)
        tone(180)
        return
      }
      let target = Plot(lane: lane, column: column)
      if emberTarget != target {
        emberTarget = target
        garden.notify("Blast preview · tap this plot again to plant, or choose another.")
        tone(330)
        return
      }
    }
    let success = garden.plant(selected, lane: lane, column: column)
    if success { emberTarget = nil }
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
        if store.screen == "game" {
          PaperBackground(dark: true)
          game
        } else {
          TimelineView(.animation(paused: reduceMotion)) { timeline in
            DawnScene(phase: reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate)
          }.ignoresSafeArea()
          if store.screen == "home" { home } else { chapters }
        }
        if store.guide { guide }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: store.screen)
    }
    .foregroundStyle(Color.ink)
    .onReceive(timer) { _ in store.tick() }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active && store.garden.phase == .playing && store.screen == "game" {
        store.garden.phase = .paused
      }
    }
  }

  private var home: some View {
    HStack(spacing: 18) {
      VStack(alignment: .leading, spacing: 8) {
        Text("A LITTLE GARDEN · A GRAND DEFENSE")
          .font(.system(size: 9, weight: .semibold, design: .serif)).tracking(2.4)
          .foregroundStyle(Color.goldDeep)
        Text("Bloomguard").font(.system(size: 54, weight: .bold, design: .serif)).tracking(-2.5)
          .minimumScaleFactor(0.6).lineLimit(1)
          .shadow(color: .cream.opacity(0.8), radius: 0, x: 0, y: 1)
        Flourish().frame(width: 170, height: 17)
        Text("Grow a little courage.")
          .font(.system(size: 18, weight: .regular, design: .serif)).italic()
          .foregroundStyle(Color.pine)
        Text(
          "Gather sunshine, plant your guardians and keep\nthe clockwork pests out of your cottage."
        )
        .font(.system(size: 11.5)).foregroundStyle(Color.ink.opacity(0.72)).lineSpacing(3)
        HStack(spacing: 10) {
          action("Enter the garden", icon: "arrow.right", gold: true) { store.screen = "chapters" }
          circleButton("How to play", icon: "questionmark") { store.guide = true }
        }.padding(.top, 6)
        Button {
          store.start(endless: true)
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "infinity").font(.system(size: 12, weight: .bold))
            Text("Endless garden").font(.system(size: 12, weight: .semibold))
            Text("BEST \(store.best.formatted())")
              .font(.system(size: 9, weight: .bold, design: .serif)).tracking(1)
              .padding(.horizontal, 7).padding(.vertical, 3)
              .background(Color.gold.opacity(0.35), in: Capsule())
          }.padding(.horizontal, 14).frame(height: 34)
            .background(Color.cream.opacity(0.55), in: Capsule())
            .overlay(Capsule().stroke(Color.ink.opacity(0.25), lineWidth: 1))
        }.buttonStyle(.plain).accessibilityIdentifier("endless")
      }
      .padding(22)
      .background(
        LinearGradient(
          colors: [.cream.opacity(0.92), .parchment.opacity(0.88)], startPoint: .top,
          endPoint: .bottom),
        in: RoundedRectangle(cornerRadius: 26)
      )
      .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.cream, lineWidth: 1.5))
      .overlay(
        RoundedRectangle(cornerRadius: 22).stroke(Color.goldDeep.opacity(0.35), lineWidth: 1)
          .padding(5)
      )
      .shadow(color: .ink.opacity(0.22), radius: 18, y: 8)
      .frame(maxWidth: 360)
      ZStack(alignment: .topTrailing) {
        VStack(spacing: 0) {
          ZStack(alignment: .bottom) {
            Cottage().frame(height: 200).offset(y: -40)
            HStack(spacing: -12) {
              GardenArt(seed: .marigold).frame(width: 104, height: 104).rotationEffect(.degrees(-8))
              GardenArt(seed: .peashooter).frame(width: 122, height: 122)
              GardenArt(seed: .frost).frame(width: 96, height: 96).rotationEffect(.degrees(6))
              GardenArt(seed: .bramble).frame(width: 90, height: 90).rotationEffect(.degrees(10))
                .offset(y: -6)
            }.offset(y: 14)
          }.frame(height: 250)
          Text("FIVE GUARDIANS · ONE PRECIOUS PATCH")
            .font(.system(size: 8, weight: .semibold, design: .serif)).tracking(2)
            .foregroundStyle(Color.ink.opacity(0.7)).padding(.top, 16)
        }.frame(maxWidth: .infinity)
        circleButton("Toggle sound", icon: store.sound ? "speaker.wave.2" : "speaker.slash") {
          store.toggleSound()
        }
      }
    }.padding(.horizontal, 22).padding(.vertical, 16)
  }

  private var chapters: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        circleButton("Back", icon: "arrow.left") { store.screen = "home" }
        VStack(alignment: .leading, spacing: 1) {
          Text("The garden journal").font(.system(size: 27, weight: .semibold, design: .serif))
          Text("FOUR SMALL CHAPTERS · A GROWING ADVENTURE")
            .font(.system(size: 8, weight: .semibold, design: .serif)).tracking(1.8)
            .foregroundStyle(Color.goldDeep)
        }
        Spacer()
        Button {
          store.start(endless: true)
        } label: {
          Label("Endless garden", systemImage: "infinity").font(
            .system(size: 12, weight: .semibold)
          )
          .padding(.horizontal, 14).frame(height: 36)
          .background(Color.cream.opacity(0.7), in: Capsule())
          .overlay(Capsule().stroke(Color.ink.opacity(0.25), lineWidth: 1))
        }.buttonStyle(.plain)
      }
      HStack(spacing: 12) {
        ForEach(0..<4) { index in chapterCard(index) }
      }
      HStack(spacing: 6) {
        Image(systemName: "bird.fill").font(.system(size: 10))
        Text("Keep 4 robins for three stars · 2 robins for two · every victory earns one")
          .font(.system(size: 10, weight: .medium))
      }.foregroundStyle(Color.ink.opacity(0.8))
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color.cream.opacity(0.7), in: Capsule())
    }.padding(.horizontal, 22).padding(.vertical, 16)
  }

  private func chapterCard(_ index: Int) -> some View {
    let open = index <= store.unlocked
    let bands: [[Color]] = [
      [Color(red: 0.99, green: 0.84, blue: 0.62), Color(red: 0.96, green: 0.70, blue: 0.45)],
      [Color(red: 0.90, green: 0.62, blue: 0.42), Color(red: 0.70, green: 0.42, blue: 0.26)],
      [Color(red: 0.72, green: 0.87, blue: 0.90), Color(red: 0.42, green: 0.66, blue: 0.75)],
      [Color(red: 0.42, green: 0.45, blue: 0.68), Color(red: 0.20, green: 0.24, blue: 0.42)],
    ]
    return Button {
      if open { store.start(level: index) }
    } label: {
      VStack(alignment: .leading, spacing: 0) {
        ZStack(alignment: .topLeading) {
          LinearGradient(colors: bands[index], startPoint: .top, endPoint: .bottom)
          if index == 3 {
            Circle().fill(Color.cream.opacity(0.85)).frame(width: 22, height: 22)
              .position(x: 120, y: 18)
          }
          GardenArt(seed: Seed.allCases[index]).frame(height: 84).frame(maxWidth: .infinity)
            .offset(y: 8).saturation(open ? 1 : 0.2)
          Text("0\(index + 1)").font(.system(size: 10, weight: .bold, design: .serif))
            .frame(width: 24, height: 24)
            .background(Color.cream, in: Circle())
            .overlay(Circle().stroke(Color.goldDeep, lineWidth: 1.2))
            .padding(8)
          if !open {
            Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(Color.cream)
              .padding(8).frame(maxWidth: .infinity, alignment: .trailing)
          }
        }.frame(height: 92).clipped()
        VStack(alignment: .leading, spacing: 4) {
          Text(Chapter.all[index].subtitle)
            .font(.system(size: 7.5, weight: .bold, design: .serif)).tracking(1.6)
            .foregroundStyle(Color.goldDeep)
          Text(Chapter.all[index].title).font(.system(size: 16, weight: .semibold, design: .serif))
            .lineLimit(1).minimumScaleFactor(0.7)
          Text(open ? Chapter.all[index].lesson : "Clear chapter \(index) to unlock")
            .font(.system(size: 9.5)).lineSpacing(2).fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 28, alignment: .topLeading).foregroundStyle(Color.ink.opacity(0.75))
          HStack(spacing: 3) {
            ForEach(0..<3) { star in
              Image(systemName: star < store.medals[index] ? "star.fill" : "star")
                .foregroundStyle(
                  star < store.medals[index] ? Color.goldDeep : Color.ink.opacity(0.3))
            }
            Spacer()
            Text(open ? "PLAY" : "LOCKED").font(.system(size: 8, weight: .bold, design: .serif))
              .tracking(1.2)
              .padding(.horizontal, 8).padding(.vertical, 3)
              .background(open ? Color.gold : Color.ink.opacity(0.1), in: Capsule())
          }.font(.system(size: 10)).padding(.top, 2)
        }.padding(12)
      }
      .background(Color.cream.opacity(open ? 0.96 : 0.7), in: RoundedRectangle(cornerRadius: 18))
      .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cream, lineWidth: 1.5))
      .shadow(color: .ink.opacity(open ? 0.22 : 0.08), radius: 10, y: 5)
    }.buttonStyle(.plain).disabled(!open)
  }

  private var game: some View {
    ZStack {
      VStack(spacing: 5) {
        HStack(spacing: 10) {
          Button {
            store.collect()
          } label: {
            HStack(spacing: 8) {
              SunCoin().frame(width: 28, height: 28)
                .shadow(color: .gold.opacity(store.garden.drops.isEmpty ? 0 : 0.8), radius: 6)
              Text("\(store.garden.sunshine)").font(
                .system(size: 22, weight: .bold, design: .serif)
              ).monospacedDigit().foregroundStyle(Color.cream)
              VStack(alignment: .leading, spacing: 1) {
                Text(store.garden.endless ? "SUNSHINE / 500" : "SUNSHINE")
                  .font(.system(size: 7, weight: .bold, design: .serif)).tracking(1.2)
                  .foregroundStyle(Color.cream.opacity(0.75))
                Text(store.garden.drops.isEmpty ? "tap gold drops" : "TAP TO GATHER").font(
                  .system(size: 7, weight: .bold, design: .serif)
                ).tracking(0.6).foregroundStyle(Color.gold)
              }
            }.padding(.horizontal, 10).frame(height: 40)
              .background(Color.black.opacity(0.22), in: Capsule())
              .overlay(Capsule().stroke(Color.cream.opacity(0.18), lineWidth: 1))
          }.buttonStyle(.plain)
            .accessibilityLabel("Gather sunshine, \(store.garden.sunshine) available")
            .accessibilityIdentifier("collect")
          VStack(alignment: .leading, spacing: 2) {
            Text(store.garden.title).font(.system(size: 16, weight: .semibold, design: .serif))
              .foregroundStyle(Color.cream)
            HStack(spacing: 6) {
              if store.garden.endless {
                Text("WAVE \(store.garden.wave)")
              } else {
                ForEach(0..<3) { wave in
                  Image(systemName: "leaf.fill").font(.system(size: 8))
                    .foregroundStyle(
                      wave < store.garden.wave ? Color.gold : Color.cream.opacity(0.3))
                }
                Text("WAVE \(store.garden.wave) OF 3")
              }
              Text("·").foregroundStyle(Color.cream.opacity(0.5))
              Text("\(store.garden.score.formatted()) PTS")
            }
            .font(.system(size: 9, weight: .bold, design: .serif)).tracking(1)
            .foregroundStyle(Color.cream.opacity(0.8))
          }
          Spacer(minLength: 0)
          Text(
            store.garden.nextWave > 0
              ? "A breath between waves"
              : store.garden.wave == 1 && store.garden.pests.isEmpty && store.garden.waveTime < 17
                ? "Plant your first guardians"
                : store.garden.endless && store.garden.wave >= 4 && !store.garden.schedule.isEmpty
                  ? "NEXT: LANE \((store.garden.schedule.first?.lane ?? 0) + 1)"
                  : "\(store.garden.pests.count) CLOCKWORKS"
          )
          .font(.system(size: 9, weight: .bold, design: .serif)).tracking(1)
          .foregroundStyle(Color.cream.opacity(0.85))
          .lineLimit(1).minimumScaleFactor(0.7)
          .padding(.horizontal, 12).frame(height: 28)
          .background(Color.black.opacity(0.22), in: Capsule())
          circleButton("Pause", icon: "pause.fill", light: true) { store.garden.togglePause() }
            .accessibilityIdentifier("pause")
        }
        GardenBoard(store: store)
        HStack(spacing: 6) {
          ForEach(Seed.allCases, id: \.self) { seed in seedPacket(seed) }
          Button {
            store.shovel.toggle()
            store.emberTarget = nil
          } label: {
            VStack(spacing: 2) {
              ShovelArt().frame(width: 26, height: 26)
              Text("SHOVEL").font(.system(size: 7.5, weight: .bold, design: .serif)).tracking(1)
              Text("½ refund").font(.system(size: 8.5))
            }.frame(width: 58, height: 62)
              .background(
                LinearGradient(
                  colors: store.shovel
                    ? [.gold, .goldDeep] : [.cream.opacity(0.16), .cream.opacity(0.08)],
                  startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 12)
              )
              .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(
                  store.shovel ? Color.cream : Color.cream.opacity(0.25), lineWidth: 1.5)
              )
              .foregroundStyle(store.shovel ? Color.ink : Color.cream)
          }.buttonStyle(.plain).accessibilityIdentifier("shovel")
        }
        HStack {
          if store.garden.noticeTime > 0 && store.garden.noticeIsError {
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Color.gold)
          }
          Text(
            store.garden.noticeTime > 0
              ? store.garden.notice
              : store.shovel
                ? "Tap a guardian to compost it for half its cost."
                : store.selected == .ember
                  ? "Emberbud · tap to preview its reach, then tap again to plant."
                  : "\(store.selected.name) · \(store.selected.detail). Tap an empty plot."
          )
          .lineLimit(1).minimumScaleFactor(0.7)
          Spacer(minLength: 0)
          Text("DEFEND YOUR COTTAGE").font(.system(size: 8, weight: .semibold, design: .serif))
            .tracking(1.5).foregroundStyle(Color.cream.opacity(0.5))
        }.font(.system(size: 11)).foregroundStyle(Color.cream).frame(height: 16)
      }.padding(.horizontal, 6).padding(.vertical, 5)
      if store.garden.phase == .paused { pause }
      if store.garden.finished { results }
    }
  }

  private func seedPacket(_ seed: Seed) -> some View {
    let selected = store.selected == seed && !store.shovel
    let cooldown = store.garden.cooldowns[seed] ?? 0
    let poor = store.garden.sunshine < seed.cost
    return Button {
      store.selected = seed
      store.shovel = false
      store.emberTarget = nil
      if store.garden.sunshine < seed.cost {
        store.garden.notify(
          "Need \(seed.cost - store.garden.sunshine) more sunshine for \(seed.name).", error: true)
      } else if cooldown > 0 {
        store.garden.notify("\(seed.name) is resting for \(Int(ceil(cooldown)))s.", error: true)
      } else {
        store.garden.notify(
          seed == .ember
            ? "Emberbud · tap to preview its reach, then tap again to plant."
            : "\(seed.name) · \(seed.detail). Choose an empty plot.")
      }
    } label: {
      HStack(spacing: 2) {
        ZStack {
          RoundedRectangle(cornerRadius: 8).fill(
            LinearGradient(
              colors: [seed.tint.opacity(0.75), seed.tint.opacity(0.35)], startPoint: .top,
              endPoint: .bottom)
          ).frame(width: 46, height: 52)
          GardenArt(seed: seed).frame(width: 46, height: 48).offset(y: 2)
        }
        VStack(alignment: .leading, spacing: 2) {
          Text(seed.name).font(.system(size: 11, weight: .bold, design: .serif)).lineLimit(1)
            .minimumScaleFactor(0.75)
          HStack(spacing: 3) {
            SunCoin().frame(width: 10, height: 10)
            Text("\(seed.cost)").font(.system(size: 10, weight: .bold, design: .serif))
          }
          Text(
            cooldown > 0
              ? "\(Int(ceil(cooldown)))s rest"
              : poor ? "Need sun" : "READY"
          )
          .font(.system(size: 7, weight: .bold, design: .serif)).tracking(0.8)
          .foregroundStyle(
            cooldown > 0 || poor ? Color(red: 0.63, green: 0.24, blue: 0.16) : Color.moss)
        }
        Spacer(minLength: 0)
      }.padding(.horizontal, 4).frame(maxWidth: .infinity).frame(height: 62)
        .background(
          LinearGradient(colors: [.cream, .parchment], startPoint: .top, endPoint: .bottom),
          in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(alignment: .bottom) {
          if cooldown > 0 {
            RoundedRectangle(cornerRadius: 12).fill(Color.ink.opacity(0.18))
              .frame(height: 62 * min(1, cooldown / seed.cooldown))
          }
        }
        .overlay(
          RoundedRectangle(cornerRadius: 12).stroke(
            selected ? Color.gold : Color.cream.opacity(0.3), lineWidth: selected ? 3 : 1)
        )
        .opacity(poor && !selected ? 0.72 : 1)
        .scaleEffect(selected ? 1.03 : 1)
        .shadow(
          color: selected ? .gold.opacity(0.45) : .black.opacity(0.2), radius: selected ? 8 : 3,
          y: 2
        )
        .foregroundStyle(Color.ink)
    }.buttonStyle(.plain).accessibilityLabel("\(seed.name), \(seed.cost) sunshine, \(seed.detail)")
      .accessibilityIdentifier("seed-\(seed.rawValue)")
  }

  private var pause: some View {
    modal {
      Text("A MOMENT OF STILLNESS").font(.system(size: 9, weight: .bold, design: .serif)).tracking(
        2.4
      )
      .foregroundStyle(Color.goldDeep)
      Text("Your garden will wait.").font(.system(size: 30, weight: .semibold, design: .serif))
      Flourish().frame(width: 160, height: 16)
      HStack {
        action("Keep growing", icon: "play.fill", gold: true) { store.garden.togglePause() }
        action("Field guide", icon: "book", secondary: true) { store.guide = true }
      }.padding(.top, 8)
      HStack(spacing: 26) {
        Button {
          store.toggleSound()
        } label: {
          Label(
            store.sound ? "Sound on" : "Sound off",
            systemImage: store.sound ? "speaker.wave.2" : "speaker.slash")
        }
        if store.garden.endless {
          Button("Finish & save record") {
            store.garden.retire()
            store.tick()
          }
        } else {
          Button("Leave garden") { store.screen = "home" }
        }
      }.font(.system(size: 12, weight: .semibold)).padding(.top, 8)
      Text(
        store.garden.endless
          ? "Finish saves the points and waves you have earned."
          : "Leaving ends this attempt. Your completed chapters stay saved."
      )
      .font(.system(size: 9)).foregroundStyle(Color.moss)
    }
  }

  private var results: some View {
    let won = store.garden.phase == .won
    let retired = store.garden.phase == .retired
    return modal {
      HStack(spacing: 16) {
        ZStack {
          Circle().fill(
            RadialGradient(
              colors: [.gold.opacity(won || retired ? 0.5 : 0.15), .clear], center: .center,
              startRadius: 10, endRadius: 50)
          ).frame(width: 100, height: 100)
          GardenArt(seed: won || retired ? .marigold : .bramble).frame(width: 82, height: 82)
        }
        VStack(alignment: .leading, spacing: 4) {
          Text(
            won ? "THE GARDEN IS YOURS" : retired ? "YOUR RECORD IS SAVED" : "EVERY GARDENER GROWS"
          )
          .font(.system(size: 9, weight: .bold, design: .serif)).tracking(2.4).foregroundStyle(
            Color.goldDeep)
          Text(
            won ? "Beautifully defended." : retired ? "A well-earned rest." : "A little overgrown."
          )
          .font(.system(size: 30, weight: .semibold, design: .serif))
          Text(
            won
              ? "The cottage is safe. Another morning awaits."
              : retired
                ? "Every wave earned. Come back and grow a little further."
                : "Try Sunbells early, then cover all five lanes."
          )
          .font(.system(size: 12)).foregroundStyle(Color.moss)
        }
      }
      if won {
        HStack(spacing: 6) {
          ForEach(0..<3) { index in
            Image(systemName: index < store.medals[store.garden.level] ? "star.fill" : "star")
              .foregroundStyle(Color.goldDeep)
              .shadow(
                color: .gold.opacity(index < store.medals[store.garden.level] ? 0.8 : 0), radius: 4)
          }
          Text(
            store.garden.level < 3
              ? "\(Chapter.all[store.garden.level + 1].title) unlocked"
              : "All four chapters defended"
          )
          .font(.system(size: 11, weight: .semibold)).padding(.leading, 8)
        }.font(.system(size: 16))
      }
      Flourish().frame(width: 200, height: 16)
      HStack(spacing: 40) {
        resultStat(store.garden.score.formatted(), "GARDEN POINTS")
        resultStat("\(store.garden.wavesCleared)", "WAVES SECURED")
        resultStat(
          store.garden.endless ? store.best.formatted() : "\(store.garden.rescuers.count) / 5",
          store.garden.endless ? "PERSONAL BEST" : "ROBINS KEPT")
      }.padding(.vertical, 6)
      HStack {
        action(
          won && store.garden.level < 3 ? "Next chapter" : "Grow again", icon: "arrow.right",
          gold: true
        ) {
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
      Text(label).font(.system(size: 8, weight: .bold, design: .serif)).tracking(1.6)
        .foregroundStyle(Color.goldDeep)
    }
  }

  private var guide: some View {
    ZStack {
      Color.ink.opacity(0.82).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text("The little field guide").font(
              .system(size: 28, weight: .semibold, design: .serif))
            Text("FIVE LANES · SEVEN PLOTS · A HOME WORTH PROTECTING")
              .font(.system(size: 8, weight: .semibold, design: .serif)).tracking(1.8)
              .foregroundStyle(Color.goldDeep)
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
                .foregroundStyle(Color.ink.opacity(0.75))
            }.frame(maxWidth: .infinity).frame(height: 109)
              .background(
                LinearGradient(
                  colors: [seed.tint.opacity(0.28), seed.tint.opacity(0.08)], startPoint: .top,
                  endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 14)
              )
              .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(seed.tint.opacity(0.35), lineWidth: 1))
          }
        }
        Text(
          "1  Gather gold drops — or tap the sunshine counter to gather all.\n2  Pick a seed packet, then tap a plot. Defenders fire to the right.\n3  Keep every lane covered. Shovel returns half a plant’s cost."
        )
        .font(.system(size: 11, weight: .medium)).lineSpacing(5)
        Text(
          "Each lane has one last-chance robin. A second breach ends the run.\nEmberbuds: tap to preview, tap again to plant. Burst in 1.5s. Frost slows armor."
        )
        .font(.system(size: 10)).foregroundStyle(Color.moss).lineSpacing(3)
        if store.garden.endless {
          Text(
            "Endless: store 500 sunshine. Wave 4 brings packs and smaller sky drops. Watch the next lane."
          )
          .font(.system(size: 10, weight: .medium)).foregroundStyle(Color.moss)
        }
      }.padding(20).frame(maxWidth: 650)
        .background { PaperBackground() }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
          RoundedRectangle(cornerRadius: 20).stroke(Color.goldDeep.opacity(0.4), lineWidth: 1)
            .padding(5)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
        .padding(15)
    }
  }

  private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Color.ink.opacity(0.78).ignoresSafeArea()
      VStack(spacing: 10, content: content).padding(.horizontal, 28).padding(.vertical, 22)
        .background { PaperBackground() }
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
          RoundedRectangle(cornerRadius: 22).stroke(Color.goldDeep.opacity(0.4), lineWidth: 1)
            .padding(5)
        )
        .shadow(color: .black.opacity(0.45), radius: 24, y: 10)
        .padding(20)
    }
  }

  private func action(
    _ text: String, icon: String, secondary: Bool = false, gold: Bool = false,
    perform: @escaping () -> Void
  ) -> some View {
    Button(action: perform) {
      HStack(spacing: 12) {
        Text(text)
        Image(systemName: icon)
      }.font(.system(size: 13, weight: .semibold))
        .padding(.horizontal, 20).frame(height: 44)
        .background(
          LinearGradient(
            colors: secondary
              ? [Color.moss.opacity(0.14), Color.moss.opacity(0.10)]
              : gold ? [.gold, .goldDeep] : [.pine, .ink],
            startPoint: .top, endPoint: .bottom),
          in: Capsule()
        )
        .overlay(
          Capsule().stroke(
            secondary ? Color.ink.opacity(0.2) : Color.cream.opacity(0.35), lineWidth: 1)
        )
        .foregroundStyle(secondary || gold ? Color.ink : Color.cream)
        .shadow(color: .ink.opacity(secondary ? 0 : 0.25), radius: 6, y: 3)
    }.buttonStyle(.plain)
  }

  private func circleButton(
    _ label: String, icon: String, light: Bool = false, perform: @escaping () -> Void
  ) -> some View {
    Button(action: perform) {
      Image(systemName: icon).font(.system(size: 14, weight: .semibold)).frame(
        width: 42, height: 42
      )
      .background(light ? Color.black.opacity(0.22) : Color.cream.opacity(0.75), in: Circle())
      .overlay(Circle().stroke((light ? Color.cream : Color.ink).opacity(0.25), lineWidth: 1))
      .foregroundStyle(light ? Color.cream : Color.ink)
    }.buttonStyle(.plain).accessibilityLabel(label)
  }
}
