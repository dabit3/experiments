import SwiftUI

struct RootView: View {
  @EnvironmentObject var store: GameStore
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ZStack {
      PaperBackground()
      if store.home {
        TitleView()
      } else if let run = store.archive.run {
        VStack(spacing: 0) {
          toolbar(run)
          switch run.stage {
          case .map: MapView(run: run)
          case .battle: BattleView(run: run)
          case .reward: RewardView(run: run)
          case .rest: RestView(run: run)
          case .shop: ShopView(run: run)
          case .victory, .defeat: ResultView(run: run)
          }
        }
      }
      if store.paused { pauseOverlay }
    }
    .foregroundStyle(Ink.paper)
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: store.archive.run?.stage)
    .sheet(isPresented: $store.rules) { RulesView() }
    .sheet(isPresented: $store.deckOpen) { DeckView() }
  }

  private func toolbar(_ run: Run) -> some View {
    HStack(spacing: 10) {
      Text("PAPER RELICS").font(.system(size: 11, weight: .semibold)).tracking(2.5)
      Spacer()
      Button {
        store.deckOpen = true
      } label: {
        Label("\(run.deck.count)", systemImage: "rectangle.stack")
          .font(.system(size: 13))
          .frame(minWidth: 44, minHeight: 44)
      }.accessibilityLabel("View deck")
      Button {
        store.paused = true
      } label: {
        Image(systemName: "pause").font(.system(size: 15)).frame(width: 44, height: 44)
          .overlay(Circle().stroke(Ink.copper.opacity(0.3), lineWidth: 1).padding(5))
      }.accessibilityLabel("Pause")
    }
    .foregroundStyle(Ink.copper)
    .padding(.horizontal, 24)
    .padding(.top, 4)
  }

  private var pauseOverlay: some View {
    ZStack {
      Ink.deep.opacity(0.95).ignoresSafeArea()
      VStack(spacing: 24) {
        Image(systemName: "moon").font(.system(size: 44, weight: .ultraLight)).foregroundStyle(
          Ink.copper)
        Text("An intermission").font(Ink.serif(32))
        Text("Your story is safely saved.").font(.system(size: 15)).foregroundStyle(Ink.faded)
        PrimaryButton(title: "Resume story", symbol: "play.fill") { store.paused = false }
        Button("How to play") { store.rules = true }.frame(minHeight: 44)
        Button {
          store.archive.sound.toggle()
          store.save()
        } label: {
          Label(
            store.archive.sound ? "Sound on" : "Sound off",
            systemImage: store.archive.sound ? "speaker.wave.2" : "speaker.slash")
        }.frame(minHeight: 44)
        Button("Save & return to title") {
          store.save()
          store.paused = false
          store.home = true
        }.frame(minHeight: 44).foregroundStyle(Ink.copper)
      }.padding(32)
    }
  }
}

struct PrimaryButton: View {
  var title: String
  var symbol = "arrow.right"
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack {
        Spacer()
        Text(title).font(.system(size: 16, weight: .semibold))
        Spacer()
        Image(systemName: symbol).font(.system(size: 13, weight: .semibold))
      }
      .padding(.horizontal, 20).frame(height: 54)
      .foregroundStyle(Ink.deep)
      .background(Ink.paper, in: RoundedRectangle(cornerRadius: 14))
      .overlay(RoundedRectangle(cornerRadius: 14).stroke(Ink.copper, lineWidth: 1))
    }.buttonStyle(.plain)
  }
}

