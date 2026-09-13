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
          if run.stage != .victory && run.stage != .defeat { toolbar(run) }
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
    .foregroundStyle(Ink.white)
    .animation(reduceMotion ? nil : .linear(duration: 0.12), value: store.archive.run?.stage)
    .sheet(isPresented: $store.rules) { RulesView() }
    .sheet(isPresented: $store.deckOpen) { DeckView() }
  }

  private func toolbar(_ run: Run) -> some View {
    HStack(spacing: 6) {
      PixelText("PAPER RELICS", px: 1.5, color: Ink.gold, shadow: Ink.black)
      Spacer()
      Button {
        store.deckOpen = true
      } label: {
        HStack(spacing: 6) {
          SpriteView(Pix.cards, px: 2)
          PixelText("\(run.deck.count)", px: 2, color: Ink.white)
        }
        .frame(minWidth: 44, minHeight: 44)
      }.accessibilityLabel("View deck")
      Button {
        store.paused = true
      } label: {
        SpriteView(Pix.pause, px: 2).frame(width: 44, height: 44)
      }.accessibilityLabel("Pause")
    }
    .padding(.horizontal, 24)
    .padding(.top, 2)
  }

  private var pauseOverlay: some View {
    ZStack {
      Ink.black.opacity(0.85).ignoresSafeArea()
      Window {
        VStack(spacing: 18) {
          PixelText("PAUSED", px: 4, color: Ink.gold, shadow: Ink.maroon)
          PixelText("YOUR STORY IS SAVED", px: 1.5, color: Ink.silver)
          PrimaryButton(title: "RESUME") { store.paused = false }
          MenuButton(title: "HOW TO PLAY") { store.rules = true }
          MenuButton(
            title: store.archive.sound ? "SOUND: ON" : "SOUND: OFF",
            icon: store.archive.sound ? Pix.speaker : Pix.speakerOff
          ) {
            store.archive.sound.toggle()
            store.save()
          }
          MenuButton(title: "SAVE & QUIT TO TITLE", tone: Ink.rose) {
            store.save()
            store.paused = false
            store.home = true
          }
        }
        .padding(24)
      }
      .padding(28)
    }
  }
}

struct BevelButtonStyle: ButtonStyle {
  var fill: Color
  var shade: Color
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(
        ZStack(alignment: .top) {
          fill
          Ink.white.opacity(0.45).frame(height: 3)
        }
      )
      .overlay(Rectangle().stroke(Ink.black, lineWidth: 2))
      .background(alignment: .bottom) {
        if !configuration.isPressed {
          shade.frame(height: 4).offset(y: 4)
        }
      }
      .background(alignment: .bottom) {
        if !configuration.isPressed { Ink.black.frame(height: 4).offset(y: 6) }
      }
      .offset(y: configuration.isPressed ? 4 : 0)
      .animation(.linear(duration: 0.05), value: configuration.isPressed)
  }
}

struct PrimaryButton: View {
  var title: String
  var symbol = ""
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      PixelText(title.uppercased(), px: 2, color: Ink.white, shadow: Ink.black)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .leading) {
          Blink { PixelText("▶", px: 2, color: Ink.white) }.padding(.leading, 14)
        }
        .padding(.horizontal, 20).frame(height: 54)
    }.buttonStyle(BevelButtonStyle(fill: Ink.green, shade: Ink.navy))
      .padding(.bottom, 6)
  }
}

struct MenuButton: View {
  var title: String
  var icon: Sprite? = nil
  var tone: Color = Ink.white
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        if let icon { SpriteView(icon, px: 2) }
        PixelText(title.uppercased(), px: 1.5, color: tone)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 16).frame(maxWidth: .infinity, minHeight: 46)
    }.buttonStyle(BevelButtonStyle(fill: Ink.navy, shade: Ink.black))
      .padding(.bottom, 6)
  }
}

struct TitleView: View {
  @EnvironmentObject var store: GameStore
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var lit = false
  private var canContinue: Bool {
    guard let run = store.archive.run else { return false }
    return run.stage != .victory && run.stage != .defeat
  }

