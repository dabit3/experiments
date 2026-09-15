import SwiftUI

/// Original 5x7 bitmap typeface rendered as crisp squares, in the spirit of 8-bit console lettering.
enum PixelFont {
    static let width = 5
    static let height = 7

    static func rows(for character: Character) -> [UInt8] {
        glyphs[character] ?? glyphs["?"]!
    }

    static func size(of text: String, scale: CGFloat) -> CGSize {
        let lines = text.uppercased().split(separator: "\n", omittingEmptySubsequences: false)
        let columns = lines.map { line in line.count * (width + 1) - 1 }.max() ?? 0
        let rows = lines.count * (height + 2) - 2
        return CGSize(width: CGFloat(max(columns, 0)) * scale, height: CGFloat(rows) * scale)
    }

    private static let glyphs: [Character: [UInt8]] = {
        let table: [(String, String)] = [
            ("A", "01110 10001 10001 11111 10001 10001 10001"),
            ("B", "11110 10001 10001 11110 10001 10001 11110"),
            ("C", "01111 10000 10000 10000 10000 10000 01111"),
            ("D", "11110 10001 10001 10001 10001 10001 11110"),
            ("E", "11111 10000 10000 11110 10000 10000 11111"),
            ("F", "11111 10000 10000 11110 10000 10000 10000"),
            ("G", "01111 10000 10000 10111 10001 10001 01111"),
            ("H", "10001 10001 10001 11111 10001 10001 10001"),
            ("I", "11111 00100 00100 00100 00100 00100 11111"),
            ("J", "00111 00010 00010 00010 00010 10010 01100"),
            ("K", "10001 10010 10100 11000 10100 10010 10001"),
            ("L", "10000 10000 10000 10000 10000 10000 11111"),
            ("M", "10001 11011 10101 10101 10001 10001 10001"),
            ("N", "10001 11001 10101 10011 10001 10001 10001"),
            ("O", "01110 10001 10001 10001 10001 10001 01110"),
            ("P", "11110 10001 10001 11110 10000 10000 10000"),
            ("Q", "01110 10001 10001 10001 10101 10010 01101"),
            ("R", "11110 10001 10001 11110 10100 10010 10001"),
            ("S", "01111 10000 10000 01110 00001 00001 11110"),
            ("T", "11111 00100 00100 00100 00100 00100 00100"),
            ("U", "10001 10001 10001 10001 10001 10001 01110"),
            ("V", "10001 10001 10001 10001 10001 01010 00100"),
            ("W", "10001 10001 10001 10101 10101 10101 01010"),
            ("X", "10001 10001 01010 00100 01010 10001 10001"),
            ("Y", "10001 10001 01010 00100 00100 00100 00100"),
            ("Z", "11111 00001 00010 00100 01000 10000 11111"),
            ("0", "01110 10001 10011 10101 11001 10001 01110"),
            ("1", "00100 01100 00100 00100 00100 00100 01110"),
            ("2", "01110 10001 00001 00010 00100 01000 11111"),
            ("3", "11111 00010 00100 00010 00001 10001 01110"),
            ("4", "00010 00110 01010 10010 11111 00010 00010"),
            ("5", "11111 10000 11110 00001 00001 10001 01110"),
            ("6", "00110 01000 10000 11110 10001 10001 01110"),
            ("7", "11111 00001 00010 00100 01000 01000 01000"),
            ("8", "01110 10001 10001 01110 10001 10001 01110"),
            ("9", "01110 10001 10001 01111 00001 00010 01100"),
            (" ", "00000 00000 00000 00000 00000 00000 00000"),
            (".", "00000 00000 00000 00000 00000 01100 01100"),
            (",", "00000 00000 00000 00000 01100 00100 01000"),
            ("!", "00100 00100 00100 00100 00100 00000 00100"),
            ("?", "01110 10001 00001 00010 00100 00000 00100"),
            (":", "00000 01100 01100 00000 01100 01100 00000"),
            ("-", "00000 00000 00000 11111 00000 00000 00000"),
            ("+", "00000 00100 00100 11111 00100 00100 00000"),
            ("'", "01100 00100 01000 00000 00000 00000 00000"),
            ("/", "00001 00010 00010 00100 01000 01000 10000"),
            ("&", "01000 10100 10100 01000 10101 10010 01101"),
            (">", "10000 11000 11100 11110 11100 11000 10000"),
            ("<", "00001 00011 00111 01111 00111 00011 00001"),
            ("^", "00100 01110 11111 00100 00100 00100 00100"),
            ("_", "00100 00100 00100 00100 11111 01110 00100"),
            ("*", "00000 01010 00100 11011 00100 01010 00000"),
            ("(", "00010 00100 01000 01000 01000 00100 00010"),
            (")", "01000 00100 00010 00010 00010 00100 01000"),
            ("=", "00000 00000 11111 00000 11111 00000 00000"),
        ]
        var result: [Character: [UInt8]] = [:]
        for (key, rows) in table {
            result[Character(key)] = rows.split(separator: " ").map { UInt8($0, radix: 2) ?? 0 }
        }
        return result
    }()
}

