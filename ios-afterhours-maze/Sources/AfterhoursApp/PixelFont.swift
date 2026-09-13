import SwiftUI

enum PixelFont {
  static let width = 5
  static let height = 7

  static let glyphs: [Character: [String]] = [
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
    "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
    "G": ["01111", "10000", "10000", "10111", "10001", "10001", "01111"],
    "H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
    "J": ["00111", "00010", "00010", "00010", "00010", "10010", "01100"],
    "K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    "N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    "Q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
    "V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    "W": ["10001", "10001", "10001", "10101", "10101", "10101", "01010"],
    "X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
    "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    "Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
    "0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
    "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
    "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    "5": ["11111", "10000", "10000", "11110", "00001", "00001", "11110"],
    "6": ["01110", "10000", "10000", "11110", "10001", "10001", "01110"],
    "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
    "9": ["01110", "10001", "10001", "01111", "00001", "00001", "01110"],
    " ": ["00000", "00000", "00000", "00000", "00000", "00000", "00000"],
    ".": ["00000", "00000", "00000", "00000", "00000", "01100", "01100"],
    ",": ["00000", "00000", "00000", "00000", "01100", "00100", "01000"],
    "!": ["00100", "00100", "00100", "00100", "00100", "00000", "00100"],
    "?": ["01110", "10001", "00001", "00010", "00100", "00000", "00100"],
    "-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
    ":": ["00000", "01100", "01100", "00000", "01100", "01100", "00000"],
    "/": ["00001", "00010", "00010", "00100", "01000", "01000", "10000"],
    "+": ["00000", "00100", "00100", "11111", "00100", "00100", "00000"],
    "x": ["00000", "00000", "10001", "01010", "00100", "01010", "10001"],
    "'": ["01100", "00100", "01000", "00000", "00000", "00000", "00000"],
    ">": ["10000", "11000", "11100", "11110", "11100", "11000", "10000"],
    "<": ["00001", "00011", "00111", "01111", "00111", "00011", "00001"],
    "^": ["00100", "01110", "11111", "00100", "00100", "00100", "00100"],
    "v": ["00100", "00100", "00100", "00100", "11111", "01110", "00100"],
    "*": ["00100", "10101", "01110", "11111", "01110", "10101", "00100"],
    "@": ["01110", "10001", "10101", "10111", "10000", "10001", "01110"],
    "#": ["01010", "01010", "11111", "01010", "11111", "01010", "01010"],
  ]

  static func rows(for character: Character) -> [String] {
    glyphs[character] ?? glyphs[Character(character.uppercased())] ?? glyphs["?"]!
  }

  static func draw(
    _ text: String, in context: GraphicsContext, at origin: CGPoint, scale: CGFloat, color: Color
  ) {
    var path = Path()
    var x = origin.x
    for character in text {
      let rows = rows(for: character)
      for (row, bits) in rows.enumerated() {
        for (column, bit) in bits.enumerated() where bit == "1" {
          path.addRect(
            CGRect(
              x: x + CGFloat(column) * scale, y: origin.y + CGFloat(row) * scale, width: scale,
              height: scale))
        }
      }
      x += CGFloat(width + 1) * scale
    }
    context.fill(path, with: .color(color))
  }

  static func size(of text: String, scale: CGFloat) -> CGSize {
    CGSize(
      width: max(0, CGFloat(text.count * (width + 1) - 1) * scale),
      height: CGFloat(height) * scale)
  }
}

struct PixelText: View {
  let text: String
  var scale: CGFloat = 2
  var color: Color = .white
  var shadow: Color? = nil

  init(_ text: String, scale: CGFloat = 2, color: Color = .white, shadow: Color? = nil) {
    self.text = text
    self.scale = scale
    self.color = color
    self.shadow = shadow
  }

  var body: some View {
    let size = PixelFont.size(of: text, scale: scale)
    Canvas { context, _ in
      if let shadow {
        PixelFont.draw(
          text, in: context, at: CGPoint(x: scale, y: scale), scale: scale, color: shadow)
      }
      PixelFont.draw(text, in: context, at: .zero, scale: scale, color: color)
    }
    .frame(
      width: size.width + (shadow == nil ? 0 : scale),
      height: size.height + (shadow == nil ? 0 : scale)
    )
    .accessibilityLabel(Text(text))
  }
}

struct PixelPanel<Content: View>: View {
  var fill: Color = Palette.ink
  var border: Color = .white
  var unit: CGFloat = 3
  @ViewBuilder var content: () -> Content

  var body: some View {
    content()
      .background(fill)
      .overlay(
        ZStack {
          Rectangle().strokeBorder(border, lineWidth: unit)
          Rectangle().strokeBorder(border, lineWidth: unit).padding(unit * 2)
        }
      )
  }
}

struct PixelButtonStyle: ButtonStyle {
  var fill: Color
  var text: Color
  var unit: CGFloat = 3

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(text)
      .background(configuration.isPressed ? fill.opacity(0.75) : fill)
      .overlay(
        ZStack(alignment: .topLeading) {
          Rectangle().strokeBorder(Palette.ink, lineWidth: unit)
          VStack(spacing: 0) {
            Rectangle().fill(.white.opacity(0.65)).frame(height: unit).padding(.horizontal, unit)
            Spacer()
            Rectangle().fill(Palette.ink.opacity(0.45)).frame(height: unit).padding(
              .horizontal, unit)
          }.padding(unit)
        }
      )
      .offset(y: configuration.isPressed ? unit : 0)
  }
}