  var body: some View {
    GeometryReader { geometry in
      let compact = geometry.size.height < 700
      ScrollView {
        VStack(spacing: compact ? 10 : 16) {
          Eyebrow(text: "A pocket paper theater").padding(.top, compact ? 12 : 22)
          Spacer(minLength: 0)
          Proscenium(kind: .moth)
            .frame(height: min(geometry.size.height * (compact ? 0.3 : 0.36), 320))
            .padding(.horizontal, 28)
            .opacity(lit || reduceMotion ? 1 : 0)
          VStack(spacing: compact ? 4 : 8) {
            PixelText("PAPER", px: compact ? 5 : 6, color: Ink.white, shadow: Ink.navy)
            PixelText("RELICS", px: compact ? 6 : 7, color: Ink.gold, shadow: Ink.maroon)
          }
          .padding(.top, compact ? 6 : 12)
          PixelRule().frame(width: 160)
          PixelText("EVERY CARD, A SMALL REBELLION", px: 1.5, color: Ink.mint)
          if !compact {
            PixelText(
              "BUILD A DECK. BREAK THE STRINGS.\nREWRITE THE FINAL ACT.", px: 1.5,
              color: Ink.silver,
              alignment: .center
            ).padding(.top, 4)
          }
          Spacer(minLength: 8)
          Blink(period: 0.7) { PixelText("- PRESS START -", px: 2, color: Ink.white) }
            .padding(.bottom, 4)
          VStack(spacing: 10) {
            PrimaryButton(title: canContinue ? "Continue" : "Start") {
              if canContinue { store.home = false } else { store.start() }
            }
            MenuButton(title: "How to play") { store.rules = true }
          }.padding(.horizontal, 32)
          HStack(spacing: 22) {
            HStack(spacing: 6) {
              SpriteView(Pix.crown, px: 1.5)
              PixelText("WINS \(store.archive.wins)", px: 1.5, color: Ink.silver)
            }
            if store.archive.best > 0 {
              PixelText("BEST \(arcade(store.archive.best))", px: 1.5, color: Ink.gold)
            }
          }
          .padding(.bottom, 18)
        }
        .frame(minHeight: geometry.size.height)
      }.scrollIndicators(.hidden)
    }
    .onAppear {
      withAnimation(.linear(duration: 0.3)) { lit = true }
    }
  }
}

func arcade(_ score: Int) -> String {
  String(format: "%06d", max(0, score))
}

