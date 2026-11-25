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
}