struct PixelText: View {
    let text: String
    var scale: CGFloat = 3
    var color: Color = .white
    var shadow: Color? = Color(uiColor: ToyColor.dark)
    var alignment: HorizontalAlignment = .leading

    init(
        _ text: String,
        scale: CGFloat = 3,
        color: Color = .white,
        shadow: Color? = Color(uiColor: ToyColor.dark),
        alignment: HorizontalAlignment = .leading
    ) {
        self.text = text
        self.scale = scale
        self.color = color
        self.shadow = shadow
        self.alignment = alignment
    }

    var body: some View {
        let size = PixelFont.size(of: text, scale: scale)
        let extra = shadow == nil ? 0 : scale
        Canvas(rendersAsynchronously: false) { context, _ in
            let path = glyphPath(width: size.width)
            if let shadow {
                context.fill(path.offsetBy(dx: extra, dy: extra), with: .color(shadow))
            }
            context.fill(path, with: .color(color))
        }
        .frame(width: size.width + extra, height: size.height + extra)
        .accessibilityLabel(Text(text.replacingOccurrences(of: "\n", with: " ")))
        .accessibilityAddTraits(.isStaticText)
    }

    private func glyphPath(width: CGFloat) -> Path {
        var path = Path()
        let lines = text.uppercased().split(separator: "\n", omittingEmptySubsequences: false)
        for (lineIndex, line) in lines.enumerated() {
            let lineWidth = CGFloat(line.count * (PixelFont.width + 1) - 1) * scale
            let originX: CGFloat = switch alignment {
            case .center: (width - lineWidth) / 2
            case .trailing: width - lineWidth
            default: 0
            }
            let originY = CGFloat(lineIndex * (PixelFont.height + 2)) * scale
            for (column, character) in line.enumerated() {
                let glyphX = originX + CGFloat(column * (PixelFont.width + 1)) * scale
                for (row, bits) in PixelFont.rows(for: character).enumerated() {
                    for bit in 0 ..< PixelFont.width where bits & (1 << (PixelFont.width - 1 - bit)) != 0 {
                        path.addRect(CGRect(
                            x: glyphX + CGFloat(bit) * scale,
                            y: originY + CGFloat(row) * scale,
                            width: scale,
                            height: scale
                        ))
                    }
                }
            }
        }
        return path
    }
}

/// A 16x16 original duck sprite shared by the wardrobe, results and app icon.
enum DuckSprite {
    static let rows = [
        "................",
        "......kkkk......",
        ".....kyyyyk.....",
        "....kyywyyyk....",
        "....kyykyyykooo.",
        "....kyyyyyyykook",
        "....kyyyyyyyyko.",
        ".....kyyyyyyk...",
        "..kkkkkyyyyyk...",
        ".kyyyyyyyyyyyk..",
        "kyyyyyyyyyyyyyk.",
        "kyllllyyyyyyyyk.",
        "kylllllyyyyyyk..",
        ".kyllllyyyyyyk..",
        "..kkkkkkkkkkk...",
        "....ook..ook....",
    ]

    static func color(for character: Character, plumage: UIColor) -> UIColor? {
        switch character {
        case "k": ToyColor.dark
        case "y": plumage
        case "l": ToyColor.lighten(plumage)
        case "w": .white
        case "o": ToyColor.beak
        default: nil
        }
    }
}

struct DuckSpriteView: View {
    let plumage: UIColor
    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            let unit = min(size.width, size.height) / 16
            for (rowIndex, row) in DuckSprite.rows.enumerated() {
                for (column, character) in row.enumerated() {
                    if let color = DuckSprite.color(for: character, plumage: plumage) {
                        context.fill(
                            Path(CGRect(
                                x: CGFloat(column) * unit,
                                y: CGFloat(rowIndex) * unit,
                                width: unit,
                                height: unit
                            )),
                            with: .color(Color(uiColor: color))
                        )
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
