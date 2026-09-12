import Foundation

enum GamePhase: Equatable {
  case playing, hurt, gameOver, completed
}

enum GameEvent: Equatable {
  case jump, coin, stomp, shield, checkpoint, hurt, finish
}

struct Game {
  let levelIndex: Int
  let level: Level
  var player = Point(x: 100, y: 90)
  var velocity = Point(x: 0, y: 0)
  var grounded = true
  var support: Int? = 0
  var direction = 0.0
  var jumpHeld = false
  var facing = 1.0
  var phase = GamePhase.playing
  var time = 0.0
  var score = 0
  var lives = 3
  var collected: Set<Int> = []
  var stomped: Set<Int> = []
  var shield = false
  var powerupTaken = false
  var checkpointActive = false
  var invincible = 0.0
  var coyote = 0.12
  var jumpBuffer = 0.0
  var events: [GameEvent] = []

  init(levelIndex: Int) {
    self.levelIndex = levelIndex
    level = Level.all[levelIndex]
  }

  var coinCount: Int { collected.count }
  var progress: Double { min(1, max(0, player.x / level.goal.x)) }
  var stars: Int {
    starGoals.filter { $0 }.count
  }

  var starGoals: [Bool] {
    guard phase == .completed else { return [false, false, false] }
    return [true, coinCount * 2 >= level.coins.count, lives == 3]
  }

  mutating func pressJump() {
    guard phase == .playing else { return }
    jumpHeld = true
    jumpBuffer = 0.14
  }

  mutating func releaseJump() {
    jumpHeld = false
    if velocity.y > 220 { velocity.y *= 0.48 }
  }

  mutating func clearInput() {
    direction = 0
    jumpHeld = false
    jumpBuffer = 0
  }

  mutating func respawn() {
    guard phase == .hurt else { return }
    player = checkpointActive ? level.checkpoint : Point(x: 100, y: 90)
    velocity = Point(x: 0, y: 0)
    grounded = false
    support = nil
    coyote = 0
    invincible = 2
    clearInput()
    phase = .playing
  }

  func bugPosition(_ index: Int, at clock: Double? = nil) -> Point {
    let bug = level.bugs[index]
    return Point(x: bug.x + sin((clock ?? time) * 1.2 + bug.phase) * bug.patrol, y: bug.y)
  }

  mutating func step(_ delta: Double) {
    events = []
    guard phase == .playing else { return }
    let dt = min(max(delta, 0), 1.0 / 30)
    let previousTime = time
    time += dt
    invincible = max(0, invincible - dt)
    jumpBuffer = max(0, jumpBuffer - dt)
    coyote = grounded ? 0.12 : max(0, coyote - dt)
    if let support, grounded {
      player.x +=
        level.ledges[support].offset(at: time) - level.ledges[support].offset(at: previousTime)
    }
    let target = direction * 250
    let acceleration = grounded ? 1900.0 : 1250.0
    velocity.x += min(max(target - velocity.x, -acceleration * dt), acceleration * dt)
    if abs(direction) > 0.1 { facing = direction > 0 ? 1 : -1 }
    if jumpBuffer > 0, coyote > 0 {
      velocity.y = 555
      grounded = false
      support = nil
      coyote = 0
      jumpBuffer = 0
      events.append(.jump)
    }
    let old = player
    velocity.y -= (velocity.y > 0 && jumpHeld ? 1060 : 1520) * dt
    player.x = min(max(16, player.x + velocity.x * dt), level.length)
    player.y += velocity.y * dt
    grounded = false
    support = nil
    if velocity.y <= 0 {
      for (index, ledge) in level.ledges.enumerated() {
        let left = ledge.x + ledge.offset(at: time)
        if player.x + 12 > left, player.x - 12 < left + ledge.width,
          old.y >= ledge.y - 1, player.y <= ledge.y
        {
          player.y = ledge.y
          velocity.y = 0
          grounded = true
          support = index
          break
        }
      }
    }
    for (index, coin) in level.coins.enumerated() where !collected.contains(index) {
      if abs(player.x - coin.x) < 25, abs(player.y + 24 - coin.y) < 33 {
        collected.insert(index)
        score += 50
        events.append(.coin)
      }
    }
    if !powerupTaken, abs(player.x - level.powerup.x) < 30,
      abs(player.y + 23 - level.powerup.y) < 37
    {
      powerupTaken = true
      shield = true
      score += 100
      events.append(.shield)
    }
    if !checkpointActive, abs(player.x - level.checkpoint.x) < 34,
      abs(player.y - level.checkpoint.y) < 70
    {
      checkpointActive = true
      score += 150
      events.append(.checkpoint)
    }
    for index in level.bugs.indices where !stomped.contains(index) {
      let bug = bugPosition(index)
      if abs(player.x - bug.x) < 29, player.y < bug.y + 27, player.y + 40 > bug.y {
        if velocity.y < 0, old.y >= bug.y + 21 {
          stomped.insert(index)
          velocity.y = jumpHeld ? 445 : 330
          player.y = bug.y + 29
          grounded = false
          support = nil
          score += 125
          events.append(.stomp)
        } else if invincible <= 0 {
          if shield {
            shield = false
            invincible = 2
            velocity.y = 260
            events.append(.shield)
          } else {
            hurt()
          }
        }
      }
    }
    if player.y < -100 { hurt() }
    if phase == .playing, player.x >= level.goal.x - 18, player.y < level.goal.y + 100 {
      score += max(0, 2000 - Int(time * 10))
      phase = .completed
      clearInput()
      events.append(.finish)
    }
  }

  mutating func hurt() {
    guard phase == .playing else { return }
    lives -= 1
    shield = false
    phase = lives > 0 ? .hurt : .gameOver
    clearInput()
    events.append(.hurt)
  }
}
