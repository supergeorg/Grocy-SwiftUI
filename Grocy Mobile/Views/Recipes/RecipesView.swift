//
//  RecipesView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 02.12.22.
//

import SwiftUI
import SwiftData


struct RecipesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \Recipe.name, order: .forward) var recipes: Recipes
    
    //#if os(iOS)
    //    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    //#endif
    
    @State private var searchString: String = ""
    @State private var sortOrder = [KeyPathComparator(\Recipe.name)]
    //    @State private var selection: Recipe.ID?
    
    private let dataToUpdate: [ObjectEntities] = [.recipes, .products]
    private let additionalDataToUpdate: [AdditionalEntities] = [.recipeFulfillments]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    private var gridLayout = [GridItem(.flexible()), GridItem(.flexible())]
    
    var filteredRecipes: Recipes {
        recipes
            .filter({
                $0.type == .normal
            })
            .filter({
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            })
            .sorted(using: sortOrder)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridLayout, alignment: .center, spacing: 10.0) {
                ForEach(filteredRecipes, id:\.id) { recipe in
                    NavigationLink(value: recipe, label: {
                        RecipeRowView(recipe: recipe)
                            .foregroundStyle(.foreground)
                    })
                }
            }
        }
        .navigationTitle("Recipes")
        .navigationDestination(for: Recipe.self, destination: { recipe in
            RecipeView(recipe: recipe)
        })
        .refreshable(action: {
            await updateData()
        })
        .task {
                await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
        .animation(.default, value: recipes.count)
        .toolbar(content: {
            ToolbarItem(placement: .automatic, content: {
#if os(macOS)
                RefreshButton(updateData: { Task { await updateData() } })
#endif
            })
        })
    }
}

struct RecipesView_Previews: PreviewProvider {
    static var previews: some View {
        RecipesView()
    }
}
