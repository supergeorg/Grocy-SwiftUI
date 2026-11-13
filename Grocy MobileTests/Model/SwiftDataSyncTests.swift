//
//  SwiftDataSyncTests.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 13.11.26.
//

import Foundation
import SwiftData
import Testing

@testable import Grocy_Mobile

@MainActor
@Suite("SwiftData synchronization")
struct SwiftDataSyncTests {
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

    private func stockElement(productID: Int, amount: Double = 1) throws -> StockElement {
        let json = """
            {"amount": \(amount), "amount_aggregated": \(amount), "value": 0, "best_before_date": "2999-12-31",
             "amount_opened": 0, "amount_opened_aggregated": 0, "is_aggregated_amount": 0, "due_type": 1, "product_id": \(productID)}
            """
        return try JSONDecoder().decode(StockElement.self, from: Data(json.utf8))
    }

    @Test("A changed object updates the stored object in place")
    func changedObjectKeepsIdentity() throws {
        try sync.syncPersistentCollection([MDLocation(id: 1, name: "Fridge"), MDLocation(id: 2, name: "Pantry")])
        let original = try #require(try context.fetch(FetchDescriptor<MDLocation>(predicate: #Predicate { $0.id == 1 })).first)
        let originalID = original.persistentModelID

        try sync.syncPersistentCollection([MDLocation(id: 1, name: "Freezer"), MDLocation(id: 2, name: "Pantry")])

        let stored = try context.fetch(FetchDescriptor<MDLocation>(sortBy: [SortDescriptor(\.id)]))
        #expect(stored.map(\.name) == ["Freezer", "Pantry"])
        #expect(stored.first?.persistentModelID == originalID)
        #expect(original.name == "Freezer")
    }

    @Test("Objects missing from the server are deleted")
    func removedObjectIsDeleted() throws {
        try sync.syncPersistentCollection([MDLocation(id: 1, name: "Fridge"), MDLocation(id: 2, name: "Pantry")])
        try sync.syncPersistentCollection([MDLocation(id: 2, name: "Pantry")])

        let stored = try context.fetch(FetchDescriptor<MDLocation>())
        #expect(stored.map(\.id) == [2])
    }

    @Test("Updating a product keeps the stock element's link to it")
    func productUpdateKeepsStockLink() throws {
        try sync.syncPersistentCollection([MDProduct(id: 1, name: "Milk")])
        try sync.syncStockElements([try stockElement(productID: 1)])

        try sync.syncPersistentCollection([MDProduct(id: 1, name: "Oat milk")])

        let element = try #require(try context.fetch(FetchDescriptor<StockElement>()).first)
        #expect(element.product?.name == "Oat milk")
    }

    @Test("Stock synced before the products is linked once the products arrive")
    func stockBeforeProductsIsLinked() throws {
        try sync.syncStockElements([try stockElement(productID: 1)])
        #expect(try context.fetch(FetchDescriptor<StockElement>()).first?.product == nil)

        try sync.syncPersistentCollection([MDProduct(id: 1, name: "Milk")])
        try sync.linkStockElementsToProducts()

        let element = try #require(try context.fetch(FetchDescriptor<StockElement>()).first)
        #expect(element.product?.name == "Milk")
    }

    @Test("Resetting the cache removes the data from the store")
    func deleteAllCachedDataIsPersisted() throws {
        let profileSchema = Schema([ServerProfile.self, LoginCustomHeader.self])
        let profileContainer = try ModelContainer(for: profileSchema, configurations: ModelConfiguration(schema: profileSchema, isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let grocyVM = GrocyViewModel(modelContext: context, profileModelContext: profileContainer.mainContext)

        try sync.syncPersistentCollection([MDLocation(id: 1, name: "Fridge")])
        try sync.syncPersistentCollection([MDTaskCategory(id: 1, name: "Cleaning")])
        try sync.syncStockElements([try stockElement(productID: 1)])

        grocyVM.deleteAllCachedData()

        // A separate context only sees what was saved to the store.
        let otherContext = ModelContext(container)
        #expect(try otherContext.fetchCount(FetchDescriptor<MDLocation>()) == 0)
        #expect(try otherContext.fetchCount(FetchDescriptor<MDTaskCategory>()) == 0)
        #expect(try otherContext.fetchCount(FetchDescriptor<StockElement>()) == 0)
    }
}
