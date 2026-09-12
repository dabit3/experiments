import Combine
import SwiftUI

struct PrismRoot: View {
  @Bindable var model: GameModel
  private let clock = Timer.publish(every: 1.0 / 60, on: .main, in: .common).autoconnect()

  var body: some View {
    ZStack {
      PrismBackdrop()
      switch model.screen {
      case .title: TitleView(model: model)
      case .playing, .ending:
        GameView(model: model).allowsHitTesting(model.screen == .playing)
      case .paused: PauseView(model: model)
      case .result: ResultView(model: model)
      }
    }
    .foregroundStyle(PrismStyle.paper)
    .background(KeyboardBridge(model: model).frame(width: 0, height: 0))
    .onReceive(clock) { model.tick($0) }
    .sheet(isPresented: $model.showingGuide) { GuideView(model: model) }
  }
}

struct TitleView: View {
  @Bindable var model: GameModel

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        HStack {
          Eyebrow(text: "THE FALLING BLOCK COLLECTION")
          Spacer()
          Image(systemName: "sparkle").foregroundStyle(PrismStyle.ice)
        }.padding(.top, 14)
        Spacer(minLength: 15)
        HeroPrism().frame(width: 260, height: min(geometry.size.height * 0.32, 255))
        Spacer(minLength: 18)
        VStack(spacing: 7) {
          Text("PRISM").font(.system(size: 56, weight: .ultraLight)).tracking(12)
          Text("S T A C K").font(.system(size: 18, weight: .medium)).tracking(7)
        }
        .padding(.leading, 12)
        Text("Find your flow.\nLeave nothing behind.")
          .font(.system(size: 16, weight: .regular)).lineSpacing(5)
          .foregroundStyle(PrismStyle.mist).multilineTextAlignment(.center)
          .padding(.top, 23)
        Spacer(minLength: 20)
        HStack(spacing: 12) {
          Rectangle().fill(.white.opacity(0.10)).frame(height: 1)
          VStack(spacing: 6) {
            Eyebrow(text: "PERSONAL BEST")
            Text(model.best.formatted()).font(.system(size: 24, weight: .light, design: .rounded))
              .monospacedDigit()
          }.fixedSize()
          Rectangle().fill(.white.opacity(0.10)).frame(height: 1)
        }.padding(.bottom, 26)
        PrismButton(
          title: model.hasSavedGame ? "Continue your flow" : "Enter the flow",
          symbol: "arrow.right", primary: true
        ) { model.start() }
        HStack {
          Button {
            model.showingGuide = true
          } label: {
            Label("How to play", systemImage: "questionmark.circle")
              .font(.system(size: 13)).frame(height: 48)
          }
          Spacer()
          Button {
            model.toggleSound()
          } label: {
            Image(systemName: model.sound ? "speaker.wave.2" : "speaker.slash")
              .frame(width: 48, height: 48)
          }.accessibilityLabel(model.sound ? "Mute sound" : "Enable sound")
        }.foregroundStyle(PrismStyle.mist)
      }.padding(.horizontal, 30).padding(.bottom, 5)
    }
  }
}

struct GameView: View {
  @Bindable var model: GameModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var dragPosition: CGFloat = 0
  @State private var softPosition: CGFloat = 0
  @State private var dragActive = false

