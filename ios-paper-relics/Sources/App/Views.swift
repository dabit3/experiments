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
    .foregroundStyle(Ink.paper)
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: store.archive.run?.stage)
    .sheet(isPresented: $store.rules) { RulesView() }
    .sheet(isPresented: $store.deckOpen) { DeckView() }
  }

  private func toolbar(_ run: Run) -> some View {
    HStack(spacing: 6) {
      Text("Paper Relics").font(Ink.display(15)).tracking(1.5).foregroundStyle(Ink.gilt)
      Spacer()
      Button {
        store.deckOpen = true
      } label: {
        HStack(spacing: 6) {
          ZStack {
            RoundedRectangle(cornerRadius: 2).fill(Ink.parchment).frame(width: 10, height: 14)
              .rotationEffect(.degrees(-12)).offset(x: -3)
            RoundedRectangle(cornerRadius: 2).fill(Ink.cream).frame(width: 10, height: 14)
              .overlay(RoundedRectangle(cornerRadius: 2).stroke(Ink.bronze, lineWidth: 0.6))
          }
          Text("\(run.deck.count)").font(Ink.bold(14)).monospacedDigit()
        }
        .frame(minWidth: 44, minHeight: 44)
      }.accessibilityLabel("View deck")
      Button {
        store.paused = true
      } label: {
        Image(systemName: "pause").font(.system(size: 13, weight: .semibold)).frame(
          width: 44, height: 44
        )
        .overlay(Circle().stroke(Ink.copper.opacity(0.5), lineWidth: 1).padding(6))
      }.accessibilityLabel("Pause")
    }
    .foregroundStyle(Ink.copper)
    .padding(.horizontal, 24)
    .padding(.top, 2)
  }

  private var pauseOverlay: some View {
    ZStack {
      Ink.deep.opacity(0.96).ignoresSafeArea()
      VStack(spacing: 22) {
        ZStack {
          Circle().stroke(Ink.copper.opacity(0.35), lineWidth: 1).frame(width: 96, height: 96)
          Circle().stroke(Ink.copper.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
            .frame(width: 112, height: 112)
          Image(systemName: "moon.stars").font(.system(size: 36, weight: .ultraLight))
            .foregroundStyle(Ink.gilt)
        }
        Eyebrow(text: "Intermission")
        Text("The house lights\nrise a moment.").font(Ink.display(34)).multilineTextAlignment(
          .center)
        Text("Your story is safely saved.").font(Ink.italic(16)).foregroundStyle(Ink.faded)
        PrimaryButton(title: "Resume story", symbol: "play.fill") { store.paused = false }
          .padding(.top, 6)
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
      }.font(Ink.serif(16)).padding(32)
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
        Text(title).font(Ink.bold(17))
        Spacer()
        Image(systemName: symbol).font(.system(size: 13, weight: .semibold))
      }
      .padding(.horizontal, 20).frame(height: 56)
      .foregroundStyle(Ink.deep)
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: 14).fill(Ink.sheet)
          RoundedRectangle(cornerRadius: 14).fill(
            LinearGradient(
              colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center))
        }
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14).strokeBorder(Ink.metal, lineWidth: 1.4)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 10).stroke(Ink.bronze.opacity(0.35), lineWidth: 0.6).padding(
          4)
      )
      .shadow(color: Ink.gilt.opacity(0.25), radius: 12, x: 0, y: 4)
      .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 5)
    }.buttonStyle(CardPressStyle())
  }
}

