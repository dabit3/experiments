import SwiftUI

enum Ink {
  static let black = Color(red: 0, green: 0, blue: 0)
  static let night = Color(red: 0.04, green: 0.05, blue: 0.16)
  static let navy = Color(red: 0.0, green: 0.12, blue: 0.42)
  static let blue = Color(red: 0.0, green: 0.35, blue: 0.97)
  static let sky = Color(red: 0.24, green: 0.74, blue: 0.99)
  static let green = Color(red: 0.0, green: 0.62, blue: 0.08)
  static let leaf = Color(red: 0.30, green: 0.86, blue: 0.28)
  static let mint = Color(red: 0.72, green: 0.97, blue: 0.72)
  static let red = Color(red: 0.85, green: 0.16, blue: 0.0)
  static let rose = Color(red: 0.97, green: 0.47, blue: 0.35)
  static let copper = Color(red: 0.91, green: 0.47, blue: 0.16)
  static let gold = Color(red: 0.97, green: 0.72, blue: 0.0)
  static let cream = Color(red: 0.99, green: 0.89, blue: 0.68)
  static let white = Color(red: 0.99, green: 0.99, blue: 0.99)
  static let silver = Color(red: 0.74, green: 0.74, blue: 0.74)
  static let gray = Color(red: 0.49, green: 0.49, blue: 0.49)
  static let purple = Color(red: 0.36, green: 0.13, blue: 0.55)
  static let plum = Color(red: 0.20, green: 0.06, blue: 0.32)
  static let violet = Color(red: 0.58, green: 0.27, blue: 0.99)
  static let brown = Color(red: 0.63, green: 0.31, blue: 0.08)
  static let maroon = Color(red: 0.53, green: 0.08, blue: 0.0)

  static func body(_ size: CGFloat) -> Font {
    .system(size: size, weight: .semibold, design: .rounded)
  }
  static func heavy(_ size: CGFloat) -> Font {
    .system(size: size, weight: .heavy, design: .rounded)
  }
}

// MARK: - Pixel font

enum PixelFont {
  static let rows = 7
  static let leading = 2

  private static let glyphs: [Character: String] = [
    "A": ".###./#...#/#...#/#####/#...#/#...#/#...#",
    "B": "####./#...#/#...#/####./#...#/#...#/####.",
    "C": ".####/#..../#..../#..../#..../#..../.####",
    "D": "####./#...#/#...#/#...#/#...#/#...#/####.",
    "E": "#####/#..../#..../####./#..../#..../#####",
    "F": "#####/#..../#..../####./#..../#..../#....",
    "G": ".####/#..../#..../#.###/#...#/#...#/.####",
    "H": "#...#/#...#/#...#/#####/#...#/#...#/#...#",
    "I": "###../.#.../.#.../.#.../.#.../.#.../###..",
    "J": "..###/...#./...#./...#./...#./#..#./.##..",
    "K": "#...#/#..#./#.#../##.../#.#../#..#./#...#",
    "L": "#..../#..../#..../#..../#..../#..../#####",
    "M": "#...#/##.##/#.#.#/#.#.#/#...#/#...#/#...#",
    "N": "#...#/##..#/#.#.#/#..##/#...#/#...#/#...#",
    "O": ".###./#...#/#...#/#...#/#...#/#...#/.###.",
    "P": "####./#...#/#...#/####./#..../#..../#....",
    "Q": ".###./#...#/#...#/#...#/#.#.#/#..#./.##.#",
    "R": "####./#...#/#...#/####./#.#../#..#./#...#",
    "S": ".####/#..../#..../.###./....#/....#/####.",
    "T": "#####/..#../..#../..#../..#../..#../..#..",
    "U": "#...#/#...#/#...#/#...#/#...#/#...#/.###.",
    "V": "#...#/#...#/#...#/#...#/#...#/.#.#./..#..",
    "W": "#...#/#...#/#...#/#.#.#/#.#.#/##.##/#...#",
    "X": "#...#/#...#/.#.#./..#../.#.#./#...#/#...#",
    "Y": "#...#/#...#/.#.#./..#../..#../..#../..#..",
    "Z": "#####/....#/...#./..#../.#.../#..../#####",
    "0": ".###./#...#/#..##/#.#.#/##..#/#...#/.###.",
    "1": ".#.../##.../.#.../.#.../.#.../.#.../###..",
    "2": ".###./#...#/....#/...#./..#../.#.../#####",
    "3": "#####/...#./..#../...#./....#/#...#/.###.",
    "4": "...#./..##./.#.#./#..#./#####/...#./...#.",
    "5": "#####/#..../####./....#/....#/#...#/.###.",
    "6": "..###/.#.../#..../####./#...#/#...#/.###.",
    "7": "#####/....#/...#./..#../.#.../.#.../.#...",
    "8": ".###./#...#/#...#/.###./#...#/#...#/.###.",
    "9": ".###./#...#/#...#/.####/....#/...#./###..",
    ".": "...../...../...../...../...../##.../##...",
    ",": "...../...../...../...../.#.../.#.../#....",
    ":": "...../##.../##.../...../##.../##.../.....",
    ";": "...../.#.../.#.../...../.#.../.#.../#....",
    "!": "#..../#..../#..../#..../#..../...../#....",
    "?": ".###./#...#/....#/...#./..#../...../..#..",
    "'": "#..../#..../...../...../...../...../.....",
    "-": "...../...../...../###../...../...../.....",
    "+": "...../..#../..#../#####/..#../..#../.....",
    "/": "....#/...#./...#./..#../.#.../.#.../#....",
    "(": "..#../.#.../#..../#..../#..../.#.../..#..",
    ")": "#..../.#.../..#../..#../..#../.#.../#....",
    "=": "...../####./...../####./...../...../.....",
    ">": "#..../.#.../..#../...#./..#../.#.../#....",
    "<": "...#./..#../.#.../#..../.#.../..#../...#.",
    "&": ".##../#..#./#.#../.#.../#.#.#/#..#./.##.#",
    "%": "##..#/##.#./..#../..#../.#.../#.##./#..##",
    "*": "...../#.#.#/.###./#####/.###./#.#.#/.....",
    "\"": "#.#../#.#../...../...../...../...../.....",
    "×": "...../#...#/.#.#./..#../.#.#./#...#/.....",
    "·": "...../...../##.../##.../...../...../.....",
    "−": "...../...../...../###../...../...../.....",
    "♥": ".#.#./#####/#####/#####/.###./..#../.....",
    "✓": "...../....#/...#./#.#../.#.../...../.....",
    "▶": "#..../##.../###../####./###../##.../#....",
    "◆": "..#../.###./#####/.###./..#../...../.....",
    "■": "...../####./####./####./####./...../.....",
    "⚡": "..##./.##../###../.###./..#../.#.../#....",
  ]

