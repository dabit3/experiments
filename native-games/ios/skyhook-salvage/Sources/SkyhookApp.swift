import Combine
import SwiftUI
import UIKit

@main
struct SkyhookApp: App {
  var body: some Scene {
    WindowGroup { HarborView() }
  }
}

struct SharePayload: Identifiable {
  let id = UUID()
  let image: UIImage
  let text: String
}

struct TutorialRequest: Identifiable {
  let id = UUID()
  let startsGame: Bool
  let practice: Bool
}

struct HarborView: View {
  @State private var game = GameModel()
  @State private var selectedContract = 0
  @State private var settingsShown = false
  @State private var tutorialRequest: TutorialRequest?
  @State private var sharePayload: SharePayload?
  @State private var feedback = Feedback()
  @AppStorage("tutorialSeen") private var tutorialSeen = false
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reducedMotion
  private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

  var body: some View {
    ZStack {
      HarborPalette.cream.ignoresSafeArea()
      if !game.isPlaying {
        home
      } else if game.phase == .finished {
        results
      } else {
        gameplay
      }
      if game.paused && game.isPlaying && game.phase != .finished {
        pauseOverlay
      }
    }
    .foregroundStyle(HarborPalette.ink)
    .onReceive(timer) { _ in game.tick(1.0 / 30) }
    .onChange(of: game.cueSerial) {
      if let cue = game.cue {
        feedback.play(cue, audio: game.audioEnabled, haptics: game.hapticsEnabled)
      }
    }
    .onChange(of: scenePhase) {
      if scenePhase != .active && game.isPlaying && game.phase != .finished { game.paused = true }
    }
    .sheet(isPresented: $settingsShown) { settings }
    .sheet(item: $tutorialRequest) { request in tutorial(request) }
    .sheet(item: $sharePayload) { payload in
      NativeShare(payload: payload)
        .presentationDetents([.medium, .large])
    }
    .preferredColorScheme(.light)
  }

  private var home: some View {
    GeometryReader { geometry in
      let compact = geometry.size.height < 700
      VStack(spacing: 0) {
        HStack(spacing: 10) {
          HarborMark().frame(width: 31, height: 31)
          VStack(alignment: .leading, spacing: 3) {
            eyebrow("PORT MARLOW")
            Text("Salvage office · No. 07")
              .font(.system(size: 10)).foregroundStyle(HarborPalette.muted)
          }
          Spacer()
          iconButton("slider.horizontal.3", label: "Settings", id: "settings") {
            settingsShown = true
          }
        }
        .padding(.horizontal, 24)
        VStack(spacing: 0) {
          Text("Skyhook")
            .font(.custom("Baskerville", size: compact ? 54 : 70, relativeTo: .largeTitle))
            .tracking(-2)
          HStack(spacing: 15) {
            Rectangle().frame(width: 25, height: 0.5)
            Text("SALVAGE COMPANY")
              .font(.system(size: 10, weight: .medium)).tracking(3.5)
            Rectangle().frame(width: 25, height: 0.5)
          }
          .foregroundStyle(HarborPalette.brass)
          Text("Lost things. Lofty ambitions.")
            .font(.custom("Baskerville-Italic", size: 15))
            .foregroundStyle(HarborPalette.muted)
            .padding(.top, compact ? 8 : 12)
        }
        .padding(.top, compact ? 0 : 7)
        .padding(.bottom, compact ? 15 : 22)
        VStack(spacing: 0) {
          GeometryReader { art in
            Image("HarborCover")
              .resizable().scaledToFill()
              .frame(width: art.size.width, height: art.size.height)
              .clipped()
          }
          .accessibilityLabel("Illustrated brass airship and rooftop crane above Port Marlow")
          HStack {
            eyebrow("THE SMALL WONDER")
            Spacer()
            Text("A second life for beautiful things.")
              .font(.custom("Baskerville-Italic", size: 11))
          }
          .padding(.horizontal, 12).padding(.vertical, 10)
          .background(HarborPalette.paper)
        }
        .overlay(Rectangle().strokeBorder(HarborPalette.rule, lineWidth: 0.7))
        .padding(.horizontal, 20)
        VStack(spacing: compact ? 8 : 13) {
          HStack(spacing: 13) {
            VStack(spacing: 0) {
              Text("NO.").font(.system(size: 7, weight: .semibold)).tracking(1.5)
              Text(String(format: "%02d", selectedContract + 1))
                .font(.custom("Baskerville", size: 30))
            }
            .foregroundStyle(HarborPalette.orange)
            .frame(width: 43, height: 49)
            .overlay(Rectangle().stroke(HarborPalette.orange.opacity(0.35), lineWidth: 0.7))
            VStack(alignment: .leading, spacing: 5) {
              Text(Contract.all[selectedContract].title)
                .font(.custom("Baskerville", size: 23))
                .lineLimit(1).minimumScaleFactor(0.8)
              eyebrow(
                "\(Contract.all[selectedContract].cargo.count) TREASURES  ·  \(Int(Contract.all[selectedContract].seconds)) SECONDS"
              )
              .foregroundStyle(HarborPalette.muted)
            }
            Spacer(minLength: 0)
            HStack(spacing: 0) {
              iconButton("chevron.left", label: "Previous contract", id: "previousContract") {
                selectedContract = max(0, selectedContract - 1)
              }.disabled(selectedContract == 0)
              iconButton("chevron.right", label: "Next unlocked contract", id: "nextContract") {
                selectedContract = min(game.unlocked, selectedContract + 1)
              }.disabled(selectedContract >= game.unlocked)
            }
          }
          primaryButton("Begin salvage", symbol: "arrow.up.right", id: "beginSalvage") {
            begin(practice: false)
          }
          HStack {
            Button {
              begin(practice: true)
            } label: {
              HStack(spacing: 7) {
                Image(systemName: "wind").font(.system(size: 12))
                Text("Practice dock").font(.custom("Baskerville", size: 16))
              }.frame(minHeight: 44)
            }.accessibilityIdentifier("practiceDock")
            Spacer()
            eyebrow("BEST  \(game.best.formatted())")
              .foregroundStyle(HarborPalette.muted)
          }
        }
        .padding(.horizontal, 24)
        .padding(.top, compact ? 14 : 20)
      }
    }
  }

