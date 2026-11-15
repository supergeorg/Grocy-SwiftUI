//
//  GlobalSearchView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 15.11.26.
//

import SwiftData
import SwiftUI

/// One search across stock, products and recipes, for the search tab of the iPhone navigation prototype.
/// Matches names, and products by an exact barcode (typed in or scanned).
struct GlobalSearchView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query private var stock: [StockElement]
    @Query(sort: \MDProduct.name) private var products: MDProducts
    @Query private var barcodes: MDProductBarcodes
    @Query(sort: \Recipe.name) private var recipes: Recipes
    @Query private var quantityUnits: MDQuantityUnits

    /// Owned by the search tab, which puts `.searchable` on its navigation stack (needed for the search tab's field).
    @Binding var searchText: String

    private let dataToUpdate: [ObjectEntities] = [.products, .product_barcodes, .recipes, .quantity_units]
    private let additionalDataToUpdate: [AdditionalEntities] = [.stock]

    private var query: String { searchText.trimmingCharacters(in: .whitespaces) }

    private func matches(_ name: String) -> Bool {
        name.localizedStandardContains(query)
    }

    private var stockResults: [StockElement] {
        stock
            .filter { matches($0.product?.name ?? "") }
            .sorted { ($0.product?.name ?? "") < ($1.product?.name ?? "") }
    }

    /// Products that aren't in stock (those are listed under stock already), by name or exact barcode.
    private var productResults: [MDProduct] {
        let inStock = Set(stock.map(\.productID))
        let barcodeProductIDs = Set(barcodes.filter { $0.barcode == query }.map(\.productID))
        return products.filter { product in
            !inStock.contains(product.id) && (matches(product.name) || barcodeProductIDs.contains(product.id))
        }
    }

    private var recipeResults: [Recipe] {
        recipes.filter { $0.type == .normal && matches($0.name) }
    }

    var body: some View {
        List {
            if query.isEmpty {
                ContentUnavailableView(
                    "Search",
                    systemImage: MySymbols.search,
                    description: Text("Find products, stock and recipes by name or barcode.")
                )
            } else if stockResults.isEmpty && productResults.isEmpty && recipeResults.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                if !stockResults.isEmpty {
                    Section("Stock overview") {
                        ForEach(stockResults) { stockElement in
                            NavigationLink(value: stockElement) {
                                stockRow(stockElement)
                            }
                        }
                    }
                }
                if !productResults.isEmpty {
                    Section("Products") {
                        ForEach(productResults) { product in
                            NavigationLink(value: product) {
                                VStack(alignment: .leading) {
                                    Text(product.name)
                                        .font(.headline)
                                    Text("Not in stock")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                }
                if !recipeResults.isEmpty {
                    Section("Recipes") {
                        ForEach(recipeResults) { recipe in
                            NavigationLink(value: recipe) {
                                Label(recipe.name, systemImage: MySymbols.recipe)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Search")
        .navigationDestination(for: StockElement.self) { stockElement in
            StockEntriesView(stockElement: stockElement)
        }
        .navigationDestination(for: MDProduct.self) { product in
            MDProductFormView(existingProduct: product)
        }
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeView(initialRecipe: recipe)
        }
        .task {
            await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
        }
        .refreshable {
            await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
        }
    }

    private func stockRow(_ stockElement: StockElement) -> some View {
        let quantityUnit = quantityUnits.first(where: { $0.id == stockElement.product?.quIDStock })
        return VStack(alignment: .leading) {
            Text(stockElement.product?.name ?? "")
                .font(.headline)
            Text("\(stockElement.amount.formattedAmount) \(quantityUnit?.getName(amount: stockElement.amount) ?? "")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .previewData) {
    @Previewable @State var searchText: String = ""
    NavigationStack {
        GlobalSearchView(searchText: $searchText)
    }
    .searchable(text: $searchText)
}