struct Eyebrow: View {
  var text: String
  var body: some View {
    HStack(spacing: 8) {
      Diamond().fill(Ink.copper).frame(width: 4, height: 4)
      Text(text.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(2.8)
      Diamond().fill(Ink.copper).frame(width: 4, height: 4)
    }.foregroundStyle(Ink.copper)
  }
}

struct Plaque<Content: View>: View {
  var content: Content
  init(@ViewBuilder content: () -> Content) { self.content = content() }
  var body: some View {
    content
      .background(
        RoundedRectangle(cornerRadius: 14).fill(
          LinearGradient(
            colors: [Ink.paper.opacity(0.09), Ink.paper.opacity(0.03)], startPoint: .top,
            endPoint: .bottom))
      )
      .overlay(RoundedRectangle(cornerRadius: 14).stroke(Ink.copper.opacity(0.45), lineWidth: 0.9))
      .overlay(
        RoundedRectangle(cornerRadius: 10).stroke(Ink.copper.opacity(0.18), lineWidth: 0.6).padding(
          4))
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
      ScrollView {
        VStack(spacing: 14) {
          Eyebrow(text: "A pocket paper theater").padding(.top, 22)
          Spacer(minLength: 0)
          Proscenium(kind: .moth)
            .frame(height: min(geometry.size.height * 0.36, 300))
            .padding(.horizontal, 28)
            .offset(y: lit || reduceMotion ? 0 : 10)
            .opacity(lit || reduceMotion ? 1 : 0)
          VStack(spacing: -6) {
            Text("Paper").font(Ink.display(60)).tracking(2)
            Text("Relics").font(Ink.display(70)).tracking(2)
              .foregroundStyle(Ink.metal)
              .shadow(color: Ink.gilt.opacity(0.35), radius: 14, x: 0, y: 0)
          }
          .padding(.top, 10)
          Flourish().frame(width: 150)
          Text("Every card, a small rebellion.").font(Ink.italic(18)).foregroundStyle(Ink.faded)
          Text("Build a deck. Break the strings.\nRewrite the final act.").font(Ink.serif(15))
            .lineSpacing(4)
            .multilineTextAlignment(.center).foregroundStyle(Ink.faded.opacity(0.85))
          Spacer(minLength: 8)
          VStack(spacing: 8) {
            PrimaryButton(title: canContinue ? "Continue your story" : "Enter the theater") {
              if canContinue { store.home = false } else { store.start() }
            }
            Button("The art of playing") { store.rules = true }
              .font(Ink.serif(15)).foregroundStyle(Ink.copper).frame(height: 44)
          }.padding(.horizontal, 32)
          HStack(spacing: 22) {
            Label("\(store.archive.wins) endings rewritten", systemImage: "crown")
            if store.archive.best > 0 { Text("Best \(store.archive.best)") }
          }
          .font(Ink.serif(12)).foregroundStyle(Ink.faded.opacity(0.75))
          .padding(.bottom, 18)
        }
        .frame(minHeight: geometry.size.height)
      }.scrollIndicators(.hidden)
    }
    .onAppear {
      withAnimation(.easeOut(duration: 0.7)) { lit = true }
    }
  }
}

