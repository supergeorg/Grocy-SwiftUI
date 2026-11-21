//
//  ProductEntity.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 21.11.26.
//

import AppIntents
import Foundation
import SwiftData

/// A Grocy product, as Siri and Shortcuts see it.
///
/// The ID is the product's ID on the Grocy server, so saved shortcuts keep working across launches and devices
/// (as long as they use the same server). Don't change the ID scheme: saved shortcuts store it.
struct ProductEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Product", numericFormat: "\(placeholder: .int) products")
    static let defaultQuery = ProductEntityQuery()

    let id: Int

    @Property(title: "Name")
    var name: String

    /// The product's default location, shown as subtitle to tell products with similar names apart.
    let locationName: String?

    var displayRepresentation: DisplayRepresentation {
        if let locationName, !locationName.isEmpty {
            return DisplayRepresentation(title: "\(name)", subtitle: "\(locationName)", image: .init(systemName: MySymbols.product))
        }
        return DisplayRepresentation(title: "\(name)", image: .init(systemName: MySymbols.product))
    }

    init(id: Int, name: String, locationName: String?) {
        self.id = id
        self.locationName = locationName
        self.name = name
    }
}

/// Finds products in the local SwiftData cache, so the lookup works without a server round trip.
struct ProductEntityQuery: EntityStringQuery {
    @Dependency private var grocyVM: GrocyViewModel

    init() {}

    @MainActor
    func entities(for identifiers: [Int]) async throws -> [ProductEntity] {
        let products = try await fetchProducts(predicate: #Predicate { identifiers.contains($0.id) })
        return makeEntities(products)
    }

    @MainActor
    func entities(matching string: String) async throws -> [ProductEntity] {
        let products = try await fetchProducts(predicate: #Predicate { $0.active && $0.name.localizedStandardContains(string) })
        return makeEntities(products)
    }

    @MainActor
    func suggestedEntities() async throws -> [ProductEntity] {
        let products = try await fetchProducts(predicate: #Predicate { $0.active })
        return makeEntities(products)
    }

    // MARK: - Helpers

    @MainActor
    private func fetchProducts(predicate: Predicate<MDProduct>) async throws -> [MDProduct] {
        let descriptor = FetchDescriptor<MDProduct>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        var products = try grocyVM.modelContext.fetch(descriptor)
        if products.isEmpty, try grocyVM.modelContext.fetchCount(FetchDescriptor<MDProduct>()) == 0 {
            // Nothing cached yet (for example right after the login): load the products once.
            await grocyVM.requestData(objects: [.products, .locations])
            products = try grocyVM.modelContext.fetch(descriptor)
        }
        return products
    }

    @MainActor
    private func makeEntities(_ products: [MDProduct]) -> [ProductEntity] {
        let locations = (try? grocyVM.modelContext.fetch(FetchDescriptor<MDLocation>())) ?? []
        let locationNames = Dictionary(locations.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        return products.map { ProductEntity(id: $0.id, name: $0.name, locationName: locationNames[$0.locationID]) }
    }
}
