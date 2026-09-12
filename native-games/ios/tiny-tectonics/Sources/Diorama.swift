import SwiftUI

enum Earth {
  static let paper = Color(hex: 0xF4EFDF)
  static let ink = Color(hex: 0x263D36)
  static let muted = Color(hex: 0x69776B)
  static let copper = Color(hex: 0xB65032)
  static let clay = Color(hex: 0xD98B61)
  static let sand = Color(hex: 0xE7CC97)
  static let teal = Color(hex: 0x258F88)
  static let gold = Color(hex: 0xE9AD42)
}

extension Color {
  init(hex: UInt32) {
    self.init(
      .sRGB, red: Double((hex >> 16) & 255) / 255,
      green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
  }
}

struct IslandProjection {
  let scale: CGFloat
  let origin: CGPoint

  init(level: Landscape, size: CGSize) {
    let xs = level.route.map { CGFloat($0.x - $0.y) * 49 }
    let ys = level.route.map { CGFloat($0.x + $0.y) * 27 }
    let minX = (xs.min() ?? 0) - 68
    let maxX = (xs.max() ?? 0) + 68
    let minY = (ys.min() ?? 0) - 108
    let maxY = (ys.max() ?? 0) + 65
    scale = min(size.width / (maxX - minX), size.height / (maxY - minY))
    origin = CGPoint(
      x: size.width / 2 - (minX + maxX) / 2 * scale,
      y: size.height / 2 - (minY + maxY) / 2 * scale)
  }

  func point(_ grid: GridPoint, height: Double = 0) -> CGPoint {
    CGPoint(
      x: origin.x + CGFloat(grid.x - grid.y) * 49 * scale,
      y: origin.y + (CGFloat(grid.x + grid.y) * 27 - height * 16) * scale)
  }
}

struct HeightVector: VectorArithmetic {
  var values: [Double]
  static let zero = HeightVector(values: [])
  static func + (lhs: HeightVector, rhs: HeightVector) -> HeightVector {
    HeightVector(
      values: (0..<max(lhs.values.count, rhs.values.count)).map {
        (lhs.values.indices.contains($0) ? lhs.values[$0] : 0)
          + (rhs.values.indices.contains($0) ? rhs.values[$0] : 0)
      })
  }
  static func - (lhs: HeightVector, rhs: HeightVector) -> HeightVector {
    lhs + HeightVector(values: rhs.values.map { -$0 })
  }
  mutating func scale(by rhs: Double) { values = values.map { $0 * rhs } }
  var magnitudeSquared: Double { values.reduce(0) { $0 + $1 * $1 } }
}

struct Diorama: View, Animatable {
  let level: Landscape
  let heights: [Int]
  var selected: Int? = nil
  var travel: Double = 0
  var running = false
  var celebration = false
  var onSelect: ((Int) -> Void)? = nil
  var terrain: HeightVector

  var animatableData: HeightVector {
    get { terrain }
    set { terrain = newValue }
  }

  init(
    level: Landscape, heights: [Int], selected: Int? = nil, travel: Double = 0,
    running: Bool = false, celebration: Bool = false, onSelect: ((Int) -> Void)? = nil
  ) {
    self.level = level
    self.heights = heights
    self.selected = selected
    self.travel = travel
    self.running = running
    self.celebration = celebration
    self.onSelect = onSelect
    terrain = HeightVector(values: heights.map(Double.init))
  }

  var body: some View {
    GeometryReader { geometry in
      let projection = IslandProjection(level: level, size: geometry.size)
      ZStack {
        Canvas { context, size in
          drawWorld(context: context, size: size, p: projection)
        }
        .accessibilityHidden(true)
        if let onSelect {
          ForEach(heights.indices, id: \.self) { index in
            let point = projection.point(level.route[index], height: terrain.values[index])
            Button {
              onSelect(index)
            } label: {
              Color.clear.contentShape(Rectangle())
            }
            .frame(width: 68 * projection.scale, height: 43 * projection.scale)
            .position(point)
            .accessibilityLabel(
              "Plate \(index + 1), elevation \(heights[index])\(level.fixed.contains(index) ? ", anchored" : "")"
            )
            .accessibilityHint("Select this terrain plate")
            .accessibilityIdentifier("plate-\(index + 1)")
          }
        }
      }
    }
  }

