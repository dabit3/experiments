import Foundation

enum Fruit: String, Codable {
  case apple, plum, pear

  var label: String {
    switch self {
    case .apple: return "Apple"
    case .plum: return "Burst plum"
    case .pear: return "Heavy pear"
    }
  }
}

enum Material: String {
  case wood, glass, stone

  var strength: CGFloat {
    switch self {
    case .wood: return 6.5
    case .glass: return 3
    case .stone: return 15
    }
  }
}

struct Block {
  var x: CGFloat
  var y: CGFloat
  var width: CGFloat
  var height: CGFloat
  var material: Material = .wood
}

struct GardenTarget {
  var x: CGFloat
  var y: CGFloat
}

struct Level {
  let name: String
  let subtitle: String
  let hint: String
  let fruit: [Fruit]
  let blocks: [Block]
  let targets: [GardenTarget]
  let par: Int

  static func tower(_ x: CGFloat, _ base: CGFloat = 135, glass: Bool = false) -> [Block] {
    [
      Block(x: x - 60, y: base + 51, width: 22, height: 100),
      Block(
        x: x + 60, y: base + 51, width: 22, height: 100,
        material: glass ? .glass : .wood),
      Block(x: x, y: base + 112, width: 166, height: 22),
    ]
  }

  static let all: [Level] = [
    Level(
      name: "First harvest", subtitle: "THE GARDEN GATE",
      hint: "Pull the apple back. Aim for the wooden legs.",
      fruit: [.apple, .apple, .plum],
      blocks: tower(955),
      targets: [.init(x: 955, y: 160), .init(x: 955, y: 283)], par: 2),
    Level(
      name: "Glasshouse", subtitle: "A DELICATE BALANCE",
      hint: "Glass shatters easily. Take out a lower support.",
      fruit: [.apple, .plum, .apple],
      blocks: tower(945, glass: true) + tower(945, 259, glass: true),
      targets: [
        .init(x: 945, y: 160), .init(x: 945, y: 283),
        .init(x: 945, y: 407),
      ], par: 2),
    Level(
      name: "The long table", subtitle: "A CHAIN REACTION",
      hint: "Break the table’s supports to start a chain reaction.",
      fruit: [.plum, .apple, .pear],
      blocks: [
        Block(x: 850, y: 183, width: 22, height: 94, material: .glass),
        Block(x: 1000, y: 183, width: 22, height: 94),
        Block(x: 1150, y: 183, width: 22, height: 94, material: .glass),
        Block(x: 925, y: 242, width: 184, height: 22),
        Block(x: 1075, y: 266, width: 184, height: 22),
        Block(x: 1000, y: 321, width: 32, height: 86),
      ],
      targets: [
        .init(x: 895, y: 160), .init(x: 1090, y: 160),
        .init(x: 925, y: 278), .init(x: 1080, y: 302),
      ], par: 2),
    Level(
      name: "Stone & stem", subtitle: "THE OLD ORCHARD",
      hint: "Wood beneath stone is the weak point.",
      fruit: [.pear, .plum, .apple],
      blocks: tower(940) + [
        Block(x: 880, y: 286, width: 34, height: 76, material: .stone),
        Block(x: 1000, y: 286, width: 34, height: 76, material: .stone),
        Block(x: 940, y: 337, width: 174, height: 22),
        Block(x: 1130, y: 168, width: 66, height: 64, material: .glass),
      ],
      targets: [
        .init(x: 940, y: 160), .init(x: 940, y: 283),
        .init(x: 940, y: 373), .init(x: 1130, y: 227),
      ], par: 2),
    Level(
      name: "Twin boughs", subtitle: "DIVIDE & TOPPLE",
      hint: "Two towers, one orchard. Aim between them for a bigger collapse.",
      fruit: [.plum, .pear, .plum, .apple],
      blocks: tower(860, glass: true) + tower(1130, glass: true)
        + [Block(x: 995, y: 271, width: 165, height: 24, material: .glass)],
      targets: [
        .init(x: 860, y: 160), .init(x: 860, y: 283),
        .init(x: 1130, y: 160), .init(x: 1130, y: 283),
        .init(x: 995, y: 310),
      ], par: 3),
    Level(
      name: "Golden crown", subtitle: "ONE LAST HARVEST",
      hint: "A tall crown on fragile feet. Aim for the heart of the fort.",
      fruit: [.pear, .plum, .plum, .apple],
      blocks: tower(995, glass: true) + tower(995, 259)
        + [
          Block(x: 935, y: 423, width: 30, height: 76, material: .glass),
          Block(x: 1055, y: 423, width: 30, height: 76, material: .glass),
          Block(x: 995, y: 474, width: 170, height: 22, material: .stone),
          Block(x: 1190, y: 176, width: 22, height: 80),
          Block(x: 1190, y: 228, width: 120, height: 22),
        ],
      targets: [
        .init(x: 995, y: 160), .init(x: 995, y: 283),
        .init(x: 995, y: 407), .init(x: 995, y: 510),
        .init(x: 1190, y: 264),
      ], par: 3),
  ]
}

enum Rules {
  static func stars(won: Bool, shotsUsed: Int, par: Int) -> Int {
    guard won else { return 0 }
    if shotsUsed < par { return 3 }
    return shotsUsed == par ? 2 : 1
  }

  static func finalScore(destruction: Int, shotsRemaining: Int, won: Bool) -> Int {
    destruction + (won ? max(0, shotsRemaining) * 1500 : 0)
  }

  static func clampedPull(dx: CGFloat, dy: CGFloat) -> (x: CGFloat, y: CGFloat) {
    let x = min(12, dx)
    let y = min(55, max(-110, dy))
    let length = hypot(x, y)
    let scale = length > 115 ? 115 / length : 1
    return (x * scale, y * scale)
  }

  static func shouldEndShot(elapsed: TimeInterval, speed: CGFloat, quietTime: TimeInterval) -> Bool
  {
    elapsed >= 9 || (elapsed >= 2.2 && speed < 28 && quietTime > 1.2)
  }
}
