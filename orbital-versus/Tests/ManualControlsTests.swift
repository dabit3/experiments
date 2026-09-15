import XCTest

final class ManualControlsTests: XCTestCase {
  func testManualControlPath() {
    let app = XCUIApplication()
    app.launchArguments = [
      "--server", "ws://127.0.0.1:8787", "--room", "UITEST", "--name", "TOUCH", "--join",
      "--auto-ready",
    ]
    app.launch()
    XCUIDevice.shared.orientation = .landscapeLeft
    let fire = app.buttons["FIRE"]
    XCTAssertTrue(
      fire.waitForExistence(timeout: 45), "Launch a second pilot in UITEST and ready it.")
    fire.tap()
    app.buttons["LOCK"].tap()
    let boost = app.buttons["BOOST"]
    XCTAssertTrue(boost.exists)
    boost.press(forDuration: 1.3)
    let stick = app.otherElements["JOYSTICK"]
    let start = stick.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let end = stick.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.06))
    start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 1.5)
    app.buttons["STEP"].tap()
    app.buttons["SABER"].tap()
    app.buttons["GUARD"].press(forDuration: 0.8)
    fire.tap()
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Manual native controls exercised"
    attachment.lifetime = .keepAlways
    add(attachment)
    XCTAssertTrue(fire.exists)
  }
}