struct Eyebrow: View {
  var text: String
  var body: some View {
    Text(text.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(2.7)
      .foregroundStyle(Ink.copper)
  }
}

struct TitleView: View {
  @EnvironmentObject var store: GameStore
  private var canContinue: Bool {
    guard let run = store.archive.run else { return false }
    return run.stage != .victory && run.stage != .defeat
  }

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 17) {
          Eyebrow(text: "A pocket paper theater").padding(.top, 26)
          Spacer(minLength: 0)
          EnemyArt(kind: .moth).frame(height: min(geometry.size.height * 0.34, 280))
            .padding(.horizontal, 25)
          VStack(spacing: 1) {
            Text("Paper").font(Ink.serif(58))
            Text("Relics").font(Ink.serif(66)).foregroundStyle(Ink.copper)
          }.lineSpacing(-10)
          Flourish().frame(width: 126).padding(.vertical, 1)
          Text("Every card, a small rebellion.").font(Ink.serif(17)).italic().foregroundStyle(
            Ink.faded)
          Text("Build a deck. Break the strings.\nRewrite the final act.").font(.system(size: 14))
            .lineSpacing(5)
            .multilineTextAlignment(.center).foregroundStyle(Ink.faded)
          Spacer(minLength: 6)
          VStack(spacing: 10) {
            PrimaryButton(title: canContinue ? "Continue your story" : "Enter the theater") {
              if canContinue { store.home = false } else { store.start() }
            }
            Button("The art of playing") { store.rules = true }
              .font(.system(size: 13)).foregroundStyle(Ink.copper).frame(height: 44)
          }.padding(.horizontal, 32)
          HStack(spacing: 26) {
            Label("\(store.archive.wins) endings rewritten", systemImage: "crown")
            if store.archive.best > 0 { Text("BEST \(store.archive.best)") }
          }
          .font(.system(size: 10, weight: .medium)).foregroundStyle(Ink.faded.opacity(0.7))
          .padding(.bottom, 20)
        }
        .frame(minHeight: geometry.size.height)
      }.scrollIndicators(.hidden)
    }
  }
}

struct MapView: View {
  @EnvironmentObject var store: GameStore
  var run: Run

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        HStack {
          Eyebrow(text: "Chapter \(run.step + 1) of 7")
          Spacer()
          Label("\(run.gold)", systemImage: "circle").foregroundStyle(Ink.copper)
        }.font(.system(size: 13))
        VStack(alignment: .leading, spacing: 9) {
          Text(run.step == 6 ? "The final curtain" : "A story in\nseven folds.").font(Ink.serif(38))
          Text(
            run.step == 6
              ? "The String Queen awaits. Make your ending."
              : "Choose a path through the paper theater."
          )
          .font(.system(size: 14)).foregroundStyle(Ink.faded)
        }
        HStack(spacing: 0) {
          ForEach(0..<7) { index in
            if index > 0 {
              Rectangle().fill(index <= run.step ? Ink.copper : Ink.copper.opacity(0.2)).frame(
                height: 1)
            }
            Text(index < run.step ? "✓" : "\(index + 1)")
              .font(.system(size: 11, weight: .bold))
              .frame(width: 30, height: 30)
              .background(index == run.step ? Ink.copper : Ink.green.opacity(0.4), in: Circle())
              .foregroundStyle(index == run.step ? Ink.deep : Ink.paper)
              .overlay(Circle().stroke(Ink.copper.opacity(0.4), lineWidth: 1))
          }
        }.padding(.vertical, 8)
        ForEach(run.routes) { route in
          Button {
            store.act { $0.chooseRoute(route.id) }
          } label: {
            HStack(spacing: 18) {
              ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Ink.copper.opacity(0.12)).frame(
                  width: 62, height: 76)
                Image(systemName: route.symbol).font(.system(size: 25, weight: .ultraLight))
                  .foregroundStyle(Ink.copper)
              }
              VStack(alignment: .leading, spacing: 8) {
                Text(route.title).font(Ink.serif(20)).foregroundStyle(Ink.paper)
                Text(route.subtitle).font(.system(size: 12)).foregroundStyle(Ink.faded)
              }
              Spacer(minLength: 0)
              Image(systemName: "arrow.up.right").font(.system(size: 13)).foregroundStyle(
                Ink.copper)
            }
            .padding(17)
            .background(Ink.paper.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
            .overlay(
              RoundedRectangle(cornerRadius: 20).stroke(Ink.copper.opacity(0.3), lineWidth: 1))
          }.buttonStyle(.plain)
        }
        HStack {
          Label("\(run.hp) / \(run.maxHP)", systemImage: "heart.fill").foregroundStyle(Ink.red)
          Spacer()
          Text("\(run.deck.count) cards in your deck").foregroundStyle(Ink.faded)
        }.font(.system(size: 13))
        Flourish()
        VStack(alignment: .leading, spacing: 14) {
          Eyebrow(text: "Your keepsakes")
          ForEach(run.relics, id: \.self) { relic in RelicRow(relic: relic) }
        }
      }.padding(26)
    }.scrollIndicators(.hidden)
  }
}

