//
//  GrocyCodeTests.swift
//  Grocy Mobile
//

import Testing

@testable import Grocy_Mobile

@Suite("Grocycodes")
struct GrocyCodeTests {
    @Test("A product code")
    func product() throws {
        let code = try #require(GrocyCode(string: "grcy:p:12"))
        #expect(code == GrocyCode(entityType: .product, entityID: 12, stockID: nil))
    }

    @Test("A stock entry code carries the stock ID")
    func stockEntry() throws {
        let code = try #require(GrocyCode(string: "grcy:p:12:6b062ad1bddfe"))
        #expect(code == GrocyCode(entityType: .product, entityID: 12, stockID: "6b062ad1bddfe"))
    }

    @Test("A chore code")
    func chore() throws {
        let code = try #require(GrocyCode(string: "grcy:c:3"))
        #expect(code == GrocyCode(entityType: .chore, entityID: 3, stockID: nil))
    }

    @Test("Other codes aren't Grocycodes", arguments: ["4006381333931", "grcy:p:", "grcy:p:abc", "grcy:x:1", "grcy:c:1:2", "grcy"])
    func notAGrocyCode(value: String) {
        #expect(GrocyCode(string: value) == nil)
    }
}
