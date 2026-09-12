import SwiftUI

@main
struct GoldenDropApp: App {
  @StateObject private var store = GameStore()
  @Environment(\.scenePhase) private var scenePhase
  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(store)
        .preferredColorScheme(.light)
        .onAppear { store.startClock() }
        .onChange(of: scenePhase) { _, phase in
          if phase == .active { store.startClock() } else { store.background() }
        }
    }
  }
}

struct RootView: View {
  @EnvironmentObject private var store: GameStore
  var body: some View {
    ZStack {
      Palette.cream.ignoresSafeArea()
      switch store.screen {
      case .home: HomeView()
      case .boards: GardensView()
      case .play: PlayView()
      }
      if store.screen == .play {
        if store.help {
          InstructionsView()
        } else if store.paused {
          PauseView()
        } else if store.game.phase == .won || store.game.phase == .lost {
          ResultsView()
        }
      }
    }
    .foregroundStyle(Palette.ink)
    .tint(Palette.ink)
    .dynamicTypeSize(.xSmall ... .xxxLarge)
  }
}

struct HomeView: View {
  @EnvironmentObject private var store: GameStore
  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        HStack {
          eyebrow("THE CELESTIAL COLLECTION")
          Spacer()
          SoundButton()
        }.padding(.horizontal, 26)
        Spacer(minLength: 8)
        VStack(spacing: 3) {
          Text("Golden Drop").font(.custom("Georgia", size: geometry.size.height < 730 ? 45 : 51))
            .tracking(-2)
          Text("Make a little magic.").font(.custom("Georgia-Italic", size: 18)).foregroundStyle(
            Palette.gold)
        }
        TheaterArt(game: GameRules(board: Board.all[1]), decorative: true)
          .frame(maxHeight: .infinity)
          .padding(.horizontal, 40)
          .padding(.top, 14)
          .overlay(alignment: .bottom) {
            Text("AIM.  DROP.  DELIGHT.")
              .font(.system(size: 10, weight: .semibold, design: .rounded))
              .tracking(3).foregroundStyle(Palette.gold)
              .padding(8).background(Palette.cream).offset(y: 6)
          }
        VStack(spacing: 12) {
          Text("A joyful little game of beautiful bounces.")
            .font(.system(size: 13)).foregroundStyle(Palette.ink.opacity(0.7))
            .padding(.top, 18)
          PrimaryButton(title: "Play Cloud Nine", symbol: "arrow.right") {
            store.start(Board.all[0])
          }
          Button {
            store.screen = .boards
          } label: {
            HStack(spacing: 9) {
              Image(systemName: "square.grid.2x2")
              Text("The six gardens")
              Spacer()
              Text("\(store.records.values.reduce(0) { $0 + $1.stars }) / 18")
              Image(systemName: "star.fill").font(.system(size: 11))
            }.font(.system(size: 14, weight: .medium)).padding(.horizontal, 18).frame(height: 48)
          }.accessibilityIdentifier("gardens")
          HStack(spacing: 6) {
            Image(systemName: "sparkle")
            Text("A pocketful of wonder.  No hurry required.")
          }.font(.system(size: 10)).foregroundStyle(Palette.gold)
        }.padding(.horizontal, 26).padding(.bottom, 12)
      }
    }
  }
}

