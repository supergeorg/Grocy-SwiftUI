//
//  ServerSettingsIntegrationTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 19.11.26.
//

import Foundation
import SwiftData
import Testing

@testable import Grocy_Mobile

/// The server configuration, the user settings and a product's price history, against a real Grocy server.
@MainActor
@Suite(
    "Server configuration, user settings and price history (Grocy server)",
    .tags(.integration),
    .serialized,
    .enabled(if: GrocyTestServer.isConfigured, GrocyTestServer.notConfiguredComment)
)
struct ServerSettingsIntegrationTests {
    let grocyVM: GrocyViewModel
    let container: ModelContainer
    let profileContainer: ModelContainer

    init() async throws {
        (grocyVM, container, profileContainer) = try await GrocyTestServer.makeLoggedInViewModel()
    }

    // MARK: - Config and settings

    @Test("The server's config decodes and is stored in SwiftData")
    func systemConfig() async throws {
        await grocyVM.requestData(additionalObjects: [.system_config])
        #expect(!grocyVM.failedToLoadAdditionalObjects.contains(.system_config))

        let config = try #require(grocyVM.systemConfig)
        // The test server runs in production mode with Grocy's default config.
        #expect(config.mode == "production")
        #expect(config.defaultPermissions.isEmpty == false)
        #expect(["1D", "2D"].contains(config.grocycodeType))
        #expect(config.tprinterPort > 0)

        let stored = try #require(try container.mainContext.fetch(FetchDescriptor<SystemConfig>()).first)
        #expect(stored.mode == config.mode)
        #expect(stored.featureFlagStockPriceTracking == config.featureFlagStockPriceTracking)
        #expect(stored.featureFlagShoppinglistMultipleLists == config.featureFlagShoppinglistMultipleLists)
    }

    @Test("The user's settings decode, including a changed one")
    func userSettings() async throws {
        let key = "calendar_color_tasks"
        let original: GrocyUserSettingsString = try await grocyVM.getUserSettingsEntry(settingKey: key)
        let changed = "#123456"
        let restore = GrocyUserSettingsString(value: original.value ?? "#28a745")
        do {
            try await grocyVM.putUserSettingsEntry(settingKey: key, content: GrocyUserSettingsString(value: changed))

            await grocyVM.requestData(additionalObjects: [.user_settings])
            #expect(!grocyVM.failedToLoadAdditionalObjects.contains(.user_settings))

            let settings = try #require(grocyVM.userSettings)
            #expect(settings.calendarColorTasks == changed)
            #expect(settings.nightMode != nil)
            #expect(settings.shoppingListPrintLayoutType != nil)
            #expect(settings.scanModePurchaseEnabled != nil)

            let stored = try #require(try container.mainContext.fetch(FetchDescriptor<GrocyUserSettings>()).first)
            #expect(stored.calendarColorTasks == changed)
        } catch {
            try? await grocyVM.putUserSettingsEntry(settingKey: key, content: restore)
            throw error
        }
        try await grocyVM.putUserSettingsEntry(settingKey: key, content: restore)
    }

    // MARK: - Price history

    @Test("Purchases with a price show up in the price history, newest first")
    func priceHistory() async throws {
        let name = "Price history \(UUID().uuidString.prefix(8))"
        var productID: Int?
        var quantityUnitID: Int?
        var storeID: Int?
        do {
            let locations: MDLocations = try await grocyVM.grocyApi.getObject(object: .locations)
            let locationID = try #require(locations.first?.id, "The test server has no location")
            quantityUnitID = try await grocyVM.postMDObject(object: .quantity_units, content: NewQuantityUnit(name: name, namePlural: name)).createdObjectID
            storeID = try await grocyVM.postMDObject(object: .shopping_locations, content: NewStore(name: name)).createdObjectID
            let quID = try #require(quantityUnitID)
            productID = try await grocyVM.postMDObject(
                object: .products,
                content: NewProduct(name: name, locationID: locationID, quIDPurchase: quID, quIDStock: quID, quIDConsume: quID, quIDPrice: quID)
            ).createdObjectID
            let id = try #require(productID)

            try await grocyVM.postStockObject(
                id: id,
                stockModePost: .add,
                content: Purchase(amount: 1, price: 1.25, purchasedDate: "2026-01-10", storeID: storeID)
            )
            try await grocyVM.postStockObject(id: id, stockModePost: .add, content: Purchase(amount: 2, price: 2.5, purchasedDate: "2026-02-20", storeID: nil))

            let history = try await grocyVM.getProductPriceHistory(productID: id)
            #expect(history.count == 2)
            #expect(history.map(\.price) == [2.5, 1.25])
            #expect(history[0].storeID == nil)
            #expect(history[1].storeID == storeID)
            #expect(history[1].storeName == name)
            #expect(grocyVM.stockProductPriceHistories[id] == history)

            let newest = Calendar.current.dateComponents([.year, .month, .day], from: history[0].date)
            #expect(newest.year == 2026 && newest.month == 2 && newest.day == 20)
        } catch {
            await cleanUp(productID: productID, quantityUnitID: quantityUnitID, storeID: storeID)
            throw error
        }
        await cleanUp(productID: productID, quantityUnitID: quantityUnitID, storeID: storeID)
    }