struct MapView: View {
  @EnvironmentObject var store: GameStore
  var run: Run

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        HStack {
          Eyebrow(text: "Chapter \(run.step + 1) of 7")
          Spacer()
          GoldLabel(gold: run.gold)
        }
        VStack(alignment: .leading, spacing: 10) {
          PixelText(
            run.step == 6 ? "THE FINAL\nCURTAIN" : "CHOOSE\nYOUR PATH", px: 4, color: Ink.white,
            shadow: Ink.navy)
          Text(
            run.step == 6
              ? "The String Queen awaits. Make your ending."
              : "Pick a door through the paper theater."
          )
          .font(Ink.body(14)).foregroundStyle(Ink.silver)
        }
        HStack(spacing: 0) {
          ForEach(0..<7) { index in
            if index > 0 {
              HStack(spacing: 3) {
                ForEach(0..<3) { _ in
                  Rectangle().fill(index <= run.step ? Ink.gold : Ink.gray).frame(height: 3)
                }
              }
            }
            ZStack {
              Rectangle().fill(
                index == run.step ? Ink.gold : index < run.step ? Ink.green : Ink.navy
              )
              .frame(width: 28, height: 28)
              .overlay(Rectangle().stroke(Ink.white, lineWidth: 2))
              if index == 6 {
                SpriteView(Pix.crown, px: 2)
              } else {
                PixelText(
                  index < run.step ? "✓" : "\(index + 1)", px: 2,
                  color: index == run.step ? Ink.black : Ink.white)
              }
            }
          }
        }.padding(.vertical, 4)
        ForEach(run.routes) { route in
          Button {
            store.act { $0.chooseRoute(route.id) }
          } label: {
            HStack(spacing: 14) {
              ZStack {
                Ink.black
                if let enemy = route.enemy {
                  EnemyArt(kind: enemy).padding(6)
                } else {
                  SceneGlyph(symbol: route.symbol).padding(14)
                }
              }
              .frame(width: 76, height: 76)
              .overlay(Rectangle().stroke(Ink.white, lineWidth: 2))
              VStack(alignment: .leading, spacing: 7) {
                PixelText(route.title.uppercased(), px: 1.5, color: Ink.white, maxWidth: 200)
                Text(route.subtitle).font(Ink.body(13)).foregroundStyle(Ink.silver)
                if route.subtitle.hasPrefix("Elite") || route.subtitle.hasPrefix("Boss") {
                  PixelText(
                    route.subtitle.hasPrefix("Boss") ? "BOSS" : "ELITE", px: 1, color: Ink.white
                  )
                  .padding(.horizontal, 5).padding(.vertical, 3).background(Ink.red)
                }
              }
              Spacer(minLength: 0)
              Blink(period: 0.6) { PixelText("▶", px: 2, color: Ink.gold) }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(WindowButtonStyle())
        }
        HStack {
          HStack(spacing: 6) {
            SpriteView(Pix.heart, px: 2)
            PixelText("\(run.hp)/\(run.maxHP)", px: 2, color: Ink.rose)
          }
          Spacer()
          HStack(spacing: 6) {
            SpriteView(Pix.cards, px: 2)
            PixelText("\(run.deck.count) CARDS", px: 1.5, color: Ink.silver)
          }
        }
        PixelRule()
        VStack(alignment: .leading, spacing: 12) {
          Eyebrow(text: "Relics")
          ForEach(run.relics, id: \.self) { relic in RelicRow(relic: relic) }
        }
      }.padding(24)
    }.scrollIndicators(.hidden)
  }
}

struct WindowButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(configuration.isPressed ? Ink.blue : Ink.navy)
      .overlay(PixelFrame(color: configuration.isPressed ? Ink.gold : Ink.white))
  }
}

struct GoldLabel: View {
  var gold: Int
  var body: some View {
    HStack(spacing: 6) {
      SpriteView(Pix.coin, px: 2)
      PixelText("\(gold)", px: 2, color: Ink.gold)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(gold) gold")
  }
}

struct BattleView: View {
  @EnvironmentObject var store: GameStore
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  var run: Run

