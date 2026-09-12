import Foundation

struct SeaPoint: Equatable, Codable {
  var x: Double
  var y: Double

  static func + (lhs: Self, rhs: Self) -> Self {
    Self(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }

  static func - (lhs: Self, rhs: Self) -> Self {
    Self(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
  }

  static func * (lhs: Self, rhs: Double) -> Self {
    Self(x: lhs.x * rhs, y: lhs.y * rhs)
  }

  var length: Double { hypot(x, y) }
  func distance(to other: Self) -> Double { (self - other).length }
  var clamped: Self { Self(x: min(345, max(15, x)), y: min(505, max(18, y))) }
}

struct Reef: Identifiable {
  let id: Int
  let center: SeaPoint
  let radius: Double
}

struct Current {
  let center: SeaPoint
  let radius: Double
  let force: SeaPoint
}

struct HarborChart {
  let id: String
  let name: String
  let subtitle: String
  let start: SeaPoint
  let home: SeaPoint
  let boats: [SeaPoint]
  let reefs: [Reef]
  let currents: [Current]
  let fuel: Double
  let guide: [SeaPoint]
  let chapter: Int
  var dailySeed: String?
  var shift: Int = 0

  static let campaign: [Self] = [
    Self(
      id: "first-light", name: "First light", subtitle: "A quiet sea. Three boats waiting.",
      start: SeaPoint(x: 72, y: 448), home: SeaPoint(x: 282, y: 76),
      boats: [.init(x: 96, y: 337), .init(x: 233, y: 260), .init(x: 244, y: 151)],
      reefs: [
        Reef(id: 0, center: .init(x: 151, y: 220), radius: 37),
        Reef(id: 1, center: .init(x: 302, y: 370), radius: 22),
        Reef(id: 2, center: .init(x: 51, y: 134), radius: 17),
      ],
      currents: [], fuel: 690,
      guide: [
        .init(x: 72, y: 448), .init(x: 96, y: 337), .init(x: 233, y: 260),
        .init(x: 244, y: 151), .init(x: 282, y: 76),
      ], chapter: 1),
    Self(
      id: "cross-tide", name: "Cross tide", subtitle: "Keep a little room to starboard.",
      start: .init(x: 66, y: 449), home: .init(x: 284, y: 72),
      boats: [
        .init(x: 100, y: 350), .init(x: 215, y: 300), .init(x: 258, y: 187),
        .init(x: 161, y: 110),
      ],
      reefs: [
        Reef(id: 0, center: .init(x: 123, y: 230), radius: 32),
        Reef(id: 1, center: .init(x: 301, y: 288), radius: 20),
      ],
      currents: [Current(center: .init(x: 202, y: 272), radius: 95, force: .init(x: 7, y: 0))],
      fuel: 810,
      guide: [
        .init(x: 66, y: 449), .init(x: 100, y: 350), .init(x: 215, y: 300),
        .init(x: 258, y: 187), .init(x: 161, y: 110), .init(x: 284, y: 72),
      ], chapter: 2),
    Self(
      id: "needle-passage", name: "Needle passage", subtitle: "One narrow channel. One long tow.",
      start: .init(x: 64, y: 453), home: .init(x: 280, y: 68),
      boats: [
        .init(x: 106, y: 377), .init(x: 230, y: 337), .init(x: 180, y: 253),
        .init(x: 159, y: 154), .init(x: 257, y: 116),
      ],
      reefs: [
        Reef(id: 0, center: .init(x: 102, y: 249), radius: 48),
        Reef(id: 1, center: .init(x: 258, y: 225), radius: 44),
      ],
      currents: [Current(center: .init(x: 180, y: 239), radius: 73, force: .init(x: 0, y: 6))],
      fuel: 830,
      guide: [
        .init(x: 64, y: 453), .init(x: 106, y: 377), .init(x: 230, y: 337),
        .init(x: 180, y: 253), .init(x: 159, y: 154), .init(x: 257, y: 116),
        .init(x: 280, y: 68),
      ], chapter: 3),
    Self(
      id: "last-lantern", name: "Last lantern", subtitle: "Bring every light back to the harbor.",
      start: .init(x: 69, y: 458), home: .init(x: 283, y: 72),
      boats: [
        .init(x: 184, y: 408), .init(x: 280, y: 335), .init(x: 172, y: 280),
        .init(x: 86, y: 195), .init(x: 183, y: 121),
      ],
      reefs: [
        Reef(id: 0, center: .init(x: 103, y: 329), radius: 37),
        Reef(id: 1, center: .init(x: 268, y: 202), radius: 39),
      ],
      currents: [
        Current(center: .init(x: 193, y: 352), radius: 82, force: .init(x: -6, y: 3)),
        Current(center: .init(x: 117, y: 159), radius: 65, force: .init(x: 3, y: 5)),
      ],
      fuel: 900,
      guide: [
        .init(x: 69, y: 458), .init(x: 184, y: 408), .init(x: 280, y: 335),
        .init(x: 172, y: 280), .init(x: 86, y: 195), .init(x: 183, y: 121),
        .init(x: 283, y: 72),
      ], chapter: 4),
  ]

  static func dateSeed(_ date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd"
    return formatter.string(from: date)
  }

  static func daily(seed: String, shift: Int) -> Self {
    let hash = seed.utf8.reduce(UInt64(5381)) { ($0 &* 33) &+ UInt64($1) }
    let original = campaign[(Int(hash % 4) + shift) % 4]
    let mirrored = (hash &+ UInt64(shift)) % 2 == 1
    func transform(_ p: SeaPoint) -> SeaPoint {
      mirrored ? SeaPoint(x: 360 - p.x, y: p.y) : p
    }
    return Self(
      id: "daily-\(seed)-\(shift)", name: "Daily harbor",
      subtitle: "Watch \(shift + 1) · same sea for everyone",
      start: transform(original.start), home: transform(original.home),
      boats: original.boats.map(transform),
      reefs: original.reefs.map {
        Reef(id: $0.id, center: transform($0.center), radius: $0.radius)
      },
      currents: original.currents.map {
        Current(
          center: transform($0.center), radius: $0.radius,
          force: SeaPoint(x: $0.force.x * (mirrored ? -1 : 1), y: $0.force.y))
      },
      fuel: max(HarborRules.routeLength(original.guide) * 1.12, original.fuel - Double(shift * 12)),
      guide: original.guide.map(transform), chapter: 0, dailySeed: seed, shift: shift)
  }
}

enum HarborRules {
  static let pickupRadius = 23.0
  static let dockRadius = 29.0
  static let hullRadius = 6.0

  static func routeLength(_ points: [SeaPoint]) -> Double {
    zip(points, points.dropFirst()).reduce(0) { $0 + $1.0.distance(to: $1.1) }
  }

  static func point(on route: [SeaPoint], distance: Double) -> SeaPoint {
    guard let first = route.first else { return .init(x: 0, y: 0) }
    var remaining = max(0, distance)
    var previous = first
    for next in route.dropFirst() {
      let length = previous.distance(to: next)
      if length > 0, remaining <= length {
        return previous + (next - previous) * (remaining / length)
      }
      remaining -= length
      previous = next
    }
    return previous
  }

  static func collides(_ point: SeaPoint, chart: HarborChart) -> Bool {
    point.x < 10 || point.x > 350 || point.y < 10 || point.y > 510
      || chart.reefs.contains { point.distance(to: $0.center) < $0.radius + hullRadius }
  }

  static func current(at point: SeaPoint, chart: HarborChart) -> SeaPoint {
    chart.currents.reduce(SeaPoint(x: 0, y: 0)) { value, current in
      let influence = max(0, 1 - point.distance(to: current.center) / current.radius)
      return value + current.force * influence
    }
  }

  static func score(rescued: Int, fuelRemaining: Double, routeLength: Double) -> Int {
    rescued * 250 + Int(max(0, fuelRemaining)) + max(0, 200 - Int(routeLength / 5))
  }
}