  private static let bitmaps: [Character: [[Bool]]] = glyphs.mapValues { source in
    source.split(separator: "/").map { row in row.map { $0 == "#" } }
  }
  private static let widths: [Character: Int] = bitmaps.mapValues { bits in
    bits.reduce(1) { width, row in
      row.lastIndex(of: true).map { max(width, $0 + 1) } ?? width
    }
  }

  static func normalize(_ character: Character) -> Character {
    if character == " " { return " " }
    let upper = String(character).uppercased()
    guard upper.count == 1, let key = upper.first, bitmaps[key] != nil else { return "?" }
    return key
  }

  static func bitmap(_ character: Character) -> [[Bool]] {
    let key = normalize(character)
    return key == " " ? [] : bitmaps[key] ?? []
  }

  static func width(_ character: Character) -> Int {
    let key = normalize(character)
    return key == " " ? 3 : widths[key] ?? 5
  }

  static func width(_ text: String) -> Int {
    guard !text.isEmpty else { return 0 }
    return text.reduce(0) { $0 + width($1) + 1 } - 1
  }

  static func wrap(_ text: String, maxUnits: Int?) -> [String] {
    var lines: [String] = []
    for paragraph in text.split(separator: "\n", omittingEmptySubsequences: false) {
      guard let limit = maxUnits else {
        lines.append(String(paragraph))
        continue
      }
      var current = ""
      for word in paragraph.split(separator: " ") {
        let candidate = current.isEmpty ? String(word) : current + " " + word
        if width(candidate) <= limit || current.isEmpty {
          current = candidate
        } else {
          lines.append(current)
          current = String(word)
        }
      }
      lines.append(current)
    }
    return lines
  }
}

struct PixelText: View {
  var text: String
  var px: CGFloat
  var color: Color
  var shadow: Color?
  var maxWidth: CGFloat?
  var alignment: TextAlignment

  init(
    _ text: String, px: CGFloat = 2, color: Color = Ink.white, shadow: Color? = nil,
    maxWidth: CGFloat? = nil, alignment: TextAlignment = .leading
  ) {
    self.text = text
    self.px = px
    self.color = color
    self.shadow = shadow
    self.maxWidth = maxWidth
    self.alignment = alignment
  }

  var body: some View {
    let lines = PixelFont.wrap(text, maxUnits: maxWidth.map { Int($0 / px) })
    let widths = lines.map(PixelFont.width)
    let lineUnits = PixelFont.rows + PixelFont.leading
    let width = CGFloat(widths.max() ?? 0) * px + (shadow == nil ? 0 : px)
    let height =
      CGFloat(lines.count * lineUnits - PixelFont.leading) * px + (shadow == nil ? 0 : px)
    Canvas { context, size in
      if let shadow {
        var shifted = context
        shifted.translateBy(x: px, y: px)
        draw(lines, widths, in: shifted, width: size.width - px, color: shadow)
      }
      draw(lines, widths, in: context, width: size.width - (shadow == nil ? 0 : px), color: color)
    }
    .frame(width: width, height: height)
    .accessibilityLabel(Text(text))
  }