  var body: some View {
    GeometryReader { geometry in
      let compact = geometry.size.height < 760
      ScrollView {
        VStack(spacing: compact ? 8 : 12) {
          if let enemy = run.enemy {
            HStack {
              Eyebrow(text: enemy.kind == .queen ? "The finale" : "Chapter \(run.step + 1) · Duel")
              Spacer()
              PixelText("TURN \(enemy.turn + 1)", px: 1.5, color: Ink.silver)
            }.padding(.horizontal, 26)
            ZStack(alignment: .top) {
              Proscenium(kind: enemy.kind)
                .frame(height: max(150, min(210, geometry.size.height * 0.26)))
                .id(enemy.kind)
                .phaseAnimator([0, 1, 2, 3, 4], trigger: enemy.hp) { content, phase in
                  content
                    .offset(x: reduceMotion || phase == 0 ? 0 : phase % 2 == 1 ? -6 : 6)
                    .brightness(phase == 1 || phase == 3 ? 0.5 : 0)
                } animation: { _ in
                  .linear(duration: 0.05)
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
              IntentTag(intent: enemy.intent)
            }
            .overlay(alignment: .bottomTrailing) {
              if !store.enemyFeedback.isEmpty {
                PixelText(store.enemyFeedback, px: 2, color: Ink.white)
                  .padding(.horizontal, 10).padding(.vertical, 6)
                  .background(Ink.red)
                  .overlay(Rectangle().stroke(Ink.white, lineWidth: 2))
                  .padding(.trailing, 34).padding(.bottom, 24)
                  .transition(.offset(y: 12).combined(with: .opacity))
              }
            }
            VStack(spacing: 8) {
              PixelText(enemy.kind.title.uppercased(), px: compact ? 2 : 2.5, color: Ink.white)
              HStack(spacing: 10) {
                PixelBar(value: enemy.hp, max: enemy.maxHP, color: barColor(enemy.hp, enemy.maxHP))
                  .frame(width: 150)
                PixelText("\(enemy.hp)/\(enemy.maxHP)", px: 1.5, color: Ink.white)
              }
              HStack(spacing: 14) {
                if enemy.block > 0 { status(Pix.shield, "\(enemy.block) BLOCK", Ink.sky) }
                if enemy.poison > 0 { status(Pix.potion, "\(enemy.poison) POISON", Ink.mint) }
                if enemy.weak > 0 { status(Pix.eye, "\(enemy.weak) WEAK", Ink.violet) }
              }.frame(height: 16)
            }
          }
          Window {
            VStack(spacing: 8) {
              HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                  HStack(spacing: 6) {
                    SpriteView(Pix.heart, px: 2)
                    PixelText("\(run.hp)/\(run.maxHP)", px: 2, color: Ink.white)
                    SpriteView(Pix.shield, px: 2).padding(.leading, 6)
                    PixelText("\(run.block)", px: 2, color: Ink.white)
                  }
                  PixelBar(
                    value: run.hp, max: run.maxHP, color: barColor(run.hp, run.maxHP), height: 8
                  )
                  .frame(width: 130)
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                  ZStack {
                    Rectangle().fill(run.energy > 0 ? Ink.gold : Ink.gray)
                    Rectangle().stroke(Ink.black, lineWidth: 2)
                    PixelText("\(run.energy)", px: 3, color: Ink.black)
                  }
                  .frame(width: 36, height: 36)
                  .compositingGroup()
                  .shadow(color: Ink.black, radius: 0, x: 2, y: 2)
                  VStack(alignment: .leading, spacing: 3) {
                    SpriteView(Pix.bolt, px: 1.5)
                    PixelText("ENERGY", px: 1, color: Ink.gold)
                  }
                }
              }
              HStack(spacing: 10) {
                if run.weak > 0 { PixelText("WEAK \(run.weak)", px: 1.5, color: Ink.violet) }
                if run.strength > 0 {
                  PixelText("+\(run.strength) STR", px: 1.5, color: Ink.copper)
                }
                Spacer(minLength: 0)
                PixelText(
                  store.playerFeedback, px: 1.5, color: store.playerHurt ? Ink.rose : Ink.gold)
              }
              .frame(height: 12)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
          }
          .overlay(
            Rectangle().stroke(run.hp * 3 <= run.maxHP ? Ink.red : .clear, lineWidth: 2).padding(3)
          )
          .padding(.horizontal, 22)
          Text(run.lastMessage).font(Ink.body(14)).foregroundStyle(Ink.cream)
            .lineLimit(2).multilineTextAlignment(.center).frame(height: 34).padding(.horizontal, 22)
            .accessibilityIdentifier("battleMessage")
          ScrollViewReader { reader in
            ScrollView(.horizontal) {
              HStack(spacing: 12) {
                Color.clear.frame(width: 1, height: 1).id("handStart")
                ForEach(Array(run.hand.enumerated()), id: \.element.id) { index, card in
                  Button {
                    store.play(card)
                  } label: {
                    CardFace(
                      kind: card.kind, affordable: run.energy >= card.kind.cost,
                      text: run.cardText(card.kind), width: compact ? 118 : 128)
                  }
                  .buttonStyle(CardPressStyle())
                  .id(card.id)
                  .accessibilityIdentifier("card-\(card.id)")
                  .transition(
                    reduceMotion
                      ? .identity
                      : .asymmetric(
                        insertion: .offset(x: 160, y: 40).combined(with: .opacity),
                        removal: .offset(y: -40).combined(with: .opacity)))
                }
              }
              .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 12)
              .animation(reduceMotion ? nil : .linear(duration: 0.14), value: run.hand)
            }.scrollIndicators(.hidden)
              .onChange(of: run.turns) { _, _ in
                reader.scrollTo("handStart", anchor: .leading)
              }
          }
          HStack {
            VStack(alignment: .leading, spacing: 6) {
              PixelText(
                "HAND \(run.hand.count) · DRAW \(run.drawPile.count)", px: 1.5, color: Ink.silver)
              PixelText(
                "DISCARD \(run.discard.count) EXHAUST \(run.exhaust.count)", px: 1.5,
                color: Ink.gold)
            }
            Spacer(minLength: 6)
            Button {
              store.act { $0.endTurn() }
              store.chime(frequency: 330)
            } label: {
              HStack(spacing: 8) {
                PixelText("END TURN", px: 2, color: Ink.white, shadow: Ink.black)
                SpriteView(Pix.arrow, px: 2, tint: Ink.white)
              }
              .padding(.horizontal, 12).frame(height: 46)
            }
            .buttonStyle(BevelButtonStyle(fill: Ink.copper, shade: Ink.maroon))
            .padding(.bottom, 6)
            .accessibilityIdentifier("endTurn")
          }.padding(.horizontal, 22).padding(.bottom, 16)
        }.padding(.top, 6)
      }.scrollIndicators(.hidden)
    }
  }

