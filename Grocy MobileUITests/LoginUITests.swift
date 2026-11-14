//
//  LoginUITests.swift
//  Grocy MobileUITests
//
//  Created by Georg Meißner on 13.11.26.
//

import XCTest

/// UI tests for the login screen (see `GrocyUITestCase`). The app is launched logged out through a launch argument,
/// which isn't persisted, so the login of the app installed on this device stays untouched.
final class LoginUITests: GrocyUITestCase {
    @MainActor
    func testLoginControlsAreLabeledButtons() throws {
        let app = launchApp(loggedIn: false)

        // The server choices are buttons with names VoiceOver can read.
        for label in ["Use demo server", "Use your own server"] {
            XCTAssertTrue(app.buttons[label].firstMatch.waitForExistence(timeout: 10), "No button labeled \"\(label)\".")
        }
        #if os(iOS)
            // The toolbar items are real, labeled buttons and links, not tap gestures on bare images.
            for label in ["About this app", "Settings"] {
                XCTAssertTrue(app.buttons[label].firstMatch.exists, "No toolbar button labeled \"\(label)\".")
            }
            for label in ["Github", "Grocy"] {
                XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch.exists, "No toolbar link labeled \"\(label)\".")
            }
        #endif
        attachScreenshot(of: app, named: "Login")
    }
}
