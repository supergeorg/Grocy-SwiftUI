//
//  MDLocationUITests.swift
//  Grocy MobileUITests
//
//  Created by Georg Meißner on 13.11.26.
//

import XCTest

/// UI tests for the master data locations screens against a local Grocy test server (see `TestServer/README.md`).
///
/// They check the design and accessibility rules the screens follow (HIG): status spelled out in text,
/// labeled toggles and buttons, and no validation error before the first edit.
/// Each test attaches screenshots, so the layout can be reviewed per platform in the test report.
///
/// The app is started with an in-memory store and logged in directly (`UITestConfiguration`),
/// so the tests never change the data or login of the app installed on this device.
/// Without `GROCY_TEST_SERVER_URL`, the tests are skipped.
final class MDLocationUITests: XCTestCase {
    private var serverURL: String = ""
    private var apiKey: String = ""
    private var createdLocationIDs: [Int] = []

    private let runID = UUID().uuidString.prefix(6)
    private var disabledName: String { "UITest disabled \(runID)" }
    private var freezerName: String { "UITest freezer \(runID)" }

    override func setUp() async throws {
        continueAfterFailure = false
        let environment = ProcessInfo.processInfo.environment
        guard let url = environment["GROCY_TEST_SERVER_URL"], !url.isEmpty else {
            throw XCTSkip("Set GROCY_TEST_SERVER_URL to run the UI tests against a Grocy server (see TestServer/README.md).")
        }
        serverURL = url
        apiKey = environment["GROCY_TEST_API_KEY"].flatMap { $0.isEmpty ? nil : $0 } ?? "grocy-mobile-integration-tests"

        createdLocationIDs.append(try await createLocation(name: disabledName, description: "Basement shelf", active: false, isFreezer: false))
        createdLocationIDs.append(try await createLocation(name: freezerName, description: "", active: true, isFreezer: true))
    }

    override func tearDown() async throws {
        for id in createdLocationIDs {
            try? await deleteLocation(id: id)
        }
        createdLocationIDs.removeAll()
    }

    // MARK: - Tests

    @MainActor
    func testListSpellsOutStatusInText() throws {
        let app = launchApp()
        openLocations(in: app)

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
        openLocations(in: app)

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
        openLocations(in: app)

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

    // MARK: - App helpers

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        // Launch arguments go to UserDefaults' argument domain, which isn't persisted.
        app.launchArguments += [
            "-onboardingNeeded", "NO",
            "-isLoggedIn", "YES",
            "-isDemoModus", "NO",
            "-localizationKey", "en",
            "-AppleLanguages", "(en)",
            // Pin the iPhone layout, whatever the simulator has stored.
            "-iPhoneTabNavigation", "YES",
        ]
        app.launchEnvironment["GROCY_UITEST_SERVER_URL"] = serverURL
        app.launchEnvironment["GROCY_UITEST_API_KEY"] = apiKey
        app.launch()
        return app
    }

    @MainActor
    private func openLocations(in app: XCUIApplication) {
        #if os(macOS)
            let sidebar = app.outlines["Sidebar"].firstMatch
            XCTAssertTrue(sidebar.waitForExistence(timeout: 10), "No sidebar.")
            // The row label also contains the number of entries, e.g. "Locations, 3".
            let locations = sidebar.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Locations")).firstMatch
            if !locations.exists {
                // The master data section starts collapsed, below the visible part of a small window.
                // Its disclosure chevron only appears while the pointer is over the header.
                sidebar.scroll(byDeltaX: 0, deltaY: -1000)
                let masterData = sidebar.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Master data")).firstMatch
                XCTAssertTrue(masterData.waitForExistence(timeout: 10), "No \"Master data\" section in the sidebar.\n\(sidebar.debugDescription)")
                masterData.hover()
                let headerRow = sidebar.outlineRows.containing(NSPredicate(format: "label == %@", "Master data")).firstMatch
                let chevron = headerRow.descendants(matching: .any).matching(NSPredicate(format: "elementType == %d OR elementType == %d", XCUIElement.ElementType.disclosureTriangle.rawValue, XCUIElement.ElementType.button.rawValue)).firstMatch
                if chevron.waitForExistence(timeout: 3) {
                    chevron.click()
                } else {
                    masterData.click()
                }
            }
            XCTAssertTrue(locations.waitForExistence(timeout: 5), "No \"Locations\" entry in the sidebar.\n\(sidebar.debugDescription)")
            locations.click()
        #else
            let more = app.tabBars.buttons["More"].firstMatch
            XCTAssertTrue(more.waitForExistence(timeout: 10), "No \"More\" tab.")
            more.tap()
            // The rows of the "More" list are cells with static text, not buttons.
            let masterData = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Master data")).firstMatch
            XCTAssertTrue(masterData.waitForExistence(timeout: 10), "No \"Master data\" entry.")
            masterData.tap()
            // The row label may also contain the number of entries, e.g. "Locations, 3".
            let locations = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Locations")).firstMatch
            XCTAssertTrue(locations.waitForExistence(timeout: 10), "No \"Locations\" entry.")
            locations.tap()
        #endif
    }