struct BattleView: View {
  @EnvironmentObject var store: GameStore
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  var run: Run

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 12) {
          if let enemy = run.enemy {
            HStack {
              Eyebrow(text: enemy.kind == .queen ? "The finale" : "Chapter \(run.step + 1) · Duel")
              Spacer()
              Text("TURN \(enemy.turn + 1)").font(.system(size: 10, weight: .semibold)).tracking(2)
                .foregroundStyle(Ink.faded)
            }.padding(.horizontal, 26)
            HStack(spacing: 8) {
              Image(systemName: enemy.intent.damage == 0 ? "shield" : "bolt.fill")
              Text(enemy.intent.label).font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(enemy.intent.damage == 0 ? Ink.paper : Ink.copper)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Ink.copper.opacity(0.1), in: Capsule())
            EnemyArt(kind: enemy.kind)
              .frame(height: max(132, min(205, geometry.size.height * 0.26)))
              .id(enemy.kind)
            VStack(spacing: 8) {
              Text(enemy.kind.title).font(Ink.serif(25))
              HStack(spacing: 10) {
                HealthBar(value: enemy.hp, max: enemy.maxHP, color: Ink.copper).frame(width: 130)
                Text("\(enemy.hp) / \(enemy.maxHP)").font(.system(size: 11, weight: .medium))
                  .monospacedDigit()
              }
              HStack(spacing: 12) {
                if enemy.block > 0 { Label("\(enemy.block) block", systemImage: "shield") }
                if enemy.poison > 0 { Label("\(enemy.poison) poison", systemImage: "drop") }
                if enemy.weak > 0 { Text("\(enemy.weak) weak") }
              }.font(.system(size: 11)).foregroundStyle(Ink.faded).frame(height: 12)
            }
          }
          HStack(spacing: 12) {
            Label("\(run.hp)/\(run.maxHP)", systemImage: "heart.fill").foregroundStyle(Ink.red)
            Label("\(run.block)", systemImage: "shield.fill").foregroundStyle(Ink.paper)
            if run.weak > 0 { Text("Weak \(run.weak)").foregroundStyle(Ink.copper) }
            if run.strength > 0 { Text("+\(run.strength) STR").foregroundStyle(Ink.copper) }
            Spacer(minLength: 0)
            HStack(spacing: 5) {
              Image(systemName: "sparkle")
              Text("\(run.energy)").font(.system(size: 22, weight: .semibold, design: .serif))
              Text("ENERGY").font(.system(size: 8, weight: .bold)).tracking(1)
            }.foregroundStyle(Ink.copper)
          }
          .font(.system(size: 13, weight: .medium))
          .padding(.horizontal, 16).padding(.vertical, 12)
          .background(Ink.paper.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
          .padding(.horizontal, 22)
          Text(run.lastMessage).font(.system(size: 11)).foregroundStyle(Ink.faded)
            .lineLimit(2).multilineTextAlignment(.center).frame(height: 28).padding(.horizontal, 22)
            .accessibilityIdentifier("battleMessage")
          ScrollView(.horizontal) {
            HStack(spacing: 11) {
              ForEach(run.hand) { card in
                Button {
                  store.play(card)
                } label: {
                  CardFace(kind: card.kind, affordable: run.energy >= card.kind.cost)
                }
                .buttonStyle(CardPressStyle())
                .accessibilityIdentifier("card-\(card.id)")
                .transition(reduceMotion ? .identity : .scale(scale: 0.8).combined(with: .opacity))
              }
            }
            .padding(.horizontal, 22).padding(.bottom, 7)
            .animation(reduceMotion ? nil : .spring(duration: 0.25), value: run.hand)
          }.scrollIndicators(.hidden)
          HStack {
            VStack(alignment: .leading, spacing: 6) {
              Text("Tap to play · swipe hand").foregroundStyle(Ink.faded)
              Text(
                "Draw \(run.drawPile.count)  /  Discard \(run.discard.count)  /  Exhaust \(run.exhaust.count)"
              )
              .foregroundStyle(Ink.copper.opacity(0.85))
            }.font(.system(size: 10))
            Spacer()
            Button {
              store.act { $0.endTurn() }
              store.chime(frequency: 330)
            } label: {
              HStack(spacing: 8) {
                Text("End turn")
                Image(systemName: "arrow.right")
              }
              .font(.system(size: 13, weight: .semibold))
              .padding(.horizontal, 17).frame(height: 48)
              .background(Ink.copper, in: RoundedRectangle(cornerRadius: 12))
              .foregroundStyle(Ink.deep)
            }.accessibilityIdentifier("endTurn")
          }.padding(.horizontal, 22).padding(.bottom, 16)
        }.padding(.top, 9)
      }.scrollIndicators(.hidden)
    }
  }
}