struct GardensView: View {
  @EnvironmentObject private var store: GameStore
  var body: some View {
    VStack(spacing: 16) {
      HStack {
        RoundButton(symbol: "arrow.left", label: "Home") { store.screen = .home }
        Spacer()
        eyebrow("CHOOSE YOUR CONSTELLATION")
        Spacer()
      }
      VStack(spacing: 6) {
        Text("The six gardens").font(.custom("Georgia", size: 34))
        Text("Little worlds. Lovely possibilities.").font(.custom("Georgia-Italic", size: 16))
          .foregroundStyle(Palette.gold)
      }
      ScrollView {
        VStack(spacing: 12) {
          ForEach(Board.all) { board in
            Button {
              store.start(board)
            } label: {
              HStack(spacing: 16) {
                Image(systemName: board.symbol).font(.system(size: 27, weight: .light))
                  .foregroundStyle(Palette.gold).frame(width: 56, height: 65)
                  .background(Palette.gold.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
                VStack(alignment: .leading, spacing: 7) {
                  Text("GARDEN 0\(board.id + 1)").font(.system(size: 9, weight: .semibold))
                    .tracking(2).foregroundStyle(Palette.gold)
                  Text(board.name).font(.custom("Georgia", size: 21))
                  HStack(spacing: 4) {
                    StarRow(count: store.records[String(board.id)]?.stars ?? 0, size: 11)
                    if let record = store.records[String(board.id)] {
                      Text(" · \(record.score.formatted()) best").font(.system(size: 10))
                        .foregroundStyle(Palette.ink.opacity(0.65))
                    }
                  }
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.system(size: 14)).foregroundStyle(
                  Palette.gold)
              }.padding(14).background(Palette.paper, in: RoundedRectangle(cornerRadius: 25))
                .overlay(RoundedRectangle(cornerRadius: 25).stroke(Palette.gold.opacity(0.17)))
            }.accessibilityIdentifier("board-\(board.id)")
          }
        }.padding(.bottom, 12)
      }.scrollIndicators(.hidden)
    }.padding(.horizontal, 24).padding(.top, 8)
  }
}

struct PlayView: View {
  @EnvironmentObject private var store: GameStore
  var body: some View {
    VStack(spacing: 7) {
      HStack(alignment: .center) {
        RoundButton(symbol: "pause.fill", label: "Pause") { store.paused = true }
        Spacer()
        VStack(spacing: 4) {
          eyebrow("GARDEN 0\(store.game.board.id + 1)")
          Text(store.game.board.name).font(.custom("Georgia", size: 25))
        }
        Spacer()
        SoundButton()
      }.padding(.horizontal, 23)
      HStack(spacing: 0) {
        metric("SCORE", value: store.game.score.formatted())
        Rectangle().fill(Palette.gold.opacity(0.2)).frame(width: 1, height: 29)
        metric("GOLD LEFT", value: "\(store.game.remainingGold) / \(store.game.goldTotal)")
        Rectangle().fill(Palette.gold.opacity(0.2)).frame(width: 1, height: 29)
        metric("MULTIPLIER", value: "×\(store.game.multiplier)")
      }.padding(.vertical, 8).padding(.horizontal, 16)
      GeometryReader { geometry in
        let scale = min(geometry.size.width / 390, geometry.size.height / 560)
        TheaterArt(game: store.game, sparks: store.particles)
          .contentShape(Rectangle())
          .gesture(
            DragGesture(minimumDistance: 0).onChanged { value in
              guard !store.paused, !store.help else { return }
              let x = (value.location.x - (geometry.size.width - 390 * scale) / 2) / scale
              let y = (value.location.y - (geometry.size.height - 560 * scale) / 2) / scale
              store.game.aim(at: .init(x: x, y: y))
            }
          )
          .accessibilityElement()
          .accessibilityLabel("Aim the launcher")
          .accessibilityValue("\(Int(store.game.angle * 180 / .pi)) degrees")
          .accessibilityAdjustableAction { direction in
            guard store.game.phase == .aiming else { return }
            store.game.angle = min(
              1.2, max(-1.2, store.game.angle + (direction == .increment ? 0.08 : -0.08)))
          }
          .accessibilityIdentifier("aim-field")
          .overlay(alignment: .bottom) {
            if store.toastLife > 0 {
              Text(store.toast).font(.system(size: 11, weight: .bold)).tracking(1.2)
                .foregroundStyle(Palette.paper).padding(.horizontal, 18).padding(.vertical, 11)
                .background(Palette.ink, in: Capsule()).offset(y: -38)
                .allowsHitTesting(false)
            }
          }
      }.padding(.horizontal, 14)
      VStack(spacing: 10) {
        HStack {
          HStack(spacing: 5) {
            Image(systemName: "circle.inset.filled").foregroundStyle(Palette.gold)
            Text("\(store.game.balls)").fontWeight(.bold).monospacedDigit()
            Text("balls left").foregroundStyle(Palette.ink.opacity(0.65))
          }.font(.system(size: 13))
          Spacer()
          Text(
            store.game.phase == .flying
              ? "\(store.game.shotHits) PEGS  ·  +\(store.game.shotScore)" : "DRAG TO AIM"
          )
          .font(.system(size: 10, weight: .semibold)).tracking(1.5).foregroundStyle(Palette.gold)
        }
        HStack(spacing: 10) {
          RoundButton(symbol: "minus", label: "Aim left") { nudge(-0.06) }
            .disabled(store.game.phase != .aiming)
          PrimaryButton(
            title: store.game.phase == .flying ? "A little gravity…" : "Drop the ball",
            symbol: store.game.phase == .flying ? "sparkles" : "arrow.down"
          ) { store.fire() }
          .disabled(store.game.phase != .aiming)
          .accessibilityIdentifier("launch")
          RoundButton(symbol: "plus", label: "Aim right") { nudge(0.06) }
            .disabled(store.game.phase != .aiming)
        }
        Text("Clear every gold peg. Catch the cup for a free ball.")
          .font(.system(size: 10)).foregroundStyle(Palette.ink.opacity(0.62))
      }.padding(.horizontal, 25).padding(.bottom, 8)
    }.padding(.top, 5)
  }