  private func status(_ icon: Sprite, _ text: String, _ color: Color) -> some View {
    HStack(spacing: 5) {
      SpriteView(icon, px: 1.5)
      PixelText(text, px: 1.5, color: color)
    }
  }
}

func barColor(_ value: Int, _ max: Int) -> Color {
  value * 4 <= max ? Ink.red : value * 2 <= max ? Ink.gold : Ink.leaf
}

struct CardPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.offset(y: configuration.isPressed ? -10 : 0)
      .animation(.linear(duration: 0.06), value: configuration.isPressed)
  }
}

struct RelicRow: View {
  var relic: Relic
  var body: some View {
    HStack(spacing: 14) {
      RelicGlyph(relic: relic).frame(width: 46, height: 46)
      VStack(alignment: .leading, spacing: 6) {
        PixelText(relic.title.uppercased(), px: 1.5, color: Ink.gold)
        Text(relic.text).font(Ink.body(13)).foregroundStyle(Ink.silver)
      }
    }
  }
}

struct CardFan: View {
  var kinds: [CardKind]
  var width: CGFloat
  var unavailableLabel = "NO ENERGY"
  var footer: (CardKind) -> String
  var enabled: (CardKind) -> Bool
  var action: (CardKind) -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var dealt = false
  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      ForEach(Array(kinds.enumerated()), id: \.element) { index, kind in
        Button {
          action(kind)
        } label: {
          VStack(spacing: 10) {
            CardFace(
              kind: kind, affordable: enabled(kind), unavailableLabel: unavailableLabel,
              width: width)
            PixelText(
              footer(kind).uppercased(), px: 1.5, color: enabled(kind) ? Ink.gold : Ink.gray,
              maxWidth: width, alignment: .center
            )
            .frame(height: 30)
          }
        }
        .buttonStyle(CardPressStyle())
        .disabled(!enabled(kind))
        .opacity(dealt || reduceMotion ? 1 : 0)
        .offset(y: dealt || reduceMotion ? 0 : 48)
        .animation(
          reduceMotion ? nil : .linear(duration: 0.12).delay(Double(index) * 0.1), value: dealt)
      }
    }
    .onAppear { dealt = true }
  }
}

