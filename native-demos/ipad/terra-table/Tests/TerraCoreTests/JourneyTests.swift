import Foundation
import TerraCore
import Testing

@Test func journeyRemainsValidAndDeterministic() {
  for time in stride(from: 0.0, through: LandscapeJourney.duration, by: 0.5) {
    let frame = LandscapeJourney.frame(at: time)
    #expect(frame.terrain.isValid)
    #expect(frame.terrain == LandscapeJourney.frame(at: time).terrain)
    #expect(frame.yaw.isFinite && frame.pitch.isFinite && frame.scale.isFinite)
    #expect((0...1).contains(frame.contours))
  }
  #expect(LandscapeJourney.frame(at: -.infinity).terrain == LandscapeJourney.frame(at: 0).terrain)
  #expect(LandscapeJourney.chapterIndex(at: .nan) == 0)
  #expect(LandscapeJourney.chapterIndex(at: 1e10) == 5)
}

@Test func journeyActuallyRaisesCarvesAndFloods() {
  let seabed = LandscapeJourney.frame(at: 0).terrain
  let alpine = LandscapeJourney.frame(at: 14).terrain
  let gorge = LandscapeJourney.frame(at: 28).terrain
  let flood = LandscapeJourney.frame(at: 42).terrain
  #expect(seabed.landPercent == 0)
  #expect(alpine.summit > 1000)
  #expect(alpine.landPercent > 20)
  #expect(zip(alpine.heights, gorge.heights).filter { $1 < $0 - 0.05 }.count > 500)
  #expect(zip(alpine.heights, gorge.heights).allSatisfy { $1 <= $0 + 0.00001 })
  #expect(gorge.heights == flood.heights)
  #expect(flood.water > gorge.water)
  #expect(flood.landPercent < gorge.landPercent)
  #expect(LandscapeJourney.frame(at: 84).contours == 1)
}

@Test func journeyBoundariesAndCameraAreContinuous() {
  for boundary in stride(from: 14.0, through: 70.0, by: 14) {
    let before = LandscapeJourney.frame(at: boundary - 0.001)
    let after = LandscapeJourney.frame(at: boundary + 0.001)
    let maxChange =
      zip(before.terrain.heights, after.terrain.heights)
      .map { abs($0 - $1) }.max() ?? 0
    #expect(maxChange < 0.001)
    #expect(abs(before.terrain.water - after.terrain.water) < 0.001)
    #expect(abs(before.yaw - after.yaw) < 0.001)
    #expect(abs(before.pitch - after.pitch) < 0.001)
  }
}
