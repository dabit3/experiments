import SwiftUI

/// Sixteen-ish colour cartridge palette shared by every screen, sprite and tile.
enum Ink {
  static let night = Color(red: 0.05, green: 0.07, blue: 0.20)
  static let sky = Color(red: 0.13, green: 0.18, blue: 0.42)
  static let skyLight = Color(red: 0.24, green: 0.36, blue: 0.68)
  static let outline = Color(red: 0.06, green: 0.05, blue: 0.12)
  static let cream = Color(red: 0.99, green: 0.95, blue: 0.87)
  static let sand = Color(red: 0.93, green: 0.84, blue: 0.62)
  static let grass = Color(red: 0.55, green: 0.82, blue: 0.40)
  static let grassDeep = Color(red: 0.45, green: 0.72, blue: 0.32)
  static let leaf = Color(red: 0.16, green: 0.52, blue: 0.24)
  static let water = Color(red: 0.24, green: 0.72, blue: 0.98)
  static let waterDeep = Color(red: 0.10, green: 0.45, blue: 0.85)
  static let white = Color(red: 0.98, green: 0.98, blue: 0.96)
  static let grey = Color(red: 0.62, green: 0.66, blue: 0.74)
  static let sun = Color(red: 0.99, green: 0.86, blue: 0.16)
  static let ember = Color(red: 0.97, green: 0.31, blue: 0.13)
  static let routes: [Color] = [
    Color(red: 0.94, green: 0.20, blue: 0.16),
    Color(red: 0.10, green: 0.36, blue: 0.96),
    Color(red: 0.99, green: 0.80, blue: 0.05),
    Color(red: 0.82, green: 0.22, blue: 0.78),
  ]
  static let routesDeep: [Color] = [
    Color(red: 0.62, green: 0.08, blue: 0.08),
    Color(red: 0.05, green: 0.18, blue: 0.60),
    Color(red: 0.70, green: 0.48, blue: 0.02),
    Color(red: 0.50, green: 0.08, blue: 0.48),
  ]
  static let routeNames = ["RED", "BLUE", "GOLD", "PINK"]
}

