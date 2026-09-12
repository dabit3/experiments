import SwiftUI
import UIKit

@main
struct MoonMarketApp: App {
  @StateObject private var store = MarketStore()
  var body: some Scene {
    WindowGroup {
      MarketRoot()
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }
  }
}

struct MarketRoot: View {
  @EnvironmentObject private var store: MarketStore
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage("moon.haptics") private var haptics = true
  @AppStorage("moon.learned") private var learned = false
  @State private var sheet: Panel?
  @State private var confirmRestart = false
  @State private var shareImage: UIImage?
  @State private var sharing = false
  @State private var tutorialStep = 0

  private enum Panel: String, Identifiable {
    case tutorial, settings, pause
    var id: String { rawValue }
  }

  var body: some View {
    ZStack {
      Palette.ink.ignoresSafeArea()
      if store.atHome {
        home
      } else if store.run.finished {
        results
      } else if store.run.settlement != nil {
        settlement
      } else {
        market
      }
    }
    .foregroundStyle(Palette.cream)
    .tint(Palette.mint)
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: store.atHome)
    .sheet(item: $sheet) { panel in
      Group {
        switch panel {
        case .tutorial: tutorial
        case .settings: settings
        case .pause: pause
        }
      }
      .padding(24)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Palette.panel)
      .presentationDetents(panel == .tutorial ? [.height(510)] : [.medium])
      .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $sharing) {
      ShareSheet(image: shareImage, text: shareText)
        .presentationDetents([.medium, .large])
    }
    .confirmationDialog(
      "Begin this market again?", isPresented: $confirmRestart, titleVisibility: .visible
    ) {
      Button("Restart from night 1", role: .destructive) {
        let run = store.run
        sheet = nil
        store.start(daily: run.daily, seed: run.seed)
      }
    } message: {
      Text("This run will be replaced. Your best receipt stays saved.")
    }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active { store.save() }
    }
  }

  private var home: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 0) {
          HStack {
            brand
            Spacer()
            iconButton("slider.horizontal.3", label: "Settings", id: "settings") {
              sheet = .settings
            }
          }
          .padding(.horizontal, 24)
          .padding(.top, 10)
          VStack(spacing: 8) {
            eyebrow("THE NIGHT SHIFT, REIMAGINED")
            Text("Moon Market")
              .font(.system(size: 49, weight: .regular, design: .serif))
              .tracking(-2)
              .minimumScaleFactor(0.6)
              .lineLimit(1)
            Text("A tiny stall. A whole galaxy of possibility.")
              .font(.system(size: 14))
              .foregroundStyle(Palette.muted)
          }
          .padding(.horizontal, 20)
          .padding(.top, 30)
          BazaarScene(flourishing: true)
            .frame(height: max(210, min(300, geometry.size.height * 0.37)))
            .padding(.top, 5)
          VStack(spacing: 15) {
            HStack(spacing: 0) {
              homeFact("8", "NIGHTS")
              Rectangle().fill(Palette.muted.opacity(0.25)).frame(width: 1, height: 27)
              homeFact("90", "CREDITS TO START")
              Rectangle().fill(Palette.muted.opacity(0.25)).frame(width: 1, height: 27)
              homeFact("240", "CREDITS TO WIN")
            }
            .padding(.bottom, 8)
            if let run = store.archive.run, !run.finished {
              primary("Resume night \(run.round)", icon: "arrow.right", id: "resume") {
                store.atHome = false
              }
              Button("Start a fresh market") {
                store.start(daily: false)
                offerTutorial()
              }
              .font(.system(size: 15, weight: .medium))
              .frame(minHeight: 44)
              .accessibilityIdentifier("new-market")
            } else {
              primary("Open your market", icon: "arrow.right", id: "start") {
                store.start(daily: false)
                offerTutorial()
              }
            }
            Button {
              store.start(daily: true)
              offerTutorial()
            } label: {
              HStack {
                Image(systemName: "moon.stars")
                Text("Daily orbit")
                Spacer()
                Text(String(Run.dailySeed())).font(.system(size: 12, design: .monospaced))
                Image(systemName: "arrow.up.right")
              }
              .font(.system(size: 16, weight: .medium))
              .padding(.horizontal, 18)
              .frame(minHeight: 54)
              .background(Palette.mint.opacity(0.07), in: RoundedRectangle(cornerRadius: 17))
              .overlay(RoundedRectangle(cornerRadius: 17).stroke(Palette.mint.opacity(0.22)))
            }
            .accessibilityLabel("Daily orbit. Same market for everyone today.")
            .accessibilityIdentifier("daily")
            HStack {
              Button("How to trade") {
                tutorialStep = 0
                sheet = .tutorial
              }
              .accessibilityIdentifier("how-to-play")
              Spacer()
              Text(
                store.archive.best > 0
                  ? "BEST  \(store.archive.best) cr" : "YOUR FIRST ORBIT AWAITS"
              )
              .font(.system(size: 10, weight: .semibold, design: .monospaced))
              .tracking(1)
            }
            .font(.system(size: 13))
            .foregroundStyle(Palette.muted)
            .frame(minHeight: 44)
          }
          .padding(.horizontal, 24)
          .padding(.bottom, 18)
        }
        .frame(minHeight: geometry.size.height, alignment: .top)
      }
      .scrollIndicators(.hidden)
    }
  }

  private var market: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          eyebrow("NIGHT \(String(format: "%02d", store.run.round)) / 08")
          Text(nightTitle).font(.system(size: 26, weight: .regular, design: .serif))
        }
        Spacer()
        iconButton("questionmark", label: "Trading guide", id: "guide") {
          tutorialStep = 0
          sheet = .tutorial
        }
        iconButton("pause", label: "Pause market", id: "pause") { sheet = .pause }
      }
      .padding(.horizontal, 22)
      .padding(.top, 8)
      ScrollView {
        VStack(spacing: 14) {
          HStack(alignment: .firstTextBaseline) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
              Text("\(store.run.cash)").font(.system(size: 32, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())
              Text("cr").font(.system(size: 13)).foregroundStyle(Palette.muted)
            }
            .accessibilityLabel("Wallet \(store.run.cash) credits")
            Spacer()
            stat("\(store.run.occupied)/12", caption: "CRATE SPACE")
            Spacer()
            stat("240 cr", caption: "FINAL GOAL")
          }
          .padding(.horizontal, 24)
          BazaarScene(flourishing: store.run.cash >= Run.goal)
            .frame(height: 132)
            .padding(.top, -16)
            .padding(.bottom, -6)
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Circle().fill(Palette.orange).frame(width: 6, height: 6)
              Text(store.run.market.headline.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(0.6)
            }
            Text(store.run.market.detail)
              .font(.system(size: 12))
              .foregroundStyle(Palette.muted)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 24)
          VStack(spacing: 9) {
            HStack {
              eyebrow("STOCK YOUR STALL")
              Spacer()
              Text("BUY → SELL · QUEUE").font(
                .system(size: 9, weight: .medium, design: .monospaced)
              ).foregroundStyle(Palette.muted)
            }
            ForEach(Produce.allCases) { produce in productCard(produce) }
          }
          .padding(.horizontal, 18)
          if store.run.round < 8 {
            HStack(spacing: 8) {
              Image(systemName: "sparkle").foregroundStyle(Palette.mint)
              VStack(alignment: .leading, spacing: 3) {
                Text("TOMORROW'S QUEUE").font(.system(size: 9, weight: .bold, design: .monospaced))
                  .tracking(1)
                Text(
                  Produce.allCases.map {
                    "\($0.name) \(store.run.forecast.quotes[$0.rawValue].demand)"
                  }.joined(separator: "  ·  ")
                )
                .font(.system(size: 11)).foregroundStyle(Palette.muted)
              }
              Spacer(minLength: 0)
            }.padding(.horizontal, 24)
          } else {
            Text("Last night: remaining stock clears at half tonight's buy price.")
              .font(.system(size: 11)).foregroundStyle(Palette.muted).padding(.horizontal, 24)
          }
          if store.run.inventory.reduce(0, +) > 0 {
            Button {
              store.change { $0.clearInventory() }
              tick()
            } label: {
              Text("Clear carried stock for \(store.run.salvageValue) cr")
                .font(.system(size: 13, weight: .medium)).underline()
                .frame(minHeight: 44)
            }
            .accessibilityIdentifier("clear-stock")
          }
        }
        .padding(.top, 10)
        .padding(.bottom, 14)
      }
      .scrollIndicators(.hidden)
    }
    .safeAreaInset(edge: .bottom, spacing: 0) { orderBar }
  }

  private var nightTitle: String {
    if store.run.round == 1 { return "The moon is open." }
    if store.run.round == 8 { return "Make it a moonshot." }
    return [
      "", "", "Find your rhythm.", "A little lunar hustle.", "Read the room.",
      "Follow the starlight.", "Your stall is stirring.", "One more good trade.",
    ][store.run.round]
  }

  private func productCard(_ produce: Produce) -> some View {
    let index = produce.rawValue
    let quote = store.run.market.quotes[index]
    let held = store.run.inventory[index]
    let quantity = store.run.order[index]
    return HStack(spacing: 10) {
      ProduceArt(kind: index).frame(width: 55, height: 66)
      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: 5) {
          Text(produce.name).font(.system(size: 17, weight: .semibold, design: .rounded))
          if held > 0 {
            Text("+\(held) held").font(.system(size: 9, weight: .bold)).foregroundStyle(
              Color(red: 0.22, green: 0.4, blue: 0.34))
          }
        }
        HStack(spacing: 5) {
          Text("\(quote.buy) → \(quote.sell) cr")
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
          Text("· \(quote.demand) want")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Palette.ink.opacity(0.65))
        }
        Text(
          held + quantity > quote.demand
            ? "\(held + quantity - quote.demand) will carry over"
            : "\(max(0, quote.demand - held - quantity)) more can sell tonight"
        )
        .font(.system(size: 10))
        .foregroundStyle(Palette.ink.opacity(0.6))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      HStack(spacing: 0) {
        Button {
          store.change { $0.adjust(index, by: -1) }
          tick()
        } label: {
          Image(systemName: "minus").font(.system(size: 14, weight: .semibold)).frame(
            width: 36, height: 48)
        }
        .disabled(quantity == 0)
        .opacity(quantity == 0 ? 0.3 : 1)
        .accessibilityLabel("Remove one \(produce.name)")
        .accessibilityIdentifier("minus-\(index)")
        Text("\(quantity)")
          .font(.system(size: 18, weight: .bold, design: .rounded))
          .monospacedDigit()
          .frame(width: 19)
          .accessibilityLabel("\(quantity) \(produce.name) ordered")
        Button {
          store.change { $0.adjust(index, by: 1) }
          tick()
        } label: {
          Image(systemName: "plus").font(.system(size: 14, weight: .semibold)).frame(
            width: 36, height: 48)
        }
        .disabled(!store.run.canAdd(index))
        .opacity(store.run.canAdd(index) ? 1 : 0.3)
        .accessibilityLabel("Add one \(produce.name)")
        .accessibilityIdentifier("plus-\(index)")
      }
      .background(Palette.ink.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .foregroundStyle(Palette.ink)
    .background(Palette.cream, in: RoundedRectangle(cornerRadius: 18))
  }

  private var orderBar: some View {
    VStack(spacing: 10) {
      HStack {
        Text("ORDER \(store.run.orderCost)  +  RENT 5").font(
          .system(size: 10, weight: .medium, design: .monospaced))
        Spacer()
        Text("After sales  \(store.run.projectedCash) cr")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Palette.mint)
      }
      .foregroundStyle(Palette.muted)
      primary("Open market", icon: "sparkles", id: "open-market") {
        store.change { $0.openMarket() }
        if haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) }
      }
    }
    .padding(.horizontal, 22)
    .padding(.top, 13)
    .padding(.bottom, 10)
    .background(Palette.ink)
    .overlay(alignment: .top) { Rectangle().fill(Palette.mint.opacity(0.12)).frame(height: 1) }
  }

  private var settlement: some View {
    let receipt = store.run.settlement
    return ScrollView {
      VStack(spacing: 16) {
        HStack {
          eyebrow("NIGHT \(store.run.round) · MARKET CLOSED")
          Spacer()
          iconButton("pause", label: "Pause market", id: "pause") { sheet = .pause }
        }
        .padding(.horizontal, 24)
        Text(receipt?.customers == 0 ? "A quiet little orbit." : "You made their night.")
          .font(.system(size: 31, weight: .regular, design: .serif))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 20)
        BazaarScene(
          flourishing: store.run.cash >= Run.goal, celebrating: (receipt?.customers ?? 0) > 0
        )
        .frame(height: 245)
        VStack(spacing: 13) {
          HStack {
            Text("THE NIGHT'S TAKINGS").font(.system(size: 10, weight: .bold, design: .monospaced))
              .tracking(2)
            Spacer()
            Text("\(receipt?.customers ?? 0) happy customers").font(.system(size: 11))
          }.foregroundStyle(Palette.muted)
          HStack(spacing: 16) {
            ForEach(Produce.allCases) { produce in
              HStack(spacing: 2) {
                ProduceArt(kind: produce.rawValue).frame(width: 36, height: 40)
                Text("×\(receipt?.sold[produce.rawValue] ?? 0)")
                  .font(.system(size: 16, weight: .medium, design: .rounded))
              }
            }
          }
          Divider().overlay(Palette.muted.opacity(0.2))
          ledgerLine("Sales", "+\(receipt?.revenue ?? 0) cr")
          ledgerLine("Stock bought", "−\(receipt?.cost ?? 0) cr")
          ledgerLine("Stall rent", "−\(receipt?.rent ?? 0) cr")
          HStack(alignment: .firstTextBaseline) {
            Text("Wallet").font(.system(size: 16, weight: .medium))
            Spacer()
            Text("\(store.run.cash) cr").font(
              .system(size: 34, weight: .semibold, design: .rounded)
            ).foregroundStyle(Palette.mint)
          }
          if store.run.inventory.reduce(0, +) > 0 {
            Text("\(store.run.inventory.reduce(0, +)) unsold items stay in your crate.")
              .font(.system(size: 12)).foregroundStyle(Palette.muted)
          }
          Text(
            store.run.cash >= Run.goal
              ? "Your cart has become a glowing lunar stall."
              : "\(max(0, Run.goal - store.run.cash)) credits from a glowing stall."
          )
          .font(.system(size: 12)).foregroundStyle(Palette.orange)
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 15)
      }
    }
    .scrollIndicators(.hidden)
    .safeAreaInset(edge: .bottom) {
      primary(
        store.run.round == 8
          ? "See your final receipt" : "Next night · \(store.run.round + 1) of 8",
        icon: "arrow.right", id: "next-night"
      ) {
        store.change { $0.advance() }
        tick()
      }
      .padding(.horizontal, 24).padding(.bottom, 14).background(Palette.ink)
    }
  }

  private var results: some View {
    ScrollView {
      VStack(spacing: 15) {
        HStack {
          brand
          Spacer()
          Button("Home") { store.atHome = true }
            .font(.system(size: 14, weight: .medium)).frame(minHeight: 44)
            .accessibilityIdentifier("home")
        }
        .padding(.horizontal, 24)
        eyebrow(
          store.run.won
            ? "EIGHT NIGHTS. ONE BRIGHT LITTLE STALL." : "EVERY MERCHANT STARTS SOMEWHERE."
        )
        .padding(.top, 10)
        Text(store.run.rank).font(.system(size: 33, weight: .regular, design: .serif))
          .multilineTextAlignment(.center).padding(.horizontal, 20)
        BazaarScene(flourishing: store.run.won, celebrating: store.run.won)
          .frame(height: 180)
        ReceiptView(run: store.run)
          .padding(.horizontal, 28)
        Text(
          store.run.won
            ? "The whole crater knows your name."
            : "Match your stock to the queue. Try another orbit."
        )
        .font(.system(size: 12)).foregroundStyle(Palette.muted)
        .multilineTextAlignment(.center).padding(.horizontal, 24)
        primary("Share your receipt", icon: "square.and.arrow.up", id: "share") { share() }
          .padding(.horizontal, 24)
        HStack(spacing: 16) {
          Button("Replay this seed") {
            let run = store.run
            store.start(daily: run.daily, seed: run.seed)
          }.accessibilityIdentifier("replay")
          Text("·").foregroundStyle(Palette.muted)
          Button("New orbit") { store.start(daily: false) }.accessibilityIdentifier("new-orbit")
        }
        .font(.system(size: 14, weight: .medium))
        .frame(minHeight: 44)
        Text("BEST RECEIPT  \(store.archive.best) cr  ·  \(store.archive.completed) ORBITS")
          .font(.system(size: 10, weight: .medium, design: .monospaced))
          .tracking(1).foregroundStyle(Palette.muted)
      }
      .padding(.bottom, 24)
    }.scrollIndicators(.hidden)
  }

  private var tutorial: some View {
    VStack(spacing: 20) {
      HStack {
        eyebrow("FIELD NOTES · \(tutorialStep + 1) / 3")
        Spacer()
        Button("Close") { sheet = nil }.frame(minHeight: 44).accessibilityIdentifier("close-guide")
      }
      HStack(spacing: 8) {
        ForEach(0..<3) { index in
          ProduceArt(kind: index).frame(width: 76, height: 84)
        }
      }
      Text(
        ["Buy small. Dream lunar.", "Read the queue.", "Make eight nights count."][tutorialStep]
      )
      .font(.system(size: 29, weight: .regular, design: .serif))
      .multilineTextAlignment(.center)
      Text(
        [
          "Start with 90 credits and 12 crate spaces. Tap + to order produce. The left price is what you pay; the right is what each customer pays you.",
          "“Want” is exactly how many will buy tonight. Rival effects are already included. Unsold stock carries over; tomorrow's queue helps you plan.",
          "Open market to buy your order and serve the queue. Rent is 5 credits a night. Finish with 240 to light up your stall. Leftovers clear at half buy price after night 8.",
        ][tutorialStep]
      )
      .font(.system(size: 16)).foregroundStyle(Palette.muted).lineSpacing(4)
      .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
      primary(
        tutorialStep == 2 ? "Let's trade" : "Next field note", icon: "arrow.right",
        id: "tutorial-next"
      ) {
        if tutorialStep == 2 {
          learned = true
          sheet = nil
        } else {
          tutorialStep += 1
        }
      }
    }
  }

  private var settings: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("A quieter corner.").font(.system(size: 30, design: .serif))
      Toggle("Haptic feedback", isOn: $haptics)
        .accessibilityIdentifier("haptics")
        .frame(minHeight: 44)
      Text(
        "Moon Market is intentionally silent. Motion follows your device's Reduce Motion setting. Your progress stays on this device."
      )
      .font(.system(size: 14)).foregroundStyle(Palette.muted).lineSpacing(3)
      Text("Daily orbit resets at midnight UTC.")
        .font(.system(size: 12, design: .monospaced)).foregroundStyle(Palette.mint)
      Spacer(minLength: 0)
      primary("Back to the moon", icon: "arrow.right", id: "close-settings") { sheet = nil }
    }
  }

  private var pause: some View {
    VStack(spacing: 16) {
      eyebrow("YOUR STALL IS SAFE")
      Text("Take a little moonwalk.").font(.system(size: 28, design: .serif))
        .multilineTextAlignment(.center)
      Text("No timers. No rush. Every trade is saved.")
        .font(.system(size: 14)).foregroundStyle(Palette.muted)
      primary("Keep trading", icon: "play.fill", id: "resume-game") { sheet = nil }
      HStack {
        Button("Restart this seed") { confirmRestart = true }.accessibilityIdentifier("restart")
        Spacer()
        Button("Save & home") {
          store.save()
          store.atHome = true
          sheet = nil
        }.accessibilityIdentifier("save-home")
      }.font(.system(size: 14)).frame(minHeight: 44)
      Text("SEED \(store.run.seed)\(store.run.daily ? " · DAILY" : "")")
        .font(.system(size: 11, design: .monospaced)).foregroundStyle(Palette.muted)
    }
  }

  private var brand: some View {
    HStack(spacing: 7) {
      Image(systemName: "moon.fill").font(.system(size: 12)).foregroundStyle(Palette.orange)
      Text("LUNE TRADING CO.").font(.system(size: 10, weight: .semibold, design: .monospaced))
        .tracking(1.8)
    }
  }
  private func eyebrow(_ text: String) -> some View {
    Text(text).font(.system(size: 10, weight: .semibold, design: .monospaced))
      .tracking(1.3).foregroundStyle(Palette.mint)
  }
  private func homeFact(_ value: String, _ label: String) -> some View {
    VStack(spacing: 5) {
      Text(value).font(.system(size: 25, weight: .medium, design: .serif))
      Text(label).font(.system(size: 8, weight: .semibold, design: .monospaced)).tracking(0.7)
        .foregroundStyle(Palette.muted)
    }.frame(maxWidth: .infinity)
  }
  private func stat(_ value: String, caption: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(value).font(.system(size: 17, weight: .semibold, design: .rounded))
      Text(caption).font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(0.7)
        .foregroundStyle(Palette.muted)
    }
  }
  private func ledgerLine(_ label: String, _ value: String) -> some View {
    HStack {
      Text(label).foregroundStyle(Palette.muted)
      Spacer()
      Text(value).monospacedDigit()
    }.font(.system(size: 14))
  }
  private func primary(_ label: String, icon: String, id: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      HStack {
        Spacer()
        Text(label).font(.system(size: 16, weight: .semibold))
        Spacer()
        Image(systemName: icon).font(.system(size: 15, weight: .semibold))
      }
      .padding(.horizontal, 20)
      .frame(minHeight: 55)
      .foregroundStyle(Palette.ink)
      .background(Palette.orange, in: RoundedRectangle(cornerRadius: 17))
    }
    .buttonStyle(PressStyle())
    .accessibilityIdentifier(id)
  }
  private func iconButton(_ icon: String, label: String, id: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      Image(systemName: icon).font(.system(size: 17))
        .frame(width: 44, height: 44)
        .background(Palette.mint.opacity(0.07), in: Circle())
    }.accessibilityLabel(label).accessibilityIdentifier(id)
  }
  private func offerTutorial() {
    if !learned {
      tutorialStep = 0
      sheet = .tutorial
    }
  }
  private func tick() {
    if haptics { UISelectionFeedbackGenerator().selectionChanged() }
  }
  private var shareText: String {
    "Moon Market · \(store.run.rank)\n\(store.run.cash) credits · \(store.run.profit >= 0 ? "+" : "")\(store.run.profit) profit\n8 nights · seed \(store.run.seed)\(store.run.daily ? " · Daily orbit" : "")"
  }
  private func share() {
    let renderer = ImageRenderer(
      content:
        VStack(spacing: 22) {
          Text("MOON MARKET").font(.system(size: 18, weight: .medium, design: .serif)).tracking(4)
            .foregroundStyle(Palette.cream)
          ReceiptView(run: store.run)
          Text("A tiny stall. A whole galaxy of possibility.")
            .font(.system(size: 11)).foregroundStyle(Palette.muted)
        }
        .padding(30).frame(width: 390).background(Palette.ink)
    )
    renderer.scale = 3
    shareImage = renderer.uiImage
    sharing = true
  }
}

