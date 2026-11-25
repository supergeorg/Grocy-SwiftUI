//
//  UserManagementIntegrationTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 19.11.26.
//

import CoreGraphics
import Foundation
import ImageIO
import SwiftData
import Testing
import UniformTypeIdentifiers

@testable import Grocy_Mobile

/// Editing users and their permissions, userfields and included recipes, against a real Grocy server.
@MainActor
@Suite(
    "Users, permissions, userfields and included recipes (Grocy server)",
    .tags(.integration),
    .serialized,
    .enabled(if: GrocyTestServer.isConfigured, GrocyTestServer.notConfiguredComment)
)
struct UserManagementIntegrationTests {
    let grocyVM: GrocyViewModel
    let container: ModelContainer
    let profileContainer: ModelContainer

    init() async throws {
        (grocyVM, container, profileContainer) = try await GrocyTestServer.makeLoggedInViewModel()
    }

    private func uniqueName(_ prefix: String) -> String {
        "\(prefix)\(UUID().uuidString.prefix(8).lowercased())"
    }

    /// Creates a user and returns its ID (Grocy's create doesn't return one).
    private func createUser(username: String) async throws -> Int {
        try await grocyVM.postUser(
            user: GrocyUserPOST(id: -1, username: username, firstName: "First", lastName: "Last", password: "secret-\(username)", rowCreatedTimestamp: Date())
        )
        let users = try await grocyVM.grocyApi.getUsers()
        return try #require(users.first(where: { $0.username == username })?.id, "The created user wasn't found")
    }

    // MARK: - Users

    @Test("Editing a user changes the names and keeps the password when it's empty")
    func editUser() async throws {
        let username = uniqueName("edit")
        var userID: Int?
        do {
            userID = try await createUser(username: username)
            let id = try #require(userID)

            try await grocyVM.putUser(
                id: id,
                user: GrocyUserPOST(id: id, username: username, firstName: "Changed", lastName: "Name", password: "", rowCreatedTimestamp: Date())
            )
            let edited = try #require(try await grocyVM.grocyApi.getUsers().first(where: { $0.id == id }))
            #expect(edited.firstName == "Changed")
            #expect(edited.lastName == "Name")
            #expect(edited.pictureFileName == nil)
        } catch {
            if let userID { try? await grocyVM.deleteUser(id: userID) }
            throw error
        }
        if let userID { try await grocyVM.deleteUser(id: userID) }
    }

