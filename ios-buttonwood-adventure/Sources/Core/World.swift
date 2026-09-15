import Foundation

struct Point: Equatable, Sendable {
  var x: Double
  var y: Double
}

struct Ledge: Sendable {
  var x: Double
  var y: Double
  var width: Double
  var depth: Double = 26
  var travel: Double = 0
  var period: Double = 4

  func offset(at time: Double) -> Double {
    travel * sin(time * 2 * .pi / period)
  }
}

struct Bug: Sendable {
  var x: Double
  var y: Double
  var patrol: Double
  var phase: Double = 0
}

struct Level: Sendable {
  var name: String
  var subtitle: String
  var hint: String
  var length: Double
  var palette: Int
  var ledges: [Ledge]
  var coins: [Point]
  var bugs: [Bug]
  var checkpoint: Point
  var powerup: Point
  var goal: Point

  static let all: [Level] = [
    Level(
      name: "Fernlight Trail", subtitle: "A little courage goes a long way.",
      hint: "Hold a direction to run. Hold jump to leap higher.",
      length: 3380, palette: 0,
      ledges: [
        Ledge(x: -200, y: 90, width: 1000, depth: 240),
        Ledge(x: 905, y: 90, width: 770, depth: 240),
        Ledge(x: 1800, y: 90, width: 640, depth: 240),
        Ledge(x: 2550, y: 90, width: 1020, depth: 240),
        Ledge(x: 360, y: 160, width: 130),
        Ledge(x: 550, y: 220, width: 140),
        Ledge(x: 1080, y: 180, width: 140),
        Ledge(x: 1290, y: 225, width: 130),
        Ledge(x: 1570, y: 180, width: 150, travel: 48),
        Ledge(x: 2060, y: 180, width: 145),
        Ledge(x: 2290, y: 225, width: 140),
        Ledge(x: 2690, y: 165, width: 130),
        Ledge(x: 2910, y: 220, width: 160),
      ],
      coins: coinArc(350, 198, count: 4) + coinArc(744, 150, count: 5)
        + coinArc(1098, 221, count: 3) + coinArc(1289, 264, count: 3)
        + coinArc(1590, 222, count: 3) + coinArc(2045, 225, count: 4)
        + coinArc(2380, 153, count: 5) + coinArc(2905, 264, count: 4),
      bugs: [
        Bug(x: 560, y: 90, patrol: 90), Bug(x: 1260, y: 90, patrol: 85),
        Bug(x: 2180, y: 90, patrol: 100), Bug(x: 2870, y: 90, patrol: 100),
      ],
      checkpoint: Point(x: 1850, y: 90), powerup: Point(x: 1100, y: 211),
      goal: Point(x: 3270, y: 90)
    ),
    Level(
      name: "Brasswater Grove", subtitle: "Where the woodland winds its gears.",
      hint: "Brass platforms move. Land on top and ride along.",
      length: 3570, palette: 1,
      ledges: [
        Ledge(x: -200, y: 90, width: 830, depth: 240),
        Ledge(x: 800, y: 110, width: 570, depth: 240),
        Ledge(x: 1510, y: 90, width: 460, depth: 240),
        Ledge(x: 2150, y: 90, width: 480, depth: 240),
        Ledge(x: 2820, y: 90, width: 1000, depth: 240),
        Ledge(x: 330, y: 165, width: 130),
        Ledge(x: 610, y: 155, width: 130, travel: 60),
        Ledge(x: 945, y: 195, width: 135),
        Ledge(x: 1230, y: 230, width: 125),
        Ledge(x: 1390, y: 150, width: 130, travel: 70),
        Ledge(x: 1790, y: 170, width: 120),
        Ledge(x: 1990, y: 180, width: 140, travel: 65),
        Ledge(x: 2310, y: 200, width: 150),
        Ledge(x: 2630, y: 155, width: 130, travel: 75),
        Ledge(x: 2980, y: 180, width: 130),
        Ledge(x: 3210, y: 235, width: 160),
      ],
      coins: coinArc(325, 209, count: 4) + coinArc(635, 226, count: 3)
        + coinArc(945, 237, count: 4) + coinArc(1220, 271, count: 4)
        + coinArc(1750, 219, count: 4) + coinArc(1990, 249, count: 3)
        + coinArc(2320, 246, count: 3) + coinArc(2630, 233, count: 3)
        + coinArc(3210, 280, count: 4),
      bugs: [
        Bug(x: 460, y: 90, patrol: 90), Bug(x: 1090, y: 110, patrol: 95),
        Bug(x: 1700, y: 90, patrol: 90), Bug(x: 2420, y: 90, patrol: 110),
        Bug(x: 3080, y: 90, patrol: 115),
      ],
      checkpoint: Point(x: 1600, y: 90), powerup: Point(x: 960, y: 227),
      goal: Point(x: 3460, y: 90)
    ),
    Level(
      name: "Firefly Canopy", subtitle: "Bring the last light home.",
      hint: "Follow the fireflies. Every brave landing counts.",
      length: 3770, palette: 2,
      ledges: [
        Ledge(x: -200, y: 90, width: 840, depth: 240),
        Ledge(x: 790, y: 90, width: 490, depth: 240),
        Ledge(x: 1470, y: 90, width: 630, depth: 240),
        Ledge(x: 2270, y: 90, width: 470, depth: 240),
        Ledge(x: 2920, y: 90, width: 1100, depth: 240),
        Ledge(x: 280, y: 160, width: 120),
        Ledge(x: 470, y: 225, width: 120),
        Ledge(x: 640, y: 160, width: 120, travel: 45),
        Ledge(x: 940, y: 190, width: 140),
        Ledge(x: 1180, y: 245, width: 120),
        Ledge(x: 1320, y: 170, width: 135, travel: 65),
        Ledge(x: 1640, y: 180, width: 130),
        Ledge(x: 1840, y: 240, width: 130),
        Ledge(x: 2110, y: 170, width: 140, travel: 60),
        Ledge(x: 2410, y: 190, width: 125),
        Ledge(x: 2720, y: 155, width: 140, travel: 65),
        Ledge(x: 3020, y: 175, width: 130),
        Ledge(x: 3230, y: 235, width: 135),
        Ledge(x: 3450, y: 190, width: 130),
      ],
      coins: coinArc(285, 202, count: 3) + coinArc(470, 270, count: 3)
        + coinArc(680, 226, count: 3) + coinArc(940, 235, count: 4)
        + coinArc(1180, 285, count: 3) + coinArc(1650, 220, count: 3)
        + coinArc(1840, 280, count: 3) + coinArc(2140, 236, count: 3)
        + coinArc(2420, 235, count: 3) + coinArc(2740, 223, count: 3)
        + coinArc(3240, 277, count: 3) + coinArc(3450, 233, count: 3),
      bugs: [
        Bug(x: 450, y: 90, patrol: 90), Bug(x: 1000, y: 90, patrol: 120),
        Bug(x: 1740, y: 90, patrol: 125), Bug(x: 2480, y: 90, patrol: 100),
        Bug(x: 3210, y: 90, patrol: 145),
      ],
      checkpoint: Point(x: 1550, y: 90), powerup: Point(x: 965, y: 222),
      goal: Point(x: 3650, y: 90)
    ),
  ]

  static func coinArc(_ x: Double, _ y: Double, count: Int) -> [Point] {
    (0..<count).map {
      Point(x: x + Double($0) * 34, y: y + sin(Double($0) / Double(max(1, count - 1)) * .pi) * 28)
    }
  }
}
