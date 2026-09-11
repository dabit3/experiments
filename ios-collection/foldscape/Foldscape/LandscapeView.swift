import SwiftUI
import UIKit

struct LandscapeView: View {
  let scene: Landscape
  @EnvironmentObject private var store: AtlasStore
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage("foldscape.numbers") private var numbers = true
  @AppStorage("foldscape.haptics") private var haptics = true
  @State private var pace: Pace = .gentle
  @State private var playing = false
  @State private var preview = false
  @State private var restart = false
  @State private var hinted = false
  @State private var guidance = "Tap a piece beside the empty space."

  private var puzzle: Puzzle? { store.saved.puzzles[scene.id] }
  private var complete: Bool { playing && puzzle?.isComplete == true }

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        HStack {
          Button {
            dismiss()
          } label: {
            Image(systemName: "arrow.left").frame(width: 44, height: 44)
          }
          .accessibilityLabel("Back to landscapes")
          Spacer()
          Text("LANDSCAPE \(scene.number) / 06")
            .font(.system(.caption2, design: .monospaced)).tracking(1.5)
          Spacer()
          Image(systemName: complete ? "checkmark.seal" : "leaf")
            .frame(width: 44, height: 44).accessibilityHidden(true)
        }
        .foregroundStyle(Paper.ink)

        VStack(spacing: 6) {
          Text(complete ? "A little world, whole." : scene.title)
            .font(.system(.largeTitle, design: .serif))
            .multilineTextAlignment(.center)
          Text(complete ? scene.title : scene.subtitle)
            .font(.subheadline).foregroundStyle(Paper.muted)
        }

        if playing && !complete, let puzzle {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("\(puzzle.moves)").font(.system(.title, design: .serif))
                .contentTransition(.numericText())
              Text("MOVES").font(.system(.caption2, design: .monospaced)).tracking(1)
            }
            Spacer()
            Text(puzzle.pace.caption).font(.subheadline).foregroundStyle(Paper.muted)
          }
          PuzzleBoard(
            scene: scene, puzzle: puzzle, numbers: numbers,
            hint: hinted ? puzzle.hintIndex : nil
          ) { index in
            let moved = store.move(scene.id, at: index)
            if moved {
              hinted = false
              guidance = "Tap a piece beside the empty space."
              if haptics {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
              }
              if store.saved.puzzles[scene.id]?.isComplete == true && haptics {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
              }
            } else {
              guidance = "Only pieces touching the empty space can slide."
              if haptics {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
              }
            }
          }
          .animation(
            reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.8), value: puzzle.tiles)
          Text(guidance)
            .font(.subheadline).foregroundStyle(Paper.muted)
            .multilineTextAlignment(.center).frame(minHeight: 40)
          HStack(spacing: 12) {
            tool("Preview", icon: "eye") { preview = true }
            tool("Hint", icon: "sparkle") {
              hinted = true
              guidance = "Slide the outlined piece. Hints retrace a path home."
            }
            tool("Restart", icon: "arrow.counterclockwise") { restart = true }
          }
          Text("No timer. Just one piece at a time.")
            .font(.system(.footnote, design: .serif)).italic()
            .foregroundStyle(Paper.muted)
        } else {
          LivingLandscape(scene: scene, living: complete)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .shadow(color: scene.color.opacity(0.16), radius: 16, x: 0, y: 10)
          if complete {
            completion
          } else {
            introduction
          }
        }
      }
      .padding(.horizontal, 24).padding(.bottom, 32)
    }
    .background(Paper.stock)
    .toolbar(.hidden, for: .navigationBar)
    .sheet(isPresented: $preview) {
      PreviewView(scene: scene)
    }
    .confirmationDialog("Start a fresh shuffle?", isPresented: $restart, titleVisibility: .visible)
    {
      Button("Restart with a new shuffle", role: .destructive) {
        start(puzzle?.pace ?? pace)
      }
    } message: {
      Text("This puzzle’s moves will reset. Collected landscapes stay safe.")
    }
  }

  private var introduction: some View {
    VStack(spacing: 20) {
      Text("Slide eight paper pieces into place.\nBring a quiet landscape to life.")
        .font(.body).foregroundStyle(Paper.muted).multilineTextAlignment(.center)
      Picker("Puzzle pace", selection: $pace) {
        ForEach(Pace.allCases, id: \.self) { Text($0.title).tag($0) }
      }
      .pickerStyle(.segmented)
      if let puzzle, !puzzle.isComplete {
        Button("Continue · \(puzzle.moves) moves") { playing = true }
          .buttonStyle(InkButton())
        Button("Start a new \(pace.title.lowercased()) puzzle") { restart = true }
          .font(.subheadline).frame(minHeight: 44)
      } else {
        Button {
          start(pace)
        } label: {
          HStack {
            Text("Unfold this place")
            Image(systemName: "arrow.right")
          }
        }
        .buttonStyle(InkButton())
      }
      if let record = store.saved.completions[scene.id] {
        Label("Collected · best \(record.bestMoves) moves", systemImage: "checkmark.seal")
          .font(.footnote).foregroundStyle(scene.color)
      }
    }
  }

  private var completion: some View {
    VStack(spacing: 20) {
      Label("ADDED TO YOUR COLLECTION", systemImage: "checkmark")
        .font(.system(.caption2, design: .monospaced)).tracking(1)
        .foregroundStyle(scene.color)
      Text(scene.story).font(.system(.body, design: .serif))
        .multilineTextAlignment(.center).lineSpacing(5)
      HStack(spacing: 32) {
        VStack(spacing: 5) {
          Text("\(puzzle?.moves ?? 0)").font(.system(.title, design: .serif))
          Text("moves").font(.caption).foregroundStyle(Paper.muted)
        }
        Rectangle().fill(Paper.edge).frame(width: 1, height: 36)
        VStack(spacing: 5) {
          Text("\(store.saved.completions.count) / 6").font(.system(.title, design: .serif))
          Text("collected").font(.caption).foregroundStyle(Paper.muted)
        }
      }
      Button("Back to landscapes") { dismiss() }.buttonStyle(InkButton())
      Button("Fold it again") { start(puzzle?.pace ?? pace) }
        .font(.subheadline).frame(minHeight: 44)
    }
  }

  private func start(_ selectedPace: Pace) {
    store.begin(scene.id, pace: selectedPace)
    playing = true
    hinted = false
    guidance = "Tap a piece beside the empty space."
  }

  private func tool(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack(spacing: 8) {
        Image(systemName: icon).font(.system(size: 20))
        Text(title).font(.caption)
      }
      .frame(maxWidth: .infinity).padding(.vertical, 14)
      .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
      .overlay(RoundedRectangle(cornerRadius: 16).stroke(Paper.edge, lineWidth: 1))
    }
    .buttonStyle(.plain)
  }
}