/// Original 5×7 bitmap typeface. Upper-case only, like the cartridges it borrows its rhythm from.
enum PixelFont {
  static let glyphs: [Character: [String]] = [
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
    "C": [".####", "#....", "#....", "#....", "#....", "#....", ".####"],
    "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
    "G": [".####", "#....", "#....", "#.###", "#...#", "#...#", ".####"],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "I": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
    "J": ["....#", "....#", "....#", "....#", "#...#", "#...#", ".###."],
    "K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
    "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
    "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
    "N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
    "Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
    "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
    "X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
    "Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
    "Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
    "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
    "1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
    "3": ["#####", "...#.", "..#..", "...#.", "....#", "#...#", ".###."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
    "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
    "6": ["..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
    "9": [".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."],
    " ": [".....", ".....", ".....", ".....", ".....", ".....", "....."],
    ".": [".....", ".....", ".....", ".....", ".....", ".##..", ".##.."],
    ",": [".....", ".....", ".....", ".....", ".....", ".##..", ".#..."],
    ":": [".....", ".##..", ".##..", ".....", ".##..", ".##..", "....."],
    "!": ["..#..", "..#..", "..#..", "..#..", "..#..", ".....", "..#.."],
    "?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
    "-": [".....", ".....", ".....", "#####", ".....", ".....", "....."],
    "+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
    "/": ["....#", "....#", "...#.", "..#..", ".#...", "#....", "#...."],
    "'": [".##..", ".##..", ".#...", ".....", ".....", ".....", "....."],
    "×": [".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "....."],
    "·": [".....", ".....", ".....", "..#..", "..#..", ".....", "....."],
    "&": [".##..", "#..#.", "#..#.", ".##..", "#.#.#", "#..#.", ".##.#"],
    "(": ["..#..", ".#...", "#....", "#....", "#....", ".#...", "..#.."],
    ")": ["..#..", "...#.", "....#", "....#", "....#", "...#.", "..#.."],
    ">": ["#....", "##...", "###..", "####.", "###..", "##...", "#...."],
    "<": ["....#", "...##", "..###", ".####", "..###", "...##", "....#"],
    "%": ["##..#", "##.#.", "...#.", "..#..", ".#...", "#.##.", "#..##"],
    "\"": [".#.#.", ".#.#.", ".....", ".....", ".....", ".....", "....."],
  ]

  static func glyph(_ character: Character) -> [String] {
    glyphs[Character(character.uppercased())] ?? glyphs["?"]!
  }

  /// Greedy word wrap for a fixed column count, preserving explicit line breaks.
  static func wrap(_ text: String, columns: Int) -> [String] {
    var lines: [String] = []
    for paragraph in text.split(separator: "\n", omittingEmptySubsequences: false) {
      var line = ""
      for word in paragraph.split(separator: " ") {
        if line.isEmpty {
          line = String(word)
        } else if line.count + 1 + word.count <= columns {
          line += " " + word
        } else {
          lines.append(line)
          line = String(word)
        }
      }
      lines.append(line)
    }
    return lines
  }
}

/// Text drawn from the bitmap typeface. `scale` is the size of one pixel in points.
struct PixelText: View {
  let lines: [String]
  var scale = 2.0
  var color = Ink.white
  var shadow: Color?
  var outline: Color?
  var alignment = HorizontalAlignment.leading
  private let label: String

  init(
    _ text: String, scale: Double = 2, color: Color = Ink.white, shadow: Color? = nil,
    outline: Color? = nil, alignment: HorizontalAlignment = .leading, columns: Int? = nil
  ) {
    label = text
    lines = columns.map { PixelFont.wrap(text, columns: $0) } ?? text.components(separatedBy: "\n")
    self.scale = scale
    self.color = color
    self.shadow = shadow
    self.outline = outline
    self.alignment = alignment
  }

  private var columns: Int { lines.map(\.count).max() ?? 0 }
  private var width: Double { max(0, Double(columns) * 6 * scale - scale) }
  private var height: Double { Double(lines.count) * 8 * scale - scale }

  var body: some View {
    Canvas(rendersAsynchronously: false) { context, size in
      var cells = Path()
      for (row, line) in lines.enumerated() {
        let lineWidth = Double(line.count) * 6 * scale - scale
        let originX =
          alignment == .leading
          ? 0 : alignment == .trailing ? size.width - lineWidth : (size.width - lineWidth) / 2
        for (column, character) in line.enumerated() {
          let glyph = PixelFont.glyph(character)
          for (y, bits) in glyph.enumerated() {
            for (x, bit) in bits.enumerated() where bit == "#" {
              cells.addRect(
                CGRect(
                  x: originX + (Double(column) * 6 + Double(x)) * scale,
                  y: (Double(row) * 8 + Double(y)) * scale, width: scale, height: scale))
            }
          }
        }
      }
      if let outline {
        for dx in [-1.0, 0, 1] {
          for dy in [-1.0, 0, 1] where dx != 0 || dy != 0 {
            context.fill(
              cells.applying(CGAffineTransform(translationX: dx * scale, y: dy * scale)),
              with: .color(outline))
          }
        }
      }
      if let shadow {
        context.fill(
          cells.applying(CGAffineTransform(translationX: scale, y: scale)), with: .color(shadow))
      }
      context.fill(cells, with: .color(color))
    }
    .frame(
      width: width + (outline == nil ? 0 : scale * 2),
      height: height + (outline == nil ? 0 : scale * 2)
    )
    .padding(outline == nil ? 0 : -scale)
    .accessibilityLabel(label)
  }
}

/// Bevelled cartridge frame: light top-left, dark bottom-right, one dark pixel border.
struct PixelFrame: Shape {
  var cut = 3.0

  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
    path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
    path.closeSubpath()
    return path
  }
}

/// Dialogue-box panel: solid fill, a bright inner border and a dark pixel outline.
struct Panel<Content: View>: View {
  var fill = Ink.sky
  var border = Ink.white
  var inset = 4.0
  @ViewBuilder let content: () -> Content

  var body: some View {
    content()
      .background(fill)
      .clipShape(PixelFrame())
      .overlay(
        PixelFrame(cut: 2).stroke(border, lineWidth: 2).padding(inset)
      )
      .overlay(PixelFrame().stroke(Ink.outline, lineWidth: 3))
      .padding(1.5)
  }
}

/// Chunky arcade button with a solid drop that compresses when pressed.
struct PixelButton: ButtonStyle {
  var fill = Ink.ember
  var text = Ink.white
  var height = 50.0
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    let pressed = configuration.isPressed
    return configuration.label
      .frame(maxWidth: .infinity, minHeight: height)
      .background(isEnabled ? fill : Ink.grey)
      .clipShape(PixelFrame())
      .overlay(
        PixelFrame(cut: 2).stroke(Color.white.opacity(0.45), lineWidth: 2).padding(4)
      )
      .overlay(PixelFrame().stroke(Ink.outline, lineWidth: 3))
      .background(
        PixelFrame().fill(Ink.outline).offset(y: pressed ? 0 : 4)
      )
      .offset(y: pressed ? 4 : 0)
      .foregroundStyle(text)
      .padding(.bottom, 4)
      .padding(1.5)
      .opacity(isEnabled ? 1 : 0.6)
  }
}

/// Blinking selection cursor familiar from every pause menu ever made.
struct Cursor: View {
  var color = Ink.sun
  var scale = 2.0
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    TimelineView(.periodic(from: .now, by: 0.45)) { timeline in
      let on = reduceMotion || Int(timeline.date.timeIntervalSinceReferenceDate / 0.45) % 2 == 0
      PixelText(">", scale: scale, color: color, shadow: Ink.outline).opacity(on ? 1 : 0.15)
    }
    .accessibilityHidden(true)
  }
}

