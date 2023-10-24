//
//  RecipeModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 02.12.22.
//

import Foundation

// MARK: - Recipe
struct Recipe: Codable, Identifiable {
    let id: Int
    let name: String
    var recipeDescription: String?
    var pictureFileName: String?
    let baseServings: Int
    var desiredServings: Int?
    var notCheckShoppinglist: Int?
    var type: RecipeType?
    var productID: Int?
    let rowCreatedTimestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case recipeDescription = "description"
        case pictureFileName = "picture_file_name"
        case baseServings = "base_servings"
        case desiredServings = "desired_servings"
        case notCheckShoppinglist = "not_check_shoppinglist"
        case type
        case productID = "product_id"
        case rowCreatedTimestamp = "row_created_timestamp"
    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            self.name = try container.decode(String.self, forKey: .name)
            self.recipeDescription = try? container.decodeIfPresent(String.self, forKey: .recipeDescription) ?? nil
            self.pictureFileName = try? container.decodeIfPresent(String.self, forKey: .pictureFileName) ?? nil
            do { self.baseServings = try container.decode(Int.self, forKey: .baseServings) } catch { self.baseServings = Int(try container.decode(String.self, forKey: .baseServings))! }
            do { self.desiredServings = try container.decodeIfPresent(Int.self, forKey: .desiredServings) } catch { self.desiredServings = try? Int(container.decodeIfPresent(String.self, forKey: .desiredServings) ?? "") }
            do { self.notCheckShoppinglist = try container.decodeIfPresent(Int.self, forKey: .notCheckShoppinglist) } catch { self.notCheckShoppinglist = try? Int(container.decodeIfPresent(String.self, forKey: .notCheckShoppinglist) ?? "") }
            self.type = try? container.decodeIfPresent(RecipeType.self, forKey: .type) ?? nil
            do { self.productID = try container.decodeIfPresent(Int.self, forKey: .productID) } catch { self.productID = try? Int(container.decodeIfPresent(String.self, forKey: .productID) ?? "") }
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
}

enum RecipeType: String, Codable {
    case mealplanDay = "mealplan-day"
    case mealplanShadow = "mealplan-shadow"
    case mealplanWeek = "mealplan-week"
    case normal = "normal"
}

typealias Recipes = [Recipe]
