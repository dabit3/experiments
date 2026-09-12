import SwiftUI
import UIKit

struct GameView: View {
  let level: Level
  let home: () -> Void
  let next: () -> Void
  @State private var puzzle: PuzzleState
  @State private var sailing = false
  @State private var paused = false
  @State private var cursor = 0
  @State private var voyage: RouteResult?
  @State private var finished = false
  @State private var showHelp = false
  @State private var showReset = false
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  init(level: Level, home: @escaping () -> Void, next: @escaping () -> Void) {
    self.level = level
    self.home = home
    self.next = next
    _puzzle = State(initialValue: PuzzleState(level: level))
  }

  private var visited: [Cell] {
    guard let voyage, sailing || finished else { return puzzle.preview.cells }
    return Array(voyage.cells.prefix(cursor + 1))
  }
  private var collected: Int {
    guard sailing || finished else { return 0 }
    return puzzle.canals.filter { $0.hasStamp && visited.contains($0.cell) }.count
  }
  private var boat: Cell {
    guard let voyage, !voyage.cells.isEmpty, sailing || finished else { return level.start }
    return voyage.cells[min(cursor, voyage.cells.count - 1)]
  }

  var body: some View {
    ZStack {
      Ink.night.ignoresSafeArea()
      GeometryReader { geometry in
        ScrollView {
          VStack(spacing: 18) {
            header
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 9) {
                Eyebrow(text: "LETTER \(String(format: "%02d", level.id + 1))  /  10")
                Text(level.title).font(Ink.title(29))
                  .foregroundStyle(Ink.cream).minimumScaleFactor(0.75).lineLimit(1)
              }
              Spacer()
              VStack(alignment: .trailing, spacing: 6) {
                Text(String(format: "%02d", puzzle.moves))
                  .font(.system(size: 30, weight: .light, design: .monospaced))
                  .foregroundStyle(Ink.cream).contentTransition(.numericText())
                Eyebrow(text: "MOVES")
              }
            }
            statusStrip
            board
              .frame(width: min(geometry.size.width - 36, 440))
              .aspectRatio(1, contentMode: .fit)
            instruction
            controls
            HStack {
              Image(systemName: "drop").font(.system(size: 12))
              Text(
                sailing
                  ? "Tide \(min(cursor + 1, level.tideLimit)) / \(level.tideLimit)"
                  : "Take your time. The tide can wait."
              )
              .font(.system(size: 11, design: .monospaced))
              Spacer()
              Text("PAR \(puzzle.par)").font(.system(size: 11, design: .monospaced))
            }.foregroundStyle(Ink.muted)
            if sailing {
              ProgressView(value: Double(cursor + 1), total: Double(level.tideLimit))
                .tint(Ink.gold)
            }
          }
          .padding(.horizontal, 18)
          .padding(.top, 5)
          .padding(.bottom, 18)
          .frame(minHeight: geometry.size.height, alignment: .top)
        }
        .scrollIndicators(.hidden)
      }
      if paused {
        Ink.night.opacity(0.94).ignoresSafeArea()
        VStack(spacing: 24) {
          PaperBoat().frame(width: 110, height: 80)
          Eyebrow(text: "THE CITY HOLDS ITS BREATH")
          Text("A quiet moment").font(Ink.title(32)).foregroundStyle(Ink.cream)
          MainButton(title: "Keep sailing", icon: "play.fill") { paused = false }
            .accessibilityIdentifier("resume")
          Button("Return to planning") { returnToPlanning() }
            .foregroundStyle(Ink.paper).frame(minHeight: 44)
        }.padding(35)
      }
      if finished, let voyage {
        ResultView(
          level: level, puzzle: puzzle, voyage: voyage,
          retry: { returnToPlanning() },
          next: next, home: home)
      }
    }
    .task(id: sailing) {
      guard sailing else { return }
      while !Task.isCancelled && sailing {
        try? await Task.sleep(for: .milliseconds(780))
        guard !Task.isCancelled, !paused, let voyage else { continue }
        if cursor + 1 < voyage.cells.count {
          withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.65)) { cursor += 1 }
          Feedback.tap()
        } else {
          if voyage.success {
            ProgressStore().save(level: level.id, moves: puzzle.moves)
            Feedback.tap(success: true)
          }
          finished = true
          sailing = false
        }
      }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active && sailing { paused = true }
    }
    .sheet(isPresented: $showHelp) { help }
    .confirmationDialog(
      "Fold this route again?", isPresented: $showReset, titleVisibility: .visible
    ) {
      Button("Reset this letter", role: .destructive) {
        returnToPlanning()
        puzzle = PuzzleState(level: level)
      }
    } message: {
      Text("Your best delivery stays saved. This plan starts over.")
    }
  }

  private var header: some View {
    HStack {
      IconButton(icon: "arrow.left", label: "Back to home") { home() }
      Spacer()
      Eyebrow(text: level.district)
      Spacer()
      IconButton(icon: sailing ? "pause" : "questionmark", label: sailing ? "Pause" : "How to play")
      {
        if sailing { paused = true } else { showHelp = true }
      }
    }
  }

  private var statusStrip: some View {
    HStack {
      HStack(spacing: 7) {
        ForEach(0..<3) { index in
          Image(systemName: index < collected ? "envelope.fill" : "envelope")
            .font(.system(size: 15))
            .foregroundStyle(index < collected ? Ink.gold : Ink.muted)
        }
        Text("\(collected)/3").font(.system(size: 11, design: .monospaced))
          .foregroundStyle(Ink.paper)
      }.accessibilityElement(children: .ignore).accessibilityLabel(
        "\(collected) of 3 stamps collected")
      Spacer()
      HStack(spacing: 6) {
        Circle().fill(sailing ? Ink.gold : Ink.foam).frame(width: 5, height: 5)
        Text(sailing ? "SAILING" : (puzzle.preview.success ? "ROUTE CONNECTED" : "PAUSE & PLAN"))
          .font(.system(size: 10, weight: .bold, design: .monospaced))
          .tracking(1).foregroundStyle(Ink.foam)
      }
    }
    .padding(.vertical, 12)
    .overlay(alignment: .top) { Rectangle().fill(Ink.muted.opacity(0.2)).frame(height: 1) }
  }

  private var board: some View {
    BoardView(
      level: level, canals: puzzle.canals, lit: Set(visited), boat: boat,
      collected: sailing || finished ? Set(visited) : [],
      interactive: !sailing && !finished,
      rotate: { cell in
        Feedback.tap()
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { puzzle.rotate(cell) }
      },
      toggle: { cell in
        Feedback.tap()
        withAnimation { puzzle.toggleLock(cell) }
      })
  }

  private var instruction: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: sailing ? "wind" : "hand.tap")
        .font(.system(size: 18, weight: .light)).foregroundStyle(Ink.gold)
        .frame(width: 24)
      Text(sailing ? "Follow your letter through the rain." : level.note)
        .font(.system(size: 13)).lineSpacing(4).foregroundStyle(Ink.paper)
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
    }
  }

  private var controls: some View {
    VStack(spacing: 12) {
      HStack(spacing: 0) {
        tool("arrow.uturn.backward", "Undo", disabled: !puzzle.canUndo || sailing) { puzzle.undo() }
        Spacer()
        tool("arrow.counterclockwise", "Reset", disabled: sailing) { showReset = true }
        Spacer()
        tool("sparkle", "Hint", disabled: sailing || puzzle.preview.success) { puzzle.hint() }
      }
      if sailing {
        MainButton(title: "Return to planning", icon: "stop.fill") { returnToPlanning() }
          .accessibilityIdentifier("stopSailing")
      } else {
        MainButton(title: "Release the boat", icon: "paperplane") {
          Feedback.tap()
          voyage = puzzle.preview
          cursor = 0
          sailing = true
        }.accessibilityIdentifier("releaseBoat")
      }
    }
  }

  private func tool(_ icon: String, _ label: String, disabled: Bool, action: @escaping () -> Void)
    -> some View
  {
    Button {
      Feedback.tap()
      action()
    } label: {
      Label(label, systemImage: icon).font(.system(size: 13, weight: .medium))
        .foregroundStyle(Ink.paper).frame(minWidth: 86, minHeight: 44)
    }
    .buttonStyle(.plain).disabled(disabled).opacity(disabled ? 0.3 : 1)
    .accessibilityIdentifier(label.lowercased())
  }

  private func returnToPlanning() {
    sailing = false
    paused = false
    finished = false
    voyage = nil
    cursor = 0
  }

  private var help: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Text("Make a way\nfor a small wonder.").font(Ink.title(32)).foregroundStyle(Ink.night)
          helpRow(
            "hand.tap", "Turn the canals",
            "Tap a blue canal tile to rotate it clockwise. The pale water shows how far your connected route reaches."
          )
          helpRow(
            "envelope", "Collect all three stamps",
            "Amber envelopes sit along the route. Sail through each, then reach the red postbox.")
          helpRow(
            "lock.open", "Open the locks",
            "Tap the small lock latch in a striped tile’s corner. The separate latch opens and closes the gate."
          )
          helpRow(
            "arrow.up", "Follow the currents",
            "White arrows are one way. Rotate these canals until the arrow points along your route."
          )
          helpRow(
            "sparkle", "A little help",
            "Hint fixes one tile. Three seals reward a delivery at par without hints; hints reduce your seal rating. Undo reverses your last move."
          )
        }.padding(24)
      }.background(Ink.paper)
        .navigationTitle("The art of delivery").navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Got it") { showHelp = false } }
    }
  }

  private func helpRow(_ icon: String, _ title: String, _ text: String) -> some View {
    HStack(alignment: .top, spacing: 15) {
      Image(systemName: icon).foregroundStyle(Ink.red).frame(width: 24, height: 28)
      VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.system(size: 16, weight: .semibold))
        Text(text).font(.system(size: 14)).lineSpacing(4).foregroundStyle(Ink.blue)
      }
    }
  }
}