  private func drawWorld(context: GraphicsContext, size: CGSize, p: IslandProjection) {
    let s = p.scale
    func offset(_ point: CGPoint, _ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: point.x + x * s, y: point.y + y * s)
    }
    func polygon(_ points: [CGPoint]) -> Path {
      Path { path in
        path.addLines(points)
        path.closeSubpath()
      }
    }
    func diamond(_ center: CGPoint, _ width: CGFloat, _ height: CGFloat) -> Path {
      polygon([
        offset(center, 0, -height), offset(center, width, 0),
        offset(center, 0, height), offset(center, -width, 0),
      ])
    }
    let riverCenter = CGPoint(x: size.width * 0.48, y: size.height * 0.72)
    for ring in 0..<7 {
      let inset = CGFloat(ring) * 17 * s
      let rect = CGRect(
        x: riverCenter.x - 140 * s - inset, y: riverCenter.y - 43 * s - inset * 0.3,
        width: 280 * s + inset * 2, height: 86 * s + inset * 0.6)
      context.stroke(Path(ellipseIn: rect), with: .color(Earth.sand.opacity(0.28)), lineWidth: 0.7)
    }
    var river = Path()
    river.move(to: CGPoint(x: size.width * 0.04, y: size.height * 0.64))
    river.addCurve(
      to: CGPoint(x: size.width * 0.96, y: size.height * 0.82),
      control1: CGPoint(x: size.width * 0.65, y: size.height * 0.5),
      control2: CGPoint(x: size.width * 0.22, y: size.height * 1.0))
    context.stroke(
      river, with: .color(Color(hex: 0xBEDAD1)),
      style: StrokeStyle(lineWidth: 39 * s, lineCap: .round))
    context.stroke(
      river, with: .color(Color(hex: 0x86C5BA)),
      style: StrokeStyle(lineWidth: 23 * s, lineCap: .round))
    for ripple in 0..<15 {
      let t = Double(ripple) / 15 + 0.015
      let u = 1 - t
      let x =
        (u * u * u * 0.04 + 3 * u * u * t * 0.65 + 3 * u * t * t * 0.22 + t * t * t * 0.96)
        * size.width
      let y =
        (u * u * u * 0.64 + 3 * u * u * t * 0.5 + 3 * u * t * t * 1.0 + t * t * t * 0.82)
        * size.height
      let drift = CGFloat((ripple * 13) % 17 - 8) * s
      var current = Path()
      current.move(to: CGPoint(x: x - 4 * s, y: y + drift))
      current.addQuadCurve(
        to: CGPoint(x: x + CGFloat(3 + ripple % 5) * s, y: y + drift - 1),
        control: CGPoint(x: x, y: y + drift - 2 * s))
      context.stroke(current, with: .color(.white.opacity(0.45)), lineWidth: 0.9 * s)
      if ripple % 4 == 0 {
        let stone = CGPoint(x: x, y: y + 17 * s)
        context.fill(diamond(stone, 5 + CGFloat(ripple % 3), 3), with: .color(Earth.sand))
      }
    }

    for index in heights.indices {
      let base = p.point(level.route[index])
      context.drawLayer { shadow in
        shadow.addFilter(.blur(radius: 9 * s))
        shadow.fill(diamond(offset(base, 9, 28), 46, 22), with: .color(Earth.ink.opacity(0.18)))
      }
    }