  var body: some View {
    GeometryReader { geometry in
      let boardWidth = max(140, min(geometry.size.width - 112, (geometry.size.height - 205) / 2))
      VStack(spacing: 14) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 3) {
            Eyebrow(text: "PRISM / STACK")
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text(model.engine.score.formatted())
                .font(.system(size: 29, weight: .light, design: .rounded)).monospacedDigit()
                .accessibilityIdentifier("score")
              Text("PTS").font(.system(size: 8, weight: .semibold)).tracking(1.5)
                .foregroundStyle(PrismStyle.mist)
            }
          }
          Spacer()
          Button {
            model.pause()
          } label: {
            Image(systemName: "pause")
              .font(.system(size: 17, weight: .medium))
              .frame(width: 46, height: 46)
              .background(.white.opacity(0.05), in: Circle())
              .overlay(Circle().strokeBorder(.white.opacity(0.09)))
          }.accessibilityLabel("Pause game")
        }
        HStack(alignment: .top, spacing: 18) {
          BoardView(model: model, reduceMotion: reduceMotion)
            .frame(width: boardWidth, height: boardWidth * 2)
            .contentShape(Rectangle())
            .gesture(
              DragGesture(minimumDistance: 10)
                .onChanged { value in
                  guard model.gestures else { return }
                  dragActive = true
                  let unit = boardWidth / 10
                  let dx = value.translation.width - dragPosition
                  if abs(dx) >= unit {
                    model.act(dx > 0 ? .right : .left)
                    dragPosition += dx > 0 ? unit : -unit
                  }
                  let dy = value.translation.height - softPosition
                  if dy > unit {
                    model.act(.softDrop)
                    softPosition += unit
                  }
                }
                .onEnded { value in
                  defer {
                    dragPosition = 0
                    softPosition = 0
                    dragActive = false
                  }
                  guard model.gestures else { return }
                  if value.translation.height < -45 { model.act(.hold) }
                  if value.translation.height > 60,
                    value.predictedEndTranslation.height > value.translation.height + 100
                  {
                    model.act(.hardDrop)
                  }
                }
            )
            .onTapGesture { if model.gestures && !dragActive { model.act(.rotate) } }
          sidebar.frame(width: 58)
        }.frame(maxWidth: .infinity)
        controls
      }.padding(.horizontal, 18).padding(.top, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
  }

  private var sidebar: some View {
    VStack(spacing: 0) {
      Button {
        model.act(.hold)
      } label: {
        VStack(spacing: 10) {
          HStack(spacing: 4) {
            Eyebrow(text: "HOLD")
            if !model.engine.canHold {
              Image(systemName: "lock.fill").font(.system(size: 8))
                .foregroundStyle(PrismStyle.mist)
            }
          }
          PiecePreview(jewel: model.engine.held)
            .frame(height: 31)
        }
        .frame(width: 68, height: 72)
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
          RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.07)))
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Hold piece")
      .accessibilityValue(model.engine.canHold ? "Ready" : "Available after placing this piece")
      .disabled(!model.engine.canHold)
      Eyebrow(text: "NEXT").padding(.top, 25).padding(.bottom, 14)
      ForEach(Array(model.engine.queue.prefix(3).enumerated()), id: \.offset) { item in
        PiecePreview(jewel: item.element).frame(height: 29).padding(.bottom, 17)
      }
      Rectangle().fill(.white.opacity(0.10)).frame(height: 1).padding(.vertical, 5)
      VStack(spacing: 6) {
        Eyebrow(text: "LEVEL")
        Text(String(format: "%02d", model.engine.level))
          .font(.system(size: 23, weight: .light, design: .rounded))
        Capsule().fill(.white.opacity(0.07)).frame(height: 3)
          .overlay(alignment: .leading) {
            Capsule().fill(PrismStyle.ice)
              .frame(width: 58 * CGFloat(model.engine.lines % 10) / 10, height: 3)
          }
        Eyebrow(text: "LINES").padding(.top, 16)
        Text("\(model.engine.lines)").font(.system(size: 22, weight: .light, design: .rounded))
          .accessibilityIdentifier("lines")
      }.padding(.top, 15)
      Spacer(minLength: 12)
    }
  }

  private var controls: some View {
    VStack(spacing: 8) {
      HStack(spacing: 9) {
        ControlButton(symbol: "arrow.left", name: "Move left", repeats: true) {
          model.act(.left)
        }
        ControlButton(symbol: "arrow.clockwise", name: "Rotate", repeats: false) {
          model.act(.rotate)
        }
        ControlButton(symbol: "arrow.right", name: "Move right", repeats: true) {
          model.act(.right)
        }
      }
      HStack(spacing: 9) {
        ControlButton(symbol: "arrow.down", name: "Soft drop", repeats: true) {
          model.act(.softDrop)
        }.frame(maxWidth: 80)
        Button {
          model.act(.hardDrop)
        } label: {
          HStack(spacing: 10) {
            Image(systemName: "arrow.down.to.line.compact")
            Text("DROP").font(.system(size: 12, weight: .bold)).tracking(2)
          }.frame(maxWidth: .infinity).frame(height: 48)
            .foregroundStyle(PrismStyle.ink)
            .background(PrismStyle.ice, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain).accessibilityLabel("Hard drop")
      }
      Text(
        model.gestures
          ? "Drag to move · tap to turn · flick down to drop"
          : "Hold arrows to glide · tap DROP to place"
      )
      .font(.system(size: 10, weight: .medium)).tracking(0.25)
      .foregroundStyle(PrismStyle.mist).padding(.top, 2)
    }
  }
}