struct MapView: View {
  @EnvironmentObject var store: GameStore
  var run: Run

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        HStack {
          Eyebrow(text: "Chapter \(run.step + 1) of 7")
          Spacer()
          GoldLabel(gold: run.gold)
        }
        VStack(alignment: .leading, spacing: 8) {
          Text(run.step == 6 ? "The final\ncurtain." : "A story in\nseven folds.").font(
            Ink.display(40)
          )
          .lineSpacing(-4)
          Text(
            run.step == 6
              ? "The String Queen awaits. Make your ending."
              : "Choose a path through the paper theater."
          )
          .font(Ink.italic(15)).foregroundStyle(Ink.faded)
        }
        HStack(spacing: 0) {
          ForEach(0..<7) { index in
            if index > 0 {
              Rectangle().fill(index <= run.step ? Ink.copper : Ink.copper.opacity(0.25))
                .frame(height: 1)
                .overlay(
                  Rectangle().stroke(
                    Ink.deep, style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                  ).frame(height: 1).opacity(index <= run.step ? 0 : 1))
            }
            ZStack {
              if index == run.step {
                Circle().fill(Ink.metal).frame(width: 32, height: 32)
                  .shadow(color: Ink.gilt.opacity(0.5), radius: 8)
              } else {
                Circle().fill(index < run.step ? Ink.copper.opacity(0.35) : Ink.deep.opacity(0.7))
                  .frame(width: 28, height: 28)
                Circle().stroke(Ink.copper.opacity(0.5), lineWidth: 0.8).frame(
                  width: 28, height: 28)
              }
              if index == 6 {
                Image(systemName: "crown.fill").font(.system(size: 11))
              } else {
                Text(index < run.step ? "✓" : "\(index + 1)").font(Ink.bold(12))
              }
            }
            .foregroundStyle(index == run.step ? Ink.deep : Ink.paper)
          }
        }.padding(.vertical, 4)
        ForEach(run.routes) { route in
          Button {
            store.act { $0.chooseRoute(route.id) }
          } label: {
            HStack(spacing: 16) {
              ZStack {
                RoundedRectangle(cornerRadius: 12).fill(
                  LinearGradient(colors: [Ink.moss, Ink.deep], startPoint: .top, endPoint: .bottom))
                RadialGradient(
                  colors: [Ink.gilt.opacity(0.25), .clear], center: .center, startRadius: 2,
                  endRadius: 44
                ).clipShape(RoundedRectangle(cornerRadius: 12))
                if let enemy = route.enemy {
                  EnemyArt(kind: enemy).padding(4)
                } else {
                  SceneGlyph(symbol: route.symbol).padding(12)
                }
              }
              .frame(width: 84, height: 84)
              .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Ink.metal, lineWidth: 1))
              VStack(alignment: .leading, spacing: 6) {
                Text(route.title).font(Ink.display(21)).foregroundStyle(Ink.paper)
                Text(route.subtitle).font(Ink.serif(13)).foregroundStyle(Ink.faded)
                if route.subtitle.hasPrefix("Elite") || route.subtitle.hasPrefix("Boss") {
                  Text(route.subtitle.hasPrefix("Boss") ? "FINALE" : "ELITE")
                    .font(.system(size: 8, weight: .bold)).tracking(1.5)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Ink.wine, in: Capsule()).foregroundStyle(Ink.paper)
                }
              }
              Spacer(minLength: 0)
              Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Ink.copper)
            }
            .padding(14)
            .modifier(PlaqueStyle())
          }.buttonStyle(CardPressStyle())
        }
        HStack {
          Label("\(run.hp) / \(run.maxHP)", systemImage: "heart.fill").foregroundStyle(Ink.red)
          Spacer()
          Text("\(run.deck.count) cards in your deck").foregroundStyle(Ink.faded)
        }.font(Ink.serif(14))
        Flourish()
        VStack(alignment: .leading, spacing: 14) {
          Eyebrow(text: "Your keepsakes")
          ForEach(run.relics, id: \.self) { relic in RelicRow(relic: relic) }
        }
      }.padding(24)
    }.scrollIndicators(.hidden)
  }
}

struct PlaqueStyle: ViewModifier {
  func body(content: Content) -> some View {
    Plaque { content }
  }
}

