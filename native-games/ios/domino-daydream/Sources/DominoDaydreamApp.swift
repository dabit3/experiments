import LinkPresentation
import SwiftUI
import UIKit

@main
struct DominoDaydreamApp: App {
  @StateObject private var store = GameStore()
  var body: some Scene {
    WindowGroup {
      ContentView(store: store)
        .preferredColorScheme(.dark)
    }
  }
}

struct ContentView: View {
  @ObservedObject var store: GameStore
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var playing = false
  @State private var showCollection = false
  @State private var showSettings = false
  @State private var showHelp = false
  @State private var showReset = false
  @State private var sharePayload: SharePayload?

  var body: some View {
    ZStack {
      WalnutBackground()
      if playing { game } else { home }
    }
    .tint(Palette.coral)
    .sheet(isPresented: $showCollection) { collection.preferredColorScheme(.light) }
    .sheet(isPresented: $showSettings) { settings.preferredColorScheme(.light) }
    .sheet(isPresented: $showHelp) { instructions.preferredColorScheme(.light) }
    .sheet(item: $sharePayload) { payload in
      ShareSheet(image: payload.image, text: payload.text).preferredColorScheme(.light)
    }
    .confirmationDialog(
      "Clear your placed pieces?", isPresented: $showReset, titleVisibility: .visible
    ) {
      Button("Reset board", role: .destructive) { store.reset() }
    } message: {
      Text("Your best score stays safe. You can undo the reset.")
    }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active {
        store.pause()
        store.save()
      }
    }
  }

  private var home: some View {
    GeometryReader { geometry in
      let compact = geometry.size.height < 720
      VStack(spacing: compact ? 8 : 12) {
        HStack {
          DominoMark().frame(width: 28, height: 30)
          Text("OBJECTS OF\nLITTLE WONDER")
            .font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(1.5)
          Spacer()
          iconButton("slider.horizontal.3", label: "Settings", id: "settings") {
            showSettings = true
          }
        }
        .foregroundStyle(Palette.brass)
        .padding(.top, 4)
        VStack(alignment: .leading, spacing: -8) {
          Text("Domino").font(.custom("Baskerville", size: compact ? 54 : 72))
          HStack(alignment: .lastTextBaseline) {
            Text("Daydream").font(.custom("Baskerville-Italic", size: compact ? 54 : 72))
            Spacer(minLength: 0)
            Image(systemName: "sun.max").font(.system(size: compact ? 24 : 33, weight: .ultraLight))
              .foregroundStyle(Palette.brass)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Palette.cream)
        .accessibilityElement(children: .combine)
        .padding(.top, compact ? 0 : 8)
        HStack {
          Text("THE AFTERNOON COLLECTION")
          Spacer()
          Text("VOL. 01")
        }
        .font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(1.5)
        .foregroundStyle(Palette.muted)
        .padding(.top, 6)
        .overlay(alignment: .top) {
          Rectangle().fill(Palette.brass.opacity(0.3)).frame(height: 0.5)
        }
        TabletopView(
          puzzle: Puzzle.all[7], pieces: Puzzle.all[7].solution,
          guides: false, labels: false, interactive: false
        )
        .frame(maxHeight: .infinity)
        .padding(.horizontal, -26)
        .accessibilityLabel("Miniature porcelain domino town with a winding spiral and brass bells")
        VStack(spacing: 5) {
          Text("A little nudge. A lovely ripple.")
            .font(.custom("Baskerville-Italic", size: compact ? 21 : 24))
            .foregroundStyle(Palette.cream)
          Text("Build something wonderful. Then let it go.")
            .font(.system(size: 11)).foregroundStyle(Palette.muted)
        }
        .padding(.bottom, compact ? 4 : 10)
        primaryButton(
          store.completed == 0 ? "Begin the daydream" : "Return to the workshop",
          icon: "arrow.right", id: "begin"
        ) {
          start(store.unlocked)
        }
        HStack(spacing: 12) {
          secondaryButton("The collection", icon: "square.grid.2x2", id: "collection") {
            showCollection = true
          }
          secondaryButton("Open table", icon: "sparkles", id: "sandbox") { start(8) }
        }
        HStack(spacing: 6) {
          ForEach(0..<8, id: \.self) { index in
            RoundedRectangle(cornerRadius: 1)
              .fill(index < store.completed ? Palette.brass : Palette.cream.opacity(0.15))
              .frame(width: 4, height: 10)
          }
          Text("\(store.completed) / 8 WORLDS COMPLETE")
            .font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(1)
            .padding(.leading, 7)
        }
        .foregroundStyle(Palette.muted)
        .padding(.bottom, 8)
      }
      .padding(.horizontal, 28)
    }
  }

  private var game: some View {
    GeometryReader { geometry in
      let compact = geometry.size.height < 720
      VStack(spacing: compact ? 6 : 10) {
        HStack {
          iconButton("arrow.left", label: "Return to workshop", id: "home") {
            store.pause()
            store.save()
            playing = false
          }
          Spacer()
          HStack(spacing: 9) {
            Rectangle().fill(Palette.brass.opacity(0.4)).frame(width: 22, height: 0.5)
            Text(
              store.puzzle.sandbox
                ? "OPEN TABLE" : "WORLD \(String(format: "%02d", store.puzzle.id + 1)) / 08"
            )
            .font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(2)
            Rectangle().fill(Palette.brass.opacity(0.4)).frame(width: 22, height: 0.5)
          }
          Spacer()
          iconButton("questionmark", label: "How to play", id: "help") {
            store.pause()
            showHelp = true
          }
        }
        .foregroundStyle(Palette.brass)
        VStack(spacing: 4) {
          Text(store.puzzle.title)
            .font(.custom("Baskerville", size: compact ? 29 : 36))
            .foregroundStyle(Palette.cream)
            .minimumScaleFactor(0.75).lineLimit(1)
          HStack(spacing: 7) {
            ForEach(0..<store.puzzle.targets.count, id: \.self) { index in
              Image(systemName: index < store.bellsRung ? "bell.fill" : "bell")
                .foregroundStyle(index < store.bellsRung ? Palette.brass : Palette.muted)
            }
            Text("\(store.bellsRung) / \(store.puzzle.targets.count)")
            Text("·").padding(.horizontal, 4)
            Text(store.best == 0 ? "RING EVERY BELL" : "BEST \(store.best)")
          }
          .font(.system(size: 10, weight: .medium, design: .monospaced))
          .tracking(1).foregroundStyle(Palette.muted)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(
            "\(store.bellsRung) of \(store.puzzle.targets.count) bells rung. Best score \(store.best)"
          )
        }
        .fixedSize(horizontal: false, vertical: true)
        TabletopView(
          puzzle: store.puzzle, pieces: store.allPieces, selected: store.selected,
          result: store.result, beat: store.beat, guides: store.guides,
          reduceMotion: reduceMotion, interactive: store.phase == .editing,
          tap: { cell in
            withAnimation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.65)) {
              store.tap(cell)
            }
          }
        )
        .frame(height: max(255, geometry.size.height - (compact ? 350 : 398)))
        .padding(.horizontal, -18)
        .layoutPriority(1)
        if store.phase == .result {
          resultPanel
        } else if store.phase == .running || store.phase == .paused {
          playbackPanel
        } else {
          editingPanel(compact: compact)
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 18)
      .padding(.bottom, 10)
    }
  }

  private func editingPanel(compact: Bool) -> some View {
    VStack(spacing: compact ? 6 : 10) {
      HStack(alignment: .top, spacing: 8) {
        Rectangle().fill(Palette.brass).frame(width: 2, height: 30)
        Text(store.message)
          .font(.system(size: compact ? 12 : 13)).lineSpacing(2)
          .foregroundStyle(Palette.cream.opacity(0.86))
          .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityIdentifier("context-message")
      }
      HStack(spacing: 6) {
        ForEach(PieceKind.allCases) { kind in
          Button {
            store.choose(kind)
          } label: {
            VStack(spacing: 3) {
              HStack(alignment: .top, spacing: 5) {
                PieceGlyph(kind: kind).frame(width: 34, height: compact ? 24 : 30)
                Spacer(minLength: 0)
                Text(store.puzzle.sandbox ? "∞" : "\(store.remaining(kind))")
                  .font(.system(size: 11, weight: .semibold, design: .monospaced))
              }
              Text(kind.title.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 56 : 66)
            .foregroundStyle(
              store.tool == kind
                ? Palette.ink : Palette.cream.opacity(store.remaining(kind) == 0 ? 0.55 : 0.85)
            )
            .background(
              store.tool == kind ? Palette.cream : Color.black.opacity(0.17),
              in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 6).strokeBorder(
                store.tool == kind ? Palette.brass : Palette.cream.opacity(0.14), lineWidth: 1))
          }
          .buttonStyle(.plain)
          .accessibilityLabel(
            "\(kind.title), \(store.puzzle.sandbox ? "unlimited" : "\(store.remaining(kind)) remaining")"
          )
          .accessibilityIdentifier("piece-\(kind.rawValue)")
        }
      }
      HStack(spacing: 0) {
        toolButton("rotate.right", label: "Rotate", id: "rotate") { store.rotate() }
        toolButton("arrow.uturn.backward", label: "Undo", id: "undo", disabled: !store.canUndo) {
          store.undo()
        }
        toolButton(
          "eraser", label: "Lift", id: "erase",
          disabled: store.selected.flatMap { store.placed[$0] } == nil
        ) { store.erase() }
        toolButton("arrow.counterclockwise", label: "Reset", id: "reset") { showReset = true }
        if !store.puzzle.sandbox {
          toolButton("lightbulb", label: "Hint", id: "hint") { store.hint() }
        }
      }
      primaryButton("Give it a nudge", icon: "play.fill", id: "trigger") { store.trigger() }
    }
  }

  private var playbackPanel: some View {
    VStack(spacing: 15) {
      Text(store.phase == .paused ? "A moment of stillness." : "And away they go…")
        .font(.system(size: 22, weight: .regular, design: .serif)).foregroundStyle(Palette.cream)
      ProgressView(value: max(0, store.beat), total: Double(store.totalBeat) + 2)
        .tint(Palette.brass).padding(.horizontal, 18)
      Text(
        store.phase == .paused
          ? "Your chain is waiting right here."
          : "Watch the porcelain ripple through your little world."
      )
      .font(.system(size: 11)).foregroundStyle(Palette.muted)
      HStack {
        secondaryButton("Edit board", icon: "arrow.uturn.backward", id: "edit-running") {
          store.editAgain()
        }
        secondaryButton(
          store.phase == .paused ? "Resume" : "Pause",
          icon: store.phase == .paused ? "play" : "pause", id: "pause"
        ) {
          if store.phase == .paused { store.resume() } else { store.pause() }
        }
      }
    }
    .padding(.vertical, 22)
  }

  private var resultPanel: some View {
    let won = store.result?.won == true
    return VStack(spacing: 10) {
      HStack {
        Text(won ? "THE CHAIN IS COMPLETE" : "BACK TO THE DRAWING BOARD")
          .font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.4)
        Spacer()
        Text(String(format: "№ %02d", store.puzzle.id + 1))
          .font(.system(size: 10, design: .monospaced))
      }
      .foregroundStyle(Palette.ink.opacity(0.7))
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 5) {
          Text(won ? "Beautifully set in motion." : "One more little nudge.")
            .font(.custom("Baskerville-Italic", size: 26))
            .minimumScaleFactor(0.8).lineLimit(1)
          Text(
            won
              ? "Every bell has a story. You rang them all."
              : store.firstFailure.flatMap { store.result?.failures[$0] }
                ?? "Connect every bell and try again."
          )
          .font(.system(size: 12)).fixedSize(horizontal: false, vertical: true).lineSpacing(2)
        }
        Spacer(minLength: 0)
        Image(systemName: won ? "seal" : "arrow.triangle.turn.up.right.diamond")
          .font(.system(size: 27, weight: .ultraLight)).foregroundStyle(Palette.ink)
      }
      .foregroundStyle(Palette.ink)
      HStack {
        metric("\(store.result?.chainLength ?? 0)", caption: "DOMINOES")
        Spacer()
        metric("\(store.currentScore)", caption: "POINTS")
        Spacer()
        metric(
          "\(store.result?.reached.count ?? 0)/\(store.puzzle.targets.count)", caption: "BELLS")
      }
      Divider().overlay(Palette.ink.opacity(0.1))
      HStack(spacing: 10) {
        Button {
          store.editAgain()
        } label: {
          Label(won ? "Replay" : "Keep building", systemImage: "arrow.uturn.backward")
            .font(.system(size: 12, weight: .semibold)).frame(maxWidth: .infinity, minHeight: 43)
        }
        .accessibilityIdentifier("replay")
        .foregroundStyle(Palette.ink)
        if won {
          Button {
            share()
          } label: {
            Image(systemName: "square.and.arrow.up").frame(width: 44, height: 43)
          }
          .foregroundStyle(Palette.ink)
          .accessibilityLabel("Share finished board").accessibilityIdentifier("share")
          if !store.puzzle.sandbox && store.puzzle.id < 7 {
            Button {
              start(store.puzzle.id + 1)
            } label: {
              Label("Next", systemImage: "arrow.right")
                .font(.system(size: 12, weight: .semibold)).frame(width: 83, height: 43)
                .background(Palette.ink, in: RoundedRectangle(cornerRadius: 5))
                .foregroundStyle(Palette.cream)
            }
            .accessibilityIdentifier("next")
          }
        }
      }
    }
    .padding(17)
    .background(Palette.cream, in: RoundedRectangle(cornerRadius: 7))
    .overlay(
      RoundedRectangle(cornerRadius: 4).strokeBorder(Palette.brass.opacity(0.6), lineWidth: 0.7)
        .padding(5)
        .allowsHitTesting(false)
    )
    .accessibilityIdentifier(won ? "success-result" : "failure-result")
  }

  private var collection: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          Text("The afternoon\ncollection.").font(.custom("Baskerville", size: 42))
            .padding(.bottom, 8)
          Text("A quiet collection of small, satisfying machines.")
            .font(.system(size: 13)).foregroundStyle(.secondary).padding(.bottom, 24)
          ForEach(Puzzle.all.filter { !$0.sandbox }) { puzzle in
            let locked = puzzle.id > store.unlocked
            Button {
              showCollection = false
              start(puzzle.id)
            } label: {
              HStack(spacing: 17) {
                Text(String(format: "%02d", puzzle.id + 1))
                  .font(.system(size: 28, weight: .regular, design: .serif)).foregroundStyle(
                    Palette.brass)
                VStack(alignment: .leading, spacing: 4) {
                  Text(puzzle.title).font(.system(size: 17, weight: .medium, design: .serif))
                  Text(locked ? "Complete the previous world to open" : progressCaption(puzzle))
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(
                  systemName: locked
                    ? "lock"
                    : store.progress.scores[String(puzzle.id)] == nil
                      ? "arrow.right" : "checkmark.seal")
              }
              .frame(minHeight: 70)
              .foregroundStyle(Palette.ink)
              .opacity(locked ? 0.5 : 1)
            }
            .disabled(locked)
            .accessibilityIdentifier("world-\(puzzle.id)")
            Divider()
          }
        }
        .padding(24)
      }
      .background(Palette.cream)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) { Button("Done") { showCollection = false } }
      }
    }
  }

  private var settings: some View {
    NavigationStack {
      Form {
        Section("A little atmosphere") {
          Toggle("Sound effects", isOn: $store.sound).accessibilityIdentifier("sound-toggle")
          Toggle("Gentle haptics", isOn: $store.haptics).accessibilityIdentifier("haptics-toggle")
          Toggle("Blueprint guides", isOn: $store.guides).accessibilityIdentifier("guides-toggle")
        }
        Section {
          Text(
            "Progress and unfinished boards are saved on this iPhone. No account, no clocks, no rush."
          )
          Text(
            "Domino Daydream follows your system Reduce Motion preference. Audio and haptics depend on device settings."
          )
        }
        .font(.system(size: 13))
      }
      .navigationTitle("Make yourself at home")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) { Button("Done") { showSettings = false } }
      }
    }
    .presentationDetents([.medium, .large])
  }

  private var instructions: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          Text("A small nudge.\nA lovely ripple.").font(
            .system(size: 36, weight: .regular, design: .serif))
          Text(
            "Choose a piece from the tray, then tap a dotted socket. Tap it again to select it; Rotate turns its open edges clockwise."
          )
          ForEach(PieceKind.allCases) { kind in
            HStack(alignment: .top, spacing: 16) {
              Image(systemName: kind.symbol).font(.system(size: 22)).frame(width: 30)
                .foregroundStyle(Palette.coral)
              VStack(alignment: .leading, spacing: 5) {
                Text(kind.title).bold()
                Text(pieceHelp(kind)).font(.system(size: 13)).foregroundStyle(.secondary)
              }
            }
          }
          Text(
            "Ring every brass bell in one chain. A closed edge or an empty socket stops that branch. Hints cost 75 points; each retry after the first costs 25. Undo is free."
          )
          .font(.system(size: 13))
          Text(
            "Need a blueprint? Select a socket and tap Hint. It tells you the piece and how many clockwise quarter turns to make from its tray position."
          )
          .font(.system(size: 13))
        }
        .padding(26)
      }
      .foregroundStyle(Palette.ink).background(Palette.cream)
      .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Got it") { showHelp = false } } }
    }
  }

  private func pieceHelp(_ kind: PieceKind) -> String {
    switch kind {
    case .straight: "Carries the nudge straight across opposite edges."
    case .turn: "Bends the chain through a right angle."
    case .bridge: "Skips exactly one square. Place on the bank before the blue canal."
    case .fork: "Splits one incoming nudge into two outgoing chains."
    }
  }

  private func progressCaption(_ puzzle: Puzzle) -> String {
    if let score = store.progress.scores[String(puzzle.id)] {
      return "Best \(score) points · all bells rung"
    }
    return "\(puzzle.sockets.count) pieces to place · \(puzzle.targets.count) bells"
  }

  private func start(_ index: Int) {
    store.load(index)
    playing = true
  }

  private func share() {
    sharePayload = SharePayload.make(
      puzzle: store.puzzle, pieces: store.allPieces, result: store.result, score: store.currentScore
    )
  }

  private func metric(_ value: String, caption: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(value).font(.system(size: 26, weight: .regular, design: .serif))
      Text(caption).font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(0.5)
    }
    .foregroundStyle(Palette.ink)
  }

  private func iconButton(_ symbol: String, label: String, id: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      Image(systemName: symbol).font(.system(size: 16, weight: .light)).frame(width: 44, height: 44)
    }
    .buttonStyle(.plain).accessibilityLabel(label).accessibilityIdentifier(id)
  }

  private func toolButton(
    _ symbol: String, label: String, id: String, disabled: Bool = false,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 4) {
        Image(systemName: symbol).font(.system(size: 13))
        Text(label).font(.system(size: 11, weight: .medium))
      }
      .frame(maxWidth: .infinity, minHeight: 44)
      .foregroundStyle(Palette.cream.opacity(disabled ? 0.5 : 0.85))
    }
    .disabled(disabled).accessibilityLabel(label).accessibilityIdentifier(id)
  }

  private func primaryButton(
    _ title: String, icon: String, id: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 14) {
        Circle().fill(Palette.ink.opacity(0.3)).frame(width: 4, height: 4)
        Text(title).font(.system(size: 14, weight: .semibold)).tracking(0.3)
        Spacer()
        Image(systemName: icon).font(.system(size: 14, weight: .medium))
          .frame(width: 30, height: 30)
          .overlay(Circle().stroke(Palette.ink.opacity(0.25), lineWidth: 0.7))
      }
      .foregroundStyle(Palette.ink).padding(.horizontal, 17).frame(height: 54)
      .background(
        LinearGradient(
          colors: [Color(hex: 0xF1C08F), Palette.coral],
          startPoint: .top, endPoint: .bottom),
        in: RoundedRectangle(cornerRadius: 7)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 7).strokeBorder(Palette.cream.opacity(0.4), lineWidth: 0.7)
      )
      .background {
        RoundedRectangle(cornerRadius: 7).fill(.black.opacity(0.23)).offset(y: 4)
      }
    }
    .buttonStyle(WorkshopPressStyle()).accessibilityIdentifier(id)
  }

  private func secondaryButton(
    _ title: String, icon: String, id: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Label(title, systemImage: icon)
        .font(.system(size: 12, weight: .medium))
        .frame(maxWidth: .infinity, minHeight: 45)
        .foregroundStyle(Palette.cream)
        .overlay(alignment: .bottom) {
          Rectangle().fill(Palette.brass.opacity(0.25)).frame(height: 0.5)
        }
    }
    .buttonStyle(.plain).accessibilityIdentifier(id)
  }
}

