import SwiftUI

@main
struct TinyTectonicsApp: App {
  var body: some Scene {
    WindowGroup {
      ExpeditionView()
        .preferredColorScheme(.light)
    }
  }
}

private enum Destination {
  case home, atlas, play
}

struct ExpeditionView: View {
  @StateObject private var game = GameStore()
  @State private var destination = Destination.home
  @State private var settings = false
  @State private var restartConfirmation = false
  @State private var shareImage: SharedLandscape?
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private let clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

  var body: some View {
    ZStack {
      Earth.paper.ignoresSafeArea()
      VStack(spacing: 0) {
        switch destination {
        case .home: home
        case .atlas: atlas
        case .play: play
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 10)
      .padding(.bottom, 12)
    }
    .foregroundStyle(Earth.ink)
    .font(.system(.body, design: .rounded))
    .sheet(isPresented: $settings) { settingsSheet }
    .sheet(item: $shareImage) { item in
      NativeShare(
        image: item.image,
        caption:
          "I shaped \(game.level.name) in \(game.moves) moves. Tiny Tectonics — a world in balance."
      )
      .presentationDetents([.medium, .large])
    }
    .confirmationDialog(
      "Reset this landscape?", isPresented: $restartConfirmation, titleVisibility: .visible
    ) {
      Button("Reset landscape", role: .destructive) { game.reset() }
      Button("Keep shaping", role: .cancel) {}
    } message: {
      Text("Your current moves will be cleared. Completed landscapes stay saved.")
    }
    .onReceive(clock) { _ in game.tick(1.0 / 30) }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active, game.phase == .running { game.togglePause() }
    }
  }