  private func draw(
    _ lines: [String], _ widths: [Int], in context: GraphicsContext, width: CGFloat, color: Color
  ) {
    let lineUnits = PixelFont.rows + PixelFont.leading
    for (index, line) in lines.enumerated() {
      let lineWidth = CGFloat(widths[index]) * px
      var x: CGFloat =
        switch alignment {
        case .leading: 0
        case .center: ((width - lineWidth) / 2 / px).rounded() * px
        case .trailing: width - lineWidth
        }
      let y = CGFloat(index * lineUnits) * px
      for character in line {
        let bits = PixelFont.bitmap(character)
        for (row, columns) in bits.enumerated() {
          var start: Int?
          for column in 0...columns.count {
            let on = column < columns.count && columns[column]
            if on, start == nil { start = column }
            if !on, let begin = start {
              context.fill(
                Path(
                  CGRect(
                    x: x + CGFloat(begin) * px, y: y + CGFloat(row) * px,
                    width: CGFloat(column - begin) * px, height: px)),
                with: .color(color))
              start = nil
            }
          }
        }
        x += CGFloat(PixelFont.width(character) + 1) * px
      }
    }
  }
}

// MARK: - Sprites

struct Sprite {
  var rows: [String]
  var palette: [Character: Color]

  init(_ rows: [String], palette: [Character: Color] = Sprite.base) {
    self.rows = rows
    self.palette = palette
  }

  var width: Int { rows.first?.count ?? 0 }
  var height: Int { rows.count }

  static let base: [Character: Color] = [
    "k": Ink.black, "w": Ink.white, "g": Ink.green, "G": Ink.leaf, "m": Ink.mint,
    "o": Ink.copper, "y": Ink.gold, "c": Ink.cream, "r": Ink.red, "R": Ink.maroon,
    "i": Ink.rose, "b": Ink.blue, "s": Ink.sky, "N": Ink.navy, "p": Ink.purple,
    "q": Ink.plum, "v": Ink.violet, "n": Ink.brown, "l": Ink.silver, "d": Ink.gray,
  ]

  func draw(in context: GraphicsContext, origin: CGPoint, px: CGFloat, tint: Color? = nil) {
    for (row, line) in rows.enumerated() {
      var column = 0
      var runStart: Int?
      var runColor: Color?
      func flush(_ end: Int) {
        if let start = runStart, let color = runColor {
          context.fill(
            Path(
              CGRect(
                x: origin.x + CGFloat(start) * px, y: origin.y + CGFloat(row) * px,
                width: CGFloat(end - start) * px, height: px)),
            with: .color(tint ?? color))
        }
        runStart = nil
        runColor = nil
      }
      for character in line {
        let color = character == "." ? nil : palette[character] ?? Ink.black
        if color != runColor {
          flush(column)
          if let color {
            runStart = column
            runColor = color
          }
        }
        column += 1
      }
      flush(column)
    }
  }
}

struct SpriteView: View {
  var sprite: Sprite
  var px: CGFloat
  var tint: Color?
  init(_ sprite: Sprite, px: CGFloat = 3, tint: Color? = nil) {
    self.sprite = sprite
    self.px = px
    self.tint = tint
  }
  var body: some View {
    Canvas { context, _ in
      sprite.draw(in: context, origin: .zero, px: px, tint: tint)
    }
    .frame(width: CGFloat(sprite.width) * px, height: CGFloat(sprite.height) * px)
  }
}

struct FitSprite: View {
  var sprite: Sprite
  var tint: Color?
  init(_ sprite: Sprite, tint: Color? = nil) {
    self.sprite = sprite
    self.tint = tint
  }
  var body: some View {
    Canvas { context, size in
      let px = max(
        1, floor(min(size.width / CGFloat(sprite.width), size.height / CGFloat(sprite.height))))
      let origin = CGPoint(
        x: ((size.width - CGFloat(sprite.width) * px) / 2).rounded(),
        y: ((size.height - CGFloat(sprite.height) * px) / 2).rounded())
      sprite.draw(in: context, origin: origin, px: px, tint: tint)
    }
  }
}

