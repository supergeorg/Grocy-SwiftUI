//
//  FeatureFlagsAndPermissionsTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 19.11.26.
//

import Foundation
import SwiftUI
import Testing

@testable import Grocy_Mobile

/// The server feature flags the views read, Grocy's permission tree and the bodies sent for users and permissions.
@MainActor
@Suite("Feature flags, permissions and user bodies")
struct FeatureFlagsAndPermissionsTests {
    private func config(_ extraKeys: String = "", recipes: Bool = true) throws -> SystemConfig {
        let json = """
            {"CURRENCY": "EUR", "BASE_PATH": "", "BASE_URL": "/", "LOCALE": "en",
             "FEATURE_FLAG_STOCK": true, "FEATURE_FLAG_SHOPPINGLIST": true, "FEATURE_FLAG_RECIPES": \(recipes), "FEATURE_FLAG_CHORES": true,
             "FEATURE_FLAG_TASKS": true, "FEATURE_FLAG_BATTERIES": true, "FEATURE_FLAG_EQUIPMENT": true, "FEATURE_FLAG_CALENDAR": true\(extraKeys)}
            """
        return try JSONDecoder().decode(SystemConfig.self, from: Data(json.utf8))
    }

    // MARK: - GrocyFeatures

    @Test("Without a config every feature is on")
    func featuresWithoutConfig() {
        let features = GrocyFeatures(nil)
        #expect(features == GrocyFeatures())
        #expect(features.locationTracking && features.dueDateTracking && features.openedTracking)
        #expect(features.freezing && features.multipleShoppingLists && features.choreAssignments && features.recipes)
    }

    @Test("A config without the sub-feature flags keeps Grocy's defaults (all on)")
    func featuresDefaults() throws {
        #expect(GrocyFeatures(try config()) == GrocyFeatures())
    }

    @Test("Each flag the server turns off turns off its feature")
    func featuresTurnedOff() throws {
        let features = GrocyFeatures(
            try config(
                """
                , "FEATURE_FLAG_STOCK_LOCATION_TRACKING": false, "FEATURE_FLAG_STOCK_BEST_BEFORE_DATE_TRACKING": "0",
                "FEATURE_FLAG_STOCK_PRODUCT_OPENED_TRACKING": 0, "FEATURE_FLAG_STOCK_PRODUCT_FREEZING": false,
                "FEATURE_FLAG_SHOPPINGLIST_MULTIPLE_LISTS": false, "FEATURE_FLAG_CHORES_ASSIGNMENTS": false
                """
            )
        )
        #expect(!features.locationTracking)
        #expect(!features.dueDateTracking)
        #expect(!features.openedTracking)
        #expect(!features.freezing)
        #expect(!features.multipleShoppingLists)
        #expect(!features.choreAssignments)
        #expect(features.recipes)
    }

    @Test("The recipes flag turns off recipes")
    func featuresWithoutRecipes() throws {
        let recipesOff = try config(recipes: false)
        #expect(!GrocyFeatures(recipesOff).recipes)
        #expect(GrocyFeatures(recipesOff).locationTracking)
    }

    @Test("Turning off one flag leaves the others on")
    func featuresIndependent() throws {
        let features = GrocyFeatures(try config(#", "FEATURE_FLAG_STOCK_PRODUCT_FREEZING": false"#))
        #expect(!features.freezing)
        #expect(features.locationTracking && features.dueDateTracking && features.openedTracking)
        #expect(features.multipleShoppingLists && features.choreAssignments)
    }

    // MARK: - Inventory body

    @Test("An inventory without due date tracking doesn't send a due date")
    func inventoryWithoutDueDate() throws {
        var inventory = ProductInventory(newAmount: 3)
        let withDate = try #require(String(data: try JSONEncoder().encode(inventory), encoding: .utf8))
        #expect(withDate.contains("best_before_date"))

        inventory.sendsBestBeforeDate = false
        let withoutDate = try #require(String(data: try JSONEncoder().encode(inventory), encoding: .utf8))
        #expect(!withoutDate.contains("best_before_date"))
        #expect(withoutDate.contains("new_amount"))
    }

    // MARK: - Permissions

    /// A part of Grocy's tree: ADMIN > STOCK > STOCK_PURCHASE, ADMIN > USERS > USERS_READ, and a second root.
    private let hierarchy: GrocyPermissions = [
        GrocyPermission(id: 1, name: "ADMIN"),
        GrocyPermission(id: 2, name: "USERS", parent: 1),
        GrocyPermission(id: 3, name: "USERS_READ", parent: 2),
        GrocyPermission(id: 4, name: "STOCK", parent: 1),
        GrocyPermission(id: 5, name: "STOCK_PURCHASE", parent: 4),
        GrocyPermission(id: 6, name: "OTHER_ROOT"),
    ]

    @Test("The tree lists roots and children in ID order")
    func permissionChildren() {
        #expect(hierarchy.children(of: nil).map(\.id) == [1, 6])
        #expect(hierarchy.children(of: 1).map(\.id) == [2, 4])
        #expect(hierarchy.children(of: 5).isEmpty)
    }

    @Test("A permission includes everything below it")
    func permissionDescendants() {
        #expect(hierarchy.descendantIDs(of: 1) == [2, 3, 4, 5])
        #expect(hierarchy.descendantIDs(of: 4) == [5])
        #expect(hierarchy.descendantIDs(of: 6).isEmpty)
    }

    @Test("Permissions decode with IDs sent as strings and a null parent")
    func permissionDecoding() throws {
        let json = #"[{"id": "1", "name": "ADMIN", "parent": null}, {"id": 2, "name": "USERS", "parent": "1"}]"#
        let permissions = try JSONDecoder().decode(GrocyPermissions.self, from: Data(json.utf8))
        #expect(permissions == [GrocyPermission(id: 1, name: "ADMIN"), GrocyPermission(id: 2, name: "USERS", parent: 1)])

        let assigned = try JSONDecoder().decode(GrocyUserPermissions.self, from: Data(#"[{"id": 7, "permission_id": "4", "user_id": "2"}]"#.utf8))
        #expect(assigned == [GrocyUserPermission(permissionID: 4, userID: 2)])
    }

    @Test("Known permissions get Grocy's names, unknown ones their internal name")
    func permissionNames() {
        #expect(UserPermissionsView.displayName(of: GrocyPermission(id: 1, name: "ADMIN")) == "All permissions")
        #expect(UserPermissionsView.displayName(of: GrocyPermission(id: 99, name: "SOMETHING_NEW")) == "SOMETHING_NEW")
    }

    // MARK: - User body

    @Test("A user edit always sends the picture, as null when there is none")
    func userBodySendsPicture() throws {
        let withPicture = GrocyUserPOST(id: 1, username: "u", firstName: "", lastName: "", password: "", pictureFileName: "a.jpg", rowCreatedTimestamp: Date())
        let withoutPicture = GrocyUserPOST(id: 1, username: "u", firstName: "", lastName: "", password: "", rowCreatedTimestamp: Date())

        let object1 = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(withPicture)) as? [String: Any])
        let object2 = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(withoutPicture)) as? [String: Any])
        #expect(object1["picture_file_name"] as? String == "a.jpg")
        #expect(object2.keys.contains("picture_file_name"))
        #expect(object2["picture_file_name"] is NSNull)
    }
}
