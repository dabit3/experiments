import SwiftUI
import UIKit

struct GameView: View {
  let puzzle: Puzzle
  @EnvironmentObject private var progress: Progress
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var parade: Parade
  @State private var paused = false
  @State private var tangled = false
  @State private var tutorial = false
  @State private var showingHint = false
  @State private var hintTask: Task<Void, Never>?
  @State private var lastTouched: Tile?
  @State private var notice = "Start at the flag. Follow the street lights."
  @State private var celebrationStart: Date?
  @State private var showingResult = false
  @State private var showClearConfirmation = false

  init(puzzle: Puzzle, restored: Parade?) {
    self.puzzle = puzzle
    _parade = State(initialValue: restored ?? Parade(puzzle: puzzle))
  }

  private var colors: [LanternColor] { parade.collected(in: puzzle) }
  private var chapter: String {
    if puzzle.id.hasPrefix("daily") { return "Daily light · \(String(puzzle.id.dropFirst(6)))" }
    return
      "Town \(String(format: "%02d", (Towns.all.firstIndex { $0.id == puzzle.id } ?? 0) + 1)) of 12"
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        NightBackground()
        VStack(spacing: 0) {
          header
          ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
              HStack(alignment: .firstTextBaseline) {
                Text(puzzle.title).font(.system(size: 32, design: .serif))
                  .foregroundStyle(Ink.cream).minimumScaleFactor(0.7).lineLimit(1)
                Spacer()
                Text("PAR \(puzzle.par)").font(.system(size: 11, design: .monospaced))
                  .foregroundStyle(Ink.muted)
              }.padding(.top, 18)
              Text(puzzle.subtitle).font(.system(size: 12)).foregroundStyle(Ink.muted)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 7)
              collectionRow.padding(.top, 22)
              playableMap
                .frame(width: min(geometry.size.width - 24, 440))
                .padding(.horizontal, -12)
                .padding(.top, 12)
              HStack(spacing: 7) {
                Image(
                  systemName: parade.completed
                    ? "sparkles" : "point.topleft.down.to.point.bottomright.curvepath"
                )
                .foregroundStyle(Ink.gold)
                Text(parade.completed ? "The town is coming to life…" : notice)
                  .foregroundStyle(Ink.cream)
              }
              .font(.system(size: 12)).multilineTextAlignment(.center)
              .frame(minHeight: 38)
              .accessibilityIdentifier("route-notice")
              .padding(.horizontal, 4)
              HStack {
                Label("\(parade.route.count - 1) steps", systemImage: "shoeprints.fill")
                Spacer()
                Text("A single, unbroken ribbon")
              }.font(.system(size: 10, design: .monospaced)).foregroundStyle(Ink.muted).padding(
                .top, 14)
              Divider().overlay(Ink.muted.opacity(0.1)).padding(.vertical, 16)
              controls
              HStack(spacing: 16) {
                Label("Start", systemImage: "flag.fill")
                Label("Gate", systemImage: "door.left.hand.closed")
                Label("Square", systemImage: "sparkles")
              }.font(.system(size: 10)).foregroundStyle(Ink.muted)
                .padding(.top, 20).padding(.bottom, 22)
            }.padding(.horizontal, 24)
          }
        }
        if tutorial { tutorialOverlay }
        if paused { pauseOverlay }
        if tangled { tangleOverlay }
        if showingResult {
          ResultView(puzzle: puzzle, parade: parade, replay: reset, home: { dismiss() })
            .transition(.opacity)
        }
      }
    }
    .onAppear {
      tutorial = !progress.hasLearned
      progress.save(parade)
      if parade.completed { showingResult = true }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active {
        progress.save(parade)
        if !parade.completed && !tutorial { paused = true }
      }
    }
    .onDisappear { hintTask?.cancel() }
    .confirmationDialog(
      "Clear this ribbon and begin again?", isPresented: $showClearConfirmation,
      titleVisibility: .visible
    ) {
      Button("Clear route", role: .destructive) { reset() }
    }
  }

  private var header: some View {
    HStack {
      Button {
        paused = true
      } label: {
        Image(systemName: "pause").font(.system(size: 16)).frame(width: 44, height: 44)
          .background(Ink.panel.opacity(0.7), in: Circle())
      }.accessibilityLabel("Pause parade").accessibilityIdentifier("pause")
      Spacer()
      Eyebrow(text: chapter)
      Spacer()
      Button {
        tutorial = true
      } label: {
        Image(systemName: "questionmark").font(.system(size: 15)).frame(width: 44, height: 44)
          .overlay(Circle().stroke(Ink.muted.opacity(0.2)))
      }.accessibilityLabel("How to play").accessibilityIdentifier("help")
    }.padding(.horizontal, 24).padding(.top, 8)
  }

  private var collectionRow: some View {
    HStack(spacing: 0) {
      ForEach(LanternColor.allCases, id: \.rawValue) { color in
        HStack(spacing: 8) {
          ZStack {
            Circle().fill(color.ink.opacity(colors.contains(color) ? 0.24 : 0.07)).frame(
              width: 32, height: 32)
            Image(systemName: colors.contains(color) ? "checkmark" : color.symbol)
              .font(.system(size: 12)).foregroundStyle(color.ink)
          }
          VStack(alignment: .leading, spacing: 2) {
            Text("\(color.rawValue + 1)  \(color.name)").font(.system(size: 11, weight: .semibold))
              .foregroundStyle(Ink.cream)
            Text(
              colors.contains(color)
                ? "collected" : (colors.count == color.rawValue ? "collect next" : "then collect")
            )
            .font(.system(size: 9)).foregroundStyle(Ink.muted)
          }
        }.frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityElement(children: .combine)
      }
    }
  }

  private var playableMap: some View {
    GeometryReader { geometry in
      let geo = BoardGeometry(side: geometry.size.width, count: puzzle.size)
      ZStack {
        TimelineView(
          .animation(
            minimumInterval: 1.0 / 30,
            paused: celebrationStart == nil || reduceMotion || showingResult)
        ) { timeline in
          let elapsed = celebrationStart.map { timeline.date.timeIntervalSince($0) } ?? 0
          TownMap(
            puzzle: puzzle, route: parade.route, celebrating: parade.completed,
            procession: reduceMotion ? 1 : min(elapsed / 3.8, 1), hint: showingHint
          )
          .onChange(of: elapsed > 4.8) { _, done in
            if done { withAnimation { showingResult = true } }
          }
        }
        ForEach(0..<puzzle.size * puzzle.size, id: \.self) { index in
          let tile = Tile(x: index % puzzle.size, y: index / puzzle.size)
          if !puzzle.blocked.contains(tile) {
            Button {
              move(tile)
            } label: {
              Color.clear.contentShape(Rectangle())
            }
            .frame(
              width: max(44, min(geo.step * 0.85, 52)), height: max(44, min(geo.step * 0.85, 52))
            )
            .position(geo.point(tile))
            .accessibilityLabel(tileLabel(tile))
            .accessibilityIdentifier("tile-\(tile.x)-\(tile.y)")
            .disabled(paused || tutorial || tangled || parade.completed)
          }
        }
      }
      .simultaneousGesture(
        DragGesture(minimumDistance: 8)
          .onChanged { value in
            guard let tile = geo.tile(at: value.location), tile != lastTouched else { return }
            lastTouched = tile
            move(tile)
          }
          .onEnded { _ in lastTouched = nil }
      )
    }.aspectRatio(1, contentMode: .fit)
  }

  private var controls: some View {
    HStack(spacing: 10) {
      Button {
        parade.undo()
        notice = "One step back. Your ribbon is still together."
        progress.save(parade)
        progress.feedback()
      } label: {
        Label("Undo", systemImage: "arrow.uturn.backward")
      }.buttonStyle(GoldButtonStyle(secondary: true))
        .disabled(parade.route.count <= 1 || parade.completed)
        .opacity(parade.route.count <= 1 ? 0.4 : 1)
        .accessibilityIdentifier("undo")
      Button {
        showClearConfirmation = true
      } label: {
        Label("Clear", systemImage: "arrow.counterclockwise")
      }.buttonStyle(GoldButtonStyle(secondary: true)).disabled(parade.completed)
        .accessibilityIdentifier("clear")
      Button {
        guard !showingHint else { return }
        parade.hints += 1
        showingHint = true
        notice = "A possible route, traced in starlight."
        progress.save(parade)
        hintTask?.cancel()
        hintTask = Task { @MainActor in
          try? await Task.sleep(for: .seconds(5))
          guard !Task.isCancelled else { return }
          showingHint = false
        }
      } label: {
        Label("Guide", systemImage: "wand.and.stars")
      }.buttonStyle(GoldButtonStyle(secondary: true)).disabled(parade.completed || showingHint)
        .accessibilityIdentifier("guide")
    }
  }

  private func tileLabel(_ tile: Tile) -> String {
    let prefix = "Street \(tile.x + 1), \(tile.y + 1)"
    if tile == puzzle.start { return "\(prefix), start flag" }
    if tile == puzzle.finish { return "\(prefix), festival square" }
    if let color = puzzle.lanterns[tile] {
      return "\(prefix), \(color.name) lantern, number \(color.rawValue + 1)"
    }
    if let color = puzzle.gates[tile] { return "\(prefix), \(color.name) gate" }
    if tile == parade.route.last { return "\(prefix), parade head" }
    if parade.route.contains(tile) { return "\(prefix), ribbon already here" }
    return prefix
  }

  private func move(_ tile: Tile) {
    guard !paused, !tutorial, !tangled, !showingResult else { return }
    let outcome = parade.move(to: tile, in: puzzle)
    switch outcome {
    case .ignored: return
    case .tangled:
      tangled = true
    case .rejected(let message):
      notice = message
    case .moved:
      progress.feedback()
      if let color = puzzle.lanterns[tile] {
        notice =
          "\(color.name) joins the parade. \(colors.count == 3 ? "Bring them to the square." : "Keep the ribbon together.")"
      } else if colors.count == 3 {
        notice = "All three lights! Lead them to the festival square."
      } else {
        notice =
          "Collect \(LanternColor.allCases[colors.count].name) next. Gates open with matching light."
      }
    case .completed:
      showingHint = false
      celebrationStart = Date()
      progress.complete(parade, puzzle: puzzle)
      progress.feedback(success: true)
      if reduceMotion { showingResult = true }
    }
    progress.save(parade)
  }

  private func reset() {
    hintTask?.cancel()
    parade = Parade(puzzle: puzzle)
    paused = false
    tangled = false
    showingResult = false
    showingHint = false
    celebrationStart = nil
    lastTouched = nil
    notice = "A fresh ribbon. Start at the flag."
    progress.save(parade)
  }

  private func overlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Ink.night.opacity(0.85).ignoresSafeArea()
      VStack(spacing: 18, content: content)
        .padding(28).frame(maxWidth: 360)
        .background(Ink.panel, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Ink.gold.opacity(0.25)))
        .padding(22)
    }.accessibilityAddTraits(.isModal)
  }

  private var tutorialOverlay: some View {
    overlay {
      PaperLantern(size: 36)
      Eyebrow(text: "Carry the light")
      Text("One unbroken parade.")
        .font(.system(size: 28, design: .serif)).foregroundStyle(Ink.cream)
      VStack(alignment: .leading, spacing: 16) {
        tutorialLine("hand.draw", "Draw along the streets, or tap neighboring lights.")
        tutorialLine(
          "1.circle", "Collect Amber, Rose, then Jade. Each color opens its matching gate.")
        tutorialLine(
          "sparkles", "Reach the square. Never cross your own ribbon. Undo is always free.")
      }.padding(.vertical, 6)
      Button {
        progress.hasLearned = true
        tutorial = false
      } label: {
        Text("Let’s light the town")
      }
      .buttonStyle(GoldButtonStyle()).accessibilityIdentifier("tutorial-start")
    }
  }

  private func tutorialLine(_ symbol: String, _ text: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: symbol).foregroundStyle(Ink.gold).frame(width: 20)
      Text(text).font(.system(size: 14)).foregroundStyle(Ink.cream).fixedSize(
        horizontal: false, vertical: true)
    }
  }

  private var pauseOverlay: some View {
    overlay {
      Eyebrow(text: "A moment of quiet")
      Text("Your lanterns can wait.").font(.system(size: 28, design: .serif)).foregroundStyle(
        Ink.cream)
      Text("Your route is saved on this iPhone.").font(.subheadline).foregroundStyle(Ink.muted)
      Button("Resume parade") { paused = false }.buttonStyle(GoldButtonStyle())
        .accessibilityIdentifier("resume")
      Button("Restart town") { reset() }.buttonStyle(GoldButtonStyle(secondary: true))
        .accessibilityIdentifier("restart")
      Button("Return to the atlas") { dismiss() }.frame(minHeight: 44).accessibilityIdentifier(
        "return-home")
    }
  }

  private var tangleOverlay: some View {
    overlay {
      Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
        .font(.system(size: 34)).foregroundStyle(Ink.rose)
      Eyebrow(text: "A little tangle")
      Text("The ribbon crossed itself.").font(.system(size: 28, design: .serif)).foregroundStyle(
        Ink.cream
      )
      .multilineTextAlignment(.center)
      Text("That step didn’t count. Take one step back and find another way through.")
        .font(.subheadline).foregroundStyle(Ink.muted).multilineTextAlignment(.center)
      Button("Untangle & undo") {
        parade.undo()
        tangled = false
        lastTouched = nil
        notice = "Room to breathe. Try another street."
        progress.save(parade)
      }.buttonStyle(GoldButtonStyle()).accessibilityIdentifier("untangle")
      Button("Start a fresh ribbon") { reset() }.frame(minHeight: 44).accessibilityIdentifier(
        "tangle-restart")
    }
  }
}

