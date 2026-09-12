import Foundation

public enum GamePhase: Sendable { case ready, playing, paused, lifeLost, cleared, over }
public enum GameEvent: Sendable {
  case pellet, power
  case rival(Int)
  case hit, clear
}

public struct Runner: Sendable {
  public var tile: Tile
  public var next: Tile?
  public var progress: Double = 0
  public var direction: Direction = .left
  public init(tile: Tile) { self.tile = tile }
  public func position(width: Int) -> (x: Double, y: Double) {
    guard let next else { return (Double(tile.x), Double(tile.y)) }
    var dx = Double(next.x - tile.x)
    if abs(dx) > 1 { dx = direction == .left ? -1 : 1 }
    return (Double(tile.x) + dx * progress, Double(tile.y) + Double(next.y - tile.y) * progress)
  }
}

public struct Rival: Sendable {
  public var runner: Runner
  public var release: Double
  public var returning = false
  public let identity: Int
}

public struct Game: Sendable {
  public internal(set) var maze: Maze
  public internal(set) var player: Runner
  public internal(set) var rivals: [Rival] = []
  public internal(set) var pellets: Set<Tile>
  public internal(set) var powers: Set<Tile>
  public internal(set) var phase: GamePhase = .ready
  public internal(set) var score = 0
  public internal(set) var lives = 3
  public internal(set) var level: Int
  public internal(set) var frightened = 0.0
  public internal(set) var combo = 0
  public internal(set) var grace = 0.0
  public internal(set) var elapsed = 0.0
  public internal(set) var phaseTime = 1.6
  public internal(set) var queued: Direction = .left
  public internal(set) var events: [GameEvent] = []
  public internal(set) var lastBonus = 0
  public internal(set) var bonusTime = 0.0
  public internal(set) var hitTime = 0.0
  public internal(set) var lastHit: Runner?
  private var random: UInt64
  private var beforePause: GamePhase = .playing
  public var scatter: Bool { elapsed.truncatingRemainder(dividingBy: 27) < 7 }
  public var remaining: Int { pellets.count + powers.count }
  public var collected: Int { maze.pellets.count + maze.powers.count - remaining }

  public init(level: Int = 1, seed: UInt64 = 42) {
    self.level = level
    maze = Maze(index: level - 1)
    player = Runner(tile: maze.spawn)
    pellets = maze.pellets
    powers = maze.powers
    random = max(1, seed)
    resetActors()
  }

  public mutating func steer(_ direction: Direction) {
    queued = direction
    if direction == player.direction.opposite, let next = player.next {
      let tile = player.tile
      player.tile = next
      player.next = tile
      player.progress = 1 - player.progress
      player.direction = direction
    }
  }

  public mutating func pause() {
    guard [.playing, .ready, .lifeLost].contains(phase) else { return }
    beforePause = phase
    phase = .paused
  }

  public mutating func resume() {
    guard phase == .paused else { return }
    phase = beforePause
  }

  public mutating func nextLevel() {
    guard phase == .cleared else { return }
    let oldScore = score
    let oldLives = lives
    self = Game(level: level + 1, seed: random)
    score = oldScore
    lives = min(5, oldLives + 1)
  }

  public mutating func update(_ delta: Double) {
    events = []
    guard phase != .paused else { return }
    let dt = min(max(delta, 0), 1.0 / 30)
    hitTime = max(0, hitTime - dt)
    guard phase != .over && phase != .cleared else { return }
    if phase == .ready || phase == .lifeLost {
      phaseTime -= dt
      if phaseTime <= 0 { phase = .playing }
      return
    }
    elapsed += dt
    frightened = max(0, frightened - dt)
    grace = max(0, grace - dt)
    bonusTime = max(0, bonusTime - dt)
    movePlayer(dt)
    collect()
    if remaining == 0 {
      phase = .cleared
      score += 1000
      events.append(.clear)
      return
    }
    for index in rivals.indices {
      moveRival(index, dt)
    }
    resolveCollisions()
  }

  private mutating func resetActors() {
    player = Runner(tile: maze.spawn)
    queued = .left
    frightened = 0
    combo = 0
    grace = 2.5
    elapsed = 0
    rivals = (0..<4).map {
      Rival(
        runner: Runner(tile: Tile(8 + ($0 % 3), 9 + ($0 / 3))),
        release: Double($0) * 2.0 + 2.0, identity: $0)
    }
  }