struct ResultCard: View {
  let puzzle: Puzzle
  let pieces: [Cell: Piece]
  let result: ChainResult?
  let score: Int
  let artwork: UIImage
  var body: some View {
    ZStack {
      Palette.cream
      VStack(spacing: 12) {
        HStack {
          DominoMark().frame(width: 35, height: 35)
          Spacer()
          Text("THE AFTERNOON COLLECTION\nA MACHINE BY YOU")
            .font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(2)
            .multilineTextAlignment(.trailing)
        }
        Rectangle().fill(Palette.ink.opacity(0.25)).frame(height: 0.7)
        Text("Domino Daydream").font(.custom("Baskerville", size: 45))
          .frame(maxWidth: .infinity, alignment: .leading)
        Image(uiImage: artwork).resizable().scaledToFit().frame(width: 510, height: 490)
        Text(puzzle.title).font(.custom("Baskerville-Italic", size: 30))
        HStack {
          cardMetric("\(result?.chainLength ?? 0)", label: "DOMINOES")
          Spacer()
          cardMetric("\(score)", label: "POINTS")
          Spacer()
          cardMetric("\(result?.reached.count ?? 0)", label: "BELLS RUNG")
        }
        .padding(.horizontal, 25)
        Rectangle().fill(Palette.ink.opacity(0.25)).frame(height: 0.7)
        Text("Made by hand. Set in motion.").font(.custom("Baskerville-Italic", size: 17))
      }
      .foregroundStyle(Palette.ink)
      .padding(36)
    }
    .overlay(Rectangle().strokeBorder(Palette.brass, lineWidth: 1).padding(16))
  }