struct CardPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.scaleEffect(configuration.isPressed ? 0.96 : 1)
  }
}

struct HealthBar: View {
  var value: Int
  var max: Int
  var color: Color
  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule().fill(color.opacity(0.18))
        Capsule().fill(color).frame(
          width: geometry.size.width * CGFloat(value) / CGFloat(Swift.max(1, max)))
      }
    }.frame(height: 4)
  }
}

struct RelicRow: View {
  var relic: Relic
  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: relic.symbol).font(.system(size: 22, weight: .light)).frame(width: 32)
        .foregroundStyle(Ink.copper)
      VStack(alignment: .leading, spacing: 5) {
        Text(relic.title).font(Ink.serif(17))
        Text(relic.text).font(.system(size: 12)).foregroundStyle(Ink.faded)
      }
    }
  }
}

struct RewardView: View {
  @EnvironmentObject var store: GameStore
  var run: Run
  var body: some View {
    ScrollView {
      VStack(spacing: 23) {
        Eyebrow(text: "The spoils of your story").padding(.top, 24)
        Image(systemName: "sparkles").font(.system(size: 46, weight: .ultraLight)).foregroundStyle(
          Ink.copper)
        Text("A new page.").font(Ink.serif(38))
        Text("Choose one art to add to your deck.").font(.system(size: 14)).foregroundStyle(
          Ink.faded)
        HStack(spacing: 24) {
          Label("+\(run.enemy?.kind == .stag ? 40 : 25) gold", systemImage: "circle")
          Label("Spool healed 4", systemImage: "heart")
        }.font(.system(size: 12)).foregroundStyle(Ink.copper)
        VStack(spacing: 12) {
          ForEach(run.rewards, id: \.self) { kind in
            Button {
              store.act { $0.claimReward(kind) }
            } label: {
              RewardRow(kind: kind, trailing: "Take")
            }.buttonStyle(.plain)
          }
        }
        if let relic = run.offeredRelic {
          VStack(alignment: .leading, spacing: 13) {
            Eyebrow(text: "A keepsake, yours to keep")
            RelicRow(relic: relic)
          }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
            .background(Ink.copper.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        }
        Button("Skip card & continue") { store.act { $0.claimReward(nil) } }
          .font(.system(size: 13)).foregroundStyle(Ink.faded).frame(height: 44)
      }.padding(26)
    }.scrollIndicators(.hidden)
  }
}

struct RewardRow: View {
  var kind: CardKind
  var trailing: String
  var body: some View {
    HStack(spacing: 13) {
      ZStack(alignment: .bottomTrailing) {
        Image(systemName: kind.symbol).font(.system(size: 26, weight: .ultraLight)).frame(
          width: 44, height: 52)
        Text("\(kind.cost)").font(.system(size: 10, weight: .bold)).frame(width: 18, height: 18)
          .background(Ink.forest, in: Circle()).foregroundStyle(Ink.paper)
      }
      VStack(alignment: .leading, spacing: 7) {
        Text(kind.title).font(Ink.serif(18))
        Text(kind.text.replacingOccurrences(of: "\n", with: " ")).font(.system(size: 12)).fixedSize(
          horizontal: false, vertical: true)
      }
      Spacer(minLength: 0)
      Text(trailing).font(.system(size: 11, weight: .semibold))
    }
    .foregroundStyle(Ink.forest).padding(16)
    .frame(maxWidth: .infinity, minHeight: 91, alignment: .leading)
    .background(Ink.paper, in: RoundedRectangle(cornerRadius: 13))
  }
}

struct RestView: View {
  @EnvironmentObject var store: GameStore
  var run: Run
  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        Eyebrow(text: "A quiet interlude").padding(.top, 32)
        Image(systemName: "leaf").font(.system(size: 82, weight: .ultraLight)).foregroundStyle(
          Ink.copper
        )
        .frame(height: 160)
        .background(Circle().stroke(Ink.copper.opacity(0.2), lineWidth: 1))
        Text("Mend the edges.").font(Ink.serif(34))
        Text("The world can wait for one small breath.").font(Ink.serif(16)).italic()
          .foregroundStyle(Ink.faded)
        Text("\(run.hp) / \(run.maxHP) health").font(.system(size: 15)).foregroundStyle(Ink.red)
        PrimaryButton(title: "Rest · recover 24 health", symbol: "heart") {
          store.act { $0.rest(mend: true) }
        }
        Button {
          store.act { $0.rest(mend: false) }
        } label: {
          VStack(spacing: 7) {
            Text("Rebind · gain 8 maximum health").font(.system(size: 14, weight: .semibold))
            Text("Also restores 8 health").font(.system(size: 12)).foregroundStyle(Ink.faded)
          }.frame(maxWidth: .infinity).padding(17)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Ink.copper.opacity(0.3)))
        }.foregroundStyle(Ink.copper)
      }.padding(28)
    }
  }
}

