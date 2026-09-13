import XCTest

final class HiveSovereignUITests: XCTestCase {
  func testLobbyAndManual() {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.textFields["guestName"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.textFields["serverAddress"].exists)
    app.buttons["help"].tap()
    XCTAssertTrue(app.staticTexts["FIELD MANUAL"].exists)
    app.buttons["CLOSE  ×"].tap()
    XCTAssertTrue(app.buttons["joinRoom"].exists)
    app.buttons["joinRoom"].tap()
    XCTAssertTrue(app.staticTexts["Enter your opponent’s room code."].exists)
  }
}
