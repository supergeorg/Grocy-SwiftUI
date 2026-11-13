//
//  SwiftDataActor.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 29.11.25.
//

import Foundation
import SwiftData

/// Helper struct for synchronizing SwiftData operations within a MainActor context.
/// This avoids the overhead and concurrency issues of a separate ModelActor
/// while maintaining proper transaction semantics.
struct SwiftDataSynchronizer {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Generic sync for collection models with identity-based deduplication.
    /// Works with any Identifiable, PersistentModel collection.
    func syncPersistentCollection<T: Codable & Equatable & Identifiable & PersistentModel>(
        _ incomingObjects: [T]
    ) throws {
        // Fetch existing objects
        let fetchDescriptor = FetchDescriptor<T>()
        let existingObjects: [T]

        do {
            existingObjects = try modelContext.fetch(fetchDescriptor)
        } catch {
            // If fetch fails, clear and insert the new objects in a clean state
            try clearAndInsertObjects(incomingObjects)
            return
        }

        // Perform synchronization
        try synchronizeObjects(existing: existingObjects, incoming: incomingObjects)

        return
    }

    /// Generic sync for singleton models (one instance exists).
    /// Replaces all with the new value.
    func syncSingletonModel<T: PersistentModel>(
        _ modelType: T.Type,
        with value: T?
    ) throws {
        do {
            try modelContext.delete(model: modelType)
            if let value = value {
                modelContext.insert(value)
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    /// Generic sync for array models (complete replacement).
    /// Used when relationship tracking requires clean state.
    func syncArrayModel<T: PersistentModel>(
        _ modelType: T.Type,
        with incoming: [T]
    ) throws {
        do {
            try modelContext.delete(model: modelType)
            for item in incoming {
                modelContext.insert(item)
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    /// Specialized sync for StockElement with product relationship resolution.
    /// Fetches MDProducts from modelContext to establish relationships.
    func syncStockElements(
        _ stockElements: [StockElement]
    ) throws {
        do {
            let fetchDescriptor = FetchDescriptor<StockElement>()
            let existing = try modelContext.fetch(fetchDescriptor)

            // Delete removed items
            let incomingIds = Set(stockElements.map { $0.id })
            for item in existing where !incomingIds.contains(item.id) {
                modelContext.delete(item)
            }

            // Fetch all products for relationship resolution
            let productDescriptor = FetchDescriptor<MDProduct>()
            let productsById = Dictionary(
                uniqueKeysWithValues: try modelContext.fetch(productDescriptor).map { ($0.id, $0) }
            )

            // Insert/link new items
            let existingIds = Set(existing.map { $0.id })
            for element in stockElements where !existingIds.contains(element.id) {
                // Link to existing product if available
                if let product = productsById[element.productID] {
                    element.product = product
                }
                modelContext.insert(element)
            }

            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    /// Links every stock element to its product. Needed when the stock was synced before the products.
    func linkStockElementsToProducts() throws {
        do {
            let productsById = Dictionary(
                try modelContext.fetch(FetchDescriptor<MDProduct>()).map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            var changed = false
            for element in try modelContext.fetch(FetchDescriptor<StockElement>()) {
                let product = productsById[element.productID]
                if element.product?.persistentModelID != product?.persistentModelID {
                    element.product = product
                    changed = true
                }
            }
            if changed {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    /// Clears existing objects and inserts new ones atomically.
    private func clearAndInsertObjects<T: PersistentModel>(_ newObjects: [T]) throws {
        let fetchDescriptor = FetchDescriptor<T>()
        let existingObjects = try modelContext.fetch(fetchDescriptor)

        // Delete all existing objects
        for object in existingObjects {
            modelContext.delete(object)
        }

        // Insert new objects
        for newObject in newObjects {
            modelContext.insert(newObject)
        }

        // Save with error handling
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    /// Synchronizes existing objects with incoming data, handling inserts, updates, and deletes.
    /// All operations are performed atomically within the model context.
    private func synchronizeObjects<T: Codable & Equatable & Identifiable & PersistentModel>(
        existing: [T],
        incoming: [T]
    ) throws {
        // Build lookup dictionaries for efficient comparison
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let incomingById = Dictionary(uniqueKeysWithValues: incoming.map { ($0.id, $0) })

        // Track which objects have been processed to avoid double-deletion
        var processedIds = Set<T.ID>()

        // Phase 1: Handle deletions of objects no longer in incoming data
        for existingObject in existing {
            if incomingById[existingObject.id] == nil {
                modelContext.delete(existingObject)
                processedIds.insert(existingObject.id)
            }
        }

        // Phase 2: Handle insertions and updates
        for newObject in incoming {
            if let existingObject = existingById[newObject.id] {
                // Check if object needs updating
                if existingObject != newObject {
                    // Inserting an object whose unique id already exists updates the stored row (upsert).
                    // The existing instance keeps its identity, so views and relationships that hold it stay valid.
                    // Deleting and re-inserting would invalidate them and nullify relationships such as StockElement.product.
                    modelContext.insert(newObject)
                }
            } else {
                // New object, insert it
                modelContext.insert(newObject)
            }
            processedIds.insert(newObject.id)
        }

        // Phase 3: Save all changes atomically
        do {
            try modelContext.save()
        } catch {
            // Rollback on any error to maintain consistency
            modelContext.rollback()
            throw error
        }
    }
}
