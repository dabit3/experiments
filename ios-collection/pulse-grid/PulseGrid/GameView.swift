import SwiftUI
import UIKit

struct GameView: View {
  let level: CircuitLevel
  let next: (Int) -> Void
  @State private var session: CircuitSession
  @EnvironmentObject private var store: ProgressStore
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var showReset = false
  @State private var showGuide = false
  @State private var hintIndex: Int?

  init(level: CircuitLevel, initialSession: CircuitSession, next: @escaping (Int) -> Void) {
    self.level = level
    self.next = next
    _session = State(initialValue: initialSession)
  }

  private var network: [Int: Int] { level.connected(turns: session.turns) }
  private var received: Int { level.receivers.filter { network[$0] != nil }.count }
  private var solved: Bool { received == level.receiverCount }

  var body: some View {
    ZStack {
      InstrumentBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          HStack {
            Button {
              dismiss()
            } label: {
              HStack(spacing: 8) {
                Image(systemName: "arrow.left")
                Text("Circuits")
              }
              .font(.system(.subheadline, weight: .medium))
              .foregroundStyle(Palette.ink)
              .frame(minHeight: 44)
            }
            Spacer()
            MicroLabel(text: String(format: "CIRCUIT %02d / 10", level.id + 1))
            IconButton(symbol: "questionmark", label: "How to play") { showGuide = true }
          }
          VStack(alignment: .leading, spacing: 10) {
            MicroLabel(text: level.complexity, color: Palette.mint)
            Text(level.name)
              .font(.system(.largeTitle, design: .rounded, weight: .light))
              .foregroundStyle(Palette.ink)
              .accessibilityAddTraits(.isHeader)
            Text(level.subtitle)
              .font(.system(.subheadline))
              .foregroundStyle(Palette.muted)
          }
          HStack {
            VStack(alignment: .leading, spacing: 7) {
              MicroLabel(text: "RECEIVERS")
              HStack(spacing: 7) {
                ForEach(level.receivers, id: \.self) { receiver in
                  Image(systemName: network[receiver] == nil ? "diamond" : "diamond.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(network[receiver] == nil ? Palette.coral : Palette.mint)
                }
                Text("\(received)/\(level.receiverCount)")
                  .font(.system(.subheadline, design: .monospaced))
                  .foregroundStyle(Palette.ink)
                  .padding(.leading, 4)
              }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(received) of \(level.receiverCount) receivers powered")
            Spacer()
            VStack(alignment: .trailing, spacing: 7) {
              MicroLabel(text: "ROTATIONS")
              Text(String(format: "%02d", session.moves))
                .font(.system(.title3, design: .monospaced, weight: .light))
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText())
            }
          }
          .padding(.horizontal, 4)
          board
          HStack(spacing: 8) {
            Circle().fill(solved ? Palette.mint : Palette.coral).frame(width: 6, height: 6)
            MicroLabel(
              text: solved ? "ALL RECEIVERS ONLINE" : "TAP A TILE TO ROTATE",
              color: solved ? Palette.mint : Palette.muted)
            Spacer()
            MicroLabel(text: "\(level.size) × \(level.size)")
          }
          .padding(.top, -9)
          if solved {
            completion
          } else {
            VStack(spacing: 14) {
              HStack(spacing: 12) {
                ActionButton(title: "Reset", symbol: "arrow.counterclockwise") { showReset = true }
                ActionButton(title: "Hint", symbol: "sparkle") { giveHint() }
              }
              Text(
                hintIndex == nil
                  ? "Connect the mint source to every coral receiver."
                  : "One tile aligned. Follow the current from the source."
              )
              .font(.system(.footnote))
              .foregroundStyle(Palette.muted)
              .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 32)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { store.save(session, for: level) }
    .sheet(isPresented: $showGuide) { GuideView() }
    .confirmationDialog("Reset this circuit?", isPresented: $showReset, titleVisibility: .visible) {
      Button("Reset circuit", role: .destructive) {
        session = CircuitSession(level: level)
        hintIndex = nil
        store.save(session, for: level)
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Current rotations and hints will reset. Your completed-circuit record stays saved.")
    }
  }

  private var board: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: level.size), spacing: 7
    ) {
      ForEach(level.masks.indices, id: \.self) { index in
        if level.isRotatable(index) {
          Button {
            rotate(index)
          } label: {
            TileView(
              level: level, index: index, turns: session.turns[index],
              distance: network[index], hint: hintIndex == index)
          }
          .buttonStyle(.plain)
          .disabled(solved)
          .accessibilityLabel(tileLabel(index))
          .accessibilityHint(
            solved ? "Circuit complete. Reset to play again." : "Rotates clockwise one quarter turn"
          )
        } else {
          TileView(
            level: level, index: index, turns: session.turns[index],
            distance: network[index], hint: false
          )
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(tileLabel(index))
        }
      }
    }
    .padding(10)
    .background(Palette.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 24))
    .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(Palette.line, lineWidth: 1) }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Circuit board")
  }

  private var completion: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 6) {
          Text("Signal locked.")
            .font(.system(.title2, design: .rounded, weight: .medium))
            .foregroundStyle(Palette.mint)
          Text(
            "\(session.moves) rotations · \(session.hints == 0 ? "No hints" : "\(session.hints) hint\(session.hints == 1 ? "" : "s")")"
          )
          .font(.system(.footnote, design: .monospaced))
          .foregroundStyle(Palette.muted)
        }
        Spacer()
        Image(systemName: "checkmark.seal")
          .font(.system(size: 27, weight: .ultraLight))
          .foregroundStyle(Palette.mint)
      }
      ActionButton(
        title: level.id == 9 ? "Back to circuits" : "Next circuit",
        symbol: "arrow.right", primary: true
      ) {
        if level.id == 9 { dismiss() } else { next(level.id + 1) }
      }
      Button("Play again") { showReset = true }
        .font(.system(.subheadline))
        .foregroundStyle(Palette.muted)
        .frame(maxWidth: .infinity, minHeight: 44)
    }
    .padding(20)
    .background(Palette.panel.opacity(0.7), in: RoundedRectangle(cornerRadius: 22))
    .accessibilityElement(children: .contain)
  }

  private func rotate(_ index: Int) {
    hintIndex = nil
    withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.72)) {
      session.rotate(index, in: level)
    }
    changed()
  }

  private func giveHint() {
    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
      hintIndex = session.hint(in: level)
    }
    changed()
  }

  private func changed() {
    store.save(session, for: level)
    if store.data.haptics {
      if solved {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
      } else {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      }
    }
    if solved {
      UIAccessibility.post(
        notification: .announcement, argument: "Signal locked. All receivers online.")
    }
  }

  private func tileLabel(_ index: Int) -> String {
    let position = "Row \(index / level.size + 1), column \(index % level.size + 1)"
    if level.masks[index] == 0 { return "\(position), blocked cell" }
    let role =
      index == level.source
      ? "Fixed power source" : (level.receivers.contains(index) ? "Fixed receiver" : "Tile")
    let ports = Direction.allCases.filter {
      level.mask(at: index, turns: session.turns) & $0.bit != 0
    }.map { String(describing: $0) }.joined(separator: ", ")
    return
      "\(position), \(role), \(network[index] != nil ? "powered" : "unpowered"), connects \(ports)"
  }
}