struct GoldLabel: View {
  var gold: Int
  var body: some View {
    HStack(spacing: 6) {
      ZStack {
        Circle().fill(Ink.metal)
        Circle().stroke(Ink.deep.opacity(0.4), lineWidth: 0.6).padding(2.5)
      }.frame(width: 14, height: 14)
      Text("\(gold)").font(Ink.bold(14)).monospacedDigit()
    }.foregroundStyle(Ink.gilt)
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
              Text("Turn \(enemy.turn + 1)").font(Ink.italic(13)).foregroundStyle(Ink.faded)
            }.padding(.horizontal, 26)
            ZStack(alignment: .top) {
              Proscenium(kind: enemy.kind)
                .frame(height: max(150, min(215, geometry.size.height * 0.27)))
                .id(enemy.kind)
                .phaseAnimator([0, 1, 2, 3], trigger: enemy.hp) { content, phase in
                  content.offset(
                    x: reduceMotion || phase == 0 ? 0 : phase == 1 ? -6 : phase == 2 ? 5 : 0)
                } animation: { _ in
                  .easeOut(duration: 0.07)
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
              IntentTag(intent: enemy.intent).offset(y: -4)
            }
            .overlay(alignment: .bottomTrailing) {
              if !store.enemyFeedback.isEmpty {
                Text(store.enemyFeedback).font(Ink.display(18)).tracking(0.5)
                  .foregroundStyle(Ink.cream)
                  .padding(.horizontal, 12).padding(.vertical, 6)
                  .background(Ink.wine, in: TagShape())
                  .overlay(TagShape().stroke(Ink.gilt.opacity(0.7), lineWidth: 0.8))
                  .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
                  .padding(.trailing, 34).padding(.bottom, 26)
                  .transition(.move(edge: .bottom).combined(with: .opacity))
              }
            }
            VStack(spacing: 6) {
              Text(enemy.kind.title).font(Ink.display(compact ? 22 : 25))
              HStack(spacing: 10) {
                OrnateBar(value: enemy.hp, max: enemy.maxHP, color: Ink.copper).frame(width: 150)
                Text("\(enemy.hp) / \(enemy.maxHP)").font(Ink.bold(12)).monospacedDigit()
              }
              HStack(spacing: 12) {
                if enemy.block > 0 { Label("\(enemy.block) block", systemImage: "shield.fill") }
                if enemy.poison > 0 {
                  Label("\(enemy.poison) poison", systemImage: "drop.fill").foregroundStyle(
                    Ink.green)
                }
                if enemy.weak > 0 { Label("\(enemy.weak) weak", systemImage: "eye") }
              }.font(Ink.serif(12)).foregroundStyle(Ink.faded).frame(height: 14)
            }
          }
          Plaque {
            VStack(spacing: 7) {
              HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                  HStack(spacing: 6) {
                    Image(systemName: run.hp * 3 <= run.maxHP ? "heart.slash.fill" : "heart.fill")
                      .foregroundStyle(Ink.red)
                    Text("\(run.hp)/\(run.maxHP)").font(Ink.bold(15)).monospacedDigit().fixedSize()
                    Image(systemName: "shield.fill").foregroundStyle(Ink.faded).padding(.leading, 4)
                    Text("\(run.block)").font(Ink.bold(15)).monospacedDigit()
                  }
                  OrnateBar(value: run.hp, max: run.maxHP, color: Ink.red, height: 5).frame(
                    width: 128)
                }
                Spacer(minLength: 0)
                HStack(spacing: 7) {
                  ZStack {
                    Circle().fill(
                      RadialGradient(
                        colors: [Ink.gilt, Ink.copper, Ink.bronze], center: .init(x: 0.35, y: 0.3),
                        startRadius: 1, endRadius: 22))
                    Circle().stroke(Ink.deep.opacity(0.35), lineWidth: 0.8).padding(4)
                    Text("\(run.energy)").font(Ink.display(22)).foregroundStyle(Ink.deep)
                  }
                  .frame(width: 40, height: 40)
                  .shadow(color: Ink.gilt.opacity(run.energy > 0 ? 0.55 : 0), radius: 8)
                  Text("ENERGY").font(.system(size: 8, weight: .bold)).tracking(1.4)
                    .foregroundStyle(Ink.copper)
                }
              }
              HStack(spacing: 8) {
                if run.weak > 0 { Text("Weak \(run.weak)").foregroundStyle(Ink.copper) }
                if run.strength > 0 { Text("+\(run.strength) STR").foregroundStyle(Ink.copper) }
                Spacer(minLength: 0)
                Text(store.playerFeedback)
                  .foregroundStyle(store.playerHurt ? Ink.red : Ink.gilt)
              }
              .font(.system(size: 10, weight: .bold, design: .rounded))
              .lineLimit(1).minimumScaleFactor(0.85).frame(height: 13)
            }
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 14).padding(.vertical, 10)
          }
          .overlay(
            RoundedRectangle(cornerRadius: 14).stroke(
              run.hp * 3 <= run.maxHP ? Ink.red : .clear, lineWidth: 1.5)
          )
          .padding(.horizontal, 22)
          Text(run.lastMessage).font(Ink.italic(14)).foregroundStyle(Ink.paper)
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
                  .rotationEffect(
                    .degrees(reduceMotion ? 0 : Double(index % 3) - 1), anchor: .bottom
                  )
                  .transition(
                    reduceMotion
                      ? .identity
                      : .asymmetric(
                        insertion: .offset(x: 240, y: 90).combined(with: .opacity)
                          .combined(with: .scale(scale: 0.7)),
                        removal: .offset(y: -60).combined(with: .opacity).combined(
                          with: .scale(scale: 0.9))))
                }
              }
              .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 10)
              .animation(
                reduceMotion ? nil : .spring(duration: 0.38, bounce: 0.22), value: run.hand)
            }.scrollIndicators(.hidden)
              .onChange(of: run.turns) { _, _ in
                reader.scrollTo("handStart", anchor: .leading)
              }
          }
          HStack {
            VStack(alignment: .leading, spacing: 5) {
              Text("\(run.hand.count) cards · tap to play · swipe hand").foregroundStyle(Ink.faded)
              Text(
                "Draw \(run.drawPile.count)  ·  Discard \(run.discard.count)  ·  Exhaust \(run.exhaust.count)"
              )
              .foregroundStyle(Ink.copper.opacity(0.9))
            }.font(Ink.serif(12))
            Spacer()
            Button {
              store.act { $0.endTurn() }
              store.chime(frequency: 330)
            } label: {
              HStack(spacing: 8) {
                Text("End turn").font(Ink.bold(15))
                Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
              }
              .padding(.horizontal, 18).frame(height: 48)
              .background(Ink.metal, in: RoundedRectangle(cornerRadius: 12))
              .overlay(
                RoundedRectangle(cornerRadius: 9).stroke(Ink.deep.opacity(0.3), lineWidth: 0.7)
                  .padding(3)
              )
              .foregroundStyle(Ink.deep)
              .shadow(color: .black.opacity(0.35), radius: 5, y: 4)
            }.buttonStyle(CardPressStyle()).accessibilityIdentifier("endTurn")
          }.padding(.horizontal, 22).padding(.bottom, 16)
        }.padding(.top, 6)
      }.scrollIndicators(.hidden)
    }
  }
}