  private var gameplay: some View {
    VStack(spacing: 0) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 4) {
          eyebrow(game.practice ? "PRACTICE DOCK" : "CONTRACT 0\(game.contract.id + 1)")
          Text(game.score.formatted())
            .font(.custom("Baskerville", size: 32))
            .contentTransition(.numericText())
            .accessibilityLabel("Score \(game.score)")
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 5) {
          Text(game.practice ? "NO TIME LIMIT" : "\(Int(ceil(game.timeLeft)))s")
            .font(.system(size: 17, weight: .medium, design: .monospaced))
            .foregroundStyle(game.timeLeft < 15 ? HarborPalette.orange : HarborPalette.ink)
          Text(game.practice ? "\(game.losses) missed lifts" : "\(3 - game.losses) lifts to spare")
            .font(.system(size: 10))
            .foregroundStyle(HarborPalette.muted)
        }
        iconButton("pause", label: "Pause game", id: "pauseGame") { game.paused = true }
      }
      .padding(.horizontal, 22)
      .padding(.bottom, 8)
      HStack(spacing: 12) {
        Image(game.cargo.assetName).resizable().scaledToFit()
          .frame(width: 36, height: 32).accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 3) {
          Text(game.cargo.title).font(.custom("Baskerville", size: 20))
          eyebrow(
            "\(Int(game.cargo.weight)) TONNES  /  \(game.stack.count) OF \(game.contract.cargo.count) ABOARD"
          )
        }
        Spacer()
        HStack(spacing: 4) {
          ForEach(0..<game.contract.cargo.count, id: \.self) { index in
            Circle().fill(index < game.stack.count ? HarborPalette.orange : HarborPalette.rule)
              .frame(width: 5, height: 5)
          }
        }
        .accessibilityLabel("\(game.stack.count) of \(game.contract.cargo.count) treasures rescued")
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 10)
      .overlay(alignment: .top) { Rectangle().fill(HarborPalette.rule).frame(height: 0.5) }
      HarborCanvas(game: game, reducedMotion: reducedMotion)
        .frame(maxHeight: .infinity)
        .clipped()
        .overlay(Rectangle().strokeBorder(HarborPalette.rule, lineWidth: 0.5))
        .padding(.horizontal, 12)
      VStack(spacing: 6) {
        HStack(spacing: 9) {
          Image(systemName: game.onTarget ? "checkmark.circle.fill" : "scope")
            .font(.system(size: 12))
            .foregroundStyle(game.onTarget ? HarborPalette.sage : HarborPalette.orange)
          Text(controlHint)
            .font(.system(size: 11, weight: .medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 32)
            .accessibilityIdentifier("gameHint")
        }
        HStack(spacing: 12) {
          Button {
            game.shift(-0.25)
          } label: {
            Image(systemName: "arrow.left").frame(width: 44, height: 44)
          }
          .accessibilityLabel("Trim crane left").accessibilityIdentifier("trimLeft")
          CraneTrim(value: $game.trim)
          Button {
            game.shift(0.25)
          } label: {
            Image(systemName: "arrow.right").frame(width: 44, height: 44)
          }
          .accessibilityLabel("Trim crane right").accessibilityIdentifier("trimRight")
        }
        .disabled(!game.actionable)
        primaryButton(
          game.buttonTitle, symbol: game.phase == .release ? "arrow.down.to.line" : "arrow.down",
          id: "craneAction"
        ) { game.act() }
        .disabled(!game.actionable)
      }
      .padding(.horizontal, 24)
      .padding(.top, 3)
      .padding(.bottom, 6)
    }
  }

  private var controlHint: String {
    switch game.phase {
    case .pickup:
      return game.onTarget
        ? "In reach · drop now to catch the cargo."
        : "Adjust trim · line up the hook with the left dock."
    case .release:
      return game.onTarget
        ? "Safe to land · release cargo onto the stack."
        : "Adjust trim · place cargo above the stack's center."
    default:
      return game.message
    }
  }

  private var results: some View {
    ScrollView {
      VStack(spacing: 18) {
        HStack {
          eyebrow("CARGO MANIFEST  /  0\(game.contract.id + 1)")
          Spacer()
          iconButton("xmark", label: "Return to harbor", id: "resultsHome") { game.home() }
        }
        ManifestCard(
          won: game.won, practice: game.practice, score: game.score, stack: game.stack,
          title: game.contract.title, reason: game.resultReason)
        VStack(spacing: 10) {
          primaryButton(
            game.won && !game.practice && game.contract.id < 2 ? "Next contract" : "Try again",
            symbol: "arrow.up.right", id: "replay"
          ) {
            let next = game.won && !game.practice ? min(2, game.contract.id + 1) : game.contract.id
            selectedContract = next
            game.start(contract: next, practice: game.practice)
          }
          Button {
            shareManifest()
          } label: {
            Label("Share cargo manifest", systemImage: "square.and.arrow.up")
              .font(.system(size: 15, weight: .semibold))
              .frame(maxWidth: .infinity, minHeight: 50)
              .overlay(Rectangle().stroke(HarborPalette.rule, lineWidth: 0.7))
          }
          .accessibilityIdentifier("shareManifest")
          Text(
            game.practice
              ? "Practice run · best score unchanged" : "PERSONAL BEST  \(game.best.formatted())"
          )
          .font(.system(size: 11, weight: .medium, design: .monospaced))
          .padding(.top, 4)
        }
      }
      .padding(.horizontal, 26)
      .padding(.bottom, 24)
    }
    .scrollIndicators(.hidden)
  }

  private var pauseOverlay: some View {
    ZStack {
      HarborPalette.ink.opacity(0.55).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 20) {
        HarborMark().frame(width: 42, height: 42)
        eyebrow("ALL LINES SECURED")
        Text("Take a breather.")
          .font(.custom("Baskerville", size: 36))
        Text("Your crane and harbor clock are paused.")
          .font(.system(size: 15))
        primaryButton("Resume salvage", symbol: "play.fill", id: "resume") { game.paused = false }
        Button("Restart contract") {
          game.start(contract: game.contract.id, practice: game.practice)
        }
        .frame(maxWidth: .infinity, minHeight: 44).accessibilityIdentifier("restart")
        Button("Return to harbor") { game.home() }
          .frame(maxWidth: .infinity, minHeight: 44).accessibilityIdentifier("pauseHome")
      }
      .padding(26)
      .background(HarborPalette.paper)
      .overlay(
        Rectangle().strokeBorder(HarborPalette.brass.opacity(0.5), lineWidth: 0.8).padding(7)
      )
      .padding(24)
    }
    .accessibilityAddTraits(.isModal)
  }

  private var settings: some View {
    NavigationStack {
      Form {
        Section {
          HStack(spacing: 14) {
            HarborMark().frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 4) {
              Text("The ship's quarters").font(.custom("Baskerville", size: 27))
              eyebrow("MAKE YOURSELF AT HOME")
            }
          }
          .padding(.vertical, 12)
        }.listRowBackground(Color.clear)
        Section("On the airship") {
          Toggle("Harbor sounds", isOn: $game.audioEnabled).accessibilityIdentifier("audioToggle")
          Toggle("Haptic feedback", isOn: $game.hapticsEnabled).accessibilityIdentifier(
            "hapticsToggle")
        }.listRowBackground(HarborPalette.paper)
        Section("Your logbook") {
          LabeledContent("Best manifest", value: game.best.formatted())
          LabeledContent("Contracts cleared", value: "\(game.completed)")
          LabeledContent("Routes unlocked", value: "\(game.unlocked + 1) / 3")
        }.listRowBackground(HarborPalette.paper)
        Section {
          Button("How to salvage") {
            settingsShown = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
              tutorialRequest = TutorialRequest(startsGame: false, practice: false)
            }
          }.accessibilityIdentifier("howToPlay")
        } footer: {
          Text(
            "Made for quiet moments. Progress stays on this iPhone. Motion follows your system accessibility setting."
          )
        }
      }
      .scrollContentBackground(.hidden)
      .background(HarborPalette.cream)
      .tint(HarborPalette.orange)
      .navigationTitle("Skyhook")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { settingsShown = false }.accessibilityIdentifier("settingsDone")
        }
      }
    }
    .presentationDetents([.large])
  }

  private func tutorial(_ request: TutorialRequest) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        HStack {
          eyebrow("A NOTE FROM THE DOCKMASTER")
          Spacer()
          HarborMark().frame(width: 34, height: 34)
        }
        Text("Two moves.\nOne steady ship.")
          .font(.custom("Baskerville", size: 36))
          .tracking(-1)
        LiftDiagram().aspectRatio(330.0 / 84.0, contentMode: .fit)
        tutorialStep("01", "Catch the treasure", "Tap Drop hook as it swings over the left dock.")
        tutorialStep(
          "02", "Make a soft landing",
          "Wait for the cargo to reach the ship, then release over the stack. The dashed line predicts your landing."
        )
        tutorialStep(
          "03", "Keep your balance",
          "Trim left or right to move the crane. Heavy cargo pulls harder. Keep the deck's bubble near the middle."
        )
        Text("Three missed lifts end a contract. Practice has no clock and unlimited missed lifts.")
          .font(.system(size: 13)).foregroundStyle(HarborPalette.ink.opacity(0.8))
        primaryButton(
          request.startsGame ? "Let's salvage" : "Got it", symbol: "arrow.up.right",
          id: "tutorialContinue"
        ) {
          tutorialSeen = true
          tutorialRequest = nil
          if request.startsGame {
            game.start(contract: selectedContract, practice: request.practice)
          }
        }
      }
      .padding(28)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(HarborPalette.cream)
    .presentationDetents([.large])
  }

  private func tutorialStep(_ number: String, _ title: String, _ detail: String) -> some View {
    HStack(alignment: .top, spacing: 17) {
      Text(number).font(.custom("Baskerville", size: 25)).foregroundStyle(HarborPalette.orange)
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.custom("Baskerville", size: 21))
        Text(detail).font(.system(size: 14)).lineSpacing(3)
      }
    }
  }

  private func begin(practice: Bool) {
    if !tutorialSeen {
      tutorialRequest = TutorialRequest(startsGame: true, practice: practice)
    } else {
      game.start(contract: selectedContract, practice: practice)
    }
  }

  private func shareManifest() {
    let renderer = ImageRenderer(
      content: ManifestCard(
        won: game.won, practice: game.practice, score: game.score, stack: game.stack,
        title: game.contract.title, reason: game.resultReason
      )
      .padding(28)
      .frame(width: 390)
      .background(HarborPalette.cream)
      .environment(\.colorScheme, .light)
    )
    renderer.scale = 3
    if let image = renderer.uiImage {
      sharePayload = SharePayload(
        image: image,
        text:
          "Skyhook Salvage — \(game.score) points, \(game.stack.count) treasures aboard. \(game.contract.title)."
      )
    }
  }
}

