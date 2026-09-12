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

struct HarborView: View {
  @State private var game = GameModel()
  @State private var selectedContract = 0
  @State private var settingsShown = false
  @State private var tutorialShown = false
  @State private var pendingStart = false
  @State private var pendingPractice = false
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
    .sheet(isPresented: $tutorialShown) { tutorial }
    .sheet(item: $sharePayload) { payload in
      NativeShare(payload: payload)
        .presentationDetents([.medium, .large])
    }
    .preferredColorScheme(.light)
  }

  private var home: some View {
    VStack(spacing: 0) {
      HStack {
        eyebrow("HARBOR NO. 07  /  EST. 1926")
        Spacer()
        iconButton("slider.horizontal.3", label: "Settings", id: "settings") {
          settingsShown = true
        }
      }
      .padding(.horizontal, 24)
      VStack(alignment: .leading, spacing: 7) {
        Text("Skyhook\nSalvage")
          .font(.system(size: 59, weight: .regular, design: .serif))
          .tracking(-3)
          .lineSpacing(-10)
          .fixedSize(horizontal: false, vertical: true)
        HStack(spacing: 8) {
          Rectangle().fill(HarborPalette.orange).frame(width: 23, height: 2)
          Text("Lost things. Lofty ambitions.")
            .font(.system(size: 14, weight: .medium))
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 28)
      .padding(.bottom, 18)
      HarborCanvas(game: game, decorative: true, reducedMotion: reducedMotion)
        .frame(maxHeight: .infinity)
        .clipped()
      VStack(spacing: 12) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 4) {
            eyebrow("CONTRACT 0\(selectedContract + 1)")
            Text(Contract.all[selectedContract].title)
              .font(.system(size: 23, weight: .regular, design: .serif))
          }
          Spacer()
          HStack(spacing: 0) {
            iconButton("chevron.left", label: "Previous contract", id: "previousContract") {
              selectedContract = max(0, selectedContract - 1)
            }
            .disabled(selectedContract == 0)
            iconButton("chevron.right", label: "Next unlocked contract", id: "nextContract") {
              selectedContract = min(game.unlocked, selectedContract + 1)
            }
            .disabled(selectedContract >= game.unlocked)
          }
        }
        primaryButton("Begin salvage", symbol: "arrow.up.right", id: "beginSalvage") {
          begin(practice: false)
        }
        HStack {
          Button {
            begin(practice: true)
          } label: {
            Text("Practice dock").font(.system(size: 14, weight: .semibold))
              .frame(minHeight: 44)
          }
          .accessibilityIdentifier("practiceDock")
          Spacer()
          Text("BEST \(game.best.formatted())")
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
        }
      }
      .padding(.horizontal, 28)
      .padding(.top, 16)
      .padding(.bottom, 3)
    }
  }

  private var gameplay: some View {
    VStack(spacing: 0) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 4) {
          eyebrow(game.practice ? "PRACTICE DOCK" : "CONTRACT 0\(game.contract.id + 1)")
          Text(game.score.formatted())
            .font(.system(size: 29, weight: .regular, design: .serif))
            .contentTransition(.numericText())
            .accessibilityLabel("Score \(game.score)")
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 5) {
          Text(game.practice ? "NO TIME LIMIT" : "\(Int(ceil(game.timeLeft)))s")
            .font(.system(size: 16, weight: .semibold, design: .monospaced))
            .foregroundStyle(game.timeLeft < 15 ? HarborPalette.orange : HarborPalette.ink)
          Text(game.practice ? "\(game.losses) missed lifts" : "\(3 - game.losses) lifts to spare")
            .font(.system(size: 10, weight: .medium))
        }
        iconButton("pause", label: "Pause game", id: "pauseGame") { game.paused = true }
      }
      .padding(.horizontal, 22)
      .padding(.bottom, 10)
      HStack(spacing: 12) {
        Text(String(format: "%02d", game.cargoIndex + 1))
          .font(.system(size: 23, weight: .regular, design: .serif))
          .foregroundStyle(HarborPalette.orange)
        VStack(alignment: .leading, spacing: 3) {
          Text(game.cargo.title).font(.system(size: 16, weight: .semibold))
          eyebrow(
            "\(Int(game.cargo.weight)) TONNES  /  \(game.stack.count) OF \(game.contract.cargo.count) ABOARD"
          )
        }
        Spacer()
        HStack(spacing: 4) {
          ForEach(0..<game.contract.cargo.count, id: \.self) { index in
            Capsule().fill(
              index < game.stack.count ? HarborPalette.orange : HarborPalette.ink.opacity(0.15)
            )
            .frame(width: 5, height: 21)
          }
        }
        .accessibilityLabel("\(game.stack.count) of \(game.contract.cargo.count) treasures rescued")
      }
      .padding(.horizontal, 26)
      .padding(.vertical, 12)
      .background(HarborPalette.pale.opacity(0.6))
      HarborCanvas(game: game, reducedMotion: reducedMotion)
        .frame(maxHeight: .infinity)
        .clipped()
      VStack(spacing: 9) {
        HStack(spacing: 9) {
          Circle().fill(HarborPalette.orange).frame(width: 5, height: 5)
          Text(game.message)
            .font(.system(size: 12, weight: .medium))
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
          VStack(spacing: 1) {
            eyebrow("CRANE TRIM")
            Slider(value: $game.trim, in: -1...1)
              .tint(HarborPalette.orange)
              .accessibilityLabel("Crane trim")
              .accessibilityIdentifier("craneTrim")
          }
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
      .padding(.top, 8)
      .padding(.bottom, 8)
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
              .overlay(RoundedRectangle(cornerRadius: 12).stroke(HarborPalette.ink.opacity(0.25)))
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
        eyebrow("ALL LINES SECURED")
        Text("Take a breather.")
          .font(.system(size: 36, weight: .regular, design: .serif))
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
      .background(HarborPalette.cream, in: RoundedRectangle(cornerRadius: 24))
      .padding(24)
    }
    .accessibilityAddTraits(.isModal)
  }

  private var settings: some View {
    NavigationStack {
      Form {
        Section("On the airship") {
          Toggle("Harbor sounds", isOn: $game.audioEnabled).accessibilityIdentifier("audioToggle")
          Toggle("Haptic feedback", isOn: $game.hapticsEnabled).accessibilityIdentifier(
            "hapticsToggle")
        }
        Section("Your logbook") {
          LabeledContent("Best manifest", value: game.best.formatted())
          LabeledContent("Contracts cleared", value: "\(game.completed)")
          LabeledContent("Routes unlocked", value: "\(game.unlocked + 1) / 3")
        }
        Section {
          Button("How to salvage") {
            settingsShown = false
            pendingStart = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { tutorialShown = true }
          }.accessibilityIdentifier("howToPlay")
        } footer: {
          Text(
            "Made for quiet moments. Progress stays on this iPhone. Motion follows your system accessibility setting."
          )
        }
      }
      .tint(HarborPalette.orange)
      .navigationTitle("Ship's quarters")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { settingsShown = false }.accessibilityIdentifier("settingsDone")
        }
      }
    }
    .presentationDetents([.large])
  }

  private var tutorial: some View {
    VStack(alignment: .leading, spacing: 24) {
      eyebrow("A NOTE FROM THE DOCKMASTER")
      Text("Two moves.\nOne steady ship.")
        .font(.system(size: 39, weight: .regular, design: .serif))
        .tracking(-1)
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
        pendingStart ? "Let's salvage" : "Got it", symbol: "arrow.up.right", id: "tutorialContinue"
      ) {
        tutorialSeen = true
        tutorialShown = false
        if pendingStart { game.start(contract: selectedContract, practice: pendingPractice) }
      }
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(HarborPalette.cream)
    .presentationDetents([.large])
  }

  private func tutorialStep(_ number: String, _ title: String, _ detail: String) -> some View {
    HStack(alignment: .top, spacing: 17) {
      Text(number).font(.system(size: 25, design: .serif)).foregroundStyle(HarborPalette.orange)
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.system(size: 17, weight: .semibold))
        Text(detail).font(.system(size: 14)).lineSpacing(3)
      }
    }
  }

  private func begin(practice: Bool) {
    if !tutorialSeen {
      pendingStart = true
      pendingPractice = practice
      tutorialShown = true
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
    VStack(spacing: 12) {
      VStack(spacing: 6) {
        Text(won ? "Safe harbor." : "Another tide.")
          .font(.system(size: 46, weight: .regular, design: .serif)).tracking(-2)
        Text(won ? "CONTRACT CLEARED" : "CONTRACT INCOMPLETE")
          .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2)
          .foregroundStyle(HarborPalette.orange)
      }
      Canvas { context, size in
        let scale = size.width / 350
        context.scaleBy(x: scale, y: scale)
        let deck = 36.0 + Double(max(3, stack.count)) * 31
        let shipX = 175.0
        HarborArt.ellipse(
          &context, CGRect(x: 38, y: 18, width: 274, height: 195),
          HarborPalette.sky.opacity(0.6))
        HarborArt.cloud(&context, x: 58, y: 87, scale: 0.7)
        HarborArt.cloud(&context, x: 300, y: 55, scale: 0.5)
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
      .frame(height: CGFloat(130 + max(3, stack.count) * 31))
      .accessibilityLabel("Cargo tower with \(stack.count) treasures on the Small Wonder")
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 3) {
          Text(score.formatted()).font(.system(size: 39, weight: .regular, design: .serif))
          eyebrow(practice ? "PRACTICE POINTS" : "SALVAGE POINTS")
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 3) {
          Text("\(stack.reduce(0) { $0 + Int($1.kind.weight) }) t")
            .font(.system(size: 31, weight: .regular, design: .serif))
          eyebrow("\(stack.count) TREASURES ABOARD")
        }
      }
      Rectangle().fill(HarborPalette.ink.opacity(0.2)).frame(height: 1)
      VStack(alignment: .leading, spacing: 7) {
        ForEach(stack) { item in
          HStack {
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
      Text(reason).font(.system(size: 13)).multilineTextAlignment(.center).padding(.top, 2)
      eyebrow("SKYHOOK SALVAGE  /  \(title.uppercased())")
        .padding(.top, 3)
    }
    .foregroundStyle(HarborPalette.ink)
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
    .font(.system(size: 9, weight: .semibold, design: .monospaced))
    .tracking(1.2)
}

func primaryButton(
  _ title: String, symbol: String, id: String, action: @escaping () -> Void
) -> some View {
  Button(action: action) {
    HStack {
      Text(title)
      Spacer()
      Image(systemName: symbol)
    }
    .font(.system(size: 17, weight: .semibold))
    .padding(.horizontal, 20)
    .frame(maxWidth: .infinity, minHeight: 54)
    .foregroundStyle(HarborPalette.cream)
    .background(HarborPalette.ink, in: RoundedRectangle(cornerRadius: 13))
  }
  .buttonStyle(HarborButtonStyle())
  .accessibilityIdentifier(id)
}

func iconButton(
  _ symbol: String, label: String, id: String, action: @escaping () -> Void
) -> some View {
  Button(action: action) {
    Image(systemName: symbol).font(.system(size: 16, weight: .medium))
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