    /// Clicks on macOS, taps elsewhere.
    @MainActor
    private func press(_ element: XCUIElement) {
        #if os(macOS)
            element.click()
        #else
            element.tap()
        #endif
    }

    private func element(in app: XCUIApplication, labelContaining text: String) -> XCUIElement {
        // macOS exposes static text as the value, iOS as the label.
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text)).firstMatch
    }

    private func toggle(in app: XCUIApplication, labeled title: String) -> XCUIElement {
        #if os(macOS)
            // Depending on the style, SwiftUI toggles are switches or checkboxes on macOS.
            let predicate = NSPredicate(format: "label == %@ AND (elementType == %d OR elementType == %d)", title, XCUIElement.ElementType.switch.rawValue, XCUIElement.ElementType.checkBox.rawValue)
            return app.descendants(matching: .any).matching(predicate).firstMatch
        #else
            return app.switches[title].firstMatch
        #endif
    }

    /// iOS reports a switch's value as the string "1", macOS as a number.
    private func isOn(_ toggle: XCUIElement) -> Bool {
        if let number = toggle.value as? NSNumber {
            return number.boolValue
        }
        return (toggle.value as? String) == "1"
    }

    @MainActor
    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        #if os(macOS)
            let screenshot = app.windows.firstMatch.screenshot()
        #else
            let screenshot = XCUIScreen.main.screenshot()
        #endif
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Server fixtures

    private struct CreatedObject: Decodable {
        let createdObjectID: Int

        enum CodingKeys: String, CodingKey {
            case createdObjectID = "created_object_id"
        }

        // Grocy returns the ID as a number or as a string, depending on the version.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let id = try? container.decode(Int.self, forKey: .createdObjectID) {
                createdObjectID = id
            } else {
                let string = try container.decode(String.self, forKey: .createdObjectID)
                guard let id = Int(string) else {
                    throw DecodingError.dataCorruptedError(forKey: .createdObjectID, in: container, debugDescription: "Not an ID: \(string)")
                }
                createdObjectID = id
            }
        }
    }

    private func request(_ path: String, method: String, body: [String: Any]? = nil) throws -> URLRequest {
        let url = try XCTUnwrap(URL(string: "\(serverURL)/api/\(path)"))
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "GROCY-API-KEY")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return request
    }

    private func createLocation(name: String, description: String, active: Bool, isFreezer: Bool) async throws -> Int {
        let body: [String: Any] = ["name": name, "description": description, "active": active ? 1 : 0, "is_freezer": isFreezer ? 1 : 0]
        let (data, response) = try await URLSession.shared.data(for: request("objects/locations", method: "POST", body: body))
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        XCTAssertEqual(status, 200, "Creating the fixture location failed: \(String(decoding: data, as: UTF8.self))")
        return try JSONDecoder().decode(CreatedObject.self, from: data).createdObjectID
    }

    private func deleteLocation(id: Int) async throws {
        _ = try await URLSession.shared.data(for: request("objects/locations/\(id)", method: "DELETE"))
    }
}
