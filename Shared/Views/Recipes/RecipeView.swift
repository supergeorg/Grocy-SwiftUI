//
//  RecipeView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 23.11.23.
//

import SwiftUI

struct RecipeView: View {
    var recipe: Recipe
    
    var body: some View {
        List {
            Text(recipe.name)
        }
        .navigationTitle(recipe.name)
    }
}

//#Preview {
//    RecipeView()
//}
