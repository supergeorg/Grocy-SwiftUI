//
//  PurchasePriceTypeTests.swift
//  Grocy Mobile
//

import Foundation
import Testing

@testable import Grocy_Mobile

@MainActor
@Suite("Default purchase price type")
struct PurchasePriceTypeTests {
    /// A product as Grocy 4.7.1 returns it from /objects/products/{id}.
    private static let productJSON = """
        {"id":1,"name":"T1","description":null,"product_group_id":null,"active":1,"location_id":1,"shopping_location_id":null,
        "qu_id_purchase":1,"qu_id_stock":1,"min_stock_amount":0,"default_best_before_days":0,"default_best_before_days_after_open":0,
        "default_best_before_days_after_freezing":0,"default_best_before_days_after_thawing":0,"picture_file_name":null,
        "enable_tare_weight_handling":0,"tare_weight":0,"not_check_stock_fulfillment_for_recipes":0,"parent_product_id":null,
        "calories":null,"cumulate_min_stock_amount_of_sub_products":0,"due_type":1,"quick_consume_amount":1,"hide_on_stock_overview":0,
        "default_stock_label_type":2,"should_not_be_frozen":0,"treat_opened_as_out_of_stock":1,"no_own_stock":0,
        "default_consume_location_id":null,"move_on_open":0,"row_created_timestamp":"2026-11-25 00:24:45","qu_id_consume":1,
        "auto_reprint_stock_label":1,"quick_open_amount":1,"qu_id_price":1,"disable_open":0,"default_purchase_price_type":3,"userfields":null}
        """

    private func decode(_ json: String) throws -> MDProduct {
        try JSONDecoder().decode(MDProduct.self, from: Data(json.utf8))
    }

    @Test("The type is read from default_purchase_price_type", arguments: [(1, PurchasePriceType.unspecified), (2, .unitPrice), (3, .totalPrice)])
    func decodes(rawValue: Int, expected: PurchasePriceType) throws {
        let json = Self.productJSON.replacingOccurrences(of: "\"default_purchase_price_type\":3", with: "\"default_purchase_price_type\":\(rawValue)")
        #expect(try decode(json).defaultPurchasePriceType == expected)
    }

    @Test("A missing or unknown type is unspecified")
    func missingOrUnknown() throws {
        #expect(try decode(Self.productJSON.replacingOccurrences(of: "\"default_purchase_price_type\":3,", with: "")).defaultPurchasePriceType == .unspecified)
        #expect(
            try decode(Self.productJSON.replacingOccurrences(of: "\"default_purchase_price_type\":3", with: "\"default_purchase_price_type\":9"))
                .defaultPurchasePriceType == .unspecified
        )
    }

    @Test("The type is sent back as Grocy's number")
    func encodes() throws {
        let data = try JSONEncoder().encode(MDProduct(defaultPurchasePriceType: .totalPrice))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["default_purchase_price_type"] as? Int == 3)
    }
}
