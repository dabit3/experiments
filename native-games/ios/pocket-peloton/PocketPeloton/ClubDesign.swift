import SwiftUI

enum RaceType {
  static let title = Font.system(.title, design: .default, weight: .bold)
  static let heading = Font.system(.title3, design: .default, weight: .semibold)
  static let body = Font.system(.subheadline, design: .default, weight: .regular)
  static let label = Font.system(.subheadline, design: .default, weight: .semibold)
  static let caption = Font.system(.caption, design: .default, weight: .medium)
  static let action = Font.system(.body, design: .default, weight: .semibold)
  static let instrument = Font.system(size: 30, weight: .semibold)
}

enum RaceLayout {
  static let gutter: CGFloat = 20
  static let corner: CGFloat = 8
  static let controlHeight: CGFloat = 56
}

struct RaceRule: View {
  var body: some View {
    Rectangle().fill(Ink.navy.opacity(0.18)).frame(height: 1).accessibilityHidden(true)
  }
}

struct ClubEmblem: View {
  var size: CGFloat = 32

  var body: some View {
    ZStack {
      Circle().strokeBorder(.primary.opacity(0.28), lineWidth: 1)
      Circle().strokeBorder(.primary.opacity(0.18), lineWidth: 1).padding(3)
      Image(systemName: "bicycle")
        .font(.system(size: size * 0.44, weight: .medium))
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

struct RaceStripe: View {
  var body: some View {
    HStack(spacing: 3) {
      Ink.red.frame(width: 26)
      Ink.butter.frame(width: 12)
      Ink.sea.frame(width: 7)
    }
    .frame(height: 3)
    .accessibilityHidden(true)
  }
}

struct CourseTrace: View {
  let course: Course

  var body: some View {
    Canvas { context, size in
      var path = Path()
      for index in 0...80 {
        let t = Double(index) / 80
        let x = size.width * (0.1 + t * 0.8)
        let y =
          size.height
          * (0.5 + sin(t * .pi * (2.5 + Double(course.rawValue))) * 0.24
            + cos(t * .pi * 5) * 0.09)
        if index == 0 {
          path.move(to: CGPoint(x: x, y: y))
        } else {
          path.addLine(to: CGPoint(x: x, y: y))
        }
      }
      context.stroke(
        path, with: .color(Ink.sea.opacity(0.25)),
        style: StrokeStyle(lineWidth: 8, lineCap: .round))
      context.stroke(
        path, with: .color(Ink.sea),
        style: StrokeStyle(lineWidth: 2, lineCap: .round))
      let start = CGPoint(x: size.width * 0.1, y: size.height * 0.59)
      context.fill(
        Path(ellipseIn: CGRect(x: start.x - 3, y: start.y - 3, width: 6, height: 6)),
        with: .color(Ink.red))
    }
    .accessibilityHidden(true)
  }
}

struct ClubButtonStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reducedMotion
  @Environment(\.isEnabled) private var enabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed && !reducedMotion ? 0.985 : 1)
      .opacity(!enabled ? 0.4 : (configuration.isPressed ? 0.75 : 1))
  }
}

struct CoastalCover: View {
  var body: some View {
    GeometryReader { geometry in
      Image("CoastalCover")
        .resizable()
        .scaledToFill()
        .frame(width: geometry.size.width, height: geometry.size.height)
        .clipped()
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}