    @Test("A failed write shows the server's message, not a decoding error")
    func duplicateUsernameShowsServerMessage() async throws {
        let username = uniqueName("dup")
        var userID: Int?
        do {
            userID = try await createUser(username: username)
            let error = await #expect(throws: APIError.self) {
                _ = try await createUser(username: username)
            }
            if case .errorString(let description) = error {
                #expect(!description.isEmpty)
            } else {
                Issue.record("Expected the server's error message, got \(String(describing: error))")
            }
        } catch {
            if let userID { try? await grocyVM.deleteUser(id: userID) }
            throw error
        }
        if let userID { try await grocyVM.deleteUser(id: userID) }
    }

    @Test("A user picture is uploaded, set, loaded and deleted")
    func userPicture() async throws {
        let username = uniqueName("pic")
        let fileName = "\(UUID().uuidString)_\(username).jpg"
        var userID: Int?
        var uploaded = false
        do {
            userID = try await createUser(username: username)
            let id = try #require(userID)
            try await grocyVM.uploadUserPicture(jpegData: try #require(Self.smallJPEG()), fileName: fileName)
            uploaded = true

            try await grocyVM.putUser(
                id: id,
                user: GrocyUserPOST(
                    id: id,
                    username: username,
                    firstName: "First",
                    lastName: "Last",
                    password: "",
                    pictureFileName: fileName,
                    rowCreatedTimestamp: Date()
                )
            )
            await grocyVM.reloadUsers()
            #expect(grocyVM.users.first(where: { $0.id == id })?.pictureFileName == fileName)
            let stored = try container.mainContext.fetch(FetchDescriptor<GrocyUser>()).first(where: { $0.id == id })
            #expect(stored?.pictureFileName == fileName)

            let picture = try await grocyVM.getUserPicture(fileName: Data(fileName.utf8).base64EncodedString(), bestFitWidth: 8)
            #expect(picture?.isEmpty == false)

            try await grocyVM.deleteUserPicture(fileName: fileName)
            uploaded = false
        } catch {
            if uploaded { try? await grocyVM.deleteUserPicture(fileName: fileName) }
            if let userID { try? await grocyVM.deleteUser(id: userID) }
            throw error
        }
        if let userID { try await grocyVM.deleteUser(id: userID) }
    }

    /// A 4×4 pixel JPEG.
    private static func smallJPEG() -> Data? {
        guard
            let context = CGContext(
                data: nil,
                width: 4,
                height: 4,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
        else { return nil }
        context.setFillColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        guard let image = context.makeImage() else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination) ? output as Data : nil
    }

    // MARK: - Permissions

    @Test("The test server's API key belongs to an admin")
    func currentUserIsAdmin() async throws {
        grocyVM.isCurrentUserAdmin = nil
        await grocyVM.checkCurrentUserIsAdmin()
        #expect(grocyVM.isCurrentUserAdmin == true)
    }

    @Test("The permission tree has ADMIN as its root")
    func permissionHierarchy() async throws {
        let hierarchy = try await grocyVM.getPermissionHierarchy()
        let admin = try #require(hierarchy.first(where: { $0.name == "ADMIN" }))
        #expect(admin.parent == nil)
        #expect(hierarchy.contains(where: { $0.name == "STOCK_PURCHASE" }))
        // Everything else is below ADMIN.
        #expect(hierarchy.descendantIDs(of: admin.id).count == hierarchy.count - 1)
    }

    @Test("A user's permissions are replaced and read back")
    func replacePermissions() async throws {
        let username = uniqueName("perm")
        var userID: Int?
        do {
            userID = try await createUser(username: username)
            let id = try #require(userID)
            let hierarchy = try await grocyVM.getPermissionHierarchy()
            let stock = try #require(hierarchy.first(where: { $0.name == "STOCK" })?.id)
            let tasks = try #require(hierarchy.first(where: { $0.name == "TASKS_MARK_COMPLETED" })?.id)

            // A new user gets Grocy's default permissions.
            #expect(try await grocyVM.getUserPermissionIDs(userID: id).isEmpty == false)

            try await grocyVM.putUserPermissions(userID: id, permissionIDs: [stock, tasks])
            #expect(try await grocyVM.getUserPermissionIDs(userID: id) == [stock, tasks])

            try await grocyVM.putUserPermissions(userID: id, permissionIDs: [tasks])
            #expect(try await grocyVM.getUserPermissionIDs(userID: id) == [tasks])
        } catch {
            if let userID { try? await grocyVM.deleteUser(id: userID) }
            throw error
        }
        if let userID { try await grocyVM.deleteUser(id: userID) }
    }

    // MARK: - Userfields

    @Test("Userfields and user entities load into the view model")
    func userfieldsLoad() async throws {
        let fieldName = uniqueName("field")
        let entityName = uniqueName("entity")
        var fieldID: Int?
        var entityID: Int?
        do {
            await grocyVM.requestData(objects: [.userfields, .userentities])
            #expect(!grocyVM.failedToLoadObjects.contains(.userfields))
            #expect(!grocyVM.failedToLoadObjects.contains(.userentities))

            fieldID = try await grocyVM.postMDObject(
                object: .userfields,
                content: MDUserField(
                    id: try grocyVM.findNextID(.userfields),
                    name: fieldName,
                    entity: "products",
                    caption: "Field",
                    type: "text-single-line",
                    showAsColumnInTables: false
                )
            ).createdObjectID
            entityID = try await grocyVM.postMDObject(
                object: .userentities,
                content: MDUserEntity(id: try grocyVM.findNextID(.userentities), name: entityName, caption: "Entity", showInSidebarMenu: 0)
            ).createdObjectID

            grocyVM.timeStampsObjects[.userfields] = nil
            grocyVM.timeStampsObjects[.userentities] = nil
            await grocyVM.requestData(objects: [.userfields, .userentities])

            let field = try #require(grocyVM.mdUserFields.first(where: { $0.id == fieldID }))
            #expect(field.name == fieldName)
            #expect(field.entity == "products")
            #expect(field.showAsColumnInTables == false)
            #expect(grocyVM.mdUserEntities.first(where: { $0.id == entityID })?.name == entityName)
        } catch {
            if let fieldID { try? await grocyVM.deleteMDObject(object: .userfields, id: fieldID) }
            if let entityID { try? await grocyVM.deleteMDObject(object: .userentities, id: entityID) }
            throw error
        }
        if let fieldID { try await grocyVM.deleteMDObject(object: .userfields, id: fieldID) }
        if let entityID { try await grocyVM.deleteMDObject(object: .userentities, id: entityID) }
    }

    // MARK: - Included recipes

    @Test("An included recipe is saved and synced into SwiftData")
    func includedRecipe() async throws {
        var recipeIDs: [Int] = []
        var nestingID: Int?
        do {
            for name in [uniqueName("Main "), uniqueName("Side ")] {
                recipeIDs.append(try await grocyVM.postMDObject(object: .recipes, content: NewRecipe(name: name)).createdObjectID)
            }
            await grocyVM.requestData(objects: [.recipes_nestings])

            let nesting = RecipeNesting(id: try grocyVM.findNextID(.recipes_nestings), recipeID: recipeIDs[0], includesRecipeID: recipeIDs[1], servings: 2)
            nestingID = try await grocyVM.postMDObject(object: .recipes_nestings, content: nesting).createdObjectID

            grocyVM.timeStampsObjects[.recipes_nestings] = nil
            await grocyVM.requestData(objects: [.recipes_nestings])

            let stored = try container.mainContext.fetch(FetchDescriptor<RecipeNesting>()).first(where: { $0.id == nestingID })
            #expect(stored?.recipeID == recipeIDs[0])
            #expect(stored?.includesRecipeID == recipeIDs[1])
            #expect(stored?.servings == 2)
        } catch {
            if let nestingID { try? await grocyVM.deleteMDObject(object: .recipes_nestings, id: nestingID) }
            for id in recipeIDs { try? await grocyVM.deleteMDObject(object: .recipes, id: id) }
            throw error
        }
        if let nestingID { try await grocyVM.deleteMDObject(object: .recipes_nestings, id: nestingID) }
        for id in recipeIDs { try await grocyVM.deleteMDObject(object: .recipes, id: id) }
    }

    private struct NewRecipe: Codable {
        let name: String
    }
}
