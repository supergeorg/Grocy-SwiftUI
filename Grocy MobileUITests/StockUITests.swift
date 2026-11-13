//
//  StockUITests.swift
//  Grocy MobileUITests
//
//  Created by Georg Meißner on 13.11.26.
//

import XCTest

/// UI tests for the stock overview and the shared amount controls, against a local Grocy test server (see `GrocyUITestCase`).
///
/// - The stock status (due soon, overdue, expired, below min. stock) must be spelled out, not only shown by the row color.
/// - Amount fields and steppers must be named, so VoiceOver says which amount they change.
final class StockUITests: GrocyUITestCase {
    private var productName: String { "UITest product \(runID)" }

    /// Creates a location, a quantity unit and an active product, and returns the product's ID.
    private func createProduct() async throws -> Int {
        let locationID = try await createObject("locations", ["name": "UITest location \(runID)", "active": 1])
        let unitID = try await createObject("quantity_units", ["name": "UITest unit \(runID)", "active": 1])
        return try await createObject("products", [
            "name": productName, "active": 1, "location_id": locationID,
            "qu_id_purchase": unitID, "qu_id_stock": unitID, "qu_id_consume": unitID, "qu_id_price": unitID,
        ])
    }

    @MainActor
    func testStockRowSpellsOutDueSoonStatus() async throws {
        let productID = try await createProduct()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        try await callAPI("stock/products/\(productID)/add", ["amount": 1, "best_before_date": formatter.string(from: tomorrow)])

        let app = launchApp()
        openStockOverview(in: app)
        search(for: productName, in: app)

        let row = element(in: app, labelContaining: productName)
        XCTAssertTrue(row.waitForExistence(timeout: 15), "The product isn't listed in the stock overview.")
        XCTAssertTrue(element(in: app, labelContaining: "Due soon").waitForExistence(timeout: 5), "The due soon status isn't spelled out in the row.")
        attachScreenshot(of: app, named: "Stock overview – due soon")
    }

    @MainActor
    func testAmountFieldAndStepperAreLabeled() async throws {
        try await createProduct()

        let app = launchApp()
        openMasterData("Products", in: app)
        search(for: productName, in: app)
        let row = element(in: app, labelContaining: productName)
        XCTAssertTrue(row.waitForExistence(timeout: 10), "The product isn't listed.")
        press(row)
        let amountSection = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Amount")).firstMatch
        XCTAssertTrue(amountSection.waitForExistence(timeout: 10), "No amount section in the product form.")
        press(amountSection)

        let title = "Minimum stock amount"
        XCTAssertTrue(app.textFields[title].firstMatch.waitForExistence(timeout: 10), "The amount field isn't labeled \"\(title)\".")
        let stepper = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ AND elementType == %d", title, XCUIElement.ElementType.stepper.rawValue)).firstMatch
        XCTAssertTrue(stepper.exists, "The stepper isn't labeled \"\(title)\".\n\(app.debugDescription)")
        attachScreenshot(of: app, named: "Product form – amounts")
    }

    // MARK: - Helpers

    @MainActor
    private func openStockOverview(in app: XCUIApplication) {
        #if os(macOS)
            let entry = app.outlines["Sidebar"].buttons["Stock overview"].firstMatch
            XCTAssertTrue(entry.waitForExistence(timeout: 10), "No \"Stock overview\" entry in the sidebar.")
            entry.click()
        #else
            let tab = app.tabBars.buttons["Stock overview"].firstMatch
            XCTAssertTrue(tab.waitForExistence(timeout: 10), "No \"Stock overview\" tab.")
            tab.tap()
        #endif
    }
}
