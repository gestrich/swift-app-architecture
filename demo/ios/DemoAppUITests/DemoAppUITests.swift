import XCTest

final class DemoAppUITests: XCTestCase {
    func testGenerateGreetingFlow() {
        let app = XCUIApplication()
        app.launch()

        let nameField = app.textFields["Your name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Bill")

        let button = app.buttons["Generate Greeting"]
        XCTAssertTrue(button.isEnabled)
        button.tap()

        let predicate = NSPredicate(format: "label ENDSWITH %@", "Bill!")
        let greeting = app.staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(greeting.waitForExistence(timeout: 5))
    }
}
