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
        VStack(spacing: 8) {
          header.padding(.horizontal, 22)
          ScrollView {
            Group {
              switch game.run.phase {
              case .playing: table
              case .shop: shop
              case .lost, .won: results
              }
            }
            .padding(.horizontal, 22).padding(.top, 4).padding(.bottom, 12)
          }
          .clipped()
          .id(game.run.phase)
          if game.run.phase == .playing {
            tableActions.padding(.horizontal, 22).padding(.vertical, 8)
              .background(
                LinearGradient(
                  colors: [Palette.ink.opacity(0.85), Palette.ink], startPoint: .top,
                  endPoint: .bottom)
              )
              .overlay(alignment: .top) {
                LinearGradient(
                  colors: [
                    Palette.gold.opacity(0), Palette.gold.opacity(0.5), Palette.gold.opacity(0),
                  ],
                  startPoint: .leading, endPoint: .trailing
                ).frame(height: 1)
              }
          }
        }
        .frame(maxWidth: 540).frame(maxWidth: .infinity)
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

  private var motion: Animation? {
    reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.78)
  }

  private var header: some View {
    HStack(spacing: 10) {
      Monogram(size: 34)
      Text("Lucky Velvet").deco(15, weight: .medium, tracking: 3.2).foregroundStyle(Palette.gold)
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
    }.font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.cream)
  }

  private var title: some View {
    GeometryReader { proxy in
      ScrollView {
        VStack(spacing: 24) {
          Ornament(text: "A little luck · A lot of possibility").padding(.top, 26)
          VStack(spacing: -10) {
            Text("Lucky").font(.system(size: 64, weight: .regular, design: .serif))
              .tracking(1)
            Text("Velvet").font(.system(size: 82, weight: .regular, design: .serif)).italic()
              .foregroundStyle(Palette.foil)
          }
          .foregroundStyle(Palette.cream)
          .shadow(color: Palette.gold.opacity(0.35), radius: 24)
          ZStack {
            Circle().stroke(Palette.foilStroke, lineWidth: 1).frame(width: 238, height: 238)
              .opacity(0.6)
            Circle().stroke(Palette.gold.opacity(0.10), lineWidth: 18).frame(
              width: 214, height: 214)
            PlayingCard(card: Card(rank: 14, suit: .spades)).frame(width: 103, height: 147)
              .rotationEffect(.degrees(-19)).offset(x: -65, y: 6)
            PlayingCard(card: Card(rank: 14, suit: .hearts)).frame(width: 103, height: 147)
              .rotationEffect(.degrees(19)).offset(x: 65, y: 6)
            VStack(spacing: 0) {
              Text("THE VELVET FOX").deco(6.5, weight: .semibold, tracking: 1.4)
                .foregroundStyle(Palette.gold).lineLimit(1)
              CharmArt(charm: .velvet).frame(width: 106, height: 106)
              Text("FORTUNE FAVORS YOU").deco(5.5, weight: .semibold, tracking: 1.2)
                .foregroundStyle(Palette.gold)
            }.frame(width: 117, height: 169)
              .decoFrame(radius: 12, fill: Palette.ink, strength: 1)
              .rotationEffect(.degrees(-3)).shadow(color: .black.opacity(0.45), radius: 18, y: 14)
          }.frame(height: 240).background(Sunburst().frame(width: 460, height: 460))
            .accessibilityHidden(true)
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
          Ornament(
            text: game.records.bestScore > 0
              ? "Personal best  \(game.records.bestScore.formatted())"
              : "3 antes  ·  12 charms  ·  9 blinds")
          Text("All stakes are make-believe. The strategy is yours.")
            .font(.system(size: 10)).foregroundStyle(Palette.muted.opacity(0.7))
        }.padding(.horizontal, 30).padding(.bottom, 25)
          .frame(minHeight: proxy.size.height).frame(maxWidth: 500).frame(maxWidth: .infinity)
      }
    }
  }

  private var table: some View {
    VStack(spacing: 9) {
      HStack(spacing: 12) {
        Eyebrow(text: "Ante \(game.run.ante) / 3")
        Spacer()
        HStack(spacing: 5) {
          ForEach(0..<9) { index in
            Gem(state: index < game.run.blind ? .won : index == game.run.blind ? .live : .idle)
          }
        }
        Spacer()
        HStack(spacing: 2) {
          Text("$").font(.system(size: 13, weight: .medium, design: .serif))
          Text("\(game.run.money)").font(.system(size: 19, weight: .semibold, design: .serif))
            .contentTransition(.numericText())
        }.foregroundStyle(Palette.gold)
      }
      marquee
      HStack(spacing: 10) {
        Eyebrow(text: "Charm cabinet")
        Spacer()
        Button {
          sheet = .charms
        } label: {
          Text("\(game.run.charms.count) of 5  ·  Effects").font(.system(size: 12))
            .foregroundStyle(Palette.muted)
            .frame(minHeight: 30)
        }
      }
      HStack(spacing: 8) {
        ForEach(game.run.charms) { charm in
          Button {
            sheet = .charms
          } label: {
            CharmTile(charm: charm).frame(maxWidth: .infinity).frame(height: 52)
          }.accessibilityLabel("\(charm.name), \(charm.detail)")
        }
        ForEach(0..<max(0, 5 - game.run.charms.count), id: \.self) { _ in
          Text("✦").font(.system(size: 13)).foregroundStyle(Palette.gold.opacity(0.3))
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(
              Palette.ink.opacity(0.3), in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(
                Palette.gold.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3, 4])))
        }
      }.buttonStyle(PressStyle())
      scoreboard
      HStack {
        Eyebrow(text: "Your hand", color: Palette.muted)
        Spacer()
        Text("\(game.selected.count) of 5 selected  ·  \(game.run.deck.count) in deck")
          .font(.system(size: 12)).foregroundStyle(Palette.muted)
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
              .offset(y: game.selected.contains(card.id) ? -6 : 0)
              .rotationEffect(.degrees(game.selected.contains(card.id) ? -1.5 : 0))
          }.buttonStyle(.plain)
            .transition(
              .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .scale(scale: 0.6).combined(with: .opacity))
            )
            .accessibilityLabel(card.name)
            .accessibilityValue(game.selected.contains(card.id) ? "Selected" : "Not selected")
            .accessibilityIdentifier("card-\(card.id)")
        }
      }
    }
  }

  private var marquee: some View {
    VStack(spacing: 10) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Eyebrow(
            text: game.run.blind == 8 ? "Final challenge" : "Blind \(game.run.blind + 1) of 9",
            color: game.run.blind == 8 ? Palette.rose : Palette.gold)
          Text(game.run.blindName).font(.system(size: 26, design: .serif)).italic()
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 3) {
          Eyebrow(text: "Target", color: Palette.muted)
          Text(game.run.target.formatted()).font(
            .system(size: 27, weight: .medium, design: .serif)
          ).monospacedDigit()
        }
      }
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule().fill(Palette.ink.opacity(0.7))
          Capsule().strokeBorder(Palette.gold.opacity(0.25), lineWidth: 0.7)
          Capsule().fill(Palette.foil).frame(
            width: max(
              0,
              geometry.size.width
                * min(1, Double(game.run.score) / Double(game.run.target)))
          ).shadow(color: Palette.gold.opacity(0.6), radius: 6)
        }
      }.frame(height: 7).animation(motion, value: game.run.score)
      HStack {
        Text(game.run.score.formatted()).foregroundStyle(Palette.gold).fontWeight(.semibold)
          .contentTransition(.numericText())
        Text("scored").foregroundStyle(Palette.muted)
        Spacer()
        Text("\(max(0, game.run.target - game.run.score).formatted()) to go").foregroundStyle(
          Palette.muted)
      }.font(.system(size: 12.5, design: .serif)).monospacedDigit()
    }
    .padding(.horizontal, 16).padding(.vertical, 14)
    .decoFrame(radius: 20, fill: Palette.ink.opacity(0.62))
  }

  private var tableActions: some View {
    HStack(spacing: 12) {
      VStack(spacing: 5) {
        QuietButton(title: "Discard", icon: "arrow.triangle.2.circlepath", height: 54) {
          withAnimation(motion) { game.discard() }
        }
        .disabled(game.selected.isEmpty || game.run.discards == 0)
        .opacity(game.selected.isEmpty || game.run.discards == 0 ? 0.4 : 1)
        Text("\(game.run.discards) discards left").font(.system(size: 12, weight: .medium))
          .foregroundStyle(Palette.muted)
      }.frame(maxWidth: .infinity)
      VStack(spacing: 5) {
        GoldButton(title: "Play hand", icon: "suit.spade.fill", disabled: game.preview == nil) {
          withAnimation(motion) { game.play() }
          sheet = .score
        }.accessibilityIdentifier("playHand")
        Text("\(game.run.hands) hands left").font(.system(size: 12, weight: .medium))
          .foregroundStyle(Palette.muted)
      }.frame(maxWidth: .infinity)
    }
  }

  private var scoreboard: some View {
    VStack(spacing: 9) {
      HStack(alignment: .firstTextBaseline) {
        Text(game.preview?.hand.kind.name ?? "Find your fortune")
          .font(.system(size: 22, design: .serif)).italic()
          .contentTransition(.interpolate)
        Spacer()
        if let preview = game.preview {
          Text(preview.total.formatted())
            .font(.system(size: 26, weight: .semibold, design: .serif)).monospacedDigit()
            .foregroundStyle(Palette.foil).contentTransition(.numericText())
            .shadow(color: Palette.gold.opacity(0.5), radius: 10)
        }
      }
      if let preview = game.preview {
        HStack(spacing: 8) {
          Chip(value: "\(preview.chips)", label: "Chips", fill: Palette.cream, ink: Palette.ink)
          Text("×").font(.system(size: 15, design: .serif)).foregroundStyle(Palette.gold)
          Chip(
            value: preview.mult.formatted(), label: "Mult", fill: Palette.ruby, ink: Palette.cream)
          Spacer()
          Eyebrow(text: preview.isRounded ? "Rounded down" : "Preview", color: Palette.muted)
        }
      } else {
        HStack {
          Text("Tap one to five cards to preview your score.").font(.system(size: 12.5))
            .foregroundStyle(Palette.muted)
          Spacer()
        }
      }
    }
    .padding(.horizontal, 14).padding(.vertical, 12)
    .decoFrame(radius: 18, fill: Palette.green.opacity(0.55), strength: 0.7)
    .animation(motion, value: game.preview?.total)
  }

  private var shop: some View {
    VStack(spacing: 20) {
      Ornament(text: "Blind cleared  ·  +$\(game.run.lastReward) earned")
      VStack(spacing: 6) {
        Text("A fortunate encounter.").font(.system(size: 32, design: .serif)).italic()
          .multilineTextAlignment(.center)
        Text("A little something for your next big hand.")
          .font(.system(size: 13)).foregroundStyle(Palette.muted)
      }
      HStack {
        Eyebrow(text: "The charm cabinet")
        Spacer()
        HStack(spacing: 2) {
          Text("$").font(.system(size: 16, weight: .medium, design: .serif))
          Text("\(game.run.money)").font(.system(size: 27, weight: .medium, design: .serif))
            .contentTransition(.numericText())
        }.foregroundStyle(Palette.gold)
      }
      ForEach(game.run.offers) { charm in
        HStack(spacing: 14) {
          CharmTile(charm: charm).frame(width: 78, height: 88)
          VStack(alignment: .leading, spacing: 6) {
            Text(charm.name).font(.system(size: 19, design: .serif))
            Text(charm.detail).font(.system(size: 12.5)).foregroundStyle(Palette.muted)
              .fixedSize(horizontal: false, vertical: true)
            Button {
              withAnimation(motion) { game.buy(charm) }
            } label: {
              Text("Collect  ·  $\(charm.price)").deco(11, tracking: 1.4)
                .foregroundStyle(Palette.ink).padding(.horizontal, 12).frame(minHeight: 32)
                .background(Palette.foil, in: Capsule())
            }.buttonStyle(PressStyle())
              .disabled(game.run.money < charm.price || game.run.charms.count == 5)
              .opacity(game.run.money < charm.price || game.run.charms.count == 5 ? 0.35 : 1)
              .accessibilityIdentifier("buy-\(charm.rawValue)")
          }
          Spacer(minLength: 0)
        }.padding(12).decoFrame(radius: 20, fill: Palette.ink.opacity(0.6))
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
    VStack(spacing: 16) {
      Ornament(text: game.run.phase == .won ? "The house applauds" : "Every fortune has a story")
      CharmArt(charm: game.run.phase == .won ? .crown : .velvet).frame(width: 112, height: 112)
        .frame(height: 130).background(Sunburst().frame(width: 320, height: 320))
      Text(game.run.phase == .won ? "An extraordinary run." : "Until next time.")
        .font(.system(size: 35, design: .serif)).italic().multilineTextAlignment(.center)
      Text(
        game.run.phase == .won
          ? "Three antes. Nine blinds. Beautifully played."
          : "The house held this time.\nYour next great hand is waiting."
      )
      .font(.system(size: 14)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
      .lineSpacing(4)
      Panel {
        VStack(spacing: 13) {
          Eyebrow(text: "Your run score")
          Text(game.run.totalScore.formatted()).font(
            .system(size: 54, weight: .medium, design: .serif)
          ).foregroundStyle(Palette.foil).monospacedDigit()
            .shadow(color: Palette.gold.opacity(0.45), radius: 16)
          Ornament()
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
            .system(size: 13, weight: .semibold, design: .serif)
          ).frame(minHeight: 44)
        }.frame(maxWidth: .infinity).foregroundStyle(Palette.gold)
      }
    }.padding(.top, 10)
  }

  private func resultRow(_ title: String, _ value: String) -> some View {
    HStack {
      Text(title).foregroundStyle(Palette.muted)
      Spacer()
      Text(value).fontWeight(.semibold).monospacedDigit()
    }.font(.system(size: 13.5, design: .serif))
  }
}

struct Gem: View {
  enum State { case won, live, idle }
  let state: State
  var body: some View {
    Circle()
      .fill(
        state == .won
          ? AnyShapeStyle(Palette.foil)
          : state == .live ? AnyShapeStyle(Palette.cream) : AnyShapeStyle(Palette.ink.opacity(0.6))
      )
      .overlay(
        Circle().strokeBorder(Palette.gold.opacity(state == .idle ? 0.35 : 0.9), lineWidth: 0.6)
      )
      .frame(width: state == .live ? 8 : 6, height: state == .live ? 8 : 6)
      .shadow(color: Palette.gold.opacity(state == .idle ? 0 : 0.7), radius: state == .live ? 5 : 2)
  }
}

struct Chip: View {
  let value: String
  let label: String
  let fill: Color
  let ink: Color
  var body: some View {
    HStack(spacing: 5) {
      Text(value).font(.system(size: 14, weight: .semibold, design: .serif)).monospacedDigit()
        .contentTransition(.numericText())
      Text(label.uppercased()).deco(8.5, tracking: 1.4).opacity(0.75)
    }
    .foregroundStyle(ink).padding(.horizontal, 10).frame(minHeight: 26)
    .background(fill, in: Capsule())
    .overlay(Capsule().strokeBorder(Palette.gold.opacity(0.5), lineWidth: 0.7))
  }
}
