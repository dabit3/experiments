import SwiftUI

enum LoungeSheet: String, Identifiable {
  case rules, pause, score, charms
  var id: String { rawValue }
}

struct LoungeView: View {
  @Bindable var game: GameStore
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var sheet: LoungeSheet?
  @State private var confirmNew = false
  var body: some View {
    ZStack {
      VelvetBackground()
      if !game.started {
        title
      } else {
        ScrollView {
          VStack(spacing: 20) {
            header
            switch game.run.phase {
            case .playing: table
            case .shop: shop
            case .lost, .won: results
            }
          }.padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 26)
            .frame(maxWidth: 540).frame(maxWidth: .infinity)
        }
      }
    }
    .foregroundStyle(Palette.cream)
    .sheet(item: $sheet) { item in
      LoungeModal(
        game: game, sheet: item, dismiss: { sheet = nil },
        home: {
          game.started = false
          sheet = nil
        }
      )
      .presentationDetents([.large])
      .presentationDragIndicator(.visible)
    }
    .confirmationDialog(
      "Leave this run and deal a new one?", isPresented: $confirmNew, titleVisibility: .visible
    ) {
      Button("Start new run", role: .destructive) { game.newRun() }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active {
        if game.started { game.save() }
        if game.started && sheet == nil { sheet = .pause }
      }
    }
  }

  private var header: some View {
    HStack {
      HStack(spacing: 7) {
        Text("♣").font(.system(size: 23))
        Text("Lucky Velvet").font(.system(size: 21, weight: .medium, design: .serif))
      }.foregroundStyle(Palette.gold)
      Spacer()
      Button {
        sheet = .rules
      } label: {
        Image(systemName: "questionmark").frame(width: 44, height: 44)
      }.accessibilityLabel("How to play")
      Button {
        sheet = .pause
      } label: {
        Image(systemName: "pause.fill").frame(width: 44, height: 44)
      }.accessibilityLabel("Pause")
    }.font(.system(size: 16)).foregroundStyle(Palette.cream)
  }

  private var title: some View {
    GeometryReader { proxy in
      ScrollView {
        VStack(spacing: 25) {
          Eyebrow(text: "A little luck. A lot of possibility.")
            .padding(.top, 30)
          VStack(spacing: -7) {
            Text("Lucky").font(.system(size: 66, weight: .regular, design: .serif))
            Text("Velvet").font(.system(size: 78, weight: .regular, design: .serif)).italic()
          }.foregroundStyle(Palette.cream)
          ZStack {
            Circle().stroke(Palette.gold.opacity(0.2), lineWidth: 1).frame(width: 234, height: 234)
            Circle().stroke(Palette.gold.opacity(0.10), lineWidth: 16).frame(
              width: 210, height: 210)
            PlayingCard(card: Card(rank: 14, suit: .spades)).frame(width: 103, height: 147)
              .rotationEffect(.degrees(-19)).offset(x: -65, y: 6)
            PlayingCard(card: Card(rank: 14, suit: .hearts)).frame(width: 103, height: 147)
              .rotationEffect(.degrees(19)).offset(x: 65, y: 6)
            VStack(spacing: 0) {
              Eyebrow(text: "The velvet fox").scaleEffect(0.7)
              CharmArt(charm: .velvet).frame(width: 106, height: 106)
              Text("FORTUNE FAVORS YOU").font(.system(size: 6, weight: .bold)).tracking(1)
                .foregroundStyle(Palette.gold)
            }.frame(width: 117, height: 169)
              .background(Palette.ink, in: RoundedRectangle(cornerRadius: 10))
              .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.gold, lineWidth: 1.5))
              .rotationEffect(.degrees(-3)).shadow(color: .black.opacity(0.4), radius: 16, y: 12)
          }.frame(height: 235).accessibilityHidden(true)
          VStack(spacing: 9) {
            Text("Make your own good fortune.").font(.system(size: 21, design: .serif)).italic()
            Text(
              "Play poker hands. Collect curious charms.\nOutsmart the house, one blind at a time."
            )
            .font(.system(size: 14)).lineSpacing(5).foregroundStyle(Palette.muted)
            .multilineTextAlignment(.center)
          }
          VStack(spacing: 12) {
            GoldButton(
              title: game.hasSave && [.playing, .shop].contains(game.run.phase)
                ? "Continue your run" : "Take a seat"
            ) {
              if game.hasSave && [.playing, .shop].contains(game.run.phase) {
                game.started = true
              } else {
                game.newRun()
              }
            }.accessibilityIdentifier("startRun")
            HStack(spacing: 12) {
              QuietButton(title: "How to play", icon: "suit.club") { sheet = .rules }
              if game.hasSave {
                QuietButton(title: "New run", icon: "arrow.clockwise") { confirmNew = true }
              } else {
                QuietButton(
                  title: game.sound ? "Sound on" : "Sound off",
                  icon: game.sound ? "speaker.wave.2" : "speaker.slash"
                ) {
                  game.sound.toggle()
                }
              }
            }
          }
          HStack(spacing: 8) {
            Image(systemName: "sparkle")
            Text(
              game.records.bestScore > 0
                ? "PERSONAL BEST  \(game.records.bestScore.formatted())"
                : "3 ANTES  ·  12 CHARMS  ·  ENDLESS POSSIBILITIES")
          }.font(.system(size: 9, weight: .semibold)).tracking(1.3).foregroundStyle(
            Palette.gold.opacity(0.8))
          Text("All stakes are make-believe. The strategy is yours.")
            .font(.system(size: 10)).foregroundStyle(Palette.muted.opacity(0.7))
        }.padding(.horizontal, 30).padding(.bottom, 25)
          .frame(minHeight: proxy.size.height).frame(maxWidth: 500).frame(maxWidth: .infinity)
      }
    }
  }

  private var table: some View {
    VStack(spacing: 16) {
      HStack {
        Eyebrow(text: "Ante \(game.run.ante) / 3")
        Spacer()
        ForEach(0..<9) { index in
          Circle().fill(
            index < game.run.blind
              ? Palette.gold : index == game.run.blind ? Palette.cream : Palette.muted.opacity(0.2)
          )
          .frame(width: 6, height: 6)
        }
        Spacer()
        Text("$\(game.run.money)").font(.system(size: 18, weight: .bold, design: .rounded))
          .foregroundStyle(Palette.gold)
      }
      Panel {
        VStack(spacing: 12) {
          HStack {
            VStack(alignment: .leading, spacing: 5) {
              Eyebrow(
                text: game.run.blind == 8 ? "Final challenge" : "Blind \(game.run.blind + 1) of 9")
              Text(game.run.blindName).font(.system(size: 25, design: .serif))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
              Text("TARGET").font(.system(size: 9, weight: .bold)).tracking(2).foregroundStyle(
                Palette.muted)
              Text(game.run.target.formatted()).font(
                .system(size: 26, weight: .medium, design: .rounded))
            }
          }
          GeometryReader { geometry in
            ZStack(alignment: .leading) {
              Capsule().fill(Palette.cream.opacity(0.07))
              Capsule().fill(Palette.gold).frame(
                width: geometry.size.width
                  * min(1, Double(game.run.score) / Double(game.run.target)))
            }
          }.frame(height: 5)
          HStack {
            Text("\(game.run.score.formatted())").foregroundStyle(Palette.gold).fontWeight(.bold)
            Text("scored").foregroundStyle(Palette.muted)
            Spacer()
            Text("\(max(0, game.run.target - game.run.score).formatted()) to go").foregroundStyle(
              Palette.muted)
          }.font(.system(size: 12, design: .rounded))
        }
      }
      HStack(spacing: 10) {
        Eyebrow(text: "Your charms")
        Spacer()
        Button {
          sheet = .charms
        } label: {
          Text("\(game.run.charms.count)/5  ·  View effects").font(.system(size: 11))
            .foregroundStyle(Palette.muted)
            .frame(minHeight: 30)
        }
      }
      HStack(spacing: 8) {
        ForEach(game.run.charms) { charm in
          Button {
            sheet = .charms
          } label: {
            CharmArt(charm: charm).frame(maxWidth: .infinity).frame(height: 61)
              .background(Palette.ink.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
              .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.gold.opacity(0.3)))
          }.accessibilityLabel("\(charm.name), \(charm.detail)")
        }
        ForEach(0..<max(0, 5 - game.run.charms.count), id: \.self) { _ in
          Text("✦").font(.system(size: 15)).foregroundStyle(Palette.gold.opacity(0.2))
            .frame(maxWidth: .infinity).frame(height: 61)
            .overlay(
              RoundedRectangle(cornerRadius: 10).stroke(
                Palette.gold.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [3, 4])))
        }
      }.buttonStyle(.plain)
      scorePreview
      HStack {
        Text("YOUR HAND").font(.system(size: 10, weight: .bold)).tracking(1.6)
        Spacer()
        Text("\(game.selected.count)/5 selected · \(game.run.deck.count) in deck")
          .font(.system(size: 10)).foregroundStyle(Palette.muted)
      }
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 4), spacing: 10)
      {
        ForEach(game.run.hand) { card in
          Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.75)) {
              game.select(card)
            }
          } label: {
            PlayingCard(card: card, selected: game.selected.contains(card.id))
              .offset(y: game.selected.contains(card.id) ? -4 : 0)
          }.buttonStyle(.plain)
            .accessibilityLabel(card.name)
            .accessibilityValue(game.selected.contains(card.id) ? "Selected" : "Not selected")
            .accessibilityIdentifier("card-\(card.id)")
        }
      }
      HStack(spacing: 12) {
        VStack(spacing: 5) {
          QuietButton(title: "Discard", icon: "arrow.triangle.2.circlepath") { game.discard() }
            .disabled(game.selected.isEmpty || game.run.discards == 0)
            .opacity(game.selected.isEmpty || game.run.discards == 0 ? 0.4 : 1)
          Text("\(game.run.discards) discards left").font(.system(size: 10)).foregroundStyle(
            Palette.muted)
        }.frame(maxWidth: .infinity)
        VStack(spacing: 5) {
          GoldButton(title: "Play hand", icon: "suit.spade.fill", disabled: game.preview == nil) {
            game.play()
            sheet = .score
          }.accessibilityIdentifier("playHand")
          Text("\(game.run.hands) hands left").font(.system(size: 10)).foregroundStyle(
            Palette.muted)
        }.frame(maxWidth: .infinity)
      }
    }
  }

  private var scorePreview: some View {
    VStack(spacing: 7) {
      HStack {
        Text(game.preview?.hand.kind.name ?? "Find your fortune")
          .font(.system(size: 21, design: .serif))
        Spacer()
        if let preview = game.preview {
          Text("\(preview.total.formatted())").font(
            .system(size: 23, weight: .bold, design: .rounded)
          ).foregroundStyle(Palette.gold)
        }
      }
      HStack {
        if let preview = game.preview {
          Text("\(preview.chips) Chips × \(preview.mult.formatted()) Mult")
          Spacer()
          Text("PREVIEW").font(.system(size: 8, weight: .bold)).tracking(1.4)
        } else {
          Text("Tap 1–5 cards. Only matching cards score.")
        }
      }.font(.system(size: 11)).foregroundStyle(Palette.muted)
    }.padding(15).background(Palette.green.opacity(0.65), in: RoundedRectangle(cornerRadius: 15))
      .overlay(RoundedRectangle(cornerRadius: 15).stroke(Palette.gold.opacity(0.2)))
  }

  private var shop: some View {
    VStack(spacing: 21) {
      Eyebrow(text: "Blind cleared  ·  +$\(game.run.lastReward) earned")
      VStack(spacing: 6) {
        Text("A fortunate encounter.").font(.system(size: 31, design: .serif))
          .multilineTextAlignment(.center)
        Text("A little something for your next big hand.")
          .font(.system(size: 13)).foregroundStyle(Palette.muted)
      }
      HStack {
        Eyebrow(text: "The charm cabinet")
        Spacer()
        Text("$\(game.run.money)").font(.system(size: 27, weight: .medium, design: .rounded))
          .foregroundStyle(Palette.gold)
      }
      ForEach(game.run.offers) { charm in
        HStack(spacing: 14) {
          CharmArt(charm: charm).frame(width: 78, height: 85)
            .background(Palette.ink, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.gold.opacity(0.4)))
          VStack(alignment: .leading, spacing: 6) {
            Text(charm.name).font(.system(size: 19, design: .serif))
            Text(charm.detail).font(.system(size: 12)).foregroundStyle(Palette.muted).fixedSize(
              horizontal: false, vertical: true)
            Button {
              game.buy(charm)
            } label: {
              Text("Collect · $\(charm.price)").font(.system(size: 12, weight: .bold))
                .foregroundStyle(Palette.gold).frame(minHeight: 35)
            }.disabled(game.run.money < charm.price || game.run.charms.count == 5)
              .opacity(game.run.money < charm.price || game.run.charms.count == 5 ? 0.35 : 1)
              .accessibilityIdentifier("buy-\(charm.rawValue)")
          }
          Spacer(minLength: 0)
        }.padding(12).background(Palette.ink.opacity(0.7), in: RoundedRectangle(cornerRadius: 18))
          .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.gold.opacity(0.16)))
      }
      HStack(spacing: 12) {
        QuietButton(title: "Your charms \(game.run.charms.count)/5", icon: "sparkles") {
          sheet = .charms
        }
        QuietButton(title: "Refresh · $2", icon: "arrow.clockwise") {
          game.run.reroll()
          game.save()
        }
        .disabled(game.run.money < 2).opacity(game.run.money < 2 ? 0.4 : 1)
      }
      if game.run.charms.count == 5 {
        Text("Your cabinet is full. Sell a charm to make room.")
          .font(.system(size: 12)).foregroundStyle(Palette.gold)
      }
      GoldButton(title: "Next blind · \(Run.targets[min(8, game.run.blind + 1)].formatted())") {
        game.run.nextBlind()
        game.save()
      }
      Text(
        "Additive effects score first. × Mult effects follow.\nBuild a collection that plays well together."
      )
      .font(.system(size: 11)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
      .lineSpacing(3)
    }
  }

  private var results: some View {
    VStack(spacing: 23) {
      Eyebrow(text: game.run.phase == .won ? "The house applauds" : "Every fortune has a story")
      CharmArt(charm: game.run.phase == .won ? .crown : .velvet).frame(width: 142, height: 142)
      Text(game.run.phase == .won ? "An extraordinary run." : "Until next time.")
        .font(.system(size: 35, design: .serif)).multilineTextAlignment(.center)
      Text(
        game.run.phase == .won
          ? "Three antes. Nine blinds. Beautifully played."
          : "The house held this time.\nYour next great hand is waiting."
      )
      .font(.system(size: 14)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
      .lineSpacing(4)
      Panel {
        VStack(spacing: 17) {
          Eyebrow(text: "Your run score")
          Text(game.run.totalScore.formatted()).font(
            .system(size: 52, weight: .medium, design: .rounded)
          ).foregroundStyle(Palette.gold)
          Divider().overlay(Palette.gold.opacity(0.2))
          resultRow("Blinds cleared", "\(game.run.cleared) / 9")
          resultRow("Best hand", game.run.bestHand.formatted())
          resultRow("Personal best", game.records.bestScore.formatted())
          resultRow("Lifetime victories", "\(game.records.wins)")
        }
      }
      GoldButton(title: "Try your luck again", icon: "arrow.clockwise") { game.newRun() }
      HStack(spacing: 12) {
        QuietButton(title: "Back to lounge", icon: "house") { game.started = false }
        ShareLink(
          item:
            "Lucky Velvet · \(game.run.totalScore.formatted()) points · \(game.run.cleared)/9 blinds · Best hand: \(game.run.bestHand.formatted()). A little luck. A lot of possibility."
        ) {
          Label("Share result", systemImage: "square.and.arrow.up").font(
            .system(size: 13, weight: .semibold)
          ).frame(minHeight: 44)
        }.frame(maxWidth: .infinity).foregroundStyle(Palette.gold)
      }
    }.padding(.top, 10)
  }

  private func resultRow(_ title: String, _ value: String) -> some View {
    HStack {
      Text(title).foregroundStyle(Palette.muted)
      Spacer()
      Text(value).fontWeight(.semibold)
    }.font(.system(size: 13, design: .rounded))
  }
}