struct ManifestCard: View {
  let won: Bool
  let practice: Bool
  let score: Int
  let stack: [StackedCargo]
  let title: String
  let reason: String

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        HarborMark().frame(width: 27, height: 27)
        Spacer()
        eyebrow("PORT MARLOW  /  CARGO RECEIPT")
      }
      VStack(spacing: 6) {
        Text(won ? "Safe harbor." : "Another tide.")
          .font(.custom("Baskerville", size: 44)).tracking(-1)
          .lineLimit(1).minimumScaleFactor(0.8)
        Text(won ? "CONTRACT CLEARED" : "CONTRACT INCOMPLETE")
          .font(.system(size: 8, weight: .medium)).tracking(2)
          .foregroundStyle(HarborPalette.orange)
      }
      Canvas { context, size in
        let scale = size.width / 350
        context.scaleBy(x: scale, y: scale)
        let deck = 36.0 + Double(max(3, stack.count)) * 31
        let shipX = 175.0
        context.draw(
          Image("HarborBackdrop"),
          in: CGRect(x: 0, y: 0, width: 350, height: 135 + Double(max(3, stack.count)) * 31))
        HarborArt.airship(&context, x: shipX, y: deck, clock: 0)
        for (index, item) in stack.enumerated() {
          var cargoContext = context
          cargoContext.translateBy(x: shipX, y: deck)
          cargoContext.scaleBy(x: 0.85, y: 0.85)
          HarborArt.cargo(
            &cargoContext, kind: item.kind, x: item.x - DockRules.shipX,
            y: -Double(index + 1) * 36)
        }
        HarborArt.balanceGauge(&context, x: shipX, y: deck + 16, balance: DockRules.balance(stack))
      }
      .aspectRatio(350.0 / Double(135 + max(3, stack.count) * 31), contentMode: .fit)
      .accessibilityLabel("Cargo tower with \(stack.count) treasures on the Small Wonder")
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 3) {
          Text(score.formatted()).font(.custom("Baskerville", size: 39))
          eyebrow(practice ? "PRACTICE POINTS" : "SALVAGE POINTS")
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 3) {
          Text("\(stack.reduce(0) { $0 + Int($1.kind.weight) }) t")
            .font(.custom("Baskerville", size: 31))
          eyebrow("\(stack.count) TREASURES ABOARD")
        }
      }
      Rectangle().fill(HarborPalette.rule).frame(height: 0.7)
      VStack(alignment: .leading, spacing: 7) {
        ForEach(stack) { item in
          HStack {
            Image(item.kind.assetName).resizable().scaledToFit()
              .frame(width: 28, height: 22).accessibilityHidden(true)
            Text(item.kind.title)
            Spacer()
            Text("\(Int(item.kind.weight)) t").monospaced()
          }
          .font(.system(size: 12))
        }
        if stack.isEmpty {
          Text("An empty deck. A fresh start.").font(.system(size: 13))
        }
      }
      Text(reason).font(.custom("Baskerville-Italic", size: 16))
        .foregroundStyle(HarborPalette.muted)
        .multilineTextAlignment(.center).padding(.top, 2)
      eyebrow("SKYHOOK SALVAGE  /  \(title.uppercased())")
        .padding(.top, 3)
    }
    .padding(18)
    .background(HarborPalette.paper)
    .overlay(Rectangle().strokeBorder(HarborPalette.rule, lineWidth: 0.7))
    .foregroundStyle(HarborPalette.ink)
  }
}