enum Pix {
  static let heart = Sprite([
    ".kk..kk.",
    "krrkkrrk",
    "krirrrrk",
    "krrrrrrk",
    ".krrrrk.",
    "..krrk..",
    "...kk...",
    "........",
  ])
  static let shield = Sprite([
    "kkkkkkkk",
    "ksssws.k",
    "kssswssk",
    "kssswssk",
    ".ksswsk.",
    ".ksswsk.",
    "..kswk..",
    "...kk...",
  ])
  static let bolt = Sprite([
    "....kk..",
    "...kyk..",
    "..kyk...",
    ".kyyykk.",
    "..kkyyk.",
    "....kyk.",
    "...kyk..",
    "...kk...",
  ])
  static let coin = Sprite([
    "..kkkk..",
    ".kyyyyk.",
    "kyycyyyk",
    "kycyyyyk",
    "kyyyyyyk",
    "kyyyyoyk",
    ".kyyoyk.",
    "..kkkk..",
  ])
  static let sword = Sprite([
    "......kk",
    ".....klk",
    "....klk.",
    "...klk..",
    "kk.klk..",
    ".kkkk...",
    ".kkk....",
    "kk.kk...",
  ])
  static let eye = Sprite([
    "........",
    "..kkkk..",
    ".kwwwwk.",
    "kwwkkwwk",
    "kwwkkwwk",
    ".kwwwwk.",
    "..kkkk..",
    "........",
  ])
  static let cards = Sprite([
    "..kkkkk.",
    "kkkkccck",
    "kcckkcck",
    "kcccckck",
    "kcccckck",
    "kccccck.",
    "kccccck.",
    "kkkkkkk.",
  ])
  static let pause = Sprite([
    "kkk.kkk.",
    "kwk.kwk.",
    "kwk.kwk.",
    "kwk.kwk.",
    "kwk.kwk.",
    "kwk.kwk.",
    "kkk.kkk.",
    "........",
  ])
  static let speaker = Sprite([
    "...kk...",
    "..kwk.k.",
    "kkkwk..k",
    "kwwwk.kk",
    "kwwwk.kk",
    "kkkwk..k",
    "..kwk.k.",
    "...kk...",
  ])
  static let speakerOff = Sprite([
    "...kk...",
    "..kwk...",
    "kkkwkr.r",
    "kwwwk.r.",
    "kwwwk.r.",
    "kkkwkr.r",
    "..kwk...",
    "...kk...",
  ])
  static let crown = Sprite([
    "k..kk..k",
    "kk.kk.kk",
    "kkkkkkkk",
    "kyyyyyyk",
    "kyykkyyk",
    "kyyyyyyk",
    "kkkkkkkk",
    "........",
  ])
  static let skull = Sprite([
    "..kkkk..",
    ".kwwwwk.",
    "kwwwwwwk",
    "kwkwwkwk",
    "kwwwwwwk",
    ".kwkkwk.",
    ".kwwwwk.",
    "..kkkk..",
  ])
  static let star = Sprite([
    "...y....",
    "...y....",
    ".y.y.y..",
    "..yyy...",
    "yyyyyyy.",
    "..yyy...",
    ".y.y.y..",
    "...y....",
  ])
  static let close = Sprite([
    "kk....kk",
    "kwk..kwk",
    ".kwkkwk.",
    "..kwwk..",
    "..kwwk..",
    ".kwkkwk.",
    "kwk..kwk",
    "kk....kk",
  ])
  static let arrow = Sprite([
    "....k...",
    "....kk..",
    "kkkkkwk.",
    "kwwwwwwk",
    "kwwwwwwk",
    "kkkkkwk.",
    "....kk..",
    "....k...",
  ])
  static let potion = Sprite([
    "...k....",
    "...kk...",
    "..kppk..",
    "..kppk..",
    ".kppppk.",
    ".kpwppk.",
    ".kppppk.",
    "..kkkk..",
  ])

  static func card(_ kind: CardKind) -> Sprite {
    switch kind {
    case .strike:
      Sprite([
        ".......k",
        "......kl",
        ".....klk",
        "....klk.",
        "...klk..",
        "..klk...",
        ".kkk....",
        "kkk.....",
      ])
    case .guardCard: shield
    case .needle:
      Sprite([
        "...kl...",
        "...kl...",
        "...kl...",
        "...kl...",
        "...kl...",
        "..klkl..",
        "..kk.o..",
        "....oo..",
      ])
    case .bastion:
      Sprite([
        "kkkkkkkk",
        "klllkllk",
        "kkkkkkkk",
        "klkllklk",
        "kkkkkkkk",
        ".kllklk.",
        "..kllk..",
        "...kk...",
      ])
    case .venom: potion
    case .insight: eye
    case .echo:
      Sprite([
        "k.....k.",
        "kl...lk.",
        ".kl.lk..",
        "..klk...",
        "..klk...",
        ".kl.lk..",
        "kl...lk.",
        "k.....k.",
      ])
    case .mend: star
    case .kindle:
      Sprite([
        "....r...",
        "...rr...",
        "..rror..",
        ".rroorr.",
        ".rooyor.",
        ".royyor.",
        "..oyyo..",
        "...oo...",
      ])
    case .riposte:
      Sprite([
        "...kkkkk",
        ".....kkk",
        "....klkk",
        "...klk.k",
        "..klk...",
        ".klk....",
        "klk.....",
        "kk......",
      ])
    case .sever:
      Sprite([
        "k...l..k",
        ".k..l.k.",
        "..k.lk..",
        "...kk...",
        "...kk...",
        "..k..k..",
        ".kk..kk.",
        ".kk..kk.",
      ])
    case .sanctuary:
      Sprite([
        "kkkkkkkk",
        "kggggggk",
        "kgrrgrrk",
        "kgrrrrrk",
        ".kgrrrk.",
        ".kggrgk.",
        "..kggk..",
        "...kk...",
      ])
    case .harvest:
      Sprite([
        "..kkkk..",
        ".kyyykk.",
        "kyyk....",
        "kyk.....",
        "kyk..r..",
        "kyyk.rr.",
        ".kyyykk.",
        "..kkkk..",
      ])
    case .flourish:
      Sprite([
        "......kk",
        ".....kmm",
        "....kmmk",
        "...kmmk.",
        "..kmmk..",
        ".kmmk...",
        "kmk.....",
        "k.......",
      ])
    case .eclipse:
      Sprite([
        "..yyyy..",
        ".yyyyyy.",
        "yykkkkyy",
        "ykkkkkky",
        "ykkkkkky",
        "yykkkkyy",
        ".yyyyyy.",
        "..yyyy..",
      ])
    case .hourglass:
      Sprite([
        "kkkkkkkk",
        ".kyyyyk.",
        ".kkyykk.",
        "..kkkk..",
        "..k..k..",
        ".k.yy.k.",
        ".kyyyyk.",
        "kkkkkkkk",
      ])
    case .thorn: crown
    case .lantern:
      Sprite([
        "...kk...",
        "..kkkk..",
        ".kyyyyk.",
        ".kyyyyk.",
        ".kyooyk.",
        ".kyyyyk.",
        "..kkkk..",
        "...kk...",
      ])
    }
  }