struct PuzzleBoard: View {
  let scene: Landscape
  let puzzle: Puzzle
  let numbers: Bool
  let hint: Int?
  let move: (Int) -> Void

  var body: some View {
    GeometryReader { geometry in
      let side = geometry.size.width
      let cell = (side - 12) / 3
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 10).fill(scene.color.opacity(0.12))
        ForEach(1...8, id: \.self) { value in
          if let index = puzzle.tiles.firstIndex(of: value) {
            Button {
              move(index)
            } label: {
              PaperTile(
                scene: scene, value: value, cell: cell,
                numbers: numbers, highlighted: hint == index)
            }
            .buttonStyle(.plain)
            .position(
              x: CGFloat(index % 3) * (cell + 6) + cell / 2,
              y: CGFloat(index / 3) * (cell + 6) + cell / 2
            )
            .accessibilityLabel("Piece \(value), row \(index / 3 + 1), column \(index % 3 + 1)")
            .accessibilityHint(
              puzzle.legalIndices.contains(index)
                ? "Double tap to slide into the empty space" : "Not beside the empty space")
          }
        }
      }
    }
    .aspectRatio(1, contentMode: .fit)
  }
}

struct PaperTile: View {
  let scene: Landscape
  let value: Int
  let cell: CGFloat
  let numbers: Bool
  let highlighted: Bool

  var body: some View {
    Image(scene.id).resizable()
      .frame(width: cell * 3, height: cell * 3)
      .offset(
        x: -CGFloat((value - 1) % 3) * cell,
        y: -CGFloat((value - 1) / 3) * cell
      )
      .frame(width: cell, height: cell, alignment: .topLeading)
      .clipped()
      .overlay(alignment: .bottomLeading) {
        if numbers {
          Text("\(value)").font(.system(.caption, design: .monospaced, weight: .medium))
            .foregroundStyle(Paper.ink).padding(7)
            .background(Paper.stock.opacity(0.94), in: Circle()).padding(6)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 5))
      .overlay {
        RoundedRectangle(cornerRadius: 5)
          .stroke(
            highlighted ? Paper.stock : Color.white.opacity(0.4),
            lineWidth: highlighted ? 4 : 1)
      }
      .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 3)
  }
}

struct LivingLandscape: View {
  let scene: Landscape
  let living: Bool
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var drift = false

  var body: some View {
    GeometryReader { geometry in
      Image(scene.id).resizable().scaledToFill()
      if living {
        Ellipse().fill(.white.opacity(0.20))
          .frame(width: geometry.size.width * 0.3, height: 18)
          .blur(radius: 8)
          .offset(x: geometry.size.width * (drift ? 0.60 : 0.12), y: geometry.size.height * 0.24)
          .animation(
            reduceMotion ? nil : .easeInOut(duration: 7).repeatForever(autoreverses: true),
            value: drift)
      }
    }
    .clipped()
    .onAppear { if living && !reduceMotion { drift = true } }
    .accessibilityLabel("\(scene.title), a layered paper landscape")
  }
}

struct PreviewView: View {
  let scene: Landscape
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 24) {
      HStack {
        Text("THE WHOLE PICTURE").font(.system(.caption2, design: .monospaced)).tracking(1.5)
        Spacer()
        Button("Done") { dismiss() }.frame(minHeight: 44)
      }
      Spacer()
      Image(scene.id).resizable().scaledToFit()
        .shadow(color: scene.color.opacity(0.2), radius: 16, y: 10)
      Text(scene.title).font(.system(.largeTitle, design: .serif))
      Text("The last piece appears when everything finds its place.")
        .font(.body).foregroundStyle(Paper.muted).multilineTextAlignment(.center)
      Spacer()
    }
    .padding(24).background(Paper.stock)
    .presentationDragIndicator(.visible)
  }
}
