//
//  StockRowLookupsTests.swift
//  Grocy Mobile
//

import Foundation
import Testing

@testable import Grocy_Mobile

/// The stock rows look up their objects and status in dictionaries built once per list, which must give the same results
/// as the per-row searches they replaced.
@MainActor
@Suite("Stock rows: lookups by ID")
struct StockRowLookupsTests {
    private func element(productID: Int) -> String {
        """
        {"amount": 1, "amount_aggregated": 1, "value": 0, "best_before_date": "2026-11-20", "amount_opened": 0,
         "amount_opened_aggregated": 0, "is_aggregated_amount": 0, "due_type": 1, "product_id": \(productID)}
        """
    }

    private func missing(productID: Int) -> String {
        """
        {"id": \(productID), "name": "Product \(productID)", "amount_missing": 1, "is_partly_in_stock": 0}
        """
    }

    /// Product 1 is due soon, expired and below min. stock; 2 expired and overdue; 3 overdue and below min. stock;
    /// 4 only below min. stock; 5 has no status.
    private func volatileStock() throws -> VolatileStock {
        let json = """
            {"due_products": [\(element(productID: 1))],
             "overdue_products": [\(element(productID: 2)), \(element(productID: 3))],
             "expired_products": [\(element(productID: 1)), \(element(productID: 2))],
             "missing_products": [\(missing(productID: 1)), \(missing(productID: 3)), \(missing(productID: 4))]}
            """
        return try JSONDecoder().decode(VolatileStock.self, from: Data(json.utf8))
    }

    private func lookups(dueDateTracking: Bool) throws -> StockRowLookups {
        StockRowLookups(
            quantityUnits: [MDQuantityUnit(id: 7, name: "Pack")],
            productGroups: [MDProductGroup(id: 3, name: "Snacks")],
            products: [MDProduct(id: 1, name: "Cookies"), MDProduct(id: 2, name: "Chips")],
            shoppingList: [ShoppingListItem(id: 1, productID: 2), ShoppingListItem(id: 2, productID: nil)],
            volatileStock: try volatileStock(),
            dueDateTracking: dueDateTracking
        )
    }

    @Test("Due soon wins over expired, overdue and below min. stock")
    func statusPriority() throws {
        let status = try lookups(dueDateTracking: true).statusByProductID
        #expect(status[1] == .expiringSoon)
        #expect(status[2] == .expired)
        #expect(status[3] == .overdue)
        #expect(status[4] == .belowMinStock)
        #expect(status[5] == nil)
    }

    @Test("Without due date tracking, only below min. stock applies")
    func statusWithoutDueDateTracking() throws {
        let status = try lookups(dueDateTracking: false).statusByProductID
        #expect(status[1] == .belowMinStock)
        #expect(status[2] == nil)
        #expect(status[3] == .belowMinStock)
        #expect(status[4] == .belowMinStock)
    }

    @Test("Objects are found by their ID")
    func objectsByID() throws {
        let lookups = try lookups(dueDateTracking: true)
        #expect(lookups.quantityUnitsByID[7]?.name == "Pack")
        #expect(lookups.productGroupsByID[3]?.name == "Snacks")
        #expect(lookups.productsByID[2]?.name == "Chips")
        #expect(lookups.productsByID[9] == nil)
        #expect(lookups.productIDsOnShoppingList == [2])
    }

    @Test("Duplicate IDs keep the first object instead of crashing")
    func duplicateIDs() {
        let lookups = StockRowLookups(
            quantityUnits: [MDQuantityUnit(id: 1, name: "First"), MDQuantityUnit(id: 1, name: "Second")],
            productGroups: [],
            products: [],
            shoppingList: [],
            volatileStock: nil,
            dueDateTracking: true
        )
        #expect(lookups.quantityUnitsByID[1]?.name == "First")
        #expect(lookups.statusByProductID.isEmpty)
    }
}
