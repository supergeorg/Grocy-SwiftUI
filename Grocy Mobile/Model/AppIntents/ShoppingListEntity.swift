//
//  ShoppingListEntity.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 21.11.26.
//

import AppIntents
import Foundation
import SwiftData

/// A Grocy shopping list, as Siri and Shortcuts see it. The ID is the list's ID on the Grocy server.
struct ShoppingListEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Shopping list")
    static let defaultQuery = ShoppingListEntityQuery()

    /// Grocy's default shopping list, which always exists.
    static let defaultListID = 1

    let id: Int

    @Property(title: "Name")
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: MySymbols.shoppingList))
    }

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

/// Shopping lists are few, so the query lists them all.
struct ShoppingListEntityQuery: EnumerableEntityQuery {
    @Dependency private var grocyVM: GrocyViewModel

    init() {}

    @MainActor
    func allEntities() async throws -> [ShoppingListEntity] {
        let descriptor = FetchDescriptor<ShoppingListDescription>(sortBy: [SortDescriptor(\.id)])
        var lists = try grocyVM.modelContext.fetch(descriptor)
        if lists.isEmpty {
            await grocyVM.requestData(objects: [.shopping_lists])
            lists = try grocyVM.modelContext.fetch(descriptor)
        }
        return lists.map { ShoppingListEntity(id: $0.id, name: $0.name) }
    }

    @MainActor
    func entities(for identifiers: [Int]) async throws -> [ShoppingListEntity] {
        try await allEntities().filter { identifiers.contains($0.id) }
    }
}
