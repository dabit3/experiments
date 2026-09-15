import XCTest

final class TouchControlsTests: XCTestCase {
  func testNativeControlPath() {
    let app = XCUIApplication()
    app.launchArguments = ["--guest", "Touch", "--room", "TOUCH", "--connect"]
    app.launch()
    XCTAssertTrue(app.buttons["ready"].waitForExistence(timeout: 15))
    app.buttons["ready"].tap()
    XCTAssertTrue(app.buttons["punch"].waitForExistence(timeout: 20))
    sleep(3)
    app.buttons["move-right"].press(forDuration: 0.6)
    app.buttons["punch"].tap()
    app.buttons["kick"].tap()
    app.buttons["guard"].press(forDuration: 0.6)
    app.buttons["step-up"].press(forDuration: 0.4)
    app.buttons["launch"].tap()
    sleep(1)
    app.buttons["tag"].tap()
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Native touch input path"
    screenshot.lifetime = .keepAlways
    add(screenshot)
    XCTAssertTrue(app.staticTexts["peer-status"].exists)
  }
}
