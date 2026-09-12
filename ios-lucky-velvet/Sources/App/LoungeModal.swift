import SwiftUI

struct LoungeModal: View {
  @Bindable var game: GameStore
  let sheet: LoungeSheet
  let dismiss: () -> Void
  let home: () -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var revealed = false
  var body: some View {
    ZStack {
      VelvetBackground()
      ScrollView {
        VStack(spacing: 24) {
          HStack {
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
      }
  }

  private var score: some View {
    VStack(spacing: 22) {
      if let score = game.lastScore {
        Eyebrow(text: "A hand well played")
        Text(score.hand.kind.name).font(.system(size: 38, design: .serif)).multilineTextAlignment(
          .center)
        HStack(spacing: 7) {
          ForEach(score.hand.scoringCards) { card in
            PlayingCard(card: card).frame(maxWidth: 63)
          }
        }.frame(height: 91).opacity(revealed ? 1 : 0).offset(y: revealed ? 0 : 12)
        Panel {
          VStack(spacing: 16) {
            ForEach(Array(score.lines.enumerated()), id: \.element.id) { index, line in
              HStack {
                Text(line.name).foregroundStyle(Palette.muted)
                Spacer()
                Text(line.effect).fontWeight(.semibold)
              }.font(.system(size: 13, design: .rounded))
                .opacity(revealed ? 1 : 0)
                .animation(
                  reduceMotion ? nil : .easeOut(duration: 0.35).delay(Double(index) * 0.10),
                  value: revealed)
            }
            Divider().overlay(Palette.gold.opacity(0.3))
            HStack {
              VStack(spacing: 5) {
                Text("\(score.chips)").font(.system(size: 32, weight: .medium, design: .rounded))
                Eyebrow(text: "Chips")
              }.frame(maxWidth: .infinity)
              Text("×").font(.system(size: 26, design: .serif)).foregroundStyle(Palette.gold)
              VStack(spacing: 5) {
                Text(score.mult.formatted()).font(
                  .system(size: 32, weight: .medium, design: .rounded))
                Eyebrow(text: "Mult")
              }.frame(maxWidth: .infinity)
            }
          }
        }
        Text("+\(score.total.formatted())").font(
          .system(size: 57, weight: .medium, design: .rounded)
        )
        .foregroundStyle(Palette.gold).contentTransition(.numericText())
        .scaleEffect(revealed ? 1 : 0.85)
        Text(
          game.run.phase == .shop || game.run.phase == .won
            ? "BLIND CLEARED"
            : "\(game.run.score.formatted()) / \(game.run.target.formatted()) IN THIS BLIND"
        )
        .font(.system(size: 11, weight: .bold)).tracking(2).foregroundStyle(Palette.muted)
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
      Text("Take a breath.").font(.system(size: 42, design: .serif))
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
      Text("Your lucky little things.").font(.system(size: 32, design: .serif))
      Text(
        "Chips and +Mult add together first. Then every ×Mult stacks. Up to five charms travel with you."
      )
      .font(.system(size: 14)).foregroundStyle(Palette.muted).lineSpacing(4)
      ForEach(game.run.charms) { charm in
        Panel {
          HStack(spacing: 13) {
            CharmArt(charm: charm).frame(width: 80, height: 80)
            VStack(alignment: .leading, spacing: 6) {
              Text(charm.name).font(.system(size: 21, design: .serif))
              Text(charm.detail).font(.system(size: 13)).foregroundStyle(Palette.muted)
              if game.run.phase == .shop {
                Button("Sell for $2") {
                  game.run.sell(charm)
                  game.save()
                }
                .font(.system(size: 13, weight: .bold)).frame(minHeight: 35)
              }
            }
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
      Text("Play your cards right.").font(.system(size: 34, design: .serif))
      rule(
        "01", "Find a hand",
        "Tap 1–5 cards, then Play hand. Pairs, flushes and straights are your friends. The preview shows the exact score."
      )
      rule(
        "02", "Make it count",
        "Base Chips + scoring card values, multiplied by Mult. Only cards forming the poker hand contribute: a stray Ace beside a pair does not score."
      )
      rule(
        "03", "Beat the house",
        "Reach the target in 4 hands. Use 3 discards to replace up to 5 selected cards at once. Unplayed cards stay in your hand."
      )
      rule(
        "04", "Collect good fortune",
        "Clear a blind to earn $5 + your ante + unused hands. Buy charms in the cabinet; all their effects stack. Win all 9 blinds across 3 antes."
      )
      Text("The hand book").font(.system(size: 27, design: .serif))
      ForEach(HandKind.allCases.reversed(), id: \.rawValue) { kind in
        VStack(alignment: .leading, spacing: 5) {
          HStack {
            Text(kind.name).font(.system(size: 15, weight: .medium, design: .serif))
            Spacer()
            Text("\(kind.chips) × \(kind.mult)").font(
              .system(size: 13, weight: .bold, design: .rounded)
            ).foregroundStyle(Palette.gold)
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
      Text(number).font(.system(size: 23, design: .serif)).foregroundStyle(Palette.gold)
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.system(size: 19, design: .serif))
        Text(text).font(.system(size: 13)).foregroundStyle(Palette.muted).lineSpacing(4)
      }
    }
  }
}
