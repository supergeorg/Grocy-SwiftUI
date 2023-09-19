//
//  RecipesView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 02.12.22.
//

import SwiftUI



struct RecipesView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
#if os(iOS)
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
#endif
    
    private let dataToUpdate: [ObjectEntities] = [.recipes, .products]
    private let additionalDataToUpdate: [AdditionalEntities] = [.recipeFulfillments]
    
    @State private var searchString: String = ""
    @State private var sortOrder = [KeyPathComparator(\Recipe.name)]
    @State private var selection: Recipe.ID?
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    var recipes: Recipes {
        grocyVM.recipes
            .filter({
                $0.type == .normal
            })
            .filter({
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            })
            .sorted(using: sortOrder)
    }
    
    var body: some View {
        bodyContent
            .navigationTitle(LocalizedStringKey("str.nav.recipes"))
            .refreshable(action: {
                await updateData()
            })
            .task {
                Task {
                    await updateData()
                }
            }
            .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
            .animation(.default, value: recipes.count)
            .toolbar(content: {
                ToolbarItem(placement: .automatic, content: {
#if os(macOS)
                    RefreshButton(updateData: { Task { await updateData() } })
#endif
                })
            })
    }
    
    var bodyContent: some View {
#if os(iOS)
        Group {
            if idiom == .pad {
                tableView
            } else {
                List {
                    ForEach(recipes, id:\.id) { recipe in
                        RecipeRowView(recipe: recipe)
                    }
                }
            }
        }
#else
        tableView
#endif
    }
    var tableView: some View {
#if os(macOS)
        Table(recipes, selection: $selection, sortOrder: $sortOrder, columns: {
            TableColumn(LocalizedStringKey("str.recipes.name"), value: \.name)
            TableColumn(LocalizedStringKey("str.recipes.dueScore"), value: \.dueScore) { recipe in
                Text(String(recipe.dueScore))
            }
            TableColumn(LocalizedStringKey("str.recipes.fulfillment"), value: \.needFulfilled.rawValue) { recipe in
                switch recipe.needFulfilled {
                case .fulfilled:
                    Text(LocalizedStringKey("str.recipes.fulfillment.enough"))
                case .shoppingList:
                    Text("SHL")
                case .none:
                    Text(LocalizedStringKey("str.recipes.fulfillment.notEnough"))
                }
            }
        })
#else
        Text("Table not supported yet")
#endif
    }
}

struct RecipesView_Previews: PreviewProvider {
    static var previews: some View {
        RecipesView()
    }
}
