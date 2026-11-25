//
//  PhoneNavigationUITests.swift
//  Grocy MobileUITests
//
//  Created by Georg Meißner on 15.11.26.
//

import XCTest

/// Walks through the iPhone navigation styles (smart, own tabs, sidebar) and attaches a screenshot of each place,
/// against a local Grocy test server (see `GrocyUITestCase`).
final class PhoneNavigationUITests: GrocyUITestCase {
    private var productName: String { "UITest milk \(runID)" }

    @MainActor
    func testTabsSearchAndAccount() async throws {
        #if os(iOS)
            let locationID = try await createObject("locations", ["name": "UITest location \(runID)", "active": 1])
            let unitID = try await createObject("quantity_units", ["name": "UITest unit \(runID)", "active": 1])
            let productID = try await createObject(
                "products",
                [
                    "name": productName, "active": 1, "location_id": locationID,
                    "qu_id_purchase": unitID, "qu_id_stock": unitID, "qu_id_consume": unitID, "qu_id_price": unitID,
                ]
            )
            try await callAPI("stock/products/\(productID)/add", ["amount": 2])

            let app = launchApp()
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "No tab bar.")

            // At most five tabs, so there's no "More" tab.
            XCTAssertFalse(tabBar.buttons["More"].exists, "The tab bar still has a \"More\" tab.")
            for tab in ["Stock overview", "Shopping list", "Recipes", "Due"] {
                XCTAssertTrue(tabBar.buttons[tab].waitForExistence(timeout: 5), "No \"\(tab)\" tab.\n\(tabBar.debugDescription)")
            }

            tabBar.buttons["Stock overview"].tap()
            XCTAssertTrue(app.navigationBars.buttons["Settings"].waitForExistence(timeout: 5), "No settings button.")
            // Quick Scan belongs to the search tab only.
            XCTAssertFalse(app.buttons["Quick Scan"].exists, "Quick Scan is shown outside the search tab.")
            attachScreenshot(of: app, named: "1 Stock")

            tabBar.buttons["Shopping list"].tap()
            attachScreenshot(of: app, named: "2 Shopping list")

            tabBar.buttons["Recipes"].tap()
            attachScreenshot(of: app, named: "3 Recipes")

            // Products, chores, tasks and batteries that are due are in one agenda; the complete lists open from the settings button.
            tabBar.buttons["Due"].tap()
            XCTAssertTrue(app.navigationBars["Due"].waitForExistence(timeout: 5), "No due agenda.\n\(app.navigationBars.firstMatch.debugDescription)")
            attachScreenshot(of: app, named: "4 Due")
            app.navigationBars.buttons["Settings"].firstMatch.tap()
            app.buttons["Tasks"].firstMatch.tap()
            XCTAssertTrue(app.navigationBars["Tasks"].waitForExistence(timeout: 5), "The complete task list didn't open.")
            attachScreenshot(of: app, named: "5 Due – all tasks")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            app.navigationBars.buttons.element(boundBy: 0).tap()

            // The search tab turns into a search field; results come from stock, products and recipes.
            let searchTab = tabBar.buttons["Search"].firstMatch
            XCTAssertTrue(searchTab.exists, "No search tab.")
            searchTab.tap()
            XCTAssertTrue(app.buttons["Quick Scan"].waitForExistence(timeout: 5), "No Quick Scan button on the search tab.")
            attachScreenshot(of: app, named: "6 Search – empty")
            // Selecting the tab activates the field right away; it can take a moment to appear.
            let field = app.searchFields.firstMatch
            XCTAssertTrue(field.waitForExistence(timeout: 10), "No search field in the search tab.")
            field.tap()
            // With the keyboard up, Quick Scan must still be reachable (it used to sit behind the keyboard).
            XCTAssertTrue(app.buttons["Quick Scan"].isHittable, "The keyboard covers the Quick Scan button.")
            // The run ID is part of this run's product, location and unit names, so it finds all three.
            field.typeText(runID)
            XCTAssertTrue(element(in: app, labelContaining: productName).waitForExistence(timeout: 10), "The product isn't found.")
            XCTAssertTrue(element(in: app, labelContaining: "UITest location \(runID)").exists, "The location (master data) isn't found.")
            // A product in stock is found twice: its stock entry and the product itself (master data).
            let productResults = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", productName))
            XCTAssertEqual(productResults.count, 2, "The product isn't listed both in stock and in master data.\n\(app.debugDescription)")
            XCTAssertTrue(
                app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", productName, "Product")).firstMatch.exists,
                "The product isn't listed as master data."
            )
            attachScreenshot(of: app, named: "7 Search – results")

