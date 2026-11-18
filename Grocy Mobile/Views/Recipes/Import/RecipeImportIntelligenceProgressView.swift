//
//  RecipeImportIntelligenceProgressView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// How far Apple Intelligence is with finding products for the ingredients that matched none by name.
struct RecipeImportIntelligenceProgress: Equatable {
    var completed: Int = 0
    let total: Int
    /// The ingredient the model is looking at.
    var currentIngredientID: UUID? = nil
}

/// Shows that Apple Intelligence is looking for products, how far it is, and lets the person stop it.
/// The results are suggestions, which the ingredient rows label as coming from Apple Intelligence.
struct RecipeImportIntelligenceProgressView: View {
    var progress: RecipeImportIntelligenceProgress
    var onStop: () -> Void

    var body: some View {
        Section {
            AppleIntelligenceProgressRow(
                title: "Finding products with Apple Intelligence",
                detail: Text("\(progress.completed) of \(progress.total) ingredients"),
                completed: progress.completed,
                total: progress.total,
                onStop: onStop
            )
        } footer: {
            Text("Ingredients whose names match no product get a suggestion. You can change it before saving.")
        }
    }
}

#Preview {
    Form {
        RecipeImportIntelligenceProgressView(progress: RecipeImportIntelligenceProgress(completed: 3, total: 8), onStop: {})
    }
}