struct ResultView: View {
  let puzzle: Puzzle
  let parade: Parade
  let replay: () -> Void
  let home: () -> Void
  @EnvironmentObject private var progress: Progress
  @State private var share: SharePayload?
  @State private var shareError = false

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        NightBackground()
        ScrollView {
          VStack(spacing: 14) {
            Eyebrow(text: "A town, illuminated").padding(.top, 25)
            Text("You brought\nthe night to life.")
              .font(.system(size: 40, design: .serif)).tracking(-1)
              .foregroundStyle(Ink.cream).multilineTextAlignment(.center)
            Stars(count: parade.stars(in: puzzle)).font(.system(size: 23))
            TownMap(puzzle: puzzle, route: parade.route, celebrating: true, procession: 0.8)
              .frame(width: min(geometry.size.width - 48, geometry.size.height * 0.42))
            Text(puzzle.title).font(.system(size: 25, design: .serif)).foregroundStyle(Ink.cream)
            Text(
              "\(parade.route.count - 1) STEPS  ·  \(parade.mistakes) MISSTEPS  ·  \(parade.hints) GUIDES"
            )
            .font(.system(size: 10, design: .monospaced)).tracking(1).foregroundStyle(Ink.muted)
            Text(
              parade.stars(in: puzzle) == 3
                ? "A perfect ribbon. A radiant square."
                : "Every light arrived. A cleaner ribbon earns more stars."
            )
            .font(.system(size: 12)).foregroundStyle(Ink.muted).multilineTextAlignment(.center)
            Button {
              createShare()
            } label: {
              Label("Share your lantern poster", systemImage: "square.and.arrow.up")
            }.buttonStyle(GoldButtonStyle()).padding(.top, 8).accessibilityIdentifier(
              "share-result")
            HStack(spacing: 12) {
              Button("Parade again", action: replay).buttonStyle(GoldButtonStyle(secondary: true))
                .accessibilityIdentifier("replay")
              Button("Explore towns", action: home).buttonStyle(GoldButtonStyle(secondary: true))
                .accessibilityIdentifier("result-home")
            }
            Text("BEST  \(progress.best[puzzle.id] ?? 0) / 3 STARS · SAVED ON THIS IPHONE")
              .font(.system(size: 9, design: .monospaced)).foregroundStyle(Ink.muted)
          }.padding(.horizontal, 24).padding(.bottom, 24)
        }
      }
    }
    .sheet(item: $share) { payload in
      ActivitySheet(
        image: payload.image,
        text:
          "I illuminated \(puzzle.title) in Lantern Parade — \(parade.stars(in: puzzle))/3 stars, \(parade.route.count - 1) steps. One ribbon. A thousand little lights."
      )
    }
    .alert("Couldn’t prepare the poster", isPresented: $shareError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Please try sharing again.")
    }
  }

  @MainActor
  private func createShare() {
    let renderer = ImageRenderer(content: PosterView(puzzle: puzzle, parade: parade))
    renderer.scale = 2
    guard let image = renderer.uiImage else {
      shareError = true
      return
    }
    share = SharePayload(image: image)
  }
}