  private mutating func movePlayer(_ dt: Double) {
    if player.next == nil {
      if let next = maze.neighbor(player.tile, queued) {
        player.direction = queued
        player.next = next
      } else {
        player.next = maze.neighbor(player.tile, player.direction)
      }
    }
    guard player.next != nil else { return }
    player.progress += dt * (5.7 + min(Double(level - 1) * 0.2, 1.0))
    if player.progress >= 1 {
      player.tile = player.next!
      player.next = nil
      player.progress = 0
    }
  }

  internal mutating func collect() {
    if pellets.remove(player.tile) != nil {
      score += 10
      events.append(.pellet)
    }
    if powers.remove(player.tile) != nil {
      score += 50
      frightened = max(6, 10 - Double(level - 1) * 0.5)
      combo = 0
      for index in rivals.indices where !rivals[index].returning {
        let runner = rivals[index].runner
        if let next = runner.next {
          rivals[index].runner.tile = next
          rivals[index].runner.next = runner.tile
          rivals[index].runner.progress = 1 - runner.progress
        }
        rivals[index].runner.direction = runner.direction.opposite
      }
      events.append(.power)
    }
  }

  private mutating func moveRival(_ index: Int, _ dt: Double) {
    rivals[index].release = max(0, rivals[index].release - dt)
    guard rivals[index].release == 0 else { return }
    if rivals[index].runner.next == nil {
      let tile = rivals[index].runner.tile
      if rivals[index].returning && tile == maze.home {
        rivals[index].returning = false
        rivals[index].release = 2.5
        return
      }
      let target = target(for: index)
      let distances = maze.distanceMap(to: target)
      let runner = rivals[index].runner
      var options = Direction.allCases.filter { maze.neighbor(tile, $0) != nil }
      if options.count > 1 {
        options.removeAll { $0 == runner.direction.opposite }
      }
      random = random &* 6_364_136_223_846_793_005 &+ 1
      let direction: Direction
      if frightened > 0 && !rivals[index].returning {
        direction = options[Int(random >> 33) % options.count]
      } else {
        direction = options.min {
          distances[maze.neighbor(tile, $0)!, default: 999]
            < distances[maze.neighbor(tile, $1)!, default: 999]
        }!
      }
      rivals[index].runner.direction = direction
      rivals[index].runner.next = maze.neighbor(tile, direction)
    }
    let speed =
      rivals[index].returning
      ? 9.0
      : frightened > 0 ? 3.0 : 4.1 + min(Double(level - 1) * 0.25, 1.5)
    rivals[index].runner.progress += dt * speed
    if rivals[index].runner.progress >= 1 {
      rivals[index].runner.tile = rivals[index].runner.next!
      rivals[index].runner.next = nil
      rivals[index].runner.progress = 0
    }
  }

  private func target(for index: Int) -> Tile {
    if rivals[index].returning { return maze.home }
    let corners = [Tile(17, 1), Tile(1, 1), Tile(17, 19), Tile(1, 19)]
    if scatter { return corners[index] }
    switch index {
    case 0: return player.tile
    case 1:
      return Tile(player.tile.x + player.direction.dx * 4, player.tile.y + player.direction.dy * 4)
    case 2:
      let ahead = Tile(
        player.tile.x + player.direction.dx * 2, player.tile.y + player.direction.dy * 2)
      return Tile(ahead.x * 2 - rivals[0].runner.tile.x, ahead.y * 2 - rivals[0].runner.tile.y)
    default:
      return rivals[index].runner.tile.distance(to: player.tile) > 7 ? player.tile : corners[index]
    }
  }

  internal mutating func resolveCollisions() {
    let position = player.position(width: maze.width)
    for index in rivals.indices where !rivals[index].returning && rivals[index].release == 0 {
      let other = rivals[index].runner.position(width: maze.width)
      let dx = abs(position.x - other.x)
      let wrapped = min(dx, Double(maze.width) - dx)
      guard hypot(wrapped, position.y - other.y) < 0.65 else { continue }
      if frightened > 0 {
        combo += 1
        lastBonus = 200 * (1 << min(combo - 1, 3))
        score += lastBonus
        bonusTime = 1.2
        rivals[index].returning = true
        events.append(.rival(lastBonus))
      } else if grace <= 0 {
        lives -= 1
        lastHit = player
        hitTime = 1.1
        events.append(.hit)
        if lives == 0 {
          phase = .over
        } else {
          resetActors()
          phase = .lifeLost
          phaseTime = 2.3
        }
        return
      }
    }
  }
}
