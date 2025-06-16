//
//  RecipeFulfillmentModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 09.12.22.
//

import Foundation

// MARK: - RecipeFullfilment
struct RecipeFulfilment: Codable {
    let id: Int
    let recipeID: Int
    let needFulfilled: Int?
    let needFulfilledWithShoppingList: Int?
    let missingProductsCount: Int?
    let costs: Double?
    let costsPerServing: Double?
    let calories: Double?
    let dueScore: Int?
    let productNamesCommaSeparated: String?

    enum CodingKeys: String, CodingKey {
        case id
        case recipeID = "recipe_id"
        case needFulfilled = "need_fulfilled"
        case needFulfilledWithShoppingList = "need_fulfilled_with_shopping_list"
        case missingProductsCount = "missing_products_count"
        case costs
        case costsPerServing = "costs_per_serving"
        case calories
        case dueScore = "due_score"
        case productNamesCommaSeparated = "product_names_comma_separated"
    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            do { self.recipeID = try container.decode(Int.self, forKey: .recipeID) } catch { self.recipeID = Int(try container.decode(String.self, forKey: .recipeID))! }
            do { self.needFulfilled = try container.decodeIfPresent(Int.self, forKey: .needFulfilled) } catch { self.needFulfilled = try? Int(container.decodeIfPresent(String.self, forKey: .needFulfilled) ?? "") }
            do { self.needFulfilledWithShoppingList = try container.decodeIfPresent(Int.self, forKey: .needFulfilledWithShoppingList) } catch { self.needFulfilledWithShoppingList = try? Int(container.decodeIfPresent(String.self, forKey: .needFulfilledWithShoppingList) ?? "") }
            do { self.missingProductsCount = try container.decodeIfPresent(Int.self, forKey: .missingProductsCount) } catch { self.missingProductsCount = try? Int(container.decodeIfPresent(String.self, forKey: .missingProductsCount) ?? "") }
            do { self.costs = try container.decodeIfPresent(Double.self, forKey: .costs) } catch { self.costs = try? Double(container.decodeIfPresent(String.self, forKey: .costs) ?? "") }
            do { self.costsPerServing = try container.decodeIfPresent(Double.self, forKey: .costsPerServing) } catch { self.costsPerServing = try? Double(container.decodeIfPresent(String.self, forKey: .costsPerServing) ?? "") }
            do { self.calories = try container.decodeIfPresent(Double.self, forKey: .calories) } catch { self.calories = try? Double(container.decodeIfPresent(String.self, forKey: .calories) ?? "") }
            do { self.dueScore = try container.decodeIfPresent(Int.self, forKey: .dueScore) } catch { self.dueScore = try? Int(container.decodeIfPresent(String.self, forKey: .dueScore) ?? "") }
            self.productNamesCommaSeparated = try? container.decodeIfPresent(String.self, forKey: .productNamesCommaSeparated) ?? nil
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
}

typealias RecipeFulfilments = [RecipeFulfilment]
