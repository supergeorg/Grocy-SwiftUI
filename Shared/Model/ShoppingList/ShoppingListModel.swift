//
//  ShoppingListModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 26.11.20.
//

import Foundation

// MARK: - ShoppingListElement

struct ShoppingListItem: Codable {
    let id: Int
    let productID: Int?
    let note: String?
    let amount: Double
    let shoppingListID: Int
    let done: Int
    let quID: Int?
    let rowCreatedTimestamp: String

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case note, amount
        case shoppingListID = "shopping_list_id"
        case done
        case quID = "qu_id"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            do { self.productID = try container.decodeIfPresent(Int.self, forKey: .productID) } catch { self.productID = try? Int(container.decodeIfPresent(String.self, forKey: .productID) ?? "") }
            self.note = try? container.decodeIfPresent(String.self, forKey: .note) ?? nil
            do { self.amount = try container.decode(Double.self, forKey: .amount) } catch { self.amount = try Double(container.decode(String.self, forKey: .amount))! }
            do { self.shoppingListID = try container.decode(Int.self, forKey: .shoppingListID) } catch { self.shoppingListID = try Int(container.decode(String.self, forKey: .shoppingListID))! }
            do { self.done = try container.decode(Int.self, forKey: .done) } catch { self.done = try Int(container.decode(String.self, forKey: .done))! }
            do { self.quID = try container.decodeIfPresent(Int.self, forKey: .quID) } catch { self.quID = try? Int(container.decodeIfPresent(String.self, forKey: .quID) ?? "") }
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int,
        productID: Int? = nil,
        note: String? = nil,
        amount: Double,
        shoppingListID: Int,
        done: Int,
        quID: Int? = nil,
        rowCreatedTimestamp: String
    ) {
        self.id = id
        self.productID = productID
        self.note = note
        self.amount = amount
        self.shoppingListID = shoppingListID
        self.done = done
        self.quID = quID
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

// MARK: - ShoppingListAddItem

struct ShoppingListItemAdd: Codable {
    let amount: Double
    let note: String?
    let productID, quID: Int?
    let shoppingListID: Int

    enum CodingKeys: String, CodingKey {
        case amount, note
        case productID = "product_id"
        case quID = "qu_id"
        case shoppingListID = "shopping_list_id"
    }
}
