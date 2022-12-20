//
//  RecipesView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 02.12.22.
//

import SwiftUI



struct RecipesView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    private let dataToUpdate: [ObjectEntities] = [.recipes, .products]
    private let additionalDataToUpdate: [AdditionalEntities] = [.recipeFulfillments]
    
    @State private var searchString: String = ""
    @State private var sortOrder = [KeyPathComparator(\Recipe.name)]
    @State private var selection: Recipe.ID?
    
    func updateData() {
        grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
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
                updateData()
            })
            .onAppear(perform: updateData)
            .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
            .animation(.default, value: recipes.count)
            .toolbar(content: {
                ToolbarItem(placement: .automatic, content: {
#if os(macOS)
                    RefreshButton(updateData: { updateData() })
#endif
                })
            })
    }
    
    var bodyContent: some View {
        Group {
            if #available(iOS 16.0, *), idiom == .pad {
                Table(recipes, selection: $selection, sortOrder: $sortOrder, columns: {
                    TableColumn("NAME", value: \.name)
                    TableColumn("DUE SCORE", value: \.dueScore) { recipe in
                        Text(String(recipe.dueScore))
                    }
                    TableColumn("REQUIREMENTS FULFILLED", value: \.needFulfilled.rawValue) { recipe in
                        switch recipe.needFulfilled {
                        case .fulfilled:
                            Text("OK")
                        case .shoppingList:
                            Text("SHL")
                        case .none:
                            Text("None")
                        }
                    }
                })
            } else {
                List {
                    ForEach(recipes, id:\.id) { recipe in
                        RecipeRowView(recipe: recipe)
                    }
                }
            }
        }
    }
}

struct RecipesView_Previews: PreviewProvider {
    static var previews: some View {
        RecipesView()
    }
}
