//
//  GrocyUITestCase.swift
//  Grocy MobileUITests
//
//  Created by Georg Meißner on 13.11.26.
//

import XCTest

/// Base class for UI tests against a local Grocy test server (see `TestServer/README.md`).
///
/// The app is started with in-memory stores and logged in directly (`UITestConfiguration`),
/// so the tests never change the data or login of the app installed on this device.
/// Fixtures created with `createObject` are deleted again after each test.
/// Without `GROCY_TEST_SERVER_URL`, the tests are skipped.
class GrocyUITestCase: XCTestCase {
    private(set) var serverURL: String = ""
    private(set) var apiKey: String = ""
    private var createdObjects: [(entity: String, id: Int)] = []

    /// Unique per test, so fixture names never clash with other tests or leftovers on the server.
    let runID = String(UUID().uuidString.prefix(6))

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        let environment = ProcessInfo.processInfo.environment
        guard let url = environment["GROCY_TEST_SERVER_URL"], !url.isEmpty else {
            throw XCTSkip("Set GROCY_TEST_SERVER_URL to run the UI tests against a Grocy server (see TestServer/README.md).")
        }
        serverURL = url
        apiKey = environment["GROCY_TEST_API_KEY"].flatMap { $0.isEmpty ? nil : $0 } ?? "grocy-mobile-integration-tests"
    }

    override func tearDown() async throws {
        // Newest first, so objects are deleted before the objects they depend on.
        for object in createdObjects.reversed() {
            _ = try? await URLSession.shared.data(for: request("objects/\(object.entity)/\(object.id)", method: "DELETE"))
        }
        createdObjects.removeAll()
        try await super.tearDown()
    }

    // MARK: - App

    @MainActor
    func launchApp() -> XCUIApplication {
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

    /// Opens a master data list, e.g. "Locations", from the sidebar (macOS) or the "More" tab (iPhone).
    @MainActor
    func openMasterData(_ title: String, in app: XCUIApplication) {
        // The row label may also contain the number of entries, e.g. "Locations, 3".
        let entryPredicate = NSPredicate(format: "label == %@ OR label BEGINSWITH %@", title, "\(title), ")
        #if os(macOS)
            let sidebar = app.outlines["Sidebar"].firstMatch
            XCTAssertTrue(sidebar.waitForExistence(timeout: 10), "No sidebar.")
            let entry = sidebar.buttons.matching(entryPredicate).firstMatch
            if !entry.exists {
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
                // The expanded entries can reach below the window's bottom edge, where clicks miss
                // even though the element counts as hittable.
                XCTAssertTrue(entry.waitForExistence(timeout: 5), "No \"\(title)\" entry in the sidebar.\n\(sidebar.debugDescription)")
                sidebar.scroll(byDeltaX: 0, deltaY: -1000)
            }
            XCTAssertTrue(entry.waitForExistence(timeout: 5), "No \"\(title)\" entry in the sidebar.\n\(sidebar.debugDescription)")
            entry.click()
        #else
            let more = app.tabBars.buttons["More"].firstMatch
            XCTAssertTrue(more.waitForExistence(timeout: 10), "No \"More\" tab.")
            more.tap()
            // The rows of the "More" list are cells with static text, not buttons.
            let masterData = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Master data")).firstMatch
            XCTAssertTrue(masterData.waitForExistence(timeout: 10), "No \"Master data\" entry.")
            masterData.tap()
            let entry = app.buttons.matching(entryPredicate).firstMatch
            XCTAssertTrue(entry.waitForExistence(timeout: 10), "No \"\(title)\" entry.")
            entry.tap()
        #endif
    }

    /// Clicks on macOS, taps elsewhere.
    @MainActor
    func press(_ element: XCUIElement) {
        #if os(macOS)
            element.click()
        #else
            element.tap()
        #endif
    }

    func element(in app: XCUIApplication, labelContaining text: String) -> XCUIElement {
        // macOS exposes static text as the value, iOS as the label.
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text)).firstMatch
    }

    func toggle(in app: XCUIApplication, labeled title: String) -> XCUIElement {
        #if os(macOS)
            // Depending on the style, SwiftUI toggles are switches or checkboxes on macOS.
            let predicate = NSPredicate(format: "label == %@ AND (elementType == %d OR elementType == %d)", title, XCUIElement.ElementType.switch.rawValue, XCUIElement.ElementType.checkBox.rawValue)
            return app.descendants(matching: .any).matching(predicate).firstMatch
        #else
            return app.switches[title].firstMatch
        #endif
    }

    /// iOS reports a switch's value as the string "1", macOS as a number.
    func isOn(_ toggle: XCUIElement) -> Bool {
        if let number = toggle.value as? NSNumber {
            return number.boolValue
        }
        return (toggle.value as? String) == "1"
    }

    @MainActor
    func attachScreenshot(of app: XCUIApplication, named name: String) {
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

    /// Creates an object through `POST /objects/{entity}` and deletes it again after the test.
    @discardableResult
    func createObject(_ entity: String, _ body: [String: Any]) async throws -> Int {
        let (data, response) = try await URLSession.shared.data(for: request("objects/\(entity)", method: "POST", body: body))
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        XCTAssertEqual(status, 200, "Creating the \(entity) fixture failed: \(String(decoding: data, as: UTF8.self))")
        let id = try JSONDecoder().decode(CreatedObject.self, from: data).createdObjectID
        createdObjects.append((entity, id))
        return id
    }

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
}
