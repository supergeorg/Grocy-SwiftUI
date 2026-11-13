//
//  MDLocationUITests.swift
//  Grocy MobileUITests
//
//  Created by Georg Meißner on 13.11.26.
//

import XCTest

/// UI tests for the master data locations screens against a local Grocy test server (see `GrocyUITestCase`).
///
/// They check the design and accessibility rules the screens follow (HIG): status spelled out in text,
/// labeled toggles and buttons, and no validation error before the first edit.
/// Each test attaches screenshots, so the layout can be reviewed per platform in the test report.
final class MDLocationUITests: GrocyUITestCase {
    private var disabledName: String { "UITest disabled \(runID)" }
    private var freezerName: String { "UITest freezer \(runID)" }

    override func setUp() async throws {
        try await super.setUp()
        try await createObject("locations", ["name": disabledName, "description": "Basement shelf", "active": 0, "is_freezer": 0])
        try await createObject("locations", ["name": freezerName, "description": "", "active": 1, "is_freezer": 1])
    }

    // MARK: - Tests

    @MainActor
    func testListSpellsOutStatusInText() throws {
        let app = launchApp()
        openMasterData("Locations", in: app)

        // A disabled location says so in text, not only with a dimmed color.
        let disabledRow = element(in: app, labelContaining: disabledName)
        XCTAssertTrue(disabledRow.waitForExistence(timeout: 10), "The disabled location isn't listed.")
        XCTAssertTrue(disabledRow.label.contains("Disabled"), "The disabled row reads \"\(disabledRow.label)\".")

        // The freezer symbol has a VoiceOver label.
        let freezerRow = element(in: app, labelContaining: freezerName)
        XCTAssertTrue(freezerRow.exists, "The freezer location isn't listed.")
        XCTAssertTrue(freezerRow.label.contains("Freezer"), "The freezer row reads \"\(freezerRow.label)\".")

        attachScreenshot(of: app, named: "Locations list")
    }

    @MainActor
    func testEditFormControlsAreLabeled() throws {
        let app = launchApp()
        openMasterData("Locations", in: app)

        let freezerRow = element(in: app, labelContaining: freezerName)
        XCTAssertTrue(freezerRow.waitForExistence(timeout: 10))
        press(freezerRow)
        attachScreenshot(of: app, named: "After opening the freezer location")

        // Toggles carry their own label, so VoiceOver says what is switched.
        for title in ["Active", "Is freezer"] {
            let toggle = self.toggle(in: app, labeled: title)
            XCTAssertTrue(toggle.waitForExistence(timeout: 5), "No toggle labeled \"\(title)\".")
        }
        XCTAssertTrue(isOn(toggle(in: app, labeled: "Is freezer")), "The freezer location should have \"Is freezer\" switched on.")

        // The description editor is named, too.
        XCTAssertTrue(app.textViews["Description"].firstMatch.exists, "No text editor labeled \"Description\".")

        // The info icon is a real button with a label.
        let infoButton = app.buttons["Details"].firstMatch
        XCTAssertTrue(infoButton.exists, "The info icon isn't a button labeled \"Details\".")
        XCTAssertTrue(infoButton.isHittable)

        attachScreenshot(of: app, named: "Edit location")

        press(infoButton)
        let explanation = element(in: app, labelContaining: "freezer location, the products due date is automatically adjusted")
        XCTAssertTrue(explanation.waitForExistence(timeout: 5), "The info popover doesn't show the explanation.")
        attachScreenshot(of: app, named: "Edit location – info popover")
    }

    @MainActor
    func testCreateFormShowsValidationOnlyAfterEditing() throws {
        let app = launchApp()
        openMasterData("Locations", in: app)

        let createButton = app.buttons["Create location"].firstMatch
        XCTAssertTrue(createButton.waitForExistence(timeout: 10))
        press(createButton)
        attachScreenshot(of: app, named: "After clicking Create location")

        // The field is named by its description, so VoiceOver says what to enter.
        let nameField = app.textFields["Name"].firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "No text field labeled \"Name\".")
        // "Required" is the field's placeholder, not a separate label next to it.
        let requiredLabel = app.staticTexts.matching(NSPredicate(format: "label == %@ OR value == %@", "Required", "Required")).firstMatch
        XCTAssertFalse(requiredLabel.exists, "\"Required\" is shown as a separate label.")
        let requiredMessage = element(in: app, labelContaining: "A name is required")
        XCTAssertFalse(requiredMessage.exists, "The empty form shouldn't start with an error.")
        attachScreenshot(of: app, named: "Create location – empty")

        press(nameField)
        nameField.typeText("x")
        nameField.typeText(XCUIKeyboardKey.delete.rawValue)
        XCTAssertTrue(requiredMessage.waitForExistence(timeout: 5), "Clearing the name should show \"A name is required\".")
        attachScreenshot(of: app, named: "Create location – name cleared")

        nameField.typeText(freezerName)
        XCTAssertTrue(element(in: app, labelContaining: "Name already exists").waitForExistence(timeout: 5), "A duplicate name should be reported.")
        attachScreenshot(of: app, named: "Create location – duplicate name")
    }
}