  static func relic(_ relic: Relic) -> Sprite {
    switch relic {
    case .spool:
      Sprite([
        "kkkkkkkk",
        ".kooook.",
        ".kooook.",
        ".kokook.",
        ".kooook.",
        ".kooook.",
        ".kooook.",
        "kkkkkkkk",
      ])
    case .feather:
      Sprite([
        "......kk",
        ".....kvv",
        "....kvvk",
        "...kvvk.",
        "..kvvk..",
        ".kvvk...",
        "kvk.....",
        "k.......",
      ])
    case .candle:
      Sprite([
        "...r....",
        "..ryr...",
        "..ryr...",
        "...o....",
        "..kwwk..",
        "..kwwk..",
        "..kwwk..",
        ".kkkkkk.",
      ])
    case .thimble:
      Sprite([
        "..kkkk..",
        ".kllllk.",
        "kllllllk",
        "klkllklk",
        "kllllllk",
        "klkllklk",
        "kllllllk",
        "kkkkkkkk",
      ])
    }
  }

  static func scene(_ symbol: String) -> Sprite {
    switch symbol {
    case "moon": card(.harvest)
    case "shield": shield
    case "leaf":
      Sprite([
        ".......k",
        "....kkGk",
        "..kGGGGk",
        ".kGGGGGk",
        ".kGGGkk.",
        "kGGGkG..",
        "kGGkG...",
        "kkk.....",
      ])
    case "bag":
      Sprite([
        "..kkkk..",
        "..k..k..",
        ".kkkkkk.",
        "kooooook",
        "koooyook",
        "kooooook",
        "kooooook",
        ".kkkkkk.",
      ])
    case "scissors": card(.sever)
    case "crown": crown
    default: star
    }
  }

  static func enemy(_ kind: EnemyKind) -> Sprite {
    switch kind {
    case .moth:
      Sprite([
        ".....k....k.....",
        "....k.k..k.k....",
        ".....k.kk.k.....",
        "kk....kkkk....kk",
        "kppk.kqyyqk.kppk",
        "kpgpkkqkkqkkpgpk",
        "kppppkqqqqkppppk",
        "kpppgkqqqqkgpppk",
        ".kppkkqqqqkkppk.",
        ".kpppkqggqkpppk.",
        "..kppkqqqqkppk..",
        "..kpgpkqqkpgpk..",
        "...kppkqqkppk...",
        "....kpkqqkpk....",
        ".....kkkkkk.....",
        "......k..k......",
      ])
    case .fox:
      Sprite([
        "..kk........kk..",
        ".kook......kook.",
        ".konok....konok.",
        ".koookkkkkkoook.",
        ".kooooooooooook.",
        "kooooooooooooook",
        "koowkooooookwook",
        "kowgkooooookgwok",
        "koookoooooookook",
        ".kooooooooooook.",
        "..koowwwwwwook..",
        "...kowwkkwwok...",
        "....kwwwwwwk....",
        ".....kwwwwk.....",
        "......kkkk......",
        "................",
      ])
    case .knight:
      Sprite([
        ".....kkkkkk.....",
        "....klllllldk...",
        "...klllllllldk..",
        "...kllkkkkkkdk..",
        "...klkGGGGGGkk..",
        "...klkG.GG.Gkk..",
        "...kllkkkkkkdk..",
        "....kllllllldk..",
        "..kkkllddllkkkk.",
        ".kllklllllllkllk",
        ".kldkllldlllkdlk",
        ".kllklldddllkllk",
        ".kkkkllldlllkkkk",
        "....klllllllk...",
        "....kddkkkddk...",
        "....kkk...kkk...",
      ])
    case .twins:
      Sprite([
        "................",
        "..kkk......kkk..",
        ".kwwwk....kwwwk.",
        ".kwkwk....kwkwk.",
        ".kwwwk.ll.kwwwk.",
        "..krk..ll..krk..",
        ".krrrk.ll.krrrk.",
        "krrrrrklkkrrrrrk",
        "krkrkrkkkkrkrkrk",
        "krrrrrk..krrrrrk",
        ".krrrk....krrrk.",
        ".krkrk....krkrk.",
        ".kk.kk....kk.kk.",
        "................",
        "................",
        "................",
      ])
    case .stag:
      Sprite([
        "k..k........k..k",
        "kk.k.k....k.k.kk",
        ".kkkkk....kkkkk.",
        "...k.kG..Gk.k...",
        "...kkkkkkkkkk...",
        "..knnnnnnnnnnk..",
        ".knnwknnnnkwnnk.",
        ".knnkknnnnkknnk.",
        ".knnnnnnnnnnnnk.",
        "..knnnnkknnnnk..",
        "..knnnkkkknnnk..",
        "...knnkGGknnk...",
        "....knnkknnk....",
        ".....knnnnk.....",
        ".....kkkkkk.....",
        "................",
      ])
    case .queen:
      Sprite([
        "l..............l",
        "l....ykykyk....l",
        "l....kyyyyk....l",
        "l...kwwwwwwk...l",
        "l...kwkwwkwk...l",
        "l...kwwwwwwk...l",
        "l....kwrrwk....l",
        "l..kkkppppkkk..l",
        ".kpppppyypppppk.",
        "kpkppppyyppppkpk",
        "kpkppppppppppkpk",
        "kkkppppppppppkkk",
        "..kppppppppppk..",
        ".kppppppppppppk.",
        "kppppppppppppppk",
        "kkkkkkkkkkkkkkkk",
      ])
    }
  }
}