struct RewardView: View {
  @EnvironmentObject var store: GameStore
  var run: Run
  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 14) {
          Eyebrow(text: "Victory spoils").padding(.top, 6)
          PixelText("A NEW PAGE", px: 4, color: Ink.gold, shadow: Ink.maroon)
          Text("Choose one card to add to your deck.").font(Ink.body(14)).foregroundStyle(
            Ink.silver)
          HStack(spacing: 22) {
            HStack(spacing: 6) {
              SpriteView(Pix.coin, px: 2)
              PixelText("+\(run.enemy?.kind == .stag ? 40 : 25)", px: 2, color: Ink.gold)
            }
            HStack(spacing: 6) {
              SpriteView(Pix.heart, px: 2)
              PixelText("+4 SPOOL", px: 2, color: Ink.rose)
            }
          }
          CardFan(
            kinds: run.rewards, width: min(118, (geometry.size.width - 104) / 3),
            footer: { _ in "Take" }, enabled: { _ in true }
          ) { kind in
            store.act { $0.claimReward(kind) }
          }.padding(.top, 14).padding(.horizontal, 12)
          if let relic = run.offeredRelic {
            Window {
              VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "New relic")
                RelicRow(relic: relic)
                Text("Yours to keep, even if you skip the card.")
                  .font(Ink.body(12)).foregroundStyle(Ink.silver)
              }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
            }
          }
        }.padding(24)
      }.scrollIndicators(.visible)
        .safeAreaInset(edge: .bottom) {
          Button {
            store.act { $0.claimReward(nil) }
          } label: {
            PixelText("SKIP CARD & CONTINUE", px: 1.5, color: Ink.silver)
              .frame(maxWidth: .infinity, minHeight: 48)
          }
          .background(Ink.black)
          .overlay(alignment: .top) { Rectangle().fill(Ink.white).frame(height: 2) }
        }
    }
  }
}

struct RewardRow: View {
  var kind: CardKind
  var trailing: String
  var body: some View {
    HStack(spacing: 13) {
      ZStack(alignment: .bottomTrailing) {
        ZStack {
          Ink.navy
          CardIllustration(kind: kind).padding(6)
        }.frame(width: 56, height: 44)
          .overlay(Rectangle().stroke(Ink.black, lineWidth: 2))
        CostBadge(number: kind.cost, size: 18).offset(x: 4, y: 4)
      }
      VStack(alignment: .leading, spacing: 6) {
        PixelText(kind.title.uppercased(), px: 1.5, color: Ink.black)
        Text(kind.text.replacingOccurrences(of: "\n", with: " ")).font(Ink.body(13))
          .foregroundStyle(Ink.night).fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 0)
      PixelText(trailing, px: 2, color: Ink.black)
    }
    .padding(12)
    .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
    .background(Ink.cream)
    .overlay(Rectangle().stroke(Ink.black, lineWidth: 2))
  }
}

struct RestView: View {
  @EnvironmentObject var store: GameStore
  var run: Run
  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Eyebrow(text: "A quiet interlude").padding(.top, 24)
        ZStack {
          Ink.black
          Canvas { context, size in
            for index in 0..<40 {
              let x = CGFloat((index * 67 + 13) % 89) / 89 * size.width
              let y = CGFloat((index * 31 + 7) % 71) / 71 * size.height
              context.fill(
                Path(CGRect(x: x, y: y, width: 2, height: 2)),
                with: .color(index % 3 == 0 ? Ink.gold : Ink.navy))
            }
          }
          SpriteView(Pix.card(.lantern), px: 10)
        }
        .frame(height: 150).frame(maxWidth: 260)
        .overlay(PixelFrame(color: Ink.gold, corner: Ink.black))
        PixelText("REST STOP", px: 4, color: Ink.white, shadow: Ink.navy)
        Text("The world can wait for one small breath.").font(Ink.body(14))
          .foregroundStyle(Ink.silver)
        HStack(spacing: 10) {
          SpriteView(Pix.heart, px: 2)
          PixelBar(value: run.hp, max: run.maxHP, color: barColor(run.hp, run.maxHP)).frame(
            width: 150)
          PixelText("\(run.hp)/\(run.maxHP)", px: 2, color: Ink.rose)
        }
        PrimaryButton(title: "Rest: heal 24") {
          store.act { $0.rest(mend: true) }
        }.padding(.top, 6)
        Button {
          store.act { $0.rest(mend: false) }
        } label: {
          VStack(spacing: 8) {
            PixelText("REBIND: +8 MAX HEALTH", px: 1.5, color: Ink.gold)
            Text("Also restores 8 health").font(Ink.body(13)).foregroundStyle(Ink.silver)
          }.frame(maxWidth: .infinity).padding(16)
        }.buttonStyle(WindowButtonStyle())
      }.padding(28)
    }
  }
}