struct ControlButton: View {
  let symbol: String
  let name: String
  let repeats: Bool
  let action: () -> Void
  @State private var pressed = false
  @State private var repeatTask: Task<Void, Never>?

  var body: some View {
    Image(systemName: symbol).font(.system(size: 19, weight: .medium))
      .frame(maxWidth: .infinity).frame(height: 48)
      .background(
        .white.opacity(pressed ? 0.13 : 0.055), in: RoundedRectangle(cornerRadius: 12)
      )
      .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.09)))
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in
            guard !pressed else { return }
            pressed = true
            action()
            guard repeats else { return }
            repeatTask = Task { @MainActor in
              try? await Task.sleep(for: .milliseconds(220))
              while !Task.isCancelled {
                action()
                try? await Task.sleep(for: .milliseconds(70))
              }
            }
          }
          .onEnded { _ in
            pressed = false
            repeatTask?.cancel()
            repeatTask = nil
          }
      )
      .accessibilityLabel(name)
      .accessibilityAddTraits(.isButton)
      .accessibilityAction { action() }
      .onDisappear {
        repeatTask?.cancel()
        repeatTask = nil
        pressed = false
      }
  }
}

struct BoardView: View {
  let model: GameModel
  let reduceMotion: Bool

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 30, paused: model.screen != .playing)) {
      timeline in
      let clearAge = timeline.date.timeIntervalSince(model.clearDate)
      Canvas { context, size in
        let unit = size.width / 10
        let backdrop = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 5)
        context.fill(backdrop, with: .color(.black.opacity(0.24)))
        for y in 0..<20 {
          for x in 0..<10 {
            let rect = CGRect(x: CGFloat(x) * unit, y: CGFloat(y) * unit, width: unit, height: unit)
            context.stroke(
              Path(rect.insetBy(dx: 0.5, dy: 0.5)), with: .color(.white.opacity(0.035)),
              lineWidth: 0.45)
            if let jewel = Jewel(rawValue: model.engine.board[y + 2][x]) {
              drawGem(context, rect: rect, jewel: jewel)
            }
          }
        }
        if model.screen == .playing {
          if let ghost = model.engine.ghost {
            for cell in ghost.cells where cell.y >= 2 {
              drawGem(context, rect: rect(cell, unit), jewel: ghost.jewel, ghost: true)
            }
          }
          if let piece = model.engine.active {
            for cell in piece.cells where cell.y >= 2 {
              drawGem(context, rect: rect(cell, unit), jewel: piece.jewel)
            }
          }
        }
        if clearAge < 0.55 && !reduceMotion {
          for row in model.engine.clearedRows where row >= 2 {
            let rect = CGRect(x: 0, y: CGFloat(row - 2) * unit, width: size.width, height: unit)
            context.fill(
              Path(rect),
              with: .linearGradient(
                Gradient(colors: [
                  .clear, PrismStyle.ice.opacity(0.75 * (1 - clearAge / 0.55)), .clear,
                ]),
                startPoint: CGPoint(x: size.width * clearAge / 0.55 - size.width / 2, y: rect.midY),
                endPoint: CGPoint(x: size.width * clearAge / 0.55 + size.width / 2, y: rect.midY)))
          }
        }
      }
      .overlay {
        RoundedRectangle(cornerRadius: 5)
          .strokeBorder(
            LinearGradient(
              colors: [.white.opacity(0.22), .white.opacity(0.05)], startPoint: .topLeading,
              endPoint: .bottomTrailing),
            lineWidth: 1)
      }
      .overlay(alignment: .center) {
        if model.screen == .ending {
          Text("Stack reached the top").font(.system(size: 15, weight: .medium))
            .foregroundStyle(PrismStyle.paper).padding(16)
            .background(PrismStyle.ink.opacity(0.95), in: RoundedRectangle(cornerRadius: 10))
        } else if clearAge < 1.1 && !model.clearText.isEmpty {
          Text(model.clearText).font(.system(size: 16, weight: .bold)).tracking(3)
            .foregroundStyle(PrismStyle.ice).padding(13)
            .background(PrismStyle.ink.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
            .opacity(min(1, (1.1 - clearAge) * 4))
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Game board")
    .accessibilityValue(
      "Score \(model.engine.score), \(model.engine.lines) lines, level \(model.engine.level)")
  }

  private func rect(_ cell: Cell, _ unit: CGFloat) -> CGRect {
    CGRect(x: CGFloat(cell.x) * unit, y: CGFloat(cell.y - 2) * unit, width: unit, height: unit)
  }
}

struct PauseView: View {
  @Bindable var model: GameModel

  var body: some View {
    ZStack {
      PrismBackdrop()
      VStack(spacing: 24) {
        Image(systemName: "pause.circle").font(.system(size: 40, weight: .ultraLight))
          .foregroundStyle(PrismStyle.ice)
        VStack(spacing: 12) {
          Eyebrow(text: "TAKE A BREATH")
          Text("Still in the flow.").font(.system(size: 31, weight: .light))
          Text("Your stack will be right here.").font(.system(size: 14))
            .foregroundStyle(PrismStyle.mist)
        }
        VStack(spacing: 10) {
          PrismButton(title: "Resume", symbol: "play.fill", primary: true) { model.resume() }
          PrismButton(title: "How to play", symbol: "questionmark.circle") {
            model.showingGuide = true
          }
          HStack {
            Button {
              model.toggleSound()
            } label: {
              Label(
                model.sound ? "Sound on" : "Sound off",
                systemImage: model.sound ? "speaker.wave.2" : "speaker.slash"
              )
              .font(.system(size: 13)).frame(maxWidth: .infinity).frame(height: 48)
            }
            Button {
              model.toggleGestures()
            } label: {
              Label(model.gestures ? "Gestures on" : "Gestures off", systemImage: "hand.draw")
                .font(.system(size: 13)).frame(maxWidth: .infinity).frame(height: 48)
            }
          }.foregroundStyle(PrismStyle.mist)
          Button("Save & return home") { model.home() }
            .font(.system(size: 13)).foregroundStyle(PrismStyle.mist).frame(height: 48)
        }
      }.padding(.horizontal, 34)
    }
  }
}

struct ResultView: View {
  @Bindable var model: GameModel

  var body: some View {
    ZStack {
      PrismBackdrop()
      VStack(spacing: 24) {
        Image(systemName: "sparkles").font(.system(size: 35, weight: .ultraLight))
          .foregroundStyle(PrismStyle.ice)
        VStack(spacing: 12) {
          Eyebrow(
            text: model.engine.score > model.sessionBest ? "A NEW PERSONAL BEST" : "FLOW COMPLETE")
          Text("Beautifully played.").font(.system(size: 31, weight: .light))
          Text("Your stack reached the top.").font(.system(size: 13))
            .foregroundStyle(PrismStyle.mist)
        }
        VStack(spacing: 7) {
          Text(model.engine.score.formatted())
            .font(.system(size: 64, weight: .ultraLight, design: .rounded)).monospacedDigit()
          Eyebrow(text: "POINTS")
        }.padding(.vertical, 10)
        HStack(spacing: 0) {
          resultStat("\(model.engine.lines)", "LINES")
          resultStat("\(model.engine.level)", "LEVEL")
          resultStat(model.best.formatted(), "BEST")
        }.padding(.vertical, 19)
          .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
        VStack(spacing: 10) {
          PrismButton(title: "Find your flow again", symbol: "arrow.clockwise", primary: true) {
            model.replay()
          }
          Button("Return home") { model.home() }.frame(height: 48)
            .font(.system(size: 13)).foregroundStyle(PrismStyle.mist)
        }
      }.padding(.horizontal, 30)
    }
  }

  private func resultStat(_ value: String, _ label: String) -> some View {
    VStack(spacing: 8) {
      Text(value).font(.system(size: 22, weight: .light, design: .rounded)).monospacedDigit()
      Eyebrow(text: label)
    }.frame(maxWidth: .infinity)
  }
}

struct GuideView: View {
  @Bindable var model: GameModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      PrismBackdrop()
      ScrollView {
        VStack(alignment: .leading, spacing: 26) {
          HStack {
            Eyebrow(text: "A MOMENT TO LEARN")
            Spacer()
            Button {
              dismiss()
            } label: {
              Image(systemName: "xmark").frame(width: 44, height: 44)
            }.accessibilityLabel("Close guide")
          }
          Text("Make room\nfor what’s next.").font(.system(size: 35, weight: .light))
          Text(
            "Fill a horizontal row with no gaps to clear it. Keep your stack below the top. Every ten lines, the pace rises."
          )
          .font(.system(size: 16)).lineSpacing(5).foregroundStyle(PrismStyle.mist)
          guideRow(
            "arrow.left.and.right", "Find your position",
            "Tap the arrows to move. Hold an arrow to glide. The outline shows where your piece will land."
          )
          guideRow(
            "arrow.clockwise", "Turn & place",
            "Rotate to find a fit. Soft drop nudges down; DROP places instantly. Clear four rows together for 800 × your level."
          )
          guideRow(
            "square.on.square", "Keep a little possibility",
            "Tap HOLD to save or swap a piece, once per turn. Preview your next three pieces.")
          Button {
            model.toggleGestures()
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 5) {
                Text("Board gestures").font(.system(size: 15, weight: .medium))
                Text("Drag to move · tap to turn\nFlick down to drop · swipe up to hold")
                  .font(.system(size: 12)).foregroundStyle(PrismStyle.mist).lineSpacing(4)
              }
              Spacer()
              Image(systemName: model.gestures ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 25)).foregroundStyle(PrismStyle.ice)
            }.padding(18).background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 15))
          }.buttonStyle(.plain).accessibilityLabel(
            "Board gestures \(model.gestures ? "on" : "off")")
          PrismButton(title: "I’m ready", symbol: "arrow.right", primary: true) { dismiss() }
        }.padding(28)
      }
    }.presentationDragIndicator(.visible).preferredColorScheme(.dark)
  }

  private func guideRow(_ symbol: String, _ title: String, _ detail: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
      Image(systemName: symbol).font(.system(size: 22, weight: .light))
        .foregroundStyle(PrismStyle.ice).frame(width: 27).padding(.top, 3)
      VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.system(size: 16, weight: .medium))
        Text(detail).font(.system(size: 13)).lineSpacing(4).foregroundStyle(PrismStyle.mist)
      }
    }
  }
}