    let order = heights.indices.sorted {
      level.route[$0].x + level.route[$0].y < level.route[$1].x + level.route[$1].y
    }
    for index in order {
      let top = p.point(level.route[index], height: terrain.values[index])
      let depth = terrain.values[index] * 7 + 24
      let west = offset(top, -44, 0)
      let south = offset(top, 0, 24)
      let east = offset(top, 44, 0)
      let weathering = CGFloat(index % 3)
      let leftRim = [west, offset(top, -29, 10 + weathering), offset(top, -17, 13), south]
      let rightRim = [south, offset(top, 15, 14 - weathering), offset(top, 31, 9), east]
      let rim = leftRim + rightRim.dropFirst()
      let plateau = polygon(
        rim + [offset(top, 28, -10), offset(top, 0, -24), offset(top, -26, -12)])
      let leftFace = polygon(leftRim + leftRim.reversed().map { offset($0, 0, depth) })
      let rightFace = polygon(rightRim + rightRim.reversed().map { offset($0, 0, depth) })
      context.fill(leftFace, with: .color(Earth.copper))
      context.fill(rightFace, with: .color(Earth.clay))
      for band in 1...4 {
        let d = depth * CGFloat(band) / 5
        var line = Path()
        line.addLines(
          rim.enumerated().map { step, point in
            offset(point, 0, d + sin(Double(step + band + index)) * 1.4)
          })
        context.stroke(
          line, with: .color(Earth.sand.opacity(band % 2 == 0 ? 0.55 : 0.25)),
          lineWidth: band % 2 == 0 ? CGFloat(2 + index % 2) * s : 1 * s)
      }
      context.fill(
        plateau,
        with: .linearGradient(
          Gradient(colors: [Color(hex: 0xF0DCAD), Color(hex: 0xDABA82)]),
          startPoint: offset(top, -30, -15), endPoint: offset(top, 30, 24)))
      for ring in 0..<3 {
        let contour = polygon(
          (0..<24).map { step in
            let angle = Double(step) * .pi / 12
            let variation = 1 + sin(angle * 3 + Double(index)) * 0.12
            return offset(
              top, -7 + cos(angle) * Double(31 - ring * 7) * variation,
              -4 + sin(angle) * Double(13 - ring * 3) * variation)
          })
        context.stroke(
          contour,
          with: .color(Color(hex: 0xB69B66).opacity(0.32)), lineWidth: 0.6 * s)
      }
      if selected == index {
        context.stroke(plateau, with: .color(Earth.teal.opacity(0.22)), lineWidth: 7 * s)
        context.stroke(plateau, with: .color(Earth.teal), lineWidth: 2.5 * s)
      }
      for rock in 0..<(1 + index % 3) {
        let center = offset(top, -12 + CGFloat(rock) * 6, -12 + CGFloat((rock + index) % 3))
        context.fill(diamond(center, 2.5, 1.8), with: .color(Color(hex: 0xA89A78).opacity(0.7)))
      }
      for tree in 0..<(index % 3 == 2 ? 1 : 2) {
        let trunk = offset(top, tree == 0 ? -24 : 23, tree == 0 ? -3 : -5)
        var stem = Path()
        stem.move(to: trunk)
        stem.addLine(to: offset(trunk, 0, -11))
        context.stroke(stem, with: .color(Earth.copper), lineWidth: 2 * s)
        for tier in 0..<3 {
          let y = CGFloat(tier) * CGFloat(-4 - index % 2)
          let width = CGFloat(5 + (index + tree) % 3 - tier)
          context.fill(
            polygon([
              offset(trunk, -width, y - 4), offset(trunk, width, y - 4), offset(trunk, 0, y - 15),
            ]),
            with: .color(tree == 0 ? Color(hex: 0x466E55) : Color(hex: 0x648263)))
        }
      }
    }

