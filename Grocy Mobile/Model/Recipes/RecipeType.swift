//
//  RecipeType.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 23.11.23.
//

import Foundation

enum RecipeType: String, Codable {
    case mealplanDay = "mealplan-day"
    case mealplanShadow = "mealplan-shadow"
    case mealplanWeek = "mealplan-week"
    case normal = "normal"
}
