//
//  ParsedRecipe.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 09.02.26.
//

import FoundationModels

@Generable()
struct ParsedIngredient {
    @Guide(description: "The name of the ingredient (e.g., 'flour', 'butter', 'eggs').")
    let name: String

    @Guide(description: "The numeric amount/quantity of the ingredient. Use 0 if no specific amount is given.")
    let amount: Double

    @Guide(description: "The unit of measurement (e.g., 'cups', 'grams', 'tablespoons', 'pieces', 'ml'). Use empty string if no unit fits.")
    let unit: String
}

@Generable()
struct ParsedRecipe {
    @Guide(description: "The name of the recipe.")
    let name: String

    @Guide(description: "The full preparation instruction of the recipe in HTML format, preserving all HTML tags like <p>, <ul>, <li>, <b>, etc.")
    let descriptionHTML: String

    @Guide(description: "List of ingredients with their amounts, units, and names.")
    let ingredients: [ParsedIngredient]

    @Guide(
        description:
            "URL of the main recipe image from the website. Extract the URL for the most prominent image of the website, most likely above the ingredients."
    )
    var imageURL: String
}