// MARK: - Backgrounds, frames and chrome

struct PaperBackground: View {
  var ornaments = true
  var body: some View {
    ZStack {
      Ink.night
      Canvas { context, size in
        let cell: CGFloat = 4
        var index = 0
        for y in stride(from: 0, to: size.height, by: cell * 9) {
          for x in stride(from: 0, to: size.width, by: cell * 7) {
            index += 1
            let jitterX = CGFloat((index * 37) % 5) * cell
            let jitterY = CGFloat((index * 53) % 7) * cell
            let bright = index % 5 == 0
            context.fill(
              Path(CGRect(x: x + jitterX, y: y + jitterY, width: cell / 2, height: cell / 2)),
              with: .color(bright ? Ink.silver.opacity(0.55) : Ink.navy.opacity(0.9)))
          }
        }
        if ornaments {
          let bands: [Color] = [
            Ink.plum.opacity(0.0), Ink.plum.opacity(0.25), Ink.plum.opacity(0.5),
          ]
          for (row, color) in bands.enumerated() {
            let y = size.height - CGFloat(bands.count - row) * cell * 5
            for x in stride(from: 0, to: size.width, by: cell * 2) {
              let offset: CGFloat = row % 2 == 0 ? 0 : cell
              context.fill(
                Path(CGRect(x: x + offset, y: y, width: cell, height: cell * 5)),
                with: .color(color)
              )
            }
          }
        }
      }
    }
    .ignoresSafeArea()
  }
}

struct PixelFrame: View {
  var px: CGFloat = 2
  var color = Ink.white
  var fill: Color? = nil
  var corner = Ink.night
  var body: some View {
    Canvas { context, size in
      let rect = CGRect(origin: .zero, size: size)
      if let fill { context.fill(Path(rect), with: .color(fill)) }
      ring(context, rect, inset: 0, thickness: px / 2, color: Ink.black)
      ring(context, rect, inset: px / 2, thickness: px, color: color)
      ring(context, rect, inset: px * 1.5, thickness: px / 2, color: Ink.black)
      for x in [rect.minX, rect.maxX - px] {
        for y in [rect.minY, rect.maxY - px] {
          context.fill(Path(CGRect(x: x, y: y, width: px, height: px)), with: .color(corner))
        }
      }
    }
    .allowsHitTesting(false)
  }

  private func ring(
    _ context: GraphicsContext, _ rect: CGRect, inset: CGFloat, thickness: CGFloat, color: Color
  ) {
    var path = Path(rect.insetBy(dx: inset, dy: inset))
    path.addPath(Path(rect.insetBy(dx: inset + thickness, dy: inset + thickness)))
    context.fill(path, with: .color(color), style: FillStyle(eoFill: true))
  }
}

struct Window<Content: View>: View {
  var fill: Color
  var border: Color
  var content: Content
  init(fill: Color = Ink.navy, border: Color = Ink.white, @ViewBuilder content: () -> Content) {
    self.fill = fill
    self.border = border
    self.content = content()
  }
  var body: some View {
    content
      .background(fill)
      .overlay(PixelFrame(color: border))
  }
}

struct Blink<Content: View>: View {
  var period: Double = 0.5
  var content: Content
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  init(period: Double = 0.5, @ViewBuilder content: () -> Content) {
    self.period = period
    self.content = content()
  }
  var body: some View {
    TimelineView(.periodic(from: .now, by: period)) { timeline in
      let phase = Int(timeline.date.timeIntervalSinceReferenceDate / period) % 2
      content.opacity(reduceMotion || phase == 0 ? 1 : 0)
    }
  }
}

struct PixelRule: View {
  var color = Ink.gold
  var body: some View {
    HStack(spacing: 4) {
      Rectangle().fill(color).frame(height: 2)
      SpriteView(
        Sprite(["..#..", ".###.", "#####", ".###.", "..#.."], palette: ["#": color]), px: 2)
      Rectangle().fill(color).frame(height: 2)
    }
  }
}

struct Eyebrow: View {
  var text: String
  var color = Ink.gold
  var body: some View {
    HStack(spacing: 8) {
      Rectangle().fill(color).frame(width: 4, height: 4)
      PixelText(text.uppercased(), px: 1.5, color: color)
      Rectangle().fill(color).frame(width: 4, height: 4)
    }
  }
}