struct BoardView: View {
  let level: Level
  let canals: [Canal]
  let lit: Set<Cell>
  let boat: Cell
  let collected: Set<Cell>
  var interactive: Bool
  var rotate: (Cell) -> Void = { _ in }
  var toggle: (Cell) -> Void = { _ in }

  var body: some View {
    GeometryReader { geometry in
      let inset: CGFloat = 14
      let step = (geometry.size.width - inset * 2) / CGFloat(level.size)
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 4).fill(Color(red: 0.73, green: 0.71, blue: 0.62)).offset(
          y: 7)
        RoundedRectangle(cornerRadius: 4).fill(Ink.paper)
        PaperTexture()
        ForEach(0..<level.size, id: \.self) { row in
          ForEach(0..<level.size, id: \.self) { col in
            let cell = Cell(row: row, col: col)
            tile(cell, side: step)
              .frame(width: step, height: step)
              .offset(x: inset + CGFloat(col) * step, y: inset + CGFloat(row) * step)
          }
        }
        PaperBoat()
          .frame(width: step * 0.66, height: step * 0.48)
          .shadow(color: Ink.night.opacity(0.3), radius: 4, y: 4)
          .offset(
            x: inset + CGFloat(boat.col) * step + step * 0.17,
            y: inset + CGFloat(boat.row) * step + step * 0.26
          )
          .allowsHitTesting(false)
      }
    }
  }

  @ViewBuilder
  private func tile(_ cell: Cell, side: CGFloat) -> some View {
    if let canal = canals.first(where: { $0.cell == cell }) {
      let fixed = cell == level.start || cell == level.dock
      ZStack {
        Rectangle().fill(Ink.cream.opacity(0.6)).padding(1)
        Button {
          rotate(cell)
        } label: {
          CanalDrawing(canal: canal, lit: lit.contains(cell))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!interactive || fixed)
        .accessibilityLabel("Canal row \(cell.row + 1) column \(cell.col + 1)")
        .accessibilityValue(
          canal.ports.map { String(describing: $0) }.joined(separator: " to ")
            + (canal.isCurrent ? ", one way" : "")
        )
        .accessibilityHint("Rotate clockwise")
        .accessibilityIdentifier("canal-\(cell.row)-\(cell.col)")
        if canal.hasStamp && !collected.contains(cell) {
          Image(systemName: "envelope.fill")
            .font(.system(size: side * 0.16, weight: .medium))
            .foregroundStyle(Ink.night)
            .padding(5).background(Ink.gold, in: RoundedRectangle(cornerRadius: 3))
            .rotationEffect(.degrees(-8))
            .offset(x: side * 0.22, y: -side * 0.24)
            .allowsHitTesting(false)
        }
        if cell == level.dock {
          VStack(spacing: 1) {
            Image(systemName: "envelope.fill").font(.system(size: side * 0.17))
            Text("POST").font(.system(size: 7, weight: .black, design: .monospaced))
          }
          .foregroundStyle(Ink.cream).padding(6).background(
            Ink.red, in: RoundedRectangle(cornerRadius: 4)
          )
          .offset(y: -side * 0.10).allowsHitTesting(false)
        }
        if canal.isLock {
          VStack {
            HStack {
              Spacer(minLength: 0)
              Button {
                toggle(cell)
              } label: {
                Image(systemName: canal.open ? "lock.open.fill" : "lock.fill")
                  .font(.system(size: 13))
                  .foregroundStyle(canal.open ? Ink.night : Ink.cream)
                  .frame(width: 30, height: 28)
                  .background(
                    canal.open ? Ink.gold : Ink.red, in: RoundedRectangle(cornerRadius: 4)
                  )
                  .frame(width: 44, height: 44)
                  .contentShape(Rectangle())
              }
              .disabled(!interactive)
              .accessibilityLabel(
                "\(canal.open ? "Close" : "Open") lock row \(cell.row + 1) column \(cell.col + 1)"
              )
              .accessibilityIdentifier("lock-\(cell.row)-\(cell.col)")
            }
            Spacer(minLength: 0)
          }
        }
      }
      .clipped()
    } else {
      Canvas { context, size in
        let scale = side / 82
        context.scaleBy(x: scale, y: scale)
        drawHouse(
          &context, x: 20, y: 67, width: CGFloat(25 + (cell.row + cell.col) % 3 * 5),
          height: CGFloat(28 + (cell.row * 3 + cell.col) % 3 * 9),
          red: (cell.row + cell.col) % 3 == 0)
        if (cell.row + cell.col) % 2 == 0 {
          context.fill(
            Path(ellipseIn: CGRect(x: 58, y: 56, width: 10, height: 13)),
            with: .color(Ink.water.opacity(0.6)))
        }
      }.accessibilityHidden(true)
    }
  }
}