    for index in 1..<heights.count {
      let from = p.point(level.route[index - 1], height: terrain.values[index - 1])
      let to = p.point(level.route[index], height: terrain.values[index])
      let safe = SlopeRules.fault(from: heights[index - 1], to: heights[index]) == nil
      var route = Path()
      route.move(to: from)
      route.addLine(to: to)
      if safe {
        context.stroke(
          route, with: .color(Earth.copper.opacity(0.25)),
          style: StrokeStyle(lineWidth: 10 * s, lineCap: .round))
        context.stroke(
          route, with: .color(Color(hex: 0xFFF3D4)),
          style: StrokeStyle(lineWidth: 6 * s, lineCap: .round))
        context.stroke(
          route, with: .color(Earth.copper.opacity(0.35)),
          style: StrokeStyle(lineWidth: 0.8 * s, dash: [2 * s, 4 * s]))
      } else {
        context.stroke(
          route, with: .color(Earth.copper.opacity(0.5)),
          style: StrokeStyle(lineWidth: 1.5 * s, dash: [3 * s, 5 * s]))
        let center = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: center.x - 6 * s, y: center.y - 6 * s, width: 12 * s, height: 12 * s)),
          with: .color(Earth.copper))
        context.draw(
          Text("!").font(.system(size: 9 * s, weight: .heavy)).foregroundColor(.white), at: center)
      }
    }

    for index in heights.indices {
      let top = p.point(level.route[index], height: terrain.values[index])
      let badge = offset(top, 0, 16)
      let selectedPlate = selected == index
      context.fill(
        Path(
          ellipseIn: CGRect(x: badge.x - 8 * s, y: badge.y - 8 * s, width: 16 * s, height: 16 * s)),
        with: .color(selectedPlate ? Earth.teal : Earth.paper.opacity(0.9)))
      context.draw(
        Text("\(index + 1)").font(.system(size: 9 * s, weight: .bold, design: .rounded))
          .foregroundColor(selectedPlate ? .white : Earth.ink),
        at: badge)
      if level.fossils.contains(index), !running || travel < Double(index) {
        let gem = offset(top, 0, -11)
        context.fill(diamond(gem, 6, 9), with: .color(Earth.gold))
        context.fill(
          polygon([offset(gem, 0, -9), offset(gem, 6, 0), offset(gem, 0, 4)]),
          with: .color(Color(hex: 0xFFE2A1)))
        context.stroke(diamond(gem, 6, 9), with: .color(Earth.copper.opacity(0.5)), lineWidth: 0.7)
      }
    }

    let exit = p.point(level.route.last!, height: terrain.values.last!)
    let portal = offset(exit, 0, -15)
    context.fill(diamond(exit, 15, 8), with: .color(Earth.teal.opacity(0.25)))
    let arch = CGRect(x: portal.x - 10 * s, y: portal.y - 15 * s, width: 20 * s, height: 31 * s)
    context.stroke(Path(ellipseIn: arch), with: .color(Earth.teal), lineWidth: 5 * s)
    context.stroke(
      Path(ellipseIn: arch.insetBy(dx: 1 * s, dy: 1 * s)), with: .color(Color(hex: 0xB8E1C8)),
      lineWidth: 1.5 * s)

    let bounded = min(max(travel, 0), Double(heights.count - 1))
    let before = Int(bounded)
    let after = min(before + 1, heights.count - 1)
    let a = p.point(level.route[before], height: terrain.values[before])
    let b = p.point(level.route[after], height: terrain.values[after])
    let blend = bounded - Double(before)
    let explorer = CGPoint(x: a.x + (b.x - a.x) * blend, y: a.y + (b.y - a.y) * blend - 8 * s)
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: explorer.x - 10 * s, y: explorer.y + 5 * s, width: 22 * s, height: 8 * s)),
      with: .color(Earth.ink.opacity(0.2)))
    let sphere = Path(
      ellipseIn: CGRect(x: explorer.x - 9 * s, y: explorer.y - 9 * s, width: 18 * s, height: 18 * s)
    )
    context.fill(
      sphere,
      with: .radialGradient(
        Gradient(colors: [Color.white, Color(hex: 0xECE5C9), Color(hex: 0x9B9D86)]),
        center: offset(explorer, -3, -4), startRadius: 1, endRadius: 15 * s))
    context.stroke(sphere, with: .color(Earth.ink.opacity(0.2)), lineWidth: 0.7)
    let angle = travel * 7
    let speck = offset(explorer, cos(angle) * 5, sin(angle) * 5)
    context.fill(
      Path(ellipseIn: CGRect(x: speck.x - 2 * s, y: speck.y - 2 * s, width: 4 * s, height: 4 * s)),
      with: .color(Earth.copper))
    if running, before != after {
      for mote in 1...6 {
        let lag = max(0, blend - Double(mote) * 0.04)
        let dust = CGPoint(
          x: a.x + (b.x - a.x) * lag + sin(Double(mote) * 3) * 4 * s,
          y: a.y + (b.y - a.y) * lag - 2 * s)
        context.fill(
          Path(ellipseIn: CGRect(x: dust.x, y: dust.y, width: 2.5 * s, height: 2.5 * s)),
          with: .color(Earth.gold.opacity(0.7 - Double(mote) * 0.08)))
      }
    }
    if celebration {
      for dot in 0..<28 {
        let angle = Double(dot) * 2.399
        let radius = CGFloat(35 + (dot * 17) % 90) * s
        let point = CGPoint(
          x: exit.x + cos(angle) * radius, y: exit.y - 40 * s + sin(angle) * radius * 0.6)
        context.fill(
          diamond(point, 2, 3), with: .color(dot % 2 == 0 ? Earth.gold : Earth.teal.opacity(0.6)))
      }
    }
  }
}