  private func cardMetric(_ value: String, label: String) -> some View {
    VStack(spacing: 3) {
      Text(value).font(.custom("Baskerville", size: 36))
      Text(label).font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(2)
    }
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  let image: UIImage
  let text: String
  func makeUIViewController(context: Context) -> UIActivityViewController {
    let configuration = UIActivityItemsConfiguration(objects: [image])
    let metadata = LPLinkMetadata()
    metadata.title = text
    metadata.imageProvider = NSItemProvider(object: image)
    configuration.metadataProvider = { key in
      switch key {
      case .title, .messageBody: return text
      case .linkPresentationMetadata: return metadata
      default: return nil
      }
    }
    configuration.previewProvider = { _, _, _ in NSItemProvider(object: image) }
    return UIActivityViewController(activityItemsConfiguration: configuration)
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct SharePayload: Identifiable {
  let id = UUID()
  let image: UIImage
  let text: String

  @MainActor
  static func make(puzzle: Puzzle, pieces: [Cell: Piece], result: ChainResult?, score: Int)
    -> SharePayload?
  {
    let diorama = Diorama(puzzle: puzzle, labels: false)
    diorama.update(
      pieces: pieces, selected: nil, result: result, beat: 1000,
      guides: false, reduceMotion: true)
    let artwork = diorama.snapshot(size: CGSize(width: 1020, height: 980))
    let renderer = ImageRenderer(
      content: ResultCard(
        puzzle: puzzle, pieces: pieces, result: result, score: score, artwork: artwork
      )
      .frame(width: 600, height: 860))
    renderer.scale = 2
    guard let image = renderer.uiImage else { return nil }
    return SharePayload(
      image: image,
      text:
        "A little nudge, a lovely ripple. \(result?.chainLength ?? 0) dominoes · \(score) points in Domino Daydream."
    )
  }
}
