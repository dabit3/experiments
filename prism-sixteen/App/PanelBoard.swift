import SwiftUI
import UIKit

private let cyan = Color(red: 0.36, green: 1, blue: 0.88)
private let pink = Color(red: 1, green: 0.35, blue: 0.67)

struct PanelBoard: View {
  @ObservedObject var model: GameModel

  var body: some View {
    ZStack {
      Canvas { context, size in
        let gap: CGFloat = 7
        let side = (size.width - gap * 3) / 4
        for cell in 0..<16 {
          let rect = CGRect(
            x: CGFloat(cell % 4) * (side + gap),
            y: CGFloat(cell / 4) * (side + gap), width: side, height: side)
          let base = Path(roundedRect: rect, cornerRadius: 5)
          context.fill(
            base,
            with: .linearGradient(
              Gradient(colors: [
                Color(red: 0.095, green: 0.15, blue: 0.19),
                Color(red: 0.022, green: 0.045, blue: 0.075),
              ]),
              startPoint: rect.origin, endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
          context.stroke(base, with: .color(.white.opacity(0.22)), lineWidth: 1)
          let center = CGPoint(x: rect.midX, y: rect.midY)
          let target = rect.insetBy(dx: side * 0.22, dy: side * 0.22)
          context.stroke(Path(target), with: .color(cyan.opacity(0.08)), lineWidth: 1)
          var cross = Path()
          cross.move(to: CGPoint(x: center.x - 3, y: center.y))
          cross.addLine(to: CGPoint(x: center.x + 3, y: center.y))
          cross.move(to: CGPoint(x: center.x, y: center.y - 3))
          cross.addLine(to: CGPoint(x: center.x, y: center.y + 3))
          context.stroke(cross, with: .color(.white.opacity(0.16)), lineWidth: 1)
          context.draw(
            Text(String(format: "%02d", cell + 1)).font(.system(size: 8, design: .monospaced))
              .foregroundStyle(.white.opacity(0.23)),
            at: CGPoint(x: rect.minX + 10, y: rect.minY + 9))
          if let note = model.notes.first(where: {
            $0.cell == cell && $0.time - model.songTime < 0.78
              && $0.time - model.songTime > -0.16
              && model.me?.judged[String($0.id)] == nil
          }), model.playing {
            let remaining = note.time - model.songTime
            let phase = min(1, max(0, 1 - remaining / 0.78))
            let chord = model.notes.contains { $0.id != note.id && $0.time == note.time }
            let color = chord ? pink : cyan
            let glow = max(0.08, 1 - abs(remaining) / 0.4)
            context.fill(base, with: .color(color.opacity(glow * 0.2)))
            for index in 0..<3 {
              let spread = (0.95 - phase * 0.39) + Double(index) * 0.085
              let marker = CGRect(
                x: center.x - side * spread / 2, y: center.y - side * spread / 2,
                width: side * spread, height: side * spread)
              context.stroke(
                Path(roundedRect: marker, cornerRadius: 2),
                with: .color(color.opacity(index == 0 ? 0.95 : 0.25 - Double(index) * 0.06)),
                lineWidth: index == 0 ? 2.8 : 1)
            }
            let inner = side * (0.06 + phase * 0.5)
            context.stroke(
              Path(
                CGRect(
                  x: center.x - inner / 2, y: center.y - inner / 2, width: inner, height: inner)),
              with: .color(color.opacity(0.4 + phase * 0.6)), lineWidth: 1.5)
            context.fill(
              Path(CGRect(x: center.x - 2, y: center.y - 2, width: 4, height: 4)),
              with: .color(.white.opacity(phase)))
          }
          if let flash = model.flashes[cell] {
            let age = model.uptime - flash.at
            let alpha = max(0, 1 - age / 0.45)
            let color = flash.label == "MISS" ? pink : flash.label == "GOOD" ? Color.orange : cyan
            context.fill(base, with: .color(color.opacity(alpha * 0.45)))
            context.stroke(base, with: .color(.white.opacity(alpha)), lineWidth: 2)
            let size = side * (0.56 + age * 1.2)
            let burst = CGRect(
              x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)
            context.stroke(Path(burst), with: .color(color.opacity(alpha * 0.7)), lineWidth: 2)
            if flash.label != "TOUCH" {
              context.draw(
                Text(flash.label).font(.system(size: side * 0.12, weight: .black, design: .rounded))
                  .foregroundStyle(.white.opacity(alpha)),
                at: center)
            }
          }
        }
      }
      PanelTouchSurface { cell, time in model.panelInput(cell: cell, timestamp: time) }
    }
    .aspectRatio(1, contentMode: .fit)
    .padding(10)
    .background(
      RoundedRectangle(cornerRadius: 12).fill(
        LinearGradient(
          colors: [.white.opacity(0.16), .black, .white.opacity(0.055)],
          startPoint: .topLeading, endPoint: .bottomTrailing))
    )
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.24), lineWidth: 1))
    .shadow(color: cyan.opacity(0.08), radius: 22)
    .accessibilityIdentifier("panelBoard")
  }
}

struct PanelTouchSurface: UIViewRepresentable {
  let action: (Int, Double) -> Void

  func makeUIView(context: Context) -> TouchMatrix {
    let view = TouchMatrix()
    view.isMultipleTouchEnabled = true
    view.backgroundColor = .clear
    view.action = action
    return view
  }

  func updateUIView(_ uiView: TouchMatrix, context: Context) { uiView.action = action }
}

final class PanelAccessibilityElement: UIAccessibilityElement {
  var activate: (() -> Void)?
  override func accessibilityActivate() -> Bool {
    activate?()
    return true
  }
}

final class TouchMatrix: UIView {
  var action: ((Int, Double) -> Void)?

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      let point = touch.location(in: self)
      let side = (bounds.width - 21) / 4
      let column = Int(point.x / (side + 7))
      let row = Int(point.y / (side + 7))
      guard (0..<4).contains(column), (0..<4).contains(row),
        point.x - CGFloat(column) * (side + 7) <= side,
        point.y - CGFloat(row) * (side + 7) <= side
      else { continue }
      action?(row * 4 + column, touch.timestamp)
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let side = (bounds.width - 21) / 4
    accessibilityElements = (0..<16).map { cell in
      let element = PanelAccessibilityElement(accessibilityContainer: self)
      element.accessibilityLabel = "Panel \(cell + 1)"
      element.accessibilityIdentifier = "panel\(cell + 1)"
      element.accessibilityTraits = .button
      element.accessibilityFrameInContainerSpace = CGRect(
        x: CGFloat(cell % 4) * (side + 7), y: CGFloat(cell / 4) * (side + 7),
        width: side, height: side)
      element.activate = { [weak self] in
        self?.action?(cell, ProcessInfo.processInfo.systemUptime)
      }
      return element
    }
  }
}
