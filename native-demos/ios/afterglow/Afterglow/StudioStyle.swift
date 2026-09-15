import SwiftUI

let ink = Color(red: 0.055, green: 0.062, blue: 0.068)
let panel = Color(red: 0.09, green: 0.10, blue: 0.11)
let paper = Color(red: 0.95, green: 0.94, blue: 0.91)
let amber = Color(red: 0.91, green: 0.68, blue: 0.39)
let muted = Color(red: 0.60, green: 0.62, blue: 0.63)
let hairline = Color.white.opacity(0.09)

struct Eyebrow: View {
  let text: String
  var body: some View {
    Text(text.uppercased()).font(.system(size: 9, weight: .semibold, design: .monospaced))
      .tracking(1.8).foregroundStyle(muted)
  }
}

struct StudioButton: ButtonStyle {
  var prominent = false
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.font(.system(size: 13, weight: .semibold))
      .foregroundStyle(prominent ? ink : paper)
      .frame(maxWidth: .infinity).frame(height: 48)
      .background(prominent ? amber : paper.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
      .opacity(configuration.isPressed ? 0.7 : 1)
  }
}

struct IconButton: View {
  let icon: String
  let label: String
  var active = false
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      Image(systemName: icon).font(.system(size: 16, weight: .regular))
        .foregroundStyle(active ? amber : paper)
        .frame(width: 44, height: 44).contentShape(Rectangle())
    }.buttonStyle(.plain).accessibilityLabel(label)
  }
}

struct PrecisionSlider: View {
  @Binding var value: Double
  let range: ClosedRange<Double>
  var neutral: Double? = nil
  let onCommit: () -> Void

  private var fraction: Double {
    min(1, max(0, (value - range.lowerBound) / (range.upperBound - range.lowerBound)))
  }

  var body: some View {
    GeometryReader { geometry in
      let width = max(1, geometry.size.width - 20)
      ZStack(alignment: .leading) {
        Rectangle().fill(paper.opacity(0.12)).frame(height: 1)
        HStack(spacing: 0) {
          ForEach(0..<41) { index in
            Rectangle().fill(index % 10 == 0 ? muted : muted.opacity(0.4))
              .frame(width: 1, height: index % 10 == 0 ? 15 : 6)
            if index != 40 { Spacer(minLength: 0) }
          }
        }.padding(.horizontal, 10)
        if let neutral {
          Circle().fill(amber.opacity(0.7)).frame(width: 3, height: 3)
            .offset(
              x: 9 + width * (neutral - range.lowerBound) / (range.upperBound - range.lowerBound),
              y: 14)
        }
        RoundedRectangle(cornerRadius: 4).fill(paper)
          .frame(width: 20, height: 30)
          .overlay(Rectangle().fill(ink.opacity(0.45)).frame(width: 2, height: 12))
          .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
          .offset(x: width * fraction)
      }
      .frame(height: 44).contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged {
            let position = min(1, max(0, ($0.location.x - 10) / width))
            value = range.lowerBound + position * (range.upperBound - range.lowerBound)
          }
          .onEnded { _ in onCommit() }
      )
    }
    .frame(height: 44)
    .accessibilityElement(children: .ignore)
    .accessibilityAdjustableAction { direction in
      let step = (range.upperBound - range.lowerBound) / 40
      switch direction {
      case .increment: value = min(range.upperBound, value + step)
      case .decrement: value = max(range.lowerBound, value - step)
      @unknown default: return
      }
      onCommit()
    }
  }
}

struct HistogramView: View {
  let histogram: Histogram?
  var body: some View {
    Canvas { context, size in
      guard let histogram else { return }
      let maximum = max(0.001, (histogram.red + histogram.green + histogram.blue).max() ?? 1)
      let channels: [([Double], Color)] = [
        (histogram.red, Color(red: 0.9, green: 0.43, blue: 0.37)),
        (histogram.green, Color(red: 0.4, green: 0.72, blue: 0.61)),
        (histogram.blue, Color(red: 0.4, green: 0.59, blue: 0.86)),
      ]
      context.blendMode = .screen
      for (values, color) in channels {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        for (index, value) in values.enumerated() {
          path.addLine(
            to: CGPoint(
              x: Double(index) / 63 * size.width,
              y: size.height * (1 - sqrt(value / maximum) * 0.94)))
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        context.fill(path, with: .color(color.opacity(0.48)))
        context.stroke(path, with: .color(color.opacity(0.75)), lineWidth: 0.5)
      }
    }
    .accessibilityLabel("Rendered RGB histogram")
    .accessibilityValue(
      String(format: "%.1f percent clipped highlights", (histogram?.highlightsClipped ?? 0) * 100))
  }
}
