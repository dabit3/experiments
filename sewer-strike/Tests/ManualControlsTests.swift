import XCTest

final class ManualControlsTests: XCTestCase {
  func testTouchControlPath() {
    let app = XCUIApplication()
    app.launchArguments = [
      "-server", "ws://127.0.0.1:8767", "-room", "TOUCH",
      "-guest", "Touch", "-hero", "0", "-connect", "-create", "-testMode",
    ]
    app.launch()
    let ready = app.buttons["ready"]
    XCTAssertTrue(ready.waitForExistence(timeout: 20))
    ready.tap()
    let strike = app.buttons["strike"]
    XCTAssertTrue(
      strike.waitForExistence(timeout: 45), "Start a second guest in room TOUCH and ready it")
    app.buttons["Move right"].press(forDuration: 0.8)
    app.buttons["Move down"].press(forDuration: 0.35)
    app.buttons["jump"].tap()
    strike.tap()
    app.buttons["special"].tap()
    let stats = app.staticTexts["inputStats"]
    let predicate = NSPredicate(format: "label CONTAINS 'J1' AND label CONTAINS 'S1'")
    expectation(for: predicate, evaluatedWith: stats)
    waitForExpectations(timeout: 8)
    XCTAssertTrue(
      stats.label.contains("A1"), "Server accepted an attack through the real touch path")
    app.buttons["Game menu"].tap()
    app.buttons["RECONNECT SAME HERO"].tap()
    XCTAssertTrue(strike.waitForExistence(timeout: 15))
    XCTAssertTrue(stats.label.contains("J1"), "Reconnect retained authoritative hero stats")
  }
}