struct ShopView: View {
  @EnvironmentObject var store: GameStore
  var run: Run
  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 18) {
          Eyebrow(text: "The Night Market").padding(.top, 20)
          PixelText("SHOP", px: 4, color: Ink.gold, shadow: Ink.maroon)
          HStack(spacing: 8) {
            GoldLabel(gold: run.gold)
            PixelText("TO SPEND", px: 1.5, color: Ink.silver)
          }
          CardFan(
            kinds: [.sever, .sanctuary, .eclipse], width: min(118, (geometry.size.width - 104) / 3),
            unavailableLabel: "NEED GOLD",
            footer: { _ in run.gold >= 45 ? "45 gold" : "Need \(45 - run.gold) more" },
            enabled: { _ in run.gold >= 45 }
          ) { kind in
            store.act { $0.buy(kind) }
          }.padding(.top, 14).padding(.horizontal, 12)
          Rectangle().fill(Ink.brown).frame(height: 10)
            .overlay(alignment: .top) { Rectangle().fill(Ink.copper).frame(height: 3) }
            .overlay(alignment: .bottom) { Rectangle().fill(Ink.black).frame(height: 2) }
            .padding(.horizontal, 8).padding(.top, -8)
          Text(run.lastMessage).font(Ink.body(14)).foregroundStyle(Ink.silver)
          PrimaryButton(title: "Continue") { store.act { $0.leaveShop() } }
        }.padding(24)
      }
    }
  }
}

struct ResultView: View {
  @EnvironmentObject var store: GameStore
  var run: Run
  private var won: Bool { run.stage == .victory }
  var body: some View {
    ScrollView {
      VStack(spacing: 18) {
        Eyebrow(text: won ? "An ending, rewritten" : "A story, unfinished").padding(.top, 14)
        Proscenium(kind: won ? .moth : .queen).frame(height: 200).padding(.horizontal, 30)
        PixelText(
          won ? "YOU WIN!" : "GAME OVER", px: 5, color: won ? Ink.gold : Ink.rose,
          shadow: won ? Ink.maroon : Ink.black)
        Text(
          won
            ? "The strings are broken. The theater is yours." : "Every torn page teaches a new art."
        )
        .font(Ink.body(14)).foregroundStyle(Ink.silver).multilineTextAlignment(.center)
        PixelRule().frame(width: 170)
        Window {
          VStack(spacing: 12) {
            PixelText("SCORE", px: 1.5, color: Ink.silver)
            PixelText(arcade(run.score), px: 4, color: Ink.gold, shadow: Ink.black)
            HStack(spacing: 0) {
              resultStat("\(run.battles)", label: "Duels won")
              Rectangle().fill(Ink.white.opacity(0.4)).frame(width: 2, height: 34)
              resultStat("\(run.turns)", label: "Turns")
              Rectangle().fill(Ink.white.opacity(0.4)).frame(width: 2, height: 34)
              resultStat("\(run.gold)", label: "Gold")
            }
          }.padding(.vertical, 16)
        }
        if run.score >= store.archive.best && run.score > 0 {
          Blink { PixelText("NEW HIGH SCORE!", px: 2, color: Ink.mint) }
        } else {
          PixelText("BEST \(arcade(store.archive.best))", px: 1.5, color: Ink.gold)
        }
        PrimaryButton(title: "Play again") { store.start() }
        HStack(spacing: 10) {
          ShareLink(
            item:
              "I \(won ? "rewrote the ending" : "fought the strings") in Paper Relics: \(run.score) points, \(run.battles) duels won in \(run.turns) turns."
          ) {
            PixelText("SHARE", px: 1.5, color: Ink.white).frame(maxWidth: .infinity, minHeight: 46)
          }.buttonStyle(BevelButtonStyle(fill: Ink.navy, shade: Ink.black))
          Button {
            store.home = true
          } label: {
            PixelText("TITLE", px: 1.5, color: Ink.white).frame(maxWidth: .infinity, minHeight: 46)
          }.buttonStyle(BevelButtonStyle(fill: Ink.navy, shade: Ink.black))
        }.padding(.bottom, 6)
      }.padding(28)
    }.scrollIndicators(.hidden)
  }
  private func resultStat(_ value: String, label: String) -> some View {
    VStack(spacing: 8) {
      PixelText(value, px: 2.5, color: Ink.white)
      PixelText(label.uppercased(), px: 1, color: Ink.silver)
    }.frame(maxWidth: .infinity)
  }
}

