//
//  PhoneNavigationUITests.swift
//  Grocy MobileUITests
//
//  Created by Georg Meißner on 15.11.26.
//

import XCTest

/// Walks through the iPhone navigation prototype (`PhoneTabNavigation`) and attaches a screenshot of each place,
/// against a local Grocy test server (see `GrocyUITestCase`).
final class PhoneNavigationUITests: GrocyUITestCase {
    private var productName: String { "UITest milk \(runID)" }

    @MainActor
    func testTabsSearchAndAccount() async throws {
        #if os(iOS)
            let locationID = try await createObject("locations", ["name": "UITest location \(runID)", "active": 1])
            let unitID = try await createObject("quantity_units", ["name": "UITest unit \(runID)", "active": 1])
            let productID = try await createObject("products", [
                "name": productName, "active": 1, "location_id": locationID,
                "qu_id_purchase": unitID, "qu_id_stock": unitID, "qu_id_consume": unitID, "qu_id_price": unitID,
            ])
            try await callAPI("stock/products/\(productID)/add", ["amount": 2])

            let app = launchApp()
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "No tab bar.")

            // At most five tabs, so there's no "More" tab.
            XCTAssertFalse(tabBar.buttons["More"].exists, "The tab bar still has a \"More\" tab.")
            for tab in ["Stock overview", "Shopping list", "Recipes", "Household"] {
                XCTAssertTrue(tabBar.buttons[tab].exists, "No \"\(tab)\" tab.")
            }

            tabBar.buttons["Stock overview"].tap()
            XCTAssertTrue(app.buttons["Quick Scan"].waitForExistence(timeout: 5), "No Quick Scan button above the tab bar.")
            attachScreenshot(of: app, named: "1 Stock")

            tabBar.buttons["Shopping list"].tap()
            attachScreenshot(of: app, named: "2 Shopping list")

            tabBar.buttons["Recipes"].tap()
            attachScreenshot(of: app, named: "3 Recipes")

            // Chores and tasks are switched with the navigation title menu.
            tabBar.buttons["Household"].tap()
            let titleMenu = app.navigationBars.buttons["Chores overview"].firstMatch
            XCTAssertTrue(titleMenu.waitForExistence(timeout: 5), "No title menu in the household tab.\n\(app.navigationBars.firstMatch.debugDescription)")
            attachScreenshot(of: app, named: "4 Household – chores")
            titleMenu.tap()
            attachScreenshot(of: app, named: "4b Household – title menu")
            app.buttons["Tasks"].firstMatch.tap()
            XCTAssertTrue(app.navigationBars.buttons["Tasks"].waitForExistence(timeout: 5), "Switching to tasks didn't work.")
            attachScreenshot(of: app, named: "5 Household – tasks")

            // The search tab turns into a search field; results come from stock, products and recipes.
            let searchTab = tabBar.buttons["Search"].firstMatch
            XCTAssertTrue(searchTab.exists, "No search tab.")
            searchTab.tap()
            attachScreenshot(of: app, named: "6 Search – empty")
            // Selecting the tab activates the field right away; it can take a moment to appear.
            let field = app.searchFields.firstMatch
            XCTAssertTrue(field.waitForExistence(timeout: 10), "No search field in the search tab.")
            field.tap()
            field.typeText("UITest milk")
            XCTAssertTrue(element(in: app, labelContaining: productName).waitForExistence(timeout: 10), "The product isn't found.")
            attachScreenshot(of: app, named: "7 Search – results")

            // While searching, the tab bar shrinks to one button for the previous tab; it leads back out of search.
            tabBar.buttons.firstMatch.tap()
            XCTAssertTrue(tabBar.buttons["Stock overview"].waitForExistence(timeout: 5), "The tab bar didn't come back after search.")

            // Settings and master data open from the profile button.
            tabBar.buttons["Stock overview"].tap()
            app.navigationBars.buttons["Settings"].firstMatch.tap()
            XCTAssertTrue(element(in: app, labelContaining: "Master data").waitForExistence(timeout: 5), "No master data on the profile page.")
            attachScreenshot(of: app, named: "8 Profile page")
        #else
            throw XCTSkip("The tab navigation prototype is iPhone only.")
        #endif
    }
}