struct CostBadge: View {
  var number: Int
  var size: CGFloat = 24
  var body: some View {
    ZStack {
      Rectangle().fill(Ink.gold)
      Rectangle().stroke(Ink.black, lineWidth: 2)
      Rectangle().fill(Ink.cream).frame(width: size - 6, height: 2).offset(y: -size / 2 + 4)
      PixelText("\(number)", px: max(1, (size / 12).rounded()), color: Ink.black)
    }
    .frame(width: size, height: size)
    .compositingGroup()
    .shadow(color: Ink.black, radius: 0, x: 2, y: 2)
  }
}

struct PixelBar: View {
  var value: Int
  var max: Int
  var color: Color
  var height: CGFloat = 10
  var body: some View {
    GeometryReader { geometry in
      let fraction = CGFloat(Swift.max(0, value)) / CGFloat(Swift.max(1, max))
      let inner = geometry.size.width - 4
      let filled = (inner * fraction / 4).rounded(.down) * 4
      ZStack(alignment: .leading) {
        Rectangle().fill(Ink.black)
        Rectangle().fill(color).frame(width: value > 0 ? Swift.max(4, filled) : 0).padding(2)
        Canvas { context, size in
          for x in stride(from: 6, to: size.width - 2, by: 4) {
            context.fill(
              Path(CGRect(x: x, y: 2, width: 1, height: size.height - 4)),
              with: .color(Ink.black.opacity(0.45)))
          }
          context.fill(
            Path(CGRect(x: 2, y: 2, width: size.width - 4, height: 1)),
            with: .color(Ink.white.opacity(0.35)))
        }
      }
      .overlay(Rectangle().stroke(Ink.white, lineWidth: 2))
    }
    .frame(height: height)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(value) of \(max)")
  }
}

struct IntentTag: View {
  var intent: Intent
  private var icon: Sprite {
    intent.damage == 0 ? Pix.shield : intent.weak > 0 ? Pix.eye : Pix.sword
  }
  private var label: String {
    if intent.damage == 0 { return "GUARD \(intent.block)" }
    return intent.weak > 0 ? "HEX \(intent.damage)" : "ATTACK \(intent.damage)"
  }
  private var tone: Color { intent.damage == 0 ? Ink.sky : intent.weak > 0 ? Ink.violet : Ink.rose }
  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 8) {
        SpriteView(icon, px: 2)
        PixelText(label, px: 2, color: Ink.black)
      }
      .padding(.horizontal, 10).padding(.vertical, 7)
      .background(Ink.white)
      .overlay(Rectangle().stroke(Ink.black, lineWidth: 2))
      .overlay(alignment: .top) { Rectangle().fill(tone).frame(height: 3).padding(.horizontal, 2) }
      SpriteView(
        Sprite(["kkkkk", ".kwk.", "..k.."], palette: ["k": Ink.black, "w": Ink.white]), px: 2
      ).offset(y: -2)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Enemy intent: \(intent.label)")
  }
}

struct Proscenium: View {
  var kind: EnemyKind
  var idle = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  var body: some View {
    GeometryReader { geometry in
      let w = geometry.size.width
      let h = geometry.size.height
      let px = max(2, floor(min(h * 0.6 / 16, w * 0.42 / 16)))
      ZStack {
        Canvas { context, size in
          let unit: CGFloat = 4
          context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Ink.black))
          let bands: [Color] = [Ink.navy, Ink.navy, Ink.plum, Ink.night, Ink.night]
          let bandHeight = size.height * 0.78 / CGFloat(bands.count)
          for (index, color) in bands.enumerated() {
            context.fill(
              Path(
                CGRect(
                  x: 0, y: CGFloat(index) * bandHeight, width: size.width,
                  height: bandHeight + 1)), with: .color(color))
            if index + 1 < bands.count {
              for x in stride(from: 0, to: size.width, by: unit * 2) {
                context.fill(
                  Path(
                    CGRect(
                      x: x + (index % 2 == 0 ? 0 : unit), y: CGFloat(index + 1) * bandHeight - unit,
                      width: unit, height: unit)), with: .color(color))
              }
            }
          }
          for index in 0..<26 {
            let x = CGFloat((index * 73 + 11) % 97) / 97 * size.width
            let y = CGFloat((index * 41 + 5) % 61) / 61 * size.height * 0.5
            context.fill(
              Path(CGRect(x: x, y: y, width: unit / 2, height: unit / 2)),
              with: .color(index % 4 == 0 ? Ink.white : Ink.sky.opacity(0.7)))
          }
          let floorY = size.height * 0.78
          context.fill(
            Path(CGRect(x: 0, y: floorY, width: size.width, height: size.height - floorY)),
            with: .color(Ink.brown))
          for y in stride(from: floorY, to: size.height, by: unit * 2) {
            context.fill(
              Path(CGRect(x: 0, y: y, width: size.width, height: unit / 2)),
              with: .color(Ink.maroon))
            for x in stride(
              from: (y / (unit * 2)).truncatingRemainder(dividingBy: 2) * unit * 6,
              to: size.width, by: unit * 12)
            {
              context.fill(
                Path(CGRect(x: x, y: y, width: unit / 2, height: unit * 2)),
                with: .color(Ink.maroon))
            }
          }
          let spot = CGRect(
            x: size.width / 2 - px * 9, y: floorY - px * 2, width: px * 18, height: px * 4)
          context.fill(Path(ellipseIn: spot), with: .color(Ink.black.opacity(0.55)))
          let curtain = max(unit * 5, size.width * 0.13)
          for side in [CGFloat(0), size.width - curtain] {
            context.fill(
              Path(CGRect(x: side, y: 0, width: curtain, height: size.height)),
              with: .color(Ink.red))
            for x in stride(from: side + unit, to: side + curtain, by: unit * 2) {
              context.fill(
                Path(CGRect(x: x, y: 0, width: unit / 2, height: size.height)),
                with: .color(Ink.maroon))
            }
            context.fill(
              Path(CGRect(x: side, y: size.height - unit * 2, width: curtain, height: unit * 2)),
              with: .color(Ink.gold))
          }
          context.fill(
            Path(CGRect(x: 0, y: 0, width: size.width, height: unit * 3)), with: .color(Ink.red))
          for x in stride(from: 0, to: size.width, by: unit * 3) {
            context.fill(
              Path(CGRect(x: x, y: unit * 3, width: unit * 2, height: unit)),
              with: .color(Ink.red))
            context.fill(
              Path(CGRect(x: x + unit / 2, y: unit * 4, width: unit, height: unit / 2)),
              with: .color(Ink.gold))
          }
          context.fill(
            Path(CGRect(x: 0, y: unit * 2, width: size.width, height: unit)), with: .color(Ink.gold)
          )
        }
        TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
          let phase = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2
          SpriteView(Pix.enemy(kind), px: px)
            .offset(y: idle && !reduceMotion && phase == 1 ? -px : 0)
            .position(x: w / 2, y: h * 0.78 - px * 8 + px)
        }
      }
      .overlay(PixelFrame(color: Ink.gold, corner: Ink.black))
    }
    .accessibilityLabel(kind.title)
  }
}