struct RulesView: View {
  @EnvironmentObject var store: GameStore
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    ZStack {
      PaperBackground(ornaments: false)
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          Eyebrow(text: "How to play")
          PixelText("READ. FOLD.\nSTRIKE.", px: 3.5, color: Ink.white, shadow: Ink.navy)
          Window {
            HStack(spacing: 14) {
              IntentTag(intent: Intent(damage: 6)).scaleEffect(0.9)
              SpriteView(Pix.arrow, px: 2, tint: Ink.silver)
              CardFace(kind: .guardCard, width: 76)
            }.frame(maxWidth: .infinity).padding(.vertical, 18).padding(.horizontal, 12)
          }
          rule(
            "01", "Read the intent",
            "The speech bubble shows the enemy's next move. Match an attack with block to protect your health."
          )
          rule(
            "02", "Play your hand",
            "Start with 3 energy and 5 cards. Tap a card to play; swipe to see more. The gold badge is its energy cost."
          )
          rule(
            "03", "Turn the page",
            "End turn lets the enemy act. Your block expires, your hand is discarded, then energy and cards refill."
          )
          PrimaryButton(title: "Let's play") {
            store.archive.hasReadRules = true
            store.save()
            dismiss()
          }
          DisclosureGroup {
            VStack(alignment: .leading, spacing: 20) {
              rule(
                "04", "The life of a card",
                "An empty draw pile shuffles your discard. Exhausted cards stay out until the next battle."
              )
              rule(
                "05", "Make the ink work",
                "Poison deals its amount through block before the foe acts, then drops by 1. Weak reduces attacks by 25% (rounded down); it counts down after acting. Strength adds damage to each hit. Hand cards show adjusted damage."
              )
              rule(
                "06", "Rewrite the ending",
                "Choose routes, collect rewards, and heal or shop between fights. Defeat the String Queen in chapter 7. Relics work automatically. Your run saves after every action."
              )
              rule(
                "07", "Keep a better story",
                "Score = 100 per duel + 5 per remaining health + gold + 500 for victory. Best score and wins stay on this device."
              )
            }.padding(.top, 20)
          } label: {
            PixelText("MORE: STATUSES, PILES & SCORING", px: 1.5, color: Ink.gold)
          }.tint(Ink.gold)
        }.padding(28).padding(.vertical, 15)
      }
    }.foregroundStyle(Ink.white).presentationDragIndicator(.visible)
  }
  private func rule(_ number: String, _ title: String, _ text: String) -> some View {
    HStack(alignment: .top, spacing: 15) {
      PixelText(number, px: 2, color: Ink.gold)
      VStack(alignment: .leading, spacing: 8) {
        PixelText(title.uppercased(), px: 1.5, color: Ink.white)
        Text(text).font(Ink.body(15)).lineSpacing(3).foregroundStyle(Ink.silver)
      }
    }
  }
}

struct DeckView: View {
  @EnvironmentObject var store: GameStore
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    ZStack {
      PaperBackground(ornaments: false)
      ScrollView {
        VStack(spacing: 18) {
          HStack {
            PixelText("YOUR DECK", px: 3, color: Ink.white, shadow: Ink.navy)
            Spacer()
            Button {
              dismiss()
            } label: {
              SpriteView(Pix.close, px: 2).frame(width: 44, height: 44)
            }.accessibilityLabel("Close deck")
          }
          Text("A permanent deck. Combat piles reset each duel.").font(Ink.body(13))
            .foregroundStyle(Ink.silver)
          if let run = store.archive.run {
            ForEach(
              CardKind.allCases.filter { kind in run.deck.contains { $0.kind == kind } }, id: \.self
            ) { kind in
              RewardRow(kind: kind, trailing: "×\(run.deck.filter { $0.kind == kind }.count)")
            }
          }
        }.padding(25)
      }
    }.foregroundStyle(Ink.white).presentationDragIndicator(.visible)
  }
}