struct PosterView: View {
  let puzzle: Puzzle
  let parade: Parade
  var body: some View {
    ZStack {
      NightBackground()
      VStack(spacing: 20) {
        Eyebrow(text: "The midnight festival")
        Text("Lantern\nParade").font(.system(size: 66, design: .serif)).tracking(-2)
          .foregroundStyle(Ink.cream).multilineTextAlignment(.center)
        TownMap(puzzle: puzzle, route: parade.route, celebrating: true, procession: 0.8)
          .frame(width: 430, height: 430)
        Text(puzzle.title).font(.system(size: 32, design: .serif)).foregroundStyle(Ink.cream)
        Stars(count: parade.stars(in: puzzle)).font(.title2)
        Text("\(parade.route.count - 1) steps • One unbroken ribbon").font(.subheadline)
          .foregroundStyle(Ink.muted)
        Rectangle().fill(Ink.gold.opacity(0.3)).frame(width: 70, height: 1)
        Eyebrow(text: "I brought the night to life")
      }.padding(.vertical, 45)
    }.frame(width: 540, height: 930).environment(\.colorScheme, .dark)
  }
}

struct SharePayload: Identifiable {
  let id = UUID()
  let image: UIImage
}

struct ActivitySheet: UIViewControllerRepresentable {
  let image: UIImage
  let text: String
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
