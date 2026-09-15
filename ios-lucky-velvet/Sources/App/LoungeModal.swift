import SwiftUI

struct LoungeModal: View {
  @Bindable var game: GameStore
  let sheet: LoungeSheet
  let dismiss: () -> Void
  let home: () -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var revealed = false
  @State private var shownTotal = 0
  var body: some View {
    ZStack {
      VelvetBackground()
      ScrollView {
        VStack(spacing: 24) {
          HStack(spacing: 10) {
            Monogram(size: 30)
            Eyebrow(text: "Lucky Velvet")
            Spacer()
            Button(action: dismiss) { Image(systemName: "xmark").frame(width: 44, height: 44) }
              .accessibilityLabel("Close")
          }
          switch sheet {
          case .score: score
          case .pause: pause
          case .rules: rules
          case .charms: charms
          }
        }.padding(24).padding(.bottom, 24).frame(maxWidth: 540).frame(maxWidth: .infinity)
      }
    }.foregroundStyle(Palette.cream)
      .onAppear {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.55)) { revealed = true }
        guard let total = game.lastScore?.total else { return }
        if reduceMotion {
          shownTotal = total
        } else {
          withAnimation(.easeOut(duration: 1.1).delay(0.5)) { shownTotal = total }
        }
      }
  }

  private var score: some View {
    VStack(spacing: 22) {
      if let score = game.lastScore {
        Ornament(text: "A hand well played")
        Text(score.hand.kind.name).font(.system(size: 40, design: .serif)).italic()
          .multilineTextAlignment(.center)
        HStack(spacing: -10) {
          ForEach(Array(score.hand.scoringCards.enumerated()), id: \.element.id) { index, card in
            let spread = Double(index) - Double(score.hand.scoringCards.count - 1) / 2
            PlayingCard(card: card).frame(maxWidth: 66)
              .rotationEffect(.degrees(revealed ? spread * 6 : 0))
              .offset(y: revealed ? abs(spread) * 5 : 30)
              .opacity(revealed ? 1 : 0)
              .animation(
                reduceMotion
                  ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.06),
                value: revealed)
          }
        }.frame(height: 106).background(Sunburst().frame(width: 340, height: 340))
        Panel {
          VStack(spacing: 14) {
            ForEach(Array(score.lines.enumerated()), id: \.element.id) { index, line in
              HStack {
                Text(line.name).foregroundStyle(Palette.muted)
                Spacer()
                Text(line.effect).fontWeight(.semibold).monospacedDigit()
                  .foregroundStyle(line.effect.contains("×") ? Palette.rose : Palette.cream)
              }.font(.system(size: 13.5, design: .serif))
                .opacity(revealed ? 1 : 0).offset(x: revealed ? 0 : -8)
                .animation(
                  reduceMotion ? nil : .easeOut(duration: 0.35).delay(0.25 + Double(index) * 0.09),
                  value: revealed)
            }
            Ornament()
            HStack(spacing: 14) {
              VStack(spacing: 6) {
                Text("\(score.chips)").font(.system(size: 30, weight: .semibold, design: .serif))
                  .monospacedDigit().foregroundStyle(Palette.ink)
                  .frame(maxWidth: .infinity).frame(minHeight: 50)
                  .background(
                    Palette.cream, in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                  )
                  .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                      .strokeBorder(Palette.gold.opacity(0.7), lineWidth: 0.8))
                Eyebrow(text: "Chips")
              }
              Text("×").font(.system(size: 28, design: .serif)).foregroundStyle(Palette.gold)
                .padding(.bottom, 22)
              VStack(spacing: 6) {
                Text(score.mult.formatted()).font(
                  .system(size: 30, weight: .semibold, design: .serif)
                ).monospacedDigit().foregroundStyle(Palette.cream)
                  .frame(maxWidth: .infinity).frame(minHeight: 50)
                  .background(
                    Palette.ruby, in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                  )
                  .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                      .strokeBorder(Palette.gold.opacity(0.7), lineWidth: 0.8))
                Eyebrow(text: "Mult", color: Palette.rose)
              }
            }
          }
        }
        CountUp(value: Double(shownTotal)).font(
          .system(size: 60, weight: .medium, design: .serif)
        )
        .monospacedDigit().foregroundStyle(Palette.foil)
        .shadow(color: Palette.gold.opacity(0.55), radius: 22)
        .scaleEffect(revealed ? 1 : 0.85)
        .accessibilityLabel("Plus \(score.total.formatted()) points")
        if score.isRounded {
          Text("\(score.rawTotal.formatted()) → \(score.total) points · rounded down")
            .font(.system(size: 12)).foregroundStyle(Palette.muted)
        }
        Ornament(
          text: game.run.phase == .shop || game.run.phase == .won
            ? "Blind cleared"
            : "\(game.run.score.formatted()) / \(game.run.target.formatted()) in this blind")
        GoldButton(
          title: game.run.phase == .shop
            ? "Visit the charm cabinet"
            : [.won, .lost].contains(game.run.phase) ? "See your run" : "Back to the table",
          action: dismiss)
      }
    }
  }

  private var pause: some View {
    VStack(spacing: 24) {
      CharmArt(charm: .moon).frame(width: 150, height: 150)
        .background(Sunburst().frame(width: 360, height: 360))
      Text("Take a breath.").font(.system(size: 42, design: .serif)).italic()
      Text("Your table is just as you left it.\nEvery hand is saved automatically.")
        .font(.system(size: 15)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
        .lineSpacing(5)
      GoldButton(title: "Resume your run", icon: "play.fill", action: dismiss)
      QuietButton(
        title: game.sound ? "Sound on" : "Sound off",
        icon: game.sound ? "speaker.wave.2" : "speaker.slash"
      ) {
        game.sound.toggle()
      }
      QuietButton(title: "Back to lounge", icon: "house", action: home)
    }.padding(.top, 22)
  }

  private var charms: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Your lucky little things.").font(.system(size: 32, design: .serif)).italic()
      Text(
        "Chips and +Mult add together first. Then every ×Mult stacks. Up to five charms travel with you."
      )
      .font(.system(size: 14)).foregroundStyle(Palette.muted).lineSpacing(4)
      ForEach(game.run.charms) { charm in
        Panel {
          HStack(spacing: 13) {
            CharmTile(charm: charm).frame(width: 80, height: 88)
            VStack(alignment: .leading, spacing: 6) {
              Text(charm.name).font(.system(size: 21, design: .serif))
              Text(charm.detail).font(.system(size: 13)).foregroundStyle(Palette.muted)
              if game.run.phase == .shop {
                Button {
                  game.run.sell(charm)
                  game.save()
                } label: {
                  Text("Sell for $2").deco(11, tracking: 1.4).foregroundStyle(Palette.gold)
                    .frame(minHeight: 35)
                }
              }
            }.frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
      if game.run.charms.isEmpty {
        Text("Collect a charm in the cabinet after your next blind.").foregroundStyle(Palette.muted)
      }
      GoldButton(title: "Back to your run", action: dismiss)
    }
  }

  private var rules: some View {
    VStack(alignment: .leading, spacing: 22) {
      Text("Play your cards right.").font(.system(size: 34, design: .serif)).italic()
      rule(
        "01", "Find a hand",
        "Tap 1–5 cards, then Play hand. Pairs, flushes and straights are your friends. The preview shows the exact score."
      )
      rule(
        "02", "Make it count",
        "Base Chips + scoring card values, multiplied by Mult, rounded down to whole points. Only cards forming the poker hand contribute: a stray Ace beside a pair does not score."
      )
      rule(
        "03", "Beat the house",
        "Reach the target in 4 hands. Use 3 discards to replace up to 5 selected cards at once. Unplayed cards stay in your hand."
      )
      rule(
        "04", "Collect good fortune",
        "Clear a blind to earn $5 + your ante + unused hands. Buy charms in the cabinet; all their effects stack. Win all 9 blinds across 3 antes."
      )
      Ornament(text: "The hand book")
      ForEach(HandKind.allCases.reversed(), id: \.rawValue) { kind in
        VStack(alignment: .leading, spacing: 5) {
          HStack {
            Text(kind.name).font(.system(size: 15, weight: .medium, design: .serif))
            Spacer()
            Text("\(kind.chips) × \(kind.mult)").font(
              .system(size: 13, weight: .semibold, design: .serif)
            ).monospacedDigit().foregroundStyle(Palette.gold)
          }
          Text(kind.guide).font(.system(size: 12)).foregroundStyle(Palette.muted)
        }
      }
      Text(
        "Aces score 11 Chips, faces score 10, other cards their rank. Aces can be high or low in a straight. Each blind uses a fresh 52-card deck. No real money, accounts or online services."
      )
      .font(.system(size: 12)).foregroundStyle(Palette.muted).lineSpacing(4)
      GoldButton(title: "I'm feeling lucky", action: dismiss)
    }
  }

  private func rule(_ number: String, _ title: String, _ text: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
      Text(number).font(.system(size: 23, design: .serif)).italic().foregroundStyle(Palette.gold)
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.system(size: 19, design: .serif))
        Text(text).font(.system(size: 13)).foregroundStyle(Palette.muted).lineSpacing(4)
      }
    }
  }
}
