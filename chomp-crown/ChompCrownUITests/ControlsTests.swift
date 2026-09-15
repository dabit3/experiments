import XCTest

final class ControlsTests: XCTestCase {
  func testGuestFieldsAndHelp() {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.textFields["guest-name"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.textFields["server-address"].exists)
    app.buttons["HOW TO PLAY"].tap()
    XCTAssertTrue(app.staticTexts["RULE THE MAZE"].waitForExistence(timeout: 3))
    app.buttons["LET'S CHOMP"].tap()
    XCTAssertTrue(app.buttons["create-room"].exists)
  }
}
