import XCTest

final class FestivalDonUITests: XCTestCase {
    func testWelcomeValidationAndCalibration() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["create-room"].waitForExistence(timeout: 10))
        app.buttons["join-room"].tap()
        XCTAssertTrue(app.staticTexts["Enter the six-character room code."].exists)
        app.buttons["Dismiss"].tap()
        app.buttons["calibration"].tap()
        XCTAssertTrue(app.buttons["calibration-tap"].waitForExistence(timeout: 3))
        app.buttons["Reset"].tap()
        XCTAssertTrue(app.staticTexts["0 ms"].exists)
        app.buttons["calibration-done"].tap()
        XCTAssertTrue(app.buttons["create-room"].exists)
    }
}