            // While searching, the tab bar shrinks to one button for the previous tab; it leads back out of search.
            tabBar.buttons.firstMatch.tap()
            XCTAssertTrue(tabBar.buttons["Stock overview"].waitForExistence(timeout: 5), "The tab bar didn't come back after search.")

            // Settings and master data open from the profile button.
            tabBar.buttons["Stock overview"].tap()
            app.navigationBars.buttons["Settings"].firstMatch.tap()
            XCTAssertTrue(element(in: app, labelContaining: "Master data").waitForExistence(timeout: 5), "No master data on the profile page.")
            // Places without a tab are listed there, too.
            XCTAssertTrue(element(in: app, labelContaining: "Equipment").exists, "Equipment isn't reachable from the profile page.")
            attachScreenshot(of: app, named: "8 Profile page")
        #else
            throw XCTSkip("The tab navigation is iPhone only.")
        #endif
    }

    /// Own tabs: the chosen places are tabs, the others open from the settings button.
    @MainActor
    func testOwnTabs() throws {
        #if os(iOS)
            let app = launchApp(phoneNavigationStyle: "tabs", phoneTabs: "stock,chores,tasks")
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "No tab bar.")
            for tab in ["Stock overview", "Chores", "Tasks"] {
                XCTAssertTrue(tabBar.buttons[tab].waitForExistence(timeout: 5), "No \"\(tab)\" tab.\n\(tabBar.debugDescription)")
            }
            XCTAssertFalse(tabBar.buttons["Shopping list"].exists, "A tab that wasn't chosen is shown.")
            tabBar.buttons["Chores"].tap()
            attachScreenshot(of: app, named: "Own tabs – chores")

            tabBar.buttons["Stock overview"].tap()
            app.navigationBars.buttons["Settings"].firstMatch.tap()
            let shoppingList = element(in: app, labelContaining: "Shopping list")
            XCTAssertTrue(shoppingList.waitForExistence(timeout: 5), "The shopping list isn't reachable from the profile page.")
            attachScreenshot(of: app, named: "Own tabs – profile page")
            shoppingList.tap()
            XCTAssertTrue(app.navigationBars["Shopping list"].waitForExistence(timeout: 5), "The shopping list didn't open.")
        #else
            throw XCTSkip("The tab navigation is iPhone only.")
        #endif
    }

    /// Sidebar: the iPad sidebar as a list that pushes the screens, without a tab bar.
    @MainActor
    func testSidebar() throws {
        #if os(iOS)
            let app = launchApp(phoneNavigationStyle: "sidebar")
            let chores = element(in: app, labelContaining: "Chores overview")
            XCTAssertTrue(chores.waitForExistence(timeout: 10), "No sidebar list.\n\(app.debugDescription)")
            XCTAssertFalse(app.tabBars.firstMatch.exists, "The sidebar style shows a tab bar.")
            attachScreenshot(of: app, named: "Sidebar")
            chores.tap()
            XCTAssertTrue(app.navigationBars["Chores overview"].waitForExistence(timeout: 5), "Chores didn't open from the sidebar.")
            attachScreenshot(of: app, named: "Sidebar – chores")
        #else
            throw XCTSkip("The iPhone navigation styles are iPhone only.")
        #endif
    }
}
