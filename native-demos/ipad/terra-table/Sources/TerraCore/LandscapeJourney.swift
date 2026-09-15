import Foundation

public struct JourneyChapter: Sendable {
  public let title: String
  public let detail: String
  public let label: String
}

public struct JourneyFrame: Sendable {
  public let terrain: Terrain
  public let yaw: Float
  public let pitch: Float
  public let scale: Float
  public let contours: Float
}

public enum LandscapeJourney {
  public static let chapterDuration: Double = 14
  public static let chapters: [JourneyChapter] = [
    JourneyChapter(
      title: "Mountains rise.",
      detail: "From a quiet seabed to a snow-capped alpine spine.",
      label: "Uplift"),
    JourneyChapter(
      title: "A river finds its way.",
      detail: "A winding gorge cuts through the heart of the island.",
      label: "Carve"),
    JourneyChapter(
      title: "The coastline moves.",
      detail: "Rising water turns valleys into turquoise fjords.",
      label: "Inundate"),
    JourneyChapter(
      title: "A caldera opens.",
      detail: "The mountain folds into a ring around a volcanic lake.",
      label: "Caldera"),
    JourneyChapter(
      title: "Islands emerge.",
      detail: "One landmass becomes a chain of sculpted islands.",
      label: "Islands"),
    JourneyChapter(
      title: "Read the landscape.",
      detail: "Elevation contours reveal every ridge and shoreline.",
      label: "Survey"),
  ]
  public static let duration = chapterDuration * Double(chapters.count)

  private static let keyframes: [Terrain] = {
    var alpine = Terrain(landscape: .alpine)
    alpine.heights = alpine.heights.map { min(1.25, $0 * 1.42) }
    alpine.water = 0.19
    alpine.title = "Alpine uplift"

    var seabed = alpine
    seabed.heights = alpine.heights.map { 0.03 + $0 * 0.055 }
    seabed.title = "Quiet seabed"

    var gorge = alpine
    let n = Terrain.resolution
    for row in 0..<n {
      let z = Float(row) / Float(n - 1) * Terrain.extent - 5
      let center = sin(z * 0.90) * 0.95 + cos(z * 0.38) * 0.4
      for col in 0..<n {
        let x = Float(col) / Float(n - 1) * Terrain.extent - 5
        let distance = abs(x - center)
        let weight = exp(-distance * distance / 0.32)
        let index = row * n + col
        gorge.heights[index] = max(0.025, alpine.heights[index] * (1 - weight * 0.96))
      }
    }
    gorge.title = "The winding gorge"

    var flooded = gorge
    flooded.water = 0.53
    flooded.title = "Alpine fjords"

    var caldera = Terrain(landscape: .caldera)
    caldera.heights = caldera.heights.map { min(1.25, $0 * 1.52) }
    caldera.water = 0.31
    caldera.title = "The caldera"

    var islands = Terrain(landscape: .archipelago)
    islands.heights = islands.heights.map { min(1.25, $0 * 1.4) }
    islands.water = 0.26
    islands.title = "The island chain"
    return [seabed, alpine, gorge, flooded, caldera, islands, islands]
  }()

  public static func boundedTime(_ time: Double) -> Double {
    time.isFinite ? max(0, min(duration, time)) : 0
  }

  public static func chapterIndex(at time: Double) -> Int {
    min(chapters.count - 1, Int(boundedTime(time) / chapterDuration))
  }

  public static func frame(at time: Double) -> JourneyFrame {
    let time = boundedTime(time)
    let chapter = chapterIndex(at: time)
    let local = Float(time - Double(chapter) * chapterDuration)
    let amount = ease((local - 1) / 11)
    let from = keyframes[chapter]
    let to = keyframes[chapter + 1]
    var terrain = to
    terrain.heights = zip(from.heights, to.heights).enumerated().map { index, pair in
      let blend: Float
      if chapter == 1 {
        let row = Float(index / Terrain.resolution) / Float(Terrain.resolution - 1)
        blend = ease((amount * 1.3 - row) / 0.3)
      } else {
        blend = amount
      }
      return pair.0 + (pair.1 - pair.0) * blend
    }
    terrain.water = from.water + (to.water - from.water) * amount
    let progress = Float(time / duration)
    return JourneyFrame(
      terrain: terrain,
      yaw: .pi / 4 + progress * .pi * 2.1,
      pitch: 0.66 + sin(progress * .pi * 2 - 0.4) * 0.20,
      scale: 1.06 + sin(progress * .pi) * 0.06,
      contours: chapter == 5 ? ease(local / 5) : 0)
  }

  private static func ease(_ value: Float) -> Float {
    let t = max(0, min(1, value))
    return t * t * (3 - 2 * t)
  }
}