struct ShopView: View {
  @EnvironmentObject var store: GameStore
  var run: Run
  var body: some View {
    ScrollView {
      VStack(spacing: 22) {
        Eyebrow(text: "The Night Market").padding(.top, 25)
        Text("Rare little wonders.").font(Ink.serif(32))
        Label("\(run.gold) gold to spend", systemImage: "circle").font(.system(size: 14))
          .foregroundStyle(Ink.copper)
        ForEach([CardKind.sever, .sanctuary, .eclipse], id: \.self) { kind in
          Button {
            store.act { $0.buy(kind) }
          } label: {
            RewardRow(kind: kind, trailing: "45 gold")
          }
          .disabled(run.gold < 45).opacity(run.gold >= 45 ? 1 : 0.5)
        }
        Text(run.lastMessage).font(.system(size: 13)).foregroundStyle(Ink.faded)
        PrimaryButton(title: "Continue your story") { store.act { $0.leaveShop() } }
      }.padding(26)
    }
  }
}

struct ResultView: View {
  @EnvironmentObject var store: GameStore
  var run: Run
  private var won: Bool { run.stage == .victory }
  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Eyebrow(text: won ? "An ending, rewritten" : "A story, unfinished").padding(.top, 16)
        EnemyArt(kind: won ? .moth : .queen).frame(height: 185)
        Text(won ? "The strings\nare broken." : "The curtain\nfalls.").font(Ink.serif(40))
          .multilineTextAlignment(.center)
        Text(won ? "The theater belongs to you now." : "Every torn page teaches a new art.")
          .font(Ink.serif(16)).italic().foregroundStyle(Ink.faded)
        Flourish().frame(width: 170)
        HStack(spacing: 0) {
          resultStat("\(run.score)", label: "RUN SCORE")
          resultStat("\(run.battles)", label: "DUELS WON")
          resultStat("\(run.turns)", label: "TURNS")
        }
        Text("PERSONAL BEST  \(store.archive.best)").font(.system(size: 10, weight: .semibold))
          .tracking(2).foregroundStyle(Ink.copper)
        PrimaryButton(title: "Begin another story", symbol: "arrow.clockwise") { store.start() }
        HStack {
          ShareLink(
            item:
              "I \(won ? "rewrote the ending" : "fought the strings") in Paper Relics: \(run.score) points, \(run.battles) duels won in \(run.turns) turns."
          ) {
            Label("Share story", systemImage: "square.and.arrow.up")
          }.frame(maxWidth: .infinity, minHeight: 44)
          Button("Return to title") { store.home = true }.frame(maxWidth: .infinity, minHeight: 44)
        }.font(.system(size: 12)).foregroundStyle(Ink.copper)
      }.padding(28)
    }.scrollIndicators(.hidden)
  }
  private func resultStat(_ value: String, label: String) -> some View {
    VStack(spacing: 8) {
      Text(value).font(Ink.serif(29))
      Text(label).font(.system(size: 8, weight: .bold)).tracking(1.4).foregroundStyle(Ink.faded)
    }.frame(maxWidth: .infinity)
  }
}

