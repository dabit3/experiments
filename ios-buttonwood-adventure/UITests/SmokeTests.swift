import XCTest

final class SmokeTests: XCTestCase {
  @MainActor
  func testTitleInstructionsAndPauseRoundTrip() {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.buttons["begin"].waitForExistence(timeout: 10))
    app.buttons["How to wander"].tap()
    XCTAssertTrue(app.staticTexts["A little know-how."].exists)
    app.buttons["Got it"].tap()
    app.buttons["begin"].tap()
    XCTAssertTrue(app.buttons["pause"].waitForExistence(timeout: 5))
    app.buttons["pause"].tap()
    XCTAssertTrue(app.staticTexts["The forest can wait."].exists)
    app.buttons["Keep wandering"].tap()
    XCTAssertTrue(app.buttons["pause"].exists)
  }
}
