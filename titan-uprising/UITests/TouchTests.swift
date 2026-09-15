import XCTest

final class TouchTests: XCTestCase {
  func testCardAndConnectionControls() {
    let app = XCUIApplication()
    app.launchArguments = ["--guest", "TouchTester"]
    app.launch()
    XCTAssertTrue(app.buttons["hero-0"].waitForExistence(timeout: 10))
    app.buttons["hero-0"].tap()
    XCTAssertFalse(app.buttons["create"].isEnabled)
    app.buttons["hero-3"].tap()
    XCTAssertTrue(app.buttons["create"].isEnabled)
    app.buttons["create"].tap()
    XCTAssertTrue(app.staticTexts["room-code"].waitForExistence(timeout: 10))
    app.buttons["ready"].tap()
    XCTAssertTrue(app.buttons["ready"].label.contains("CANCEL"))
    app.buttons["ready"].tap()
    app.buttons["leave"].tap()
    XCTAssertTrue(app.buttons["create"].waitForExistence(timeout: 5))
  }
}