  func nudge(_ amount: Double) {
    guard store.game.phase == .aiming else { return }
    store.game.angle = min(1.2, max(-1.2, store.game.angle + amount))
  }

  func metric(_ title: String, value: String) -> some View {
    VStack(spacing: 4) {
      Text(title).font(.system(size: 9, weight: .semibold)).tracking(1.7).foregroundStyle(
        Palette.gold)
      Text(value).font(.custom("Georgia", size: 23)).monospacedDigit()
    }.frame(maxWidth: .infinity)
  }
}

struct InstructionsView: View {
  @EnvironmentObject private var store: GameStore
  var body: some View {
    ModalCard {
      Image(systemName: "sparkles").font(.system(size: 32, weight: .light)).foregroundStyle(
        Palette.gold)
      eyebrow("A LITTLE FIELD GUIDE")
      Text("Follow your\n golden instinct.").font(.custom("Georgia", size: 33))
        .multilineTextAlignment(.center)
      VStack(alignment: .leading, spacing: 22) {
        instruction(
          "hand.draw", title: "Aim, then let go",
          text: "Drag across the garden to aim. Tap Drop the ball to launch.")
        instruction(
          "circle.inset.filled", title: "Gold is the goal",
          text: "Clear every gold peg. More pegs in one shot multiply your points.")
        instruction(
          "plus.circle", title: "A little extra luck",
          text: "Green pegs gift a ball. Catch the moving cup for another, plus 500 points.")
      }.padding(.vertical, 10)
      PrimaryButton(title: "Let’s make magic", symbol: "arrow.right") { store.dismissHelp() }
    }
  }

  func instruction(_ icon: String, title: String, text: String) -> some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: icon).font(.system(size: 22, weight: .light)).foregroundStyle(Palette.gold)
        .frame(width: 30)
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.system(size: 15, weight: .semibold))
        Text(text).font(.system(size: 13)).foregroundStyle(Palette.ink.opacity(0.7)).fixedSize(
          horizontal: false, vertical: true)
      }
    }
  }
}

struct PauseView: View {
  @EnvironmentObject private var store: GameStore
  var body: some View {
    ModalCard {
      Image(systemName: "moon.zzz").font(.system(size: 38, weight: .ultraLight)).foregroundStyle(
        Palette.gold)
      eyebrow("TAKE YOUR TIME")
      Text("A quiet moment.").font(.custom("Georgia", size: 30))
      Text("Your garden will be right here.").font(.custom("Georgia-Italic", size: 16))
        .foregroundStyle(Palette.gold)
      PrimaryButton(title: "Keep playing", symbol: "play.fill") {
        store.paused = false
        store.lastTick = nil
      }
      Button("Begin this garden again") { store.start(store.game.board) }.frame(minHeight: 44)
      HStack {
        Button("How to play") { store.help = true }.frame(minHeight: 44)
        Spacer()
        Button("The gardens") {
          store.paused = false
          store.screen = .boards
        }.frame(minHeight: 44)
      }.font(.system(size: 13))
    }
  }
}

