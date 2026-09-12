import XCTest

@testable import Breakwater

final class HarborRulesTests: XCTestCase {
  func testRouteInterpolationHandlesCornersAndDuplicatePoints() {
    let points = [SeaPoint(x: 0, y: 0), .init(x: 0, y: 0), .init(x: 30, y: 0), .init(x: 30, y: 40)]
    XCTAssertEqual(HarborRules.routeLength(points), 70)
    XCTAssertEqual(HarborRules.point(on: points, distance: 50), .init(x: 30, y: 20))
    XCTAssertEqual(HarborRules.point(on: points, distance: 200), .init(x: 30, y: 40))
    XCTAssertEqual(HarborRules.point(on: points, distance: -2), .init(x: 0, y: 0))
  }

  func testReefCollisionIncludesHullClearance() {
    let chart = HarborChart.campaign[0]
    let reef = chart.reefs[0]
    XCTAssertTrue(HarborRules.collides(reef.center, chart: chart))
    XCTAssertTrue(HarborRules.collides(reef.center + .init(x: reef.radius + 5, y: 0), chart: chart))
    XCTAssertFalse(
      HarborRules.collides(reef.center + .init(x: reef.radius + 7, y: 0), chart: chart))
    XCTAssertTrue(HarborRules.collides(.init(x: 4, y: 200), chart: chart))
  }

  func testDailySeedIsUTCAndRepeatable() {
    let date = Date(timeIntervalSince1970: 1_789_171_200)
    XCTAssertEqual(HarborChart.dateSeed(date), "20260912")
    let a = HarborChart.daily(seed: "20260912", shift: 7)
    let b = HarborChart.daily(seed: "20260912", shift: 7)
    XCTAssertEqual(a.guide, b.guide)
    XCTAssertEqual(a.boats, b.boats)
    XCTAssertEqual(a.fuel, b.fuel)
    XCTAssertNotEqual(a.id, HarborChart.daily(seed: "20260913", shift: 7).id)
  }

  func testCurrentsFadeOutsideTheirZone() {
    let chart = HarborChart.campaign[1]
    let current = chart.currents[0]
    XCTAssertEqual(HarborRules.current(at: current.center, chart: chart), current.force)
    XCTAssertEqual(HarborRules.current(at: .init(x: 0, y: 0), chart: chart), .init(x: 0, y: 0))
  }

  func testScoreRewardsRescueAndFuelWithoutNegativeBonuses() {
    XCTAssertEqual(HarborRules.score(rescued: 3, fuelRemaining: 100, routeLength: 500), 950)
    XCTAssertEqual(HarborRules.score(rescued: 1, fuelRemaining: -10, routeLength: 2000), 250)
  }
}

@MainActor
final class HarborVoyageTests: XCTestCase {
  private func model() -> HarborModel {
    let defaults = UserDefaults(suiteName: "breakwater-tests-\(UUID().uuidString)")!
    let model = HarborModel(defaults: defaults)
    model.sound = false
    model.haptics = false
    return model
  }

  private func plot(_ points: [SeaPoint], model: HarborModel) {
    for point in points {
      model.draw(point)
      model.endDrawing()
    }
  }

  private func finish(_ model: HarborModel) {
    for _ in 0..<2400 where model.phase == .sailing { model.step(1.0 / 30) }
  }

  func testAllAuthoredChartsAreWinnableWithFullConvoy() {
    for chart in HarborChart.campaign {
      let model = model()
      model.select(chart)
      plot(chart.guide, model: model)
      model.launch()
      finish(model)
      XCTAssertEqual(model.phase, .won, "\(chart.name): \(model.failure)")
      XCTAssertEqual(model.convoy.count, chart.boats.count)
      XCTAssertGreaterThan(model.remaining, 0)
      XCTAssertGreaterThan(model.score, chart.boats.count * 250)
    }
  }

  func testDailyMirrorsAndLateWatchesRemainAchievable() {
    for seed in ["20260912", "20260913"] {
      for shift in [0, 1, 2, 3, 40] {
        let model = model()
        model.select(.daily(seed: seed, shift: shift))
        plot(model.chart.guide, model: model)
        model.launch()
        finish(model)
        XCTAssertEqual(model.phase, .won, "\(seed) watch \(shift): \(model.failure)")
      }
    }
  }

  func testCollisionEndsVoyageAndRetryPreservesEditableRoute() {
    let model = model()
    plot([model.chart.start, model.chart.reefs[0].center], model: model)
    let route = model.route
    model.launch()
    finish(model)
    XCTAssertEqual(model.phase, .lost)
    XCTAssertTrue(model.failure.contains("reef"))
    model.reset(keepRoute: true)
    XCTAssertEqual(model.phase, .plotting)
    XCTAssertEqual(model.route, route)
    XCTAssertEqual(model.convoy.count, 0)
    XCTAssertEqual(model.fuelUsed, 0)
  }

  func testArrivingWithoutRescuesIsNotSuccess() {
    let model = model()
    plot(
      [model.chart.start, .init(x: 326, y: 448), .init(x: 338, y: 75), model.chart.home],
      model: model)
    model.launch()
    finish(model)
    XCTAssertEqual(model.phase, .lost)
    XCTAssertFalse(model.allRescued)
  }

  func testFuelExhaustionIsFailure() {
    let model = model()
    var points = [model.chart.start]
    for _ in 0..<12 {
      points.append(.init(x: 240, y: 450))
      points.append(model.chart.start + .init(x: 0, y: -2))
    }
    plot(points, model: model)
    XCTAssertFalse(model.routeFits)
    model.launch()
    finish(model)
    XCTAssertEqual(model.phase, .lost)
    XCTAssertTrue(model.failure.contains("Fuel"))
  }

  func testPauseFreezesAndUndoRestoresPreviousStroke() {
    let model = model()
    let start = model.chart.start
    model.draw(start)
    model.draw(.init(x: 90, y: 390))
    model.draw(.init(x: 96, y: 337))
    model.endDrawing()
    let firstStroke = model.route
    model.draw(.init(x: 233, y: 260))
    model.endDrawing()
    model.undo()
    XCTAssertEqual(model.route, firstStroke)
    model.launch()
    model.step(0.03)
    model.pause()
    let point = model.tug
    model.step(0.05)
    XCTAssertEqual(model.tug, point)
    model.resume()
    model.step(0.03)
    XCTAssertNotEqual(model.tug, point)
  }

  func testProgressAndSettingsPersistAcrossRelaunch() {
    let defaults = UserDefaults(suiteName: "breakwater-progress-\(UUID().uuidString)")!
    let first = HarborModel(defaults: defaults)
    first.sound = false
    first.haptics = false
    plot(first.chart.guide, model: first)
    first.launch()
    finish(first)
    let second = HarborModel(defaults: defaults)
    XCTAssertEqual(second.unlocked, 2)
    XCTAssertEqual(second.best[first.chart.id], first.score)
    XCTAssertFalse(second.sound)
    XCTAssertFalse(second.haptics)
    XCTAssertTrue(second.hasLearned)
  }
}
