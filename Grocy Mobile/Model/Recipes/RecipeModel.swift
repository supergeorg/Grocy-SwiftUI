//
//  RecipeModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 02.12.22.
//

import Foundation
import SwiftData

@Model
class Recipe: Codable, Identifiable {
    @Attribute(.unique) var id: Int
    var name: String
    var recipeDescription: String?
    var pictureFileName: String?
    var baseServings: Int
    var desiredServings: Int?
    var notCheckShoppinglist: Int?
    var type: RecipeType
    var productID: Int?
    var rowCreatedTimestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case recipeDescription = "description"
        case pictureFileName = "picture_file_name"
        case baseServings = "base_servings"
        case desiredServings = "desired_servings"
        case notCheckShoppinglist = "not_check_shoppinglist"
        case type
        case productID = "product_id"
        case rowCreatedTimestamp = "row_created_timestamp"
    }
    
    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            self.name = try container.decode(String.self, forKey: .name)
            self.recipeDescription = try? container.decodeIfPresent(String.self, forKey: .recipeDescription) ?? nil
            self.pictureFileName = try? container.decodeIfPresent(String.self, forKey: .pictureFileName) ?? nil
            do { self.baseServings = try container.decode(Int.self, forKey: .baseServings) } catch { self.baseServings = Int(try container.decode(String.self, forKey: .baseServings))! }
            do { self.desiredServings = try container.decodeIfPresent(Int.self, forKey: .desiredServings) } catch { self.desiredServings = try? Int(container.decodeIfPresent(String.self, forKey: .desiredServings) ?? "") }
            do { self.notCheckShoppinglist = try container.decodeIfPresent(Int.self, forKey: .notCheckShoppinglist) } catch { self.notCheckShoppinglist = try? Int(container.decodeIfPresent(String.self, forKey: .notCheckShoppinglist) ?? "") }
            self.type = try container.decode(RecipeType.self, forKey: .type)
            do { self.productID = try container.decodeIfPresent(Int.self, forKey: .productID) } catch { self.productID = try? Int(container.decodeIfPresent(String.self, forKey: .productID) ?? "") }
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(pictureFileName, forKey: .pictureFileName)
        try container.encode(baseServings, forKey: .baseServings)
        try container.encode(desiredServings, forKey: .desiredServings)
        try container.encode(notCheckShoppinglist, forKey: .notCheckShoppinglist)
        try container.encode(type, forKey: .type)
        try container.encode(productID, forKey: .productID)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }
}

typealias Recipes = [Recipe]