  private var home: some View {
    VStack(spacing: 0) {
      HStack {
        eyebrow("A POCKET-SIZED PLANET")
        Spacer()
        iconButton("slider.horizontal.3", label: "Settings", id: "settings") { settings = true }
      }
      Spacer(minLength: 10)
      VStack(alignment: .leading, spacing: 10) {
        Text("Tiny\nTectonics")
          .font(.system(size: 57, weight: .regular, design: .serif))
          .tracking(-2.5)
          .lineSpacing(-5)
          .fixedSize(horizontal: false, vertical: true)
        HStack(spacing: 10) {
          Rectangle().fill(Earth.copper).frame(width: 27, height: 2)
          Text("Small shifts. Beautiful worlds.")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Earth.muted)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Diorama(
        level: Landscape.all[3], heights: [4, 3, 3, 2, 2, 1, 0], travel: 1.5
      )
      .frame(maxHeight: .infinity)
      .padding(.horizontal, -16)
      .accessibilityLabel("A miniature terracotta landscape above a turquoise river")
      VStack(spacing: 15) {
        HStack {
          eyebrow("FIELD NOTES / 01—10")
          Spacer()
          Text("\(game.completed) of 10 restored")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Earth.muted)
        }
        primaryButton(
          game.completed == 0 ? "Begin expedition" : "Continue expedition", symbol: "arrow.right",
          id: "begin"
        ) {
          game.load(game.unlocked)
          destination = .play
        }
        Button {
          destination = .atlas
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
            Text("The landscape collection")
          }
          .font(.system(size: 14, weight: .semibold))
          .frame(maxWidth: .infinity, minHeight: 44)
        }
        .accessibilityIdentifier("collection")
      }
    }
  }

  private var atlas: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        iconButton("arrow.left", label: "Back to home", id: "back-home") { destination = .home }
        Spacer()
        eyebrow("\(game.completed) / 10 RESTORED")
      }
      Text("The collection").font(.system(size: 34, design: .serif))
      Text("Ten landscapes. One gentle descent.")
        .font(.system(size: 15))
        .foregroundStyle(Earth.muted)
      ScrollView {
        VStack(spacing: 0) {
          ForEach(Landscape.all) { level in
            let accessible = level.id <= game.unlocked
            Button {
              game.load(level.id)
              destination = .play
            } label: {
              HStack(spacing: 16) {
                Text(String(format: "%02d", level.id + 1))
                  .font(.system(size: 27, design: .serif))
                  .foregroundStyle(accessible ? Earth.copper : Earth.muted.opacity(0.5))
                  .frame(width: 36)
                VStack(alignment: .leading, spacing: 5) {
                  Text(level.name).font(.system(size: 17, weight: .semibold))
                  Text(level.region).font(.system(size: 9, weight: .bold)).tracking(1.3)
                    .foregroundStyle(Earth.muted)
                }
                Spacer()
                if let stars = game.best["\(level.id)"] {
                  Text(String(repeating: "✦", count: stars))
                    .foregroundStyle(Earth.copper)
                    .font(.system(size: 15))
                } else {
                  Image(systemName: accessible ? "arrow.up.right" : "lock")
                    .font(.system(size: 15))
                }
              }
              .padding(.vertical, 21)
              .contentShape(Rectangle())
            }
            .disabled(!accessible)
            .opacity(accessible ? 1 : 0.6)
            .accessibilityLabel(
              "\(level.name), \(accessible ? "play landscape" : "locked, complete previous landscape")"
            )
            .accessibilityIdentifier("landscape-\(level.id + 1)")
            Rectangle().fill(Earth.ink.opacity(0.12)).frame(height: 1)
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }

  private var play: some View {
    VStack(spacing: 0) {
      HStack {
        iconButton("arrow.left", label: "Leave puzzle for collection", id: "leave-puzzle") {
          if game.phase == .running { game.togglePause() }
          destination = .atlas
        }
        Spacer()
        eyebrow("LANDSCAPE \(String(format: "%02d", game.levelIndex + 1)) / 10")
        Spacer()
        iconButton("slider.horizontal.3", label: "Settings", id: "settings") {
          if game.phase == .running { game.togglePause() }
          settings = true
        }
      }
      .padding(.bottom, 12)
      HStack(alignment: .firstTextBaseline) {
        Text(game.level.name)
          .font(.system(size: 31, design: .serif))
          .minimumScaleFactor(0.7)
          .lineLimit(1)
        Spacer(minLength: 8)
        Text(String(format: "%02d", game.levelIndex + 1))
          .font(.system(size: 31, design: .serif))
          .foregroundStyle(Earth.copper.opacity(0.45))
      }
      .padding(.bottom, 7)
      HStack {
        Label("\(game.remaining) moves left", systemImage: "square.3.layers.3d")
        Spacer()
        Label("\(game.collected) / \(game.level.fossils.count) amber", systemImage: "diamond")
      }
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(Earth.muted)
      .padding(.bottom, 14)
      Rectangle().fill(Earth.ink.opacity(0.14)).frame(height: 1)

      if game.phase == .won {
        success
      } else {
        Text(instruction)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(Earth.muted)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity, minHeight: 52)
          .padding(.top, 6)
        Diorama(
          level: game.level, heights: game.heights,
          selected: game.phase == .editing ? game.selected : nil,
          travel: game.travel, running: game.phase != .editing,
          onSelect: game.phase == .editing
            ? { index in
              game.selected = index
              game.feedback()
            } : nil
        )
        .frame(maxHeight: .infinity)
        .padding(.horizontal, -22)
        if game.phase == .failed {
          failure
        } else if game.phase == .editing {
          editor
        } else {
          simulationControls
        }
      }
    }
  }

  private var instruction: String {
    if game.phase == .failed { return "Every landscape takes a little practice." }
    if game.phase == .paused { return "Expedition paused. Your explorer is safe." }
    if game.phase == .running { return "Following gravity. Collecting little treasures." }
    if game.levelIndex == 0, game.moves == 0 {
      return "Start here: lift plate 2 once.\nThe explorer rolls level or down one layer."
    }
    if game.remaining == 0 { return "No moves left. Try your route, or undo a shift." }
    return "Tap a plate, then lift or lower.\nKeep each step level or one layer down."
  }

  private var editor: some View {
    VStack(spacing: 14) {
      HStack(spacing: 5) {
        Image(systemName: "circle.fill").font(.system(size: 5))
        Text("IVORY EXPLORER")
        Spacer()
        Image(systemName: "diamond.fill").foregroundStyle(Earth.gold)
        Text("AMBER")
        Spacer()
        Image(systemName: "circle").foregroundStyle(Earth.teal)
        Text("EXIT")
      }
      .font(.system(size: 8, weight: .bold))
      .tracking(0.7)
      .foregroundStyle(Earth.muted)
      .padding(.bottom, 4)
      HStack(spacing: 12) {
        adjustButton(delta: -1)
        VStack(spacing: 5) {
          eyebrow("PLATE \(String(format: "%02d", game.selected + 1))")
          Text("Layer \(game.heights[game.selected])")
            .font(.system(size: 22, design: .serif))
          Text(game.level.fixed.contains(game.selected) ? "Anchored" : "Ready to shape")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Earth.muted)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        adjustButton(delta: 1)
      }
      .padding(.vertical, 16)
      .padding(.horizontal, 12)
      .background(.white.opacity(0.43), in: RoundedRectangle(cornerRadius: 23))
      HStack(spacing: 12) {
        iconButton("arrow.uturn.backward", label: "Undo last terrain shift", id: "undo") {
          withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { game.undo() }
        }
        .disabled(!game.canUndo)
        .opacity(game.canUndo ? 1 : 0.35)
        primaryButton("Let it roll", symbol: "play.fill", id: "simulate") { game.simulate() }
        iconButton("arrow.counterclockwise", label: "Reset landscape", id: "reset") {
          restartConfirmation = true
        }
      }
      Text(
        "Best route: \(game.level.par) \(game.level.par == 1 ? "shift" : "shifts")  ·  Anchored ends stay in place"
      )
      .font(.system(size: 10, weight: .medium))
      .foregroundStyle(Earth.muted)
    }
  }

  private var simulationControls: some View {
    VStack(spacing: 15) {
      HStack {
        eyebrow(game.phase == .paused ? "PAUSED" : "THE EXPLORER IS ON ITS WAY")
        Spacer()
        Text("\(min(Int(game.travel) + 1, game.heights.count)) / \(game.heights.count)")
          .font(.system(size: 13, weight: .medium, design: .monospaced))
      }
      ProgressView(
        value: min(game.travel, Double(game.heights.count - 1)),
        total: Double(game.heights.count - 1)
      )
      .tint(Earth.teal)
      primaryButton(
        game.phase == .paused ? "Resume journey" : "Pause journey",
        symbol: game.phase == .paused ? "play.fill" : "pause.fill", id: "pause-resume"
      ) {
        game.togglePause()
      }
      Button("Return to shaping") { game.editAgain() }
        .font(.system(size: 14, weight: .semibold))
        .frame(minHeight: 44)
        .accessibilityIdentifier("return-to-shaping")
    }
    .padding(.bottom, 12)
  }

  private var failure: some View {
    VStack(spacing: 12) {
      Text(game.outcome.fault?.title ?? "Try another route.")
        .font(.system(size: 30, design: .serif))
      Text("Between plates \(game.outcome.reached + 1) and \(game.outcome.reached + 2)")
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(Earth.copper)
      Text(game.outcome.fault?.explanation ?? "")
        .font(.system(size: 14))
        .multilineTextAlignment(.center)
        .foregroundStyle(Earth.muted)
        .fixedSize(horizontal: false, vertical: true)
      primaryButton("Keep shaping", symbol: "arrow.uturn.backward", id: "retry") {
        game.editAgain()
      }
      Button("Reset landscape") { game.reset() }
        .font(.system(size: 13, weight: .semibold))
        .frame(minHeight: 44)
        .accessibilityIdentifier("failure-reset")
    }
  }

  private var success: some View {
    VStack(spacing: 0) {
      HStack(spacing: 8) {
        Rectangle().fill(Earth.copper.opacity(0.4)).frame(height: 1)
        eyebrow("LANDSCAPE RESTORED")
        Rectangle().fill(Earth.copper.opacity(0.4)).frame(height: 1)
      }
      .padding(.top, 25)
      Diorama(
        level: game.level, heights: game.heights, travel: Double(game.heights.count - 1),
        running: true, celebration: true
      )
      .frame(maxHeight: .infinity)
      .padding(.horizontal, -10)
      VStack(spacing: 10) {
        HStack(spacing: 10) {
          ForEach(0..<3) { index in
            Image(systemName: index < game.stars ? "sparkle" : "sparkle")
              .font(.system(size: index == 1 ? 30 : 22, weight: .medium))
              .foregroundStyle(index < game.stars ? Earth.copper : Earth.copper.opacity(0.2))
          }
        }
        .accessibilityLabel("\(game.stars) of 3 stars")
        Text(game.levelIndex == 9 ? "A world in balance." : "Beautifully balanced.")
          .font(.system(size: 29, design: .serif))
          .minimumScaleFactor(0.7)
          .lineLimit(1)
        Text(
          "\(game.moves) \(game.moves == 1 ? "shift" : "shifts")  ·  \(game.level.fossils.count) amber found  ·  \(game.stars == 3 ? "Perfect route" : "Landscape saved")"
        )
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(Earth.muted)
        .padding(.bottom, 14)
        primaryButton(
          game.levelIndex == 9 ? "View your collection" : "Next landscape", symbol: "arrow.right",
          id: "next-landscape"
        ) {
          if game.levelIndex == 9 { destination = .atlas } else { game.load(game.levelIndex + 1) }
        }
        HStack(spacing: 12) {
          Button {
            game.reset()
          } label: {
            Label("Play again", systemImage: "arrow.counterclockwise")
              .frame(maxWidth: .infinity, minHeight: 48)
          }
          .accessibilityIdentifier("play-again")
          Button {
            share()
          } label: {
            Label("Share landscape", systemImage: "square.and.arrow.up")
              .frame(maxWidth: .infinity, minHeight: 48)
          }
          .accessibilityIdentifier("share-landscape")
        }
        .font(.system(size: 12, weight: .semibold))
      }
    }
  }

  private var settingsSheet: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 22) {
        Text("A quieter kind of play.")
          .font(.system(size: 30, design: .serif))
        Toggle("Haptic feedback", isOn: $game.haptics)
          .tint(Earth.teal)
          .accessibilityIdentifier("haptics")
        Divider()
        Text("HOW THE WORLD WORKS").font(.system(size: 11, weight: .bold)).tracking(1.5)
        Text(
          "Tap a numbered plate. Lift or lower it one layer at a time. The ivory explorer rolls forward along the pale trail, on level ground or down a single layer."
        )
        Text(
          "Dotted copper links mark unsafe slopes. Anchored plates cannot move. Undo returns a move; retrying a simulation costs nothing."
        )
        Text(
          "Restore a landscape within its move limit to unlock the next. Match the best route for three stars. Your collection saves on this iPhone."
        )
        Spacer()
        Text(
          "No audio. Just a little space to think.\nFollows your iPhone’s Reduce Motion setting."
        )
        .font(.system(size: 12))
        .foregroundStyle(Earth.muted)
      }
      .font(.system(size: 15))
      .padding(26)
      .background(Earth.paper.ignoresSafeArea())
      .navigationTitle("Field guide")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { settings = false }.accessibilityIdentifier("settings-done")
        }
      }
    }
  }

  private func share() {
    let renderer = ImageRenderer(
      content: LandscapeCard(
        level: game.level, heights: game.heights, moves: game.moves, stars: game.stars))
    renderer.scale = 2
    if let image = renderer.uiImage { shareImage = SharedLandscape(image: image) }
  }

  private func adjustButton(delta: Int) -> some View {
    Button {
      withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { game.adjust(delta) }
    } label: {
      VStack(spacing: 6) {
        Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
          .font(.system(size: 20, weight: .medium))
        Text(delta > 0 ? "Lift" : "Lower").font(.system(size: 11, weight: .semibold))
      }
      .frame(width: 64, height: 69)
      .background(
        game.canAdjust(delta) ? Earth.ink : Earth.ink.opacity(0.08),
        in: RoundedRectangle(cornerRadius: 16)
      )
      .foregroundStyle(game.canAdjust(delta) ? Earth.paper : Earth.muted)
    }
    .disabled(!game.canAdjust(delta))
    .accessibilityLabel(
      delta > 0 ? "Lift selected plate one layer" : "Lower selected plate one layer"
    )
    .accessibilityIdentifier(delta > 0 ? "lift" : "lower")
  }

  private func iconButton(_ symbol: String, label: String, id: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 18, weight: .medium))
        .frame(width: 44, height: 44)
        .contentShape(Circle())
    }
    .accessibilityLabel(label)
    .accessibilityIdentifier(id)
  }

  private func primaryButton(
    _ title: String, symbol: String, id: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack {
        Text(title).font(.system(size: 16, weight: .semibold))
        Spacer()
        Image(systemName: symbol).font(.system(size: 15, weight: .semibold))
      }
      .padding(.horizontal, 22)
      .frame(maxWidth: .infinity, minHeight: 57)
      .background(Earth.ink, in: RoundedRectangle(cornerRadius: 19))
      .foregroundStyle(Earth.paper)
    }
    .accessibilityIdentifier(id)
  }

  private func eyebrow(_ title: String) -> some View {
    Text(title).font(.system(size: 9, weight: .bold)).tracking(1.5).foregroundStyle(Earth.muted)
  }
}
