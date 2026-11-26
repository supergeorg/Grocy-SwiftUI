//
//  MDProductModelTests.swift
//  Grocy Mobile
//

import Foundation
import Testing

@testable import Grocy_Mobile

@MainActor
@Suite("Product model")
struct MDProductModelTests {
    /// A product as Grocy 4.7.1 returns it from /objects/products/{id}.
    private static let productJSON = """
        {"id":1,"name":"T1","description":null,"product_group_id":null,"active":1,"location_id":1,"shopping_location_id":null,
        "qu_id_purchase":1,"qu_id_stock":1,"min_stock_amount":0,"default_best_before_days":0,"default_best_before_days_after_open":0,
        "default_best_before_days_after_freezing":0,"default_best_before_days_after_thawing":0,"picture_file_name":null,
        "enable_tare_weight_handling":0,"tare_weight":0,"not_check_stock_fulfillment_for_recipes":0,"parent_product_id":null,
        "calories":null,"cumulate_min_stock_amount_of_sub_products":0,"due_type":1,"quick_consume_amount":1,"hide_on_stock_overview":0,
        "default_stock_label_type":2,"should_not_be_frozen":0,"treat_opened_as_out_of_stock":1,"no_own_stock":0,
        "default_consume_location_id":null,"move_on_open":0,"row_created_timestamp":"2026-11-25 00:24:45","qu_id_consume":1,
        "auto_reprint_stock_label":1,"quick_open_amount":1,"qu_id_price":1,"disable_open":1,"default_purchase_price_type":1,"userfields":null}
        """

    private func decode(_ json: String) throws -> MDProduct {
        try JSONDecoder().decode(MDProduct.self, from: Data(json.utf8))
    }

    @Test("\"Can't be opened\" is read from disable_open")
    func decodesDisableOpen() throws {
        #expect(try decode(Self.productJSON).disableOpen)
        #expect(try !decode(Self.productJSON.replacingOccurrences(of: "\"disable_open\":1", with: "\"disable_open\":0")).disableOpen)
    }

    @Test("A product without disable_open can be opened")
    func missingDisableOpen() throws {
        #expect(try !decode(Self.productJSON.replacingOccurrences(of: "\"disable_open\":1,", with: "")).disableOpen)
    }

    @Test("\"Can't be opened\" is sent back to the server")
    func encodesDisableOpen() throws {
        let data = try JSONEncoder().encode(MDProduct(disableOpen: true))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["disable_open"] as? Bool == true)
    }

    // MARK: - nil, 0 and -1

    private func encodedObject(_ product: MDProduct) throws -> [String: Any] {
        let data = try JSONEncoder().encode(product)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("A new product sends null for the optional references, not -1")
    func newProductSendsNullReferences() throws {
        let object = try encodedObject(MDProduct(name: "New"))
        for key in ["shopping_location_id", "default_consume_location_id", "product_group_id", "parent_product_id"] {
            #expect(object[key] is NSNull, "\(key) is \(String(describing: object[key]))")
        }
    }

    @Test("A new product sends Grocy's defaults for the columns that can't be null")
    func newProductSendsRequiredDefaults() throws {
        let object = try encodedObject(MDProduct(name: "New"))
        #expect(object["quick_consume_amount"] as? Double == 1)
        #expect(object["quick_open_amount"] as? Double == 1)
        #expect(object["tare_weight"] as? Double == 0)
        #expect(object["default_stock_label_type"] as? Int == 0)
    }

    @Test("Empty required amounts are sent as Grocy's defaults")
    func emptyRequiredAmountsAreSentAsDefaults() throws {
        let product = MDProduct(name: "New")
        product.quickConsumeAmount = nil
        product.quickOpenAmount = nil
        product.tareWeight = nil
        product.defaultStockLabelType = nil
        let object = try encodedObject(product)
        #expect(object["quick_consume_amount"] as? Double == 1)
        #expect(object["quick_open_amount"] as? Double == 1)
        #expect(object["tare_weight"] as? Double == 0)
        #expect(object["default_stock_label_type"] as? Int == 0)
    }

    @Test("-1 stored by older app versions is read as no reference")
    func decodesMinusOneAsNoReference() throws {
        var json = Self.productJSON
        for key in ["shopping_location_id", "default_consume_location_id", "product_group_id", "parent_product_id"] {
            json = json.replacingOccurrences(of: "\"\(key)\":null", with: "\"\(key)\":\"-1\"")
        }
        let product = try decode(json)
        #expect(product.storeID == nil)
        #expect(product.defaultConsumeLocationID == nil)
        #expect(product.productGroupID == nil)
        #expect(product.parentProductID == nil)
    }

    @Test("Real references are kept")
    func decodesReferences() throws {
        let json = Self.productJSON
            .replacingOccurrences(of: "\"shopping_location_id\":null", with: "\"shopping_location_id\":2")
            .replacingOccurrences(of: "\"default_consume_location_id\":null", with: "\"default_consume_location_id\":\"3\"")
        let product = try decode(json)
        #expect(product.storeID == 2)
        #expect(product.defaultConsumeLocationID == 3)
    }

    @Test("Null in a required amount, stored by older app versions, is read as Grocy's default")
    func decodesNullRequiredAmounts() throws {
        let json = Self.productJSON
            .replacingOccurrences(of: "\"quick_consume_amount\":1", with: "\"quick_consume_amount\":null")
            .replacingOccurrences(of: "\"quick_open_amount\":1", with: "\"quick_open_amount\":null")
            .replacingOccurrences(of: "\"tare_weight\":0", with: "\"tare_weight\":null")
        let product = try decode(json)
        #expect(product.quickConsumeAmount == 1)
        #expect(product.quickOpenAmount == 1)
        #expect(product.tareWeight == 0)
    }

    @Test("An unknown due type doesn't fail decoding")
    func decodesUnknownDueType() throws {
        let product = try decode(Self.productJSON.replacingOccurrences(of: "\"due_type\":1", with: "\"due_type\":7"))
        #expect(product.dueType == .bestBefore)
    }
}
