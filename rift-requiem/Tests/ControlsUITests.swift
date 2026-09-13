import XCTest

final class ControlsUITests: XCTestCase {
    func testManualLobbyControls() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["select-vesper"].waitForExistence(timeout: 10))
        app.buttons["select-vesper"].tap()
        app.buttons["select-rook"].tap()
        app.buttons["HOW TO FIGHT"].tap()
        XCTAssertTrue(app.staticTexts["THE DUELIST'S CODE"].exists)
        app.buttons["RETURN TO THE RIFT"].tap()
        XCTAssertTrue(app.textFields["SERVER ADDRESS"].exists)
        XCTAssertTrue(app.buttons["connect"].exists)
    }
}