struct EnemyArt: View {
  var kind: EnemyKind
  var body: some View { FitSprite(Pix.enemy(kind)) }
}

struct CardIllustration: View {
  var kind: CardKind
  var body: some View { FitSprite(Pix.card(kind)) }
}

struct SceneGlyph: View {
  var symbol: String
  var body: some View { FitSprite(Pix.scene(symbol)) }
}

struct RelicGlyph: View {
  var relic: Relic
  var body: some View {
    FitSprite(Pix.relic(relic)).padding(6)
      .background(Ink.plum)
      .overlay(PixelFrame(color: Ink.gold))
  }
}

struct CardFace: View {
  var kind: CardKind
  var affordable = true
  var unavailableLabel = "NO ENERGY"
  var text: String?
  var width: CGFloat = 128
  private var accent: Color {
    kind.exhausts ? Ink.purple : kind.isDefense ? Ink.green : Ink.copper
  }
  private var artFill: Color {
    kind.exhausts ? Ink.plum : kind.isDefense ? Ink.navy : Ink.maroon
  }
  var body: some View {
    let height = (width * 1.62).rounded()
    let px = width >= 110 ? 1.5 : 1.0
    VStack(spacing: 0) {
      ZStack {
        artFill
        Canvas { context, size in
          for y in stride(from: 0, to: size.height, by: 6) {
            for x in stride(
              from: (y / 6).truncatingRemainder(dividingBy: 2) * 3, to: size.width, by: 6)
            {
              context.fill(
                Path(CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                with: .color(Ink.white.opacity(0.12)))
            }
          }
        }
        CardIllustration(kind: kind).padding(width * 0.09)
      }
      .frame(height: height * 0.34)
      .overlay(Rectangle().stroke(Ink.black, lineWidth: 2))
      .padding(.top, width * 0.13)
      PixelText(
        kind.title.uppercased(), px: px, color: Ink.black, maxWidth: width - 18, alignment: .center
      )
      .frame(height: px * 20)
      .padding(.top, 5)
      Rectangle().fill(accent).frame(height: 2).padding(.horizontal, 4)
      PixelText(
        (text ?? kind.text).uppercased(), px: px, color: Ink.night, maxWidth: width - 18,
        alignment: .center
      )
      .frame(maxHeight: .infinity, alignment: .center)
      PixelText(affordable ? kind.category : unavailableLabel, px: 1, color: Ink.white)
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(affordable ? accent : Ink.red)
        .padding(.bottom, 6)
    }
    .padding(.horizontal, 7)
    .frame(width: width, height: height)
    .background(Ink.cream)
    .overlay(Rectangle().stroke(accent, lineWidth: 2).padding(4))
    .overlay(Rectangle().stroke(Ink.black, lineWidth: 2))
    .overlay(alignment: .topLeading) {
      CostBadge(number: kind.cost, size: (width * 0.2).rounded()).offset(x: -4, y: -4)
    }
    .saturation(affordable ? 1 : 0.1)
    .opacity(affordable ? 1 : 0.8)
    .compositingGroup()
    .shadow(color: Ink.black.opacity(0.7), radius: 0, x: 4, y: 4)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(kind.title), \(kind.cost) energy. \(text ?? kind.text)\(affordable ? "" : " Not enough energy.")"
    )
  }
}
