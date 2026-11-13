//
//  MDMasterDataUITests.swift
//  Grocy MobileUITests
//
//  Created by Georg Meißner on 13.11.26.
//

import XCTest

/// UI tests for the master data lists and edit forms besides locations (see `MDLocationUITests`),
/// against a local Grocy test server (see `GrocyUITestCase`).
///
/// For each type, a disabled entry with a description is created on the server. The list must say "Disabled"
/// in text (not only with a dimmed color) and show the description, and the edit form's "Active" toggle
/// must be labeled and switched off. Screenshots of both screens are attached to the test report.
final class MDMasterDataUITests: GrocyUITestCase {
    private var entryName: String { "UITest disabled \(runID)" }
    private let entryDescription = "Created by a UI test"

    @MainActor
    func testStores() async throws {
        try await createObject("shopping_locations", ["name": entryName, "description": entryDescription, "active": 0])
        checkDisabledEntry(inList: "Stores")
    }

    @MainActor
    func testProductGroups() async throws {
        try await createObject("product_groups", ["name": entryName, "description": entryDescription, "active": 0])
        checkDisabledEntry(inList: "Product groups")
    }

    @MainActor
    func testQuantityUnits() async throws {
        try await createObject("quantity_units", ["name": entryName, "name_plural": "\(entryName)s", "description": entryDescription, "active": 0])
        checkDisabledEntry(inList: "Quantity units")
    }

    @MainActor
    func testTaskCategories() async throws {
        try await createObject("task_categories", ["name": entryName, "description": entryDescription, "active": 0])
        checkDisabledEntry(inList: "Task categories")
    }

    @MainActor
    func testChores() async throws {
        try await createObject("chores", ["name": entryName, "description": entryDescription, "period_type": "manually", "active": 0])
        checkDisabledEntry(inList: "Chores")
    }

    @MainActor
    func testProducts() async throws {
        let locationID = try await createObject("locations", ["name": "UITest location \(runID)", "active": 1])
        let unitID = try await createObject("quantity_units", ["name": "UITest unit \(runID)", "active": 1])
        try await createObject("products", [
            "name": entryName, "description": entryDescription, "active": 0, "location_id": locationID,
            "qu_id_purchase": unitID, "qu_id_stock": unitID, "qu_id_consume": unitID, "qu_id_price": unitID,
        ])
        // The product form groups its fields on sub-pages; "Active" is under the optional properties.
        checkDisabledEntry(inList: "Products", formSection: "Optional properties")
    }

    // MARK: - Checks

    @MainActor
    private func checkDisabledEntry(inList listTitle: String, formSection: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let app = launchApp()
        openMasterData(listTitle, in: app)

        let row = element(in: app, labelContaining: entryName)
        XCTAssertTrue(row.waitForExistence(timeout: 10), "The entry isn't listed in \(listTitle).", file: file, line: line)
        XCTAssertTrue(row.label.contains("Disabled"), "The disabled row reads \"\(row.label)\".", file: file, line: line)
        XCTAssertTrue(row.label.contains(entryDescription), "The row doesn't show the description: \"\(row.label)\".", file: file, line: line)
        attachScreenshot(of: app, named: "\(listTitle) list")

        press(row)
        if let formSection {
            let section = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", formSection)).firstMatch
            XCTAssertTrue(section.waitForExistence(timeout: 10), "No \"\(formSection)\" in the \(listTitle) form.", file: file, line: line)
            press(section)
        }
        let activeToggle = toggle(in: app, labeled: "Active")
        XCTAssertTrue(activeToggle.waitForExistence(timeout: 10), "No toggle labeled \"Active\" in the \(listTitle) form.", file: file, line: line)
        XCTAssertFalse(isOn(activeToggle), "The disabled entry should have \"Active\" switched off.", file: file, line: line)
        attachScreenshot(of: app, named: "\(listTitle) – edit form")
    }
}