    @Test("A product without purchases has an empty price history")
    func emptyPriceHistory() async throws {
        let name = "No price history \(UUID().uuidString.prefix(8))"
        var productID: Int?
        var quantityUnitID: Int?
        do {
            let locations: MDLocations = try await grocyVM.grocyApi.getObject(object: .locations)
            let locationID = try #require(locations.first?.id, "The test server has no location")
            quantityUnitID = try await grocyVM.postMDObject(object: .quantity_units, content: NewQuantityUnit(name: name, namePlural: name)).createdObjectID
            let quID = try #require(quantityUnitID)
            productID = try await grocyVM.postMDObject(
                object: .products,
                content: NewProduct(name: name, locationID: locationID, quIDPurchase: quID, quIDStock: quID, quIDConsume: quID, quIDPrice: quID)
            ).createdObjectID

            let history = try await grocyVM.getProductPriceHistory(productID: try #require(productID))
            #expect(history.isEmpty)
        } catch {
            await cleanUp(productID: productID, quantityUnitID: quantityUnitID, storeID: nil)
            throw error
        }
        await cleanUp(productID: productID, quantityUnitID: quantityUnitID, storeID: nil)
    }

    // MARK: - Helpers

    /// Deletes the fixtures; the stock goes first, because Grocy keeps a product that is in stock.
    private func cleanUp(productID: Int?, quantityUnitID: Int?, storeID: Int?) async {
        if let productID {
            try? await grocyVM.postStockObject(id: productID, stockModePost: .inventory, content: Inventory(newAmount: 0))
            do {
                try await grocyVM.deleteMDObject(object: .products, id: productID)
            } catch {
                Issue.record("Deleting test product \(productID) failed. \(error)")
            }
        }
        if let quantityUnitID {
            try? await grocyVM.deleteMDObject(object: .quantity_units, id: quantityUnitID)
        }
        if let storeID {
            try? await grocyVM.deleteMDObject(object: .shopping_locations, id: storeID)
        }
    }

    private struct NewQuantityUnit: Codable {
        let name: String
        let namePlural: String

        enum CodingKeys: String, CodingKey {
            case name
            case namePlural = "name_plural"
        }
    }

    private struct NewStore: Codable {
        let name: String
    }

    private struct NewProduct: Codable {
        let name: String
        let locationID: Int
        let quIDPurchase: Int
        let quIDStock: Int
        let quIDConsume: Int
        let quIDPrice: Int

        enum CodingKeys: String, CodingKey {
            case name
            case locationID = "location_id"
            case quIDPurchase = "qu_id_purchase"
            case quIDStock = "qu_id_stock"
            case quIDConsume = "qu_id_consume"
            case quIDPrice = "qu_id_price"
        }
    }

    private struct Purchase: Codable {
        let amount: Double
        let price: Double
        let purchasedDate: String
        let storeID: Int?
        var transactionType = "purchase"

        enum CodingKeys: String, CodingKey {
            case amount, price
            case purchasedDate = "purchased_date"
            case storeID = "shopping_location_id"
            case transactionType = "transaction_type"
        }
    }

    private struct Inventory: Codable {
        let newAmount: Double

        enum CodingKeys: String, CodingKey {
            case newAmount = "new_amount"
        }
    }
}