struct LiftDiagram: View {
  var body: some View {
    Canvas { context, size in
      let scale = size.width / 330
      context.scaleBy(x: scale, y: scale)
      HarborArt.rounded(
        &context, rect: CGRect(x: 0, y: 0, width: 330, height: 84),
        radius: 2, color: HarborPalette.sky.opacity(0.55))
      HarborArt.cargo(&context, kind: .trunk, x: 53, y: 24)
      HarborArt.line(
        &context, from: CGPoint(x: 16, y: 61), to: CGPoint(x: 90, y: 61),
        color: HarborPalette.ink, width: 3)
      HarborArt.cargo(&context, kind: .trunk, x: 166, y: 19)
      HarborArt.line(
        &context, from: CGPoint(x: 166, y: 2), to: CGPoint(x: 166, y: 19),
        color: HarborPalette.ink)
      HarborArt.cargo(&context, kind: .trunk, x: 277, y: 24)
      HarborArt.line(
        &context, from: CGPoint(x: 235, y: 61), to: CGPoint(x: 318, y: 61),
        color: HarborPalette.ink, width: 3)
      for x in [107.0, 220.0] {
        HarborArt.label(&context, "→", x: x, y: 40, size: 17)
      }
      HarborArt.label(&context, "CATCH", x: 53, y: 74, size: 7)
      HarborArt.label(&context, "HOIST", x: 166, y: 74, size: 7)
      HarborArt.label(&context, "LAND", x: 277, y: 74, size: 7)
    }
    .accessibilityLabel("Catch cargo on the left dock, hoist across, then land on the ship")
  }
}

