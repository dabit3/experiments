import Testing

@testable import BloomguardRules

@Test func plantingIsTransactionalAndCooldownEnforced() {
  var game = Garden(seed: 0)
  let planted = game.plant(.peashooter, lane: 0, column: 1)
  #expect(planted)
  #expect(game.sunshine == 150)
  let cooling = game.plant(.peashooter, lane: 1, column: 1)
  #expect(!cooling)
  #expect(game.sunshine == 150)
  let occupied = game.plant(.marigold, lane: 0, column: 1)
  let outside = game.plant(.bramble, lane: 7, column: 2)
  #expect(!occupied)
  #expect(!outside)
  #expect(game.plants.count == 1)
}

@Test func sunshineCollectionAndCompostDoNotDuplicateValue() {
  var game = Garden(seed: 0)
  _ = game.plant(.marigold, lane: 0, column: 0)
  game.remove(lane: 0, column: 0)
  #expect(game.sunshine == 225)
  game.remove(lane: 0, column: 0)
  #expect(game.sunshine == 225)
  for _ in 0..<25 { game.tick(0.1) }
  let amount = game.drops.reduce(0) { $0 + $1.amount }
  game.collect()
  #expect(game.sunshine == 225 + amount)
  game.collect()
  #expect(game.sunshine == 225 + amount)
}

@Test func pauseFreezesAllSimulationState() {
  var game = Garden(seed: 1)
  game.togglePause()
  for _ in 0..<200 { game.tick(0.1) }
  #expect(game.elapsed == 0)
  #expect(game.pests.isEmpty)
  #expect(game.drops.isEmpty)
}

@Test func authoredWavesCoverLanesAndEscalate() {
  let morning = Garden(level: 0, seed: 3)
  let siege = Garden(level: 3, seed: 3)
  #expect(Set(morning.schedule.map(\.lane)) == Set(0..<5))
  #expect(morning.schedule.allSatisfy { $0.kind == .beetle && $0.time >= 17 })
  #expect(siege.schedule.count > morning.schedule.count)
  #expect(siege.schedule.contains { $0.kind == .kettle })
}

@Test func projectileKillsAndAwardsPointsOnlyOnce() {
  var game = Garden(seed: 0)
  game.pests = [Pest(id: 100, kind: .beetle, lane: 0, x: 3, health: 25)]
  game.shots = [Shot(id: 101, lane: 0, x: 2.7, icy: false)]
  game.tick(0.1)
  #expect(game.pests.isEmpty)
  #expect(game.score == 25)
  game.tick(0.1)
  #expect(game.score == 25)
}

@Test func frostSlowsAndExplosionRespectsRange() {
  var game = Garden(seed: 0)
  game.pests = [
    Pest(id: 50, kind: .kettle, lane: 1, x: 3.5, health: 300),
    Pest(id: 51, kind: .kettle, lane: 4, x: 3.5, health: 300),
  ]
  game.shots = [Shot(id: 52, lane: 1, x: 3.1, icy: true)]
  game.tick(0.1)
  #expect(game.pests[0].slow > 3)
  _ = game.plant(.ember, lane: 1, column: 3)
  for _ in 0..<16 { game.tick(0.1) }
  #expect(game.pests.count == 1)
  #expect(game.pests.first?.lane == 4)
  #expect(game.plants.isEmpty)
}

@Test func robinRescueAndLossCannotBeBypassed() {
  var game = Garden(seed: 0)
  game.pests = [Pest(id: 50, kind: .beetle, lane: 2, x: -0.2, health: 100)]
  game.tick(0.1)
  #expect(!game.rescuers.contains(2))
  #expect(game.phase == .playing)
  game.pests = [Pest(id: 51, kind: .beetle, lane: 2, x: -0.2, health: 100)]
  game.tick(0.1)
  #expect(game.phase == .lost)
}

@Test func campaignVictoryAndEndlessProgression() {
  var game = Garden(seed: 0)
  game.wave = 3
  game.schedule = []
  game.tick(0.1)
  #expect(game.phase == .won)
  #expect(game.wavesCleared == 1)
  var endless = Garden(endless: true, seed: 0)
  endless.schedule = []
  for _ in 0..<53 { endless.tick(0.1) }
  #expect(endless.wave == 2)
  #expect(endless.phase == .playing)
  #expect(!endless.schedule.isEmpty)
}

@Test func occupiedEnemyPlotsRejectPlantingAndBlockersKeepSeparation() {
  var game = Garden(seed: 0)
  game.pests = [Pest(id: 90, kind: .beetle, lane: 0, x: 4.3, health: 105)]
  let blocked = game.plant(.bramble, lane: 0, column: 4)
  #expect(!blocked)
  #expect(game.sunshine == 250)
  #expect(game.noticeIsError)
  let planted = game.plant(.bramble, lane: 0, column: 3)
  #expect(planted)
  for _ in 0..<40 { game.tick(0.1) }
  #expect(game.pests[0].x > 4.1)
  #expect(game.plants[0].health < Seed.bramble.health)
  #expect(game.plants[0].health > 0)
}

@Test func pressureAppliesToNewSpawnsWithoutChangingTheirRewards() {
  var game = Garden(endless: true, seed: 0)
  game.wave = 8
  game.scheduleWave()
  game.schedule = [Spawn(time: 0, lane: 0, kind: .kettle)]
  game.tick(0.1)
  #expect(game.pests[0].health == PestKind.kettle.health * game.pressure)
  #expect(game.pests[0].strength > 1)
  #expect(game.pests[0].kind.points == 90)
  #expect(Garden(level: 3, seed: 0).pressure > Garden(level: 0, seed: 0).pressure)
}

@Test func retiringRequiresPausedEndlessAndDoesNotAwardBonusOrAdvanceTime() {
  var campaign = Garden(seed: 0)
  campaign.togglePause()
  campaign.retire()
  #expect(campaign.phase == .paused)
  var endless = Garden(endless: true, seed: 0)
  endless.retire()
  #expect(endless.phase == .playing)
  endless.tick(0.1)
  endless.togglePause()
  let score = endless.score
  let elapsed = endless.elapsed
  let waves = endless.wavesCleared
  endless.retire()
  endless.tick(0.1)
  #expect(endless.finished)
  #expect(endless.phase == .retired)
  #expect(endless.score == score)
  #expect(endless.wavesCleared == waves)
  #expect(endless.elapsed == elapsed)
}