struct ResultView: View {
  let level: Level
  let puzzle: PuzzleState
  let voyage: RouteResult
  let retry: () -> Void
  let next: () -> Void
  let home: () -> Void
  @State private var shareImage: SharedPostcard?

  var body: some View {
    ZStack {
      Ink.night.ignoresSafeArea()
      ScrollView {
        VStack(spacing: 20) {
          HStack {
            Eyebrow(text: voyage.success ? "DELIVERY CONFIRMED" : "A LETTER STILL ON ITS WAY")
            Spacer()
            IconButton(icon: "xmark", label: "Close result") { retry() }
          }
          Text(voyage.success ? "A little wonder,\ndelivered." : "Even paper boats\nmiss a turn.")
            .font(Ink.title(36)).tracking(-1)
            .foregroundStyle(Ink.cream).multilineTextAlignment(.center)
            .accessibilityIdentifier("resultTitle")
          if voyage.success {
            Postcard(level: level, puzzle: puzzle)
              .rotationEffect(.degrees(-2))
              .padding(.horizontal, 6).padding(.vertical, 6)
            HStack(spacing: 8) {
              ForEach(0..<3) { index in
                Image(systemName: "seal.fill")
                  .foregroundStyle(index < puzzle.rating ? Ink.gold : Ink.muted.opacity(0.25))
              }
              Text("\(puzzle.moves) moves · \(puzzle.hints) hints")
                .font(.system(size: 13)).foregroundStyle(Ink.paper)
            }.accessibilityLabel(
              "\(puzzle.rating) of 3 seals, \(puzzle.moves) moves, \(puzzle.hints) hints")
            MainButton(title: level.id == 9 ? "Back to the collection" : "The next letter") {
              if level.id == 9 { home() } else { next() }
            }.accessibilityIdentifier("nextLetter")
            HStack {
              Button {
                retry()
              } label: {
                Label("Sail again", systemImage: "arrow.counterclockwise")
              }.accessibilityIdentifier("replay")
              Spacer()
              Button {
                let renderer = ImageRenderer(
                  content: Postcard(level: level, puzzle: puzzle).frame(width: 380).padding(20)
                    .background(Ink.paper))
                renderer.scale = 3
                if let image = renderer.uiImage {
                  shareImage = SharedPostcard(image: image)
                }
              } label: {
                Label("Send postcard", systemImage: "square.and.arrow.up")
              }.accessibilityIdentifier("sharePostcard")
            }.font(.system(size: 13, weight: .medium)).foregroundStyle(Ink.paper)
              .frame(minHeight: 44)
          } else {
            BoardView(
              level: level, canals: puzzle.canals, lit: Set(voyage.cells),
              boat: voyage.cells.last ?? level.start, collected: voyage.stamps, interactive: false
            )
            .aspectRatio(1, contentMode: .fit).padding(.horizontal, 18)
            Text(voyage.problem?.message ?? "")
              .font(.system(size: 15)).lineSpacing(5)
              .foregroundStyle(Ink.paper).multilineTextAlignment(.center)
            MainButton(title: "Return to planning", icon: "arrow.uturn.backward", action: retry)
              .accessibilityIdentifier("retry")
          }
          Button("The letter collection", action: home)
            .font(.system(size: 12)).foregroundStyle(Ink.muted)
            .frame(minHeight: 44).accessibilityIdentifier("resultHome")
        }.padding(24)
      }.scrollIndicators(.hidden)
    }
    .sheet(item: $shareImage) { item in
      ActivitySheet(
        image: item.image,
        text: "A little wonder, delivered. \(level.title) — \(puzzle.moves) moves in Paper Current."
      )
    }
  }
}