struct ReceiptView: View {
  let run: Run
  var body: some View {
    VStack(spacing: 13) {
      HStack {
        Image(systemName: "moon.stars.fill")
        Spacer()
        Text("LUNE TRADING CO.").font(.system(size: 10, weight: .bold, design: .monospaced))
          .tracking(1)
        Spacer()
        Image(systemName: "sparkle")
      }
      Text(run.won ? "A STALL IS BORN" : "UNTIL THE NEXT ORBIT")
        .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2)
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text("\(run.cash)").font(.system(size: 57, weight: .regular, design: .serif)).tracking(-3)
        Text("cr").font(.system(size: 18, design: .serif))
      }
      HStack {
        Text("NET PROFIT")
        Spacer()
        Text("\(run.profit >= 0 ? "+" : "")\(run.profit) cr").bold()
      }.font(.system(size: 13, design: .monospaced))
      Rectangle().fill(Palette.ink.opacity(0.2)).frame(height: 1)
      HStack {
        Text("\(run.history.reduce(0) { $0 + $1.customers }) CUSTOMERS")
        Spacer()
        Text("8 NIGHTS")
      }.font(.system(size: 10, design: .monospaced))
      HStack {
        ForEach(0..<35) { index in
          Rectangle().frame(width: index % 3 == 0 ? 3 : 1, height: 19)
        }
      }.opacity(0.65).accessibilityHidden(true)
      Text("\(run.daily ? "DAILY ORBIT" : "ORBIT") / \(run.seed)")
        .font(.system(size: 10, design: .monospaced)).tracking(1)
    }
    .padding(22)
    .foregroundStyle(Palette.ink)
    .background(Palette.cream, in: ReceiptShape())
    .accessibilityElement(children: .combine)
  }
}

struct ReceiptShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: .init(x: 0, y: 0))
    path.addLine(to: .init(x: rect.maxX, y: 0))
    path.addLine(to: .init(x: rect.maxX, y: rect.maxY - 7))
    let count = 22
    for index in stride(from: count, through: 0, by: -1) {
      let x = rect.width * CGFloat(index) / CGFloat(count)
      path.addLine(to: .init(x: x, y: rect.maxY - (index % 2 == 0 ? 7 : 0)))
    }
    path.closeSubpath()
    return path
  }
}

struct PressStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
      .opacity(configuration.isPressed ? 0.85 : 1)
      .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  let image: UIImage?
  let text: String
  func makeUIViewController(context: Context) -> UIActivityViewController {
    if let image {
      return UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
    }
    return UIActivityViewController(activityItems: [text], applicationActivities: nil)
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