struct NativeShare: UIViewControllerRepresentable {
  let payload: SharePayload
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(
      activityItems: [payload.image, payload.text], applicationActivities: nil)
  }
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

func eyebrow(_ text: String) -> some View {
  Text(text)
    .font(.system(size: 8, weight: .medium))
    .tracking(1.2)
}

func primaryButton(
  _ title: String, symbol: String, id: String, action: @escaping () -> Void
) -> some View {
  Button(action: action) {
    HStack {
      Text(title)
      Spacer()
      Image(systemName: symbol).font(.system(size: 14, weight: .regular))
    }
    .font(.custom("Baskerville", size: 21))
    .padding(.horizontal, 20)
    .frame(maxWidth: .infinity, minHeight: 54)
    .foregroundStyle(HarborPalette.cream)
    .background(HarborPalette.ink, in: RoundedRectangle(cornerRadius: 3))
    .overlay(
      RoundedRectangle(cornerRadius: 1).strokeBorder(
        HarborPalette.cream.opacity(0.2), lineWidth: 0.7
      )
      .padding(4))
  }
  .buttonStyle(HarborButtonStyle())
  .accessibilityIdentifier(id)
}

func iconButton(
  _ symbol: String, label: String, id: String, action: @escaping () -> Void
) -> some View {
  Button(action: action) {
    Image(systemName: symbol).font(.system(size: 14, weight: .regular))
      .frame(width: 44, height: 44)
  }
  .accessibilityLabel(label)
  .accessibilityIdentifier(id)
}