struct ResultsView: View {
  @EnvironmentObject private var store: GameStore
  var won: Bool { store.game.phase == .won }
  var body: some View {
    ModalCard {
      Image(systemName: won ? "sun.max" : "moon.stars")
        .font(.system(size: 48, weight: .ultraLight)).foregroundStyle(Palette.gold)
      eyebrow(won ? "EVERY WISH, GRANTED" : "THE STARS WILL WAIT")
      Text(won ? "Golden hour." : "One more wish?").font(.custom("Georgia", size: 37)).tracking(-1)
      Text(
        won
          ? "A beautiful finish in \(store.game.board.name)."
          : "\(store.game.remainingGold) gold pegs left. A new angle awaits."
      )
      .font(.system(size: 13)).foregroundStyle(Palette.ink.opacity(0.7))
      StarRow(count: store.game.stars, size: 26).padding(.vertical, 5)
      VStack(spacing: 5) {
        Text(store.game.score.formatted()).font(.custom("Georgia", size: 49)).monospacedDigit()
        eyebrow("POINTS OF PURE DELIGHT")
      }
      HStack {
        resultMetric("\(store.game.caught)", "LOVELY CATCHES")
        Spacer()
        resultMetric(
          "\(store.records[String(store.game.board.id)]?.score.formatted() ?? "0")", "PERSONAL BEST"
        )
      }.padding(16).background(Palette.gold.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
      if won {
        Text("Sunlight bonus +2,500 · \(store.game.balls) saved balls × 1,000")
          .font(.system(size: 11)).foregroundStyle(Palette.gold)
      }
      PrimaryButton(title: won ? "Next garden" : "Try a new angle", symbol: "arrow.right") {
        store.start(won ? Board.all[(store.game.board.id + 1) % Board.all.count] : store.game.board)
      }
      HStack {
        Button("Play again") { store.start(store.game.board) }
        Spacer()
        ShareLink(
          item:
            "I scored \(store.game.score.formatted()) in Golden Drop’s \(store.game.board.name), earning \(store.game.stars) stars. A pocketful of wonder!"
        ) {
          Image(systemName: "square.and.arrow.up").frame(width: 44, height: 44)
        }.accessibilityLabel("Share your score")
        Spacer()
        Button("Gardens") { store.screen = .boards }
      }.font(.system(size: 13, weight: .medium)).frame(minHeight: 44)
    }
  }
  func resultMetric(_ value: String, _ label: String) -> some View {
    VStack(spacing: 5) {
      Text(value).font(.custom("Georgia", size: 21))
      Text(label).font(.system(size: 8, weight: .semibold)).tracking(1).foregroundStyle(
        Palette.gold)
    }
  }
}

struct ModalCard<Content: View>: View {
  @ViewBuilder var content: Content
  var body: some View {
    ZStack {
      Palette.ink.opacity(0.42).ignoresSafeArea()
      ScrollView {
        VStack(spacing: 17) { content }
          .padding(26).frame(maxWidth: 370)
          .background(Palette.paper, in: RoundedRectangle(cornerRadius: 34))
          .overlay(RoundedRectangle(cornerRadius: 34).stroke(Palette.gold.opacity(0.35)))
          .padding(20)
          .frame(maxWidth: .infinity)
      }.scrollIndicators(.hidden).defaultScrollAnchor(.center)
    }
  }
}

struct PrimaryButton: View {
  let title: String
  var symbol = "arrow.right"
  let action: () -> Void
  @Environment(\.isEnabled) private var enabled
  var body: some View {
    Button(action: action) {
      HStack {
        Spacer(minLength: 0)
        Text(title).font(.system(size: 15, weight: .semibold))
        Spacer(minLength: 0)
        Image(systemName: symbol).font(.system(size: 14, weight: .medium))
      }.padding(.horizontal, 21).frame(height: 54)
        .foregroundStyle(Palette.paper)
        .background(enabled ? Palette.ink : Palette.ink.opacity(0.72), in: Capsule())
        .overlay(Capsule().stroke(Palette.paper.opacity(0.2)).padding(4))
    }.buttonStyle(.plain)
  }
}

struct RoundButton: View {
  let symbol: String
  let label: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Image(systemName: symbol).font(.system(size: 14, weight: .medium))
        .frame(width: 44, height: 44)
        .background(Palette.paper, in: Circle())
        .overlay(Circle().stroke(Palette.gold.opacity(0.22)))
    }.buttonStyle(.plain).accessibilityLabel(label)
  }
}

struct SoundButton: View {
  @EnvironmentObject private var store: GameStore
  var body: some View {
    RoundButton(
      symbol: store.sound ? "speaker.wave.2" : "speaker.slash",
      label: store.sound ? "Mute sound" : "Enable sound"
    ) {
      store.toggleSound()
    }
  }
}

struct StarRow: View {
  let count: Int
  var size = 14.0
  var body: some View {
    HStack(spacing: size * 0.36) {
      ForEach(0..<3) { index in
        Image(systemName: index < count ? "star.fill" : "star")
          .foregroundStyle(index < count ? Palette.gold : Palette.gold.opacity(0.35))
      }
    }.font(.system(size: size)).accessibilityLabel("\(count) of 3 stars")
  }
}

func eyebrow(_ title: String) -> some View {
  Text(title).font(.system(size: 9, weight: .semibold)).tracking(2.2).foregroundStyle(Palette.gold)
}