struct Postcard: View {
  let level: Level
  let puzzle: PuzzleState
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 5) {
          Eyebrow(text: "GREETINGS FROM", color: Ink.blue)
          Text("Paper Current").font(Ink.title(27)).foregroundStyle(Ink.night)
        }
        Spacer()
        Image(systemName: "envelope.badge")
          .font(.system(size: 25, weight: .light)).foregroundStyle(Ink.red)
          .padding(9).overlay(
            Rectangle().strokeBorder(Ink.red, style: StrokeStyle(lineWidth: 1, dash: [2, 2])))
      }
      BoardView(
        level: level, canals: puzzle.canals, lit: Set(level.route), boat: level.dock,
        collected: Set(level.route), interactive: false
      )
      .aspectRatio(1, contentMode: .fit)
      .overlay(alignment: .bottomTrailing) {
        Text("DELIVERED\nBY PAPER BOAT")
          .font(.system(size: 9, weight: .heavy, design: .monospaced))
          .tracking(1).multilineTextAlignment(.center).foregroundStyle(Ink.red)
          .padding(9).overlay(Circle().stroke(Ink.red, lineWidth: 1.5))
          .rotationEffect(.degrees(-15)).offset(x: 8, y: 4)
      }
      HStack {
        Text("No. \(String(format: "%02d", level.id + 1)) · \(level.title)")
          .font(Ink.title(12)).foregroundStyle(Ink.blue)
        Spacer()
        Text("3 / 3").font(.system(size: 11, design: .monospaced)).foregroundStyle(Ink.red)
      }.padding(.top, 3)
    }
    .padding(16).background(Ink.cream)
    .overlay(PaperTexture())
    .shadow(color: .black.opacity(0.2), radius: 12, y: 10)
  }
}

struct SharedPostcard: Identifiable {
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
