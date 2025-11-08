//
//  RecipeView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 23.11.23.
//

import SwiftUI
import WebKit

struct RecipeView: View {
    var recipe: Recipe
    
    @State private var page = WebPage()
    let blank = URL(string: "about:blank")!
    
    var body: some View {
        //        ScrollView(.vertical) {
        //            VStack(alignment: .leading) {
        //                if let pictureFileName = recipe.pictureFileName {
        //                    PictureView(pictureFileName: pictureFileName, pictureType: .recipePictures)
        //                        .backgroundExtensionEffect()
        //                }
        
        List {
            Section("Ingredients", content: {
                Text("")
            })
            Section("Preparation", content: {
                WebView(page)
                    .aspectRatio(contentMode: .fit)
                    .onAppear {
                        if let recipeDescription = recipe.recipeDescription {
                            page.load(html: recipeDescription, baseURL: blank)
                        }
                    }
            })
        }
        .navigationTitle(recipe.name)
        //            }
        //        }
        //
    }
}

extension Recipe {
    static let sampleRecipe = Recipe(
        id: 1,
        name: "Recipe",
        recipeDescription: "This is a sample recipe.",
        pictureFileName: nil,
        baseServings: 4,
        desiredServings: 4,
        notCheckShoppinglist: 0,
        type: RecipeType.normal,
        productID: 1
    )
}

#Preview {
    NavigationStack {
        RecipeView(recipe: Recipe.sampleRecipe)
    }
}
