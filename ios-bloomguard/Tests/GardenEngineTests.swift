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

@Test func endlessCapacityPreservesUncollectedValueAndBoundsCredits() {
  var game = Garden(endless: true, seed: 0)
  game.sunshine = 490
  game.drops = [Sunshine(id: 90, lane: 0, x: 0.5, amount: 25)]
  game.collect(90)
  #expect(game.sunshine == 500)
  #expect(game.drops.first?.amount == 15)
  game.collect()
  #expect(game.drops.first?.amount == 15)
  let planted = game.plant(.marigold, lane: 0, column: 0)
  #expect(planted)
  game.collect()
  #expect(game.sunshine == 465)
  #expect(game.drops.isEmpty)
  game.sunshine = 495
  game.remove(lane: 0, column: 0)
  #expect(game.sunshine == 500)
  game.schedule = []
  game.tick(0.1)
  #expect(game.sunshine == 500)
  #expect(game.wavesCleared == 1)

  var campaign = Garden(seed: 0)
  campaign.sunshine = 490
  campaign.drops = [Sunshine(id: 90, lane: 0, x: 0.5, amount: 50)]
  campaign.collect()
  #expect(campaign.sunshine == 540)
}

@Test func endlessPacksEscalateAcrossEveryLaneWithoutReadingTheGarden() {
  for seed in 0..<5 {
    var earlier = Garden(endless: true, seed: seed)
    earlier.wave = 4
    earlier.scheduleWave()
    var later = Garden(endless: true, seed: seed)
    later.wave = 10
    later.scheduleWave()
    for game in [earlier, later] {
      #expect(Set(game.schedule.map(\.lane)) == Set(0..<5))
      #expect(game.schedule[0].lane == game.schedule[1].lane)
      #expect(game.schedule[1].time - game.schedule[0].time < 1)
      #expect(game.schedule.first?.time == 6)
      #expect(game.schedule.last!.time < 50)
    }
    #expect(later.schedule.count > earlier.schedule.count * 2)
    #expect(later.pressure > earlier.pressure * 3)
    let earlierArmor = earlier.schedule.filter { $0.kind == .kettle }.count
    let laterArmor = later.schedule.filter { $0.kind == .kettle }.count
    #expect(laterArmor > earlierArmor * 2)
    let lanes = later.schedule.map(\.lane)
    later.sunshine = 0
    later.plants = [
      Defender(id: 100, seed: .bramble, lane: 4, column: 4, health: 650)
    ]
    later.scheduleWave()
    #expect(later.schedule.map(\.lane) == lanes)
  }
}

@Test func leanEndlessSkyPreservesSunbellProductionAndCampaignEconomy() {
  var endless = Garden(endless: true, seed: 0)
  endless.wave = 4
  endless.skyTime = 0
  endless.tick(0.1)
  #expect(endless.drops.first?.amount == 25)
  #expect(endless.skyTime == 9)
  endless.plants = [
    Defender(id: 100, seed: .marigold, lane: 0, column: 0, health: 140, timer: 9.95)
  ]
  endless.tick(0.1)
  #expect(endless.drops.last?.amount == 25)
  for level in 0..<4 {
    var campaign = Garden(level: level, seed: 0)
    campaign.wave = 3
    campaign.skyTime = 0
    campaign.tick(0.1)
    #expect(campaign.drops.first?.amount == 50)
    #expect(campaign.skyTime == 6.5)
    #expect(abs(campaign.pressure - (1 + Double(level) * 0.32)) < 0.0001)
  }
}
