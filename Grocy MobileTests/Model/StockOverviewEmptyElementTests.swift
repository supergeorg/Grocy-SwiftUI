//
//  StockOverviewEmptyElementTests.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import Foundation
import SwiftData
import Testing

@testable import Grocy_Mobile

/// The stock overview shows products that aren't in stock as display-only stock elements (`StockElement(notInStock:)`),
/// with "show all out of stock products" one per product. They must stay out of SwiftData: linking a new object to a
/// stored product inserts it into the product's context, so every rebuild of the overview added objects to the store.
@MainActor
@Suite("Stock overview: elements of products not in stock")
struct StockOverviewEmptyElementTests {
    let container: ModelContainer
    let context: ModelContext
    let sync: SwiftDataSynchronizer

    init() throws {
        let schema = Schema(Grocy_MobileApp.mainModelTypes)
        container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        context = container.mainContext
        context.autosaveEnabled = false
        sync = SwiftDataSynchronizer(modelContext: context)
    }

    private func storedProducts(count: Int) throws -> [MDProduct] {
        try sync.syncPersistentCollection((1...count).map { MDProduct(id: $0, name: "Product \($0)") })
        return try context.fetch(FetchDescriptor<MDProduct>(sortBy: [SortDescriptor(\.id)]))
    }

    @Test("An element of a stored product isn't inserted into the context")
    func notInserted() throws {
        let product = try #require(try storedProducts(count: 1).first)

        let element = StockElement(notInStock: product)

        #expect(element.modelContext == nil)
        #expect(context.insertedModelsArray.isEmpty)
        #expect(element.product?.name == "Product 1")
        #expect(element.productID == 1)
        #expect(element.amount == 0)
    }

    @Test("Rebuilding the overview many times leaves the store unchanged")
    func rebuildsDontReachTheStore() throws {
        let products = try storedProducts(count: 200)

        var elements: [StockElement] = []
        for _ in 0..<10 {
            elements = products.map(StockElement.init(notInStock:))
        }
        try context.save()

        #expect(context.insertedModelsArray.isEmpty)
        #expect(try context.fetchCount(FetchDescriptor<StockElement>()) == 0)
        #expect(elements.count == 200)
    }

    @Test("A stock sync doesn't delete the elements the overview shows")
    func survivesStockSync() throws {
        let product = try #require(try storedProducts(count: 1).first)
        let element = StockElement(notInStock: product)

        try sync.syncStockElements([])

        #expect(!element.isDeleted)
        #expect(element.product?.name == "Product 1")
    }

    @Test("Stock from the server still stores its product link")
    func serverStockKeepsRelationship() throws {
        _ = try storedProducts(count: 1)
        let json = """
            {"amount": 1, "amount_aggregated": 1, "value": 0, "best_before_date": "2999-12-31",
             "amount_opened": 0, "amount_opened_aggregated": 0, "is_aggregated_amount": 0, "due_type": 1, "product_id": 1}
            """
        try sync.syncStockElements([try JSONDecoder().decode(StockElement.self, from: Data(json.utf8))])

        // A separate context only sees what was saved, so the link is in the store, not only in memory.
        let stored = try #require(try ModelContext(container).fetch(FetchDescriptor<StockElement>()).first)
        #expect(stored.product?.name == "Product 1")
    }
}