/// Blinks its content on a cartridge cadence unless Reduce Motion is on.
struct Blink<Content: View>: View {
  var period = 0.6
  @ViewBuilder let content: () -> Content
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    TimelineView(.periodic(from: .now, by: period)) { timeline in
      let on = reduceMotion || Int(timeline.date.timeIntervalSinceReferenceDate / period) % 2 == 0
      content().opacity(on ? 1 : 0.65)
    }
  }
}

/// Numbered route badge: coloured square with a dark outline, like a level marker.
struct Roundel: View {
  let number: Int
  let color: Color
  var filled = true
  var size = 30.0

  var body: some View {
    ZStack {
      PixelFrame(cut: 2).fill(filled ? color : Ink.cream)
      PixelFrame(cut: 2).stroke(Ink.outline, lineWidth: 2.5)
      PixelText("\(number)", scale: size / 14, color: filled ? Ink.white : Ink.outline)
    }
    .frame(width: size, height: size)
    .accessibilityLabel("Line \(number)")
  }
}

/// Signature mark: a four-pixel locomotive facing right.
struct Loco: View {
  var color = Ink.routes[0]
  var scale = 3.0
  var lit = true

  var body: some View {
    Canvas { context, _ in
      func px(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ c: Color) {
        context.fill(
          Path(
            CGRect(
              x: Double(x) * scale, y: Double(y) * scale, width: Double(w) * scale,
              height: Double(h) * scale)), with: .color(c))
      }
      px(0, 1, 12, 6, Ink.outline)
      px(1, 2, 10, 4, color)
      px(9, 0, 3, 3, Ink.outline)
      px(10, 1, 1, 1, Ink.sun)
      px(2, 3, 2, 2, lit ? Ink.white : Ink.grey)
      px(5, 3, 2, 2, lit ? Ink.white : Ink.grey)
      px(1, 7, 3, 2, Ink.outline)
      px(8, 7, 3, 2, Ink.outline)
      px(2, 7, 1, 1, Ink.grey)
      px(9, 7, 1, 1, Ink.grey)
    }
    .frame(width: 12 * scale, height: 9 * scale)
    .accessibilityHidden(true)
  }
}

/// Pixel destination glyphs used by stations, passengers and the guide.
struct SpriteGlyph: View {
  let kind: StationKind
  var scale = 2.0
  var fill = Ink.white
  var outline = Ink.outline

  var body: some View {
    Canvas { context, size in
      let rect = CGRect(origin: .zero, size: size).insetBy(dx: scale, dy: scale)
      let path = StationGlyph(kind: kind).path(in: rect)
      context.stroke(
        path, with: .color(outline), style: StrokeStyle(lineWidth: scale * 2, lineJoin: .miter))
      context.fill(path, with: .color(fill))
    }
    .frame(width: 7 * scale, height: 7 * scale)
    .accessibilityHidden(true)
  }
}