struct HarborButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var enabled
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.55)
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
  }
}

struct HarborMark: View {
  var body: some View {
    Canvas { context, size in
      context.scaleBy(x: size.width / 40, y: size.height / 40)
      context.stroke(
        Path(ellipseIn: CGRect(x: 1, y: 1, width: 38, height: 38)),
        with: .color(HarborPalette.brass), lineWidth: 0.7)
      context.stroke(
        Path(ellipseIn: CGRect(x: 4, y: 4, width: 32, height: 32)),
        with: .color(HarborPalette.brass.opacity(0.4)), lineWidth: 0.5)
      var hook = Path()
      hook.move(to: CGPoint(x: 20, y: 9))
      hook.addLine(to: CGPoint(x: 20, y: 21))
      hook.addCurve(
        to: CGPoint(x: 28, y: 25),
        control1: CGPoint(x: 8, y: 22), control2: CGPoint(x: 20, y: 39))
      context.stroke(
        hook, with: .color(HarborPalette.ink), style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
      HarborArt.line(
        &context, from: CGPoint(x: 15, y: 13), to: CGPoint(x: 25, y: 13),
        color: HarborPalette.brass, width: 1)
    }
    .accessibilityHidden(true)
  }
}

struct CraneTrim: View {
  @Binding var value: Double

  var body: some View {
    GeometryReader { geometry in
      let track = max(1, geometry.size.width - 24)
      let position = 12 + (value + 1) / 2 * track
      ZStack(alignment: .leading) {
        Canvas { context, size in
          HarborArt.line(
            &context, from: CGPoint(x: 12, y: 24), to: CGPoint(x: size.width - 12, y: 24),
            color: HarborPalette.brass, width: 1)
          for index in 0...20 {
            let x = 12 + Double(index) / 20 * track
            let height = index % 5 == 0 ? 12.0 : 6.0
            HarborArt.line(
              &context, from: CGPoint(x: x, y: 24 - height / 2),
              to: CGPoint(x: x, y: 24 + height / 2),
              color: HarborPalette.brass.opacity(0.65), width: 0.7)
          }
        }
        Circle().fill(HarborPalette.paper)
          .overlay(Circle().strokeBorder(HarborPalette.brass, lineWidth: 1))
          .overlay(Rectangle().fill(HarborPalette.orange).frame(width: 2, height: 10))
          .frame(width: 24, height: 24)
          .offset(x: position - 12, y: 2)
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { drag in value = max(-1, min(1, (drag.location.x - 12) / track * 2 - 1)) })
    }
    .frame(height: 44)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Crane trim")
    .accessibilityIdentifier("craneTrim")
    .accessibilityValue("\(Int(value * 100)) percent")
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment: value = min(1, value + 0.1)
      case .decrement: value = max(-1, value - 0.1)
      @unknown default: break
      }
    }
  }
}