struct RulesView: View {
  @EnvironmentObject var store: GameStore
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    ZStack {
      PaperBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 23) {
          Eyebrow(text: "The art of playing")
          Text("Read. Fold.\nStrike.").font(Ink.serif(42))
          rule(
            "01", "Read the intent",
            "The badge above your foe shows their next action. Block prevents damage, but expires at the start of your next turn."
          )
          rule(
            "02", "Play your hand",
            "Tap a card to play it immediately. Swipe to see the rest. Each turn gives 3 energy and 5 cards; the number on a card is its cost."
          )
          rule(
            "03", "Turn the page",
            "End turn lets the enemy act. Unplayed cards are discarded. An empty draw pile shuffles your discard. Exhausted cards stay out until the next battle."
          )
          rule(
            "04", "Make the ink work",
            "Poison deals its amount through block before the foe acts, then drops by 1. Weak reduces attacks by 25% (rounded down); it counts down after acting. Strength adds damage to each hit."
          )
          rule(
            "05", "Rewrite the ending",
            "Choose routes, collect one reward per duel, and heal or shop between fights. Defeat the String Queen in chapter 7. Your run saves after every action."
          )
          rule(
            "06", "Keep a better story",
            "Score = 100 per duel + 5 per remaining health + gold + 500 for victory. Relics work automatically. Best score and wins stay on this device."
          )
          PrimaryButton(title: "Let the story begin", symbol: "sparkle") {
            store.archive.hasReadRules = true
            store.save()
            dismiss()
          }
        }.padding(28).padding(.vertical, 15)
      }
    }.foregroundStyle(Ink.paper).presentationDragIndicator(.visible)
  }
  private func rule(_ number: String, _ title: String, _ text: String) -> some View {
    HStack(alignment: .top, spacing: 15) {
      Text(number).font(Ink.serif(19)).foregroundStyle(Ink.copper)
      VStack(alignment: .leading, spacing: 7) {
        Text(title).font(Ink.serif(20))
        Text(text).font(.system(size: 14)).lineSpacing(4).foregroundStyle(Ink.faded)
      }
    }
  }
}

struct DeckView: View {
  @EnvironmentObject var store: GameStore
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    ZStack {
      PaperBackground()
      ScrollView {
        VStack(spacing: 20) {
          HStack {
            Text("Your collected arts").font(Ink.serif(26))
            Spacer()
            Button {
              dismiss()
            } label: {
              Image(systemName: "xmark").frame(width: 44, height: 44)
            }.accessibilityLabel("Close deck")
          }
          Text("A permanent deck. Combat piles reset each duel.").font(.system(size: 12))
            .foregroundStyle(Ink.faded)
          if let run = store.archive.run {
            ForEach(
              CardKind.allCases.filter { kind in run.deck.contains { $0.kind == kind } }, id: \.self
            ) { kind in
              RewardRow(kind: kind, trailing: "×\(run.deck.filter { $0.kind == kind }.count)")
            }
          }
        }.padding(25)
      }
    }.foregroundStyle(Ink.paper).presentationDragIndicator(.visible)
  }
}