struct CardPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.scaleEffect(configuration.isPressed ? 0.96 : 1)
      .brightness(configuration.isPressed ? 0.04 : 0)
      .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
  }
}

struct RelicRow: View {
  var relic: Relic
  var body: some View {
    HStack(spacing: 14) {
      RelicGlyph(relic: relic).frame(width: 46, height: 46)
      VStack(alignment: .leading, spacing: 4) {
        Text(relic.title).font(Ink.display(18))
        Text(relic.text).font(Ink.serif(13)).foregroundStyle(Ink.faded)
      }
    }
  }
}

struct CardFan: View {
  var kinds: [CardKind]
  var width: CGFloat
  var footer: (CardKind) -> String
  var enabled: (CardKind) -> Bool
  var action: (CardKind) -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var dealt = false
  var body: some View {
    HStack(alignment: .top, spacing: -width * 0.08) {
      ForEach(Array(kinds.enumerated()), id: \.element) { index, kind in
        let center = Double(index) - Double(kinds.count - 1) / 2
        Button {
          action(kind)
        } label: {
          VStack(spacing: 10) {
            CardFace(kind: kind, affordable: enabled(kind), width: width)
            Text(footer(kind)).font(Ink.bold(12)).foregroundStyle(
              enabled(kind) ? Ink.gilt : Ink.faded
            )
            .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
            .frame(height: 30)
          }
          .rotationEffect(.degrees(dealt ? center * 4 : 0), anchor: .bottom)
          .offset(y: dealt ? abs(center) * 10 : 0)
        }
        .buttonStyle(CardPressStyle())
        .disabled(!enabled(kind))
        .opacity(dealt || reduceMotion ? 1 : 0)
        .offset(y: dealt || reduceMotion ? 0 : 60)
        .animation(
          reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.2).delay(Double(index) * 0.08),
          value: dealt
        )
        .zIndex(Double(index))
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
          Eyebrow(text: "The spoils of your story").padding(.top, 6)
          Text("A new page.").font(Ink.display(40))
          Text("Choose one art to add to your deck.").font(Ink.italic(15)).foregroundStyle(
            Ink.faded)
          HStack(spacing: 22) {
            GoldLabel(gold: run.enemy?.kind == .stag ? 40 : 25).overlay(alignment: .leading) {
              Text("+").font(Ink.bold(14)).foregroundStyle(Ink.gilt).offset(x: -10)
            }
            Label("Spool healed 4", systemImage: "heart.fill").foregroundStyle(Ink.red)
          }.font(Ink.serif(13))
          CardFan(
            kinds: run.rewards, width: min(124, (geometry.size.width - 60) / 3),
            footer: { _ in "Take" }, enabled: { _ in true }
          ) { kind in
            store.act { $0.claimReward(kind) }
          }.padding(.top, 14).padding(.horizontal, 12)
          if let relic = run.offeredRelic {
            Plaque {
              VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Your keepsake")
                RelicRow(relic: relic)
                Text("Automatically included—even if you skip.")
                  .font(Ink.italic(12)).foregroundStyle(Ink.faded)
              }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
            }
          }
        }.padding(24)
      }.scrollIndicators(.visible)
        .safeAreaInset(edge: .bottom) {
          Button("Skip card & continue") { store.act { $0.claimReward(nil) } }
            .font(Ink.serif(15)).foregroundStyle(Ink.copper)
            .frame(maxWidth: .infinity, minHeight: 48).background(Ink.deep)
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
          RoundedRectangle(cornerRadius: 6).fill(
            LinearGradient(colors: [Ink.moss, Ink.deep], startPoint: .top, endPoint: .bottom))
          CardIllustration(kind: kind).padding(3)
        }.frame(width: 60, height: 44)
        Seal(number: kind.cost, size: 20).offset(x: 5, y: 5)
      }
      VStack(alignment: .leading, spacing: 5) {
        Text(kind.title).font(Ink.display(17))
        Text(kind.text.replacingOccurrences(of: "\n", with: " ")).font(Ink.serif(13)).fixedSize(
          horizontal: false, vertical: true)
      }
      Spacer(minLength: 0)
      Text(trailing).font(Ink.bold(12))
    }
    .foregroundStyle(Ink.forest).padding(14)
    .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
    .background(Ink.sheet, in: RoundedRectangle(cornerRadius: 12))
    .overlay(
      RoundedRectangle(cornerRadius: 12).strokeBorder(Ink.bronze.opacity(0.5), lineWidth: 0.8))
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
          Circle().fill(
            RadialGradient(
              colors: [Ink.gilt.opacity(0.3), .clear], center: .center, startRadius: 4,
              endRadius: 90))
          Circle().stroke(Ink.copper.opacity(0.3), lineWidth: 1).frame(width: 150, height: 150)
          Circle().stroke(
            Ink.copper.opacity(0.18), style: StrokeStyle(lineWidth: 0.8, dash: [2, 5])
          )
          .frame(width: 170, height: 170)
          CardIllustration(kind: .lantern).frame(width: 110, height: 100)
        }.frame(height: 190)
        Text("Mend the edges.").font(Ink.display(36))
        Text("The world can wait for one small breath.").font(Ink.italic(16))
          .foregroundStyle(Ink.faded)
        HStack(spacing: 10) {
          OrnateBar(value: run.hp, max: run.maxHP, color: Ink.red).frame(width: 160)
          Text("\(run.hp) / \(run.maxHP)").font(Ink.bold(14)).foregroundStyle(Ink.red)
        }
        PrimaryButton(title: "Rest · recover 24 health", symbol: "heart.fill") {
          store.act { $0.rest(mend: true) }
        }.padding(.top, 6)
        Button {
          store.act { $0.rest(mend: false) }
        } label: {
          VStack(spacing: 6) {
            Text("Rebind · gain 8 maximum health").font(Ink.bold(15))
            Text("Also restores 8 health").font(Ink.italic(13)).foregroundStyle(Ink.faded)
          }.frame(maxWidth: .infinity).padding(16)
            .modifier(PlaqueStyle())
        }.buttonStyle(CardPressStyle()).foregroundStyle(Ink.gilt)
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
          Text("Rare little wonders.").font(Ink.display(34))
          HStack(spacing: 6) {
            GoldLabel(gold: run.gold)
            Text("to spend").font(Ink.italic(14)).foregroundStyle(Ink.faded)
          }
          CardFan(
            kinds: [.sever, .sanctuary, .eclipse], width: min(124, (geometry.size.width - 60) / 3),
            footer: { _ in run.gold >= 45 ? "45 gold" : "Need \(45 - run.gold) more gold" },
            enabled: { _ in run.gold >= 45 }
          ) { kind in
            store.act { $0.buy(kind) }
          }.padding(.top, 14).padding(.horizontal, 12)
          Rectangle().fill(
            LinearGradient(
              colors: [Ink.bronze.opacity(0.8), Ink.deep], startPoint: .top, endPoint: .bottom)
          ).frame(height: 6).overlay(alignment: .top) {
            Rectangle().fill(Ink.gilt.opacity(0.6)).frame(height: 1)
          }.padding(.horizontal, 8).padding(.top, -8)
          Text(run.lastMessage).font(Ink.italic(14)).foregroundStyle(Ink.faded)
          PrimaryButton(title: "Continue your story") { store.act { $0.leaveShop() } }
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
        Proscenium(kind: won ? .moth : .queen).frame(height: 210).padding(.horizontal, 30)
        Text(won ? "The strings\nare broken." : "The curtain\nfalls.").font(Ink.display(42))
          .multilineTextAlignment(.center).lineSpacing(-4)
        Text(won ? "The theater belongs to you now." : "Every torn page teaches a new art.")
          .font(Ink.italic(16)).foregroundStyle(Ink.faded)
        Flourish().frame(width: 170)
        Plaque {
          HStack(spacing: 0) {
            resultStat("\(run.score)", label: "Run score", hero: true)
            Rectangle().fill(Ink.copper.opacity(0.3)).frame(width: 0.6, height: 44)
            resultStat("\(run.battles)", label: "Duels won")
            Rectangle().fill(Ink.copper.opacity(0.3)).frame(width: 0.6, height: 44)
            resultStat("\(run.turns)", label: "Turns")
          }.padding(.vertical, 16)
        }
        Text("Personal best  \(store.archive.best)").font(Ink.bold(12)).tracking(1.5)
          .foregroundStyle(Ink.gilt)
        PrimaryButton(title: "Begin another story", symbol: "arrow.clockwise") { store.start() }
        HStack {
          ShareLink(
            item:
              "I \(won ? "rewrote the ending" : "fought the strings") in Paper Relics: \(run.score) points, \(run.battles) duels won in \(run.turns) turns."
          ) {
            Label("Share story", systemImage: "square.and.arrow.up")
          }.frame(maxWidth: .infinity, minHeight: 44)
          Button("Return to title") { store.home = true }.frame(maxWidth: .infinity, minHeight: 44)
        }.font(Ink.serif(14)).foregroundStyle(Ink.copper)
      }.padding(28)
    }.scrollIndicators(.hidden)
  }
  private func resultStat(_ value: String, label: String, hero: Bool = false) -> some View {
    VStack(spacing: 6) {
      Text(value).font(Ink.display(hero ? 34 : 28)).foregroundStyle(hero ? Ink.gilt : Ink.paper)
        .monospacedDigit()
      Text(label.uppercased()).font(.system(size: 9, weight: .bold)).tracking(1.5)
        .foregroundStyle(Ink.faded)
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
          Eyebrow(text: "The art of playing")
          Text("Read. Fold. Strike.").font(Ink.display(34))
          Plaque {
            HStack(spacing: 14) {
              IntentTag(intent: Intent(damage: 6)).scaleEffect(0.9)
              Image(systemName: "arrow.right").foregroundStyle(Ink.faded)
              CardFace(kind: .guardCard, width: 72)
            }.frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 12)
          }
          rule(
            "01", "Read the intent",
            "The hanging tag shows the enemy's next action. Match an attack with block to protect your health."
          )
          rule(
            "02", "Play your hand",
            "Start with 3 energy and 5 cards. Tap a card to play; swipe to see more. The wax seal is its energy cost."
          )
          rule(
            "03", "Turn the page",
            "End turn lets the enemy act. Your block expires, your hand is discarded, then energy and cards refill."
          )
          PrimaryButton(title: "Let the story begin", symbol: "sparkle") {
            store.archive.hasReadRules = true
            store.save()
            dismiss()
          }
          DisclosureGroup("The finer arts · statuses, piles & scoring") {
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
          }.font(Ink.serif(14)).tint(Ink.copper)
        }.padding(28).padding(.vertical, 15)
      }
    }.foregroundStyle(Ink.paper).presentationDragIndicator(.visible)
  }
  private func rule(_ number: String, _ title: String, _ text: String) -> some View {
    HStack(alignment: .top, spacing: 15) {
      Text(number).font(Ink.display(20)).foregroundStyle(Ink.copper)
      VStack(alignment: .leading, spacing: 6) {
        Text(title).font(Ink.display(21))
        Text(text).font(Ink.serif(15)).lineSpacing(3).foregroundStyle(Ink.faded)
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
            Text("Your collected arts").font(Ink.display(28))
            Spacer()
            Button {
              dismiss()
            } label: {
              Image(systemName: "xmark").frame(width: 44, height: 44)
            }.accessibilityLabel("Close deck")
          }
          Text("A permanent deck. Combat piles reset each duel.").font(Ink.italic(13))
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
