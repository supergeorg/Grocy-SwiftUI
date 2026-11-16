//
//  GlobalSearchView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 15.11.26.
//

import SwiftData
import SwiftUI

/// One search across stock, products, recipes and master data, for the search tab of the iPhone navigation prototype.
/// Matches names, and products by an exact barcode (typed in or scanned).
struct GlobalSearchView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query private var stock: [StockElement]
    @Query(sort: \MDProduct.name) private var products: MDProducts
    @Query private var barcodes: MDProductBarcodes
    @Query(sort: \Recipe.name) private var recipes: Recipes
    @Query(sort: \MDQuantityUnit.name) private var quantityUnits: MDQuantityUnits
    @Query(sort: \MDLocation.name) private var locations: MDLocations
    @Query(sort: \MDStore.name) private var stores: MDStores
    @Query(sort: \MDProductGroup.name) private var productGroups: MDProductGroups
    @Query(sort: \MDChore.name) private var chores: MDChores
    @Query(sort: \MDTaskCategory.name) private var taskCategories: MDTaskCategories
    @Query(sort: \MDBattery.name) private var batteries: MDBatteries
    @Query(sort: \MDEquipment.name) private var equipment: MDEquipments

    /// Owned by the search tab, which puts `.searchable` on its navigation stack (needed for the search tab's field).
    @Binding var searchText: String

    private let dataToUpdate: [ObjectEntities] = [
        .products, .product_barcodes, .recipes, .quantity_units,
        .locations, .shopping_locations, .product_groups, .chores, .task_categories,
        .batteries, .equipment,
    ]
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

    private var recipeResults: [Recipe] {
        recipes.filter { $0.type == .normal && matches($0.name) }
    }

    // MARK: - Master data

    /// All matching products, by name or exact barcode, also those in stock: the stock result opens the stock entries,
    /// this one the product itself.
    private var productResults: [MDProduct] {
        let barcodeProductIDs = Set(barcodes.filter { $0.barcode == query }.map(\.productID))
        return products.filter { matches($0.name) || barcodeProductIDs.contains($0.id) }
    }

    private var locationResults: MDLocations { locations.filter { matches($0.name) } }
    private var storeResults: MDStores { stores.filter { matches($0.name) } }
    private var quantityUnitResults: MDQuantityUnits { quantityUnits.filter { matches($0.name) || matches($0.namePlural) } }
    private var productGroupResults: MDProductGroups { productGroups.filter { matches($0.name) } }
    private var choreResults: MDChores { chores.filter { matches($0.name) } }
    private var taskCategoryResults: MDTaskCategories { taskCategories.filter { matches($0.name) } }
    private var batteryResults: MDBatteries { batteries.filter { matches($0.name) || matches($0.usedIn) } }
    private var equipmentResults: MDEquipments { equipment.filter { matches($0.name) } }

    private var hasMasterDataResults: Bool {
        !productResults.isEmpty || !locationResults.isEmpty || !storeResults.isEmpty || !quantityUnitResults.isEmpty
            || !productGroupResults.isEmpty || !choreResults.isEmpty || !taskCategoryResults.isEmpty || !batteryResults.isEmpty
    }

    private var hasResults: Bool {
        !stockResults.isEmpty || !recipeResults.isEmpty || !equipmentResults.isEmpty || hasMasterDataResults
    }

    var body: some View {
        List {
            if query.isEmpty {
                ContentUnavailableView(
                    "Search",
                    systemImage: MySymbols.search,
                    description: Text("Find stock, products, recipes, equipment and master data by name or barcode.")
                )
            } else if !hasResults {
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
                if !recipeResults.isEmpty {
                    Section("Recipes") {
                        ForEach(recipeResults) { recipe in
                            NavigationLink(value: recipe) {
                                Label(recipe.name, systemImage: MySymbols.recipe)
                            }
                        }
                    }
                }
                if !equipmentResults.isEmpty {
                    Section("Equipment") {
                        ForEach(equipmentResults) { item in
                            NavigationLink(value: item) {
                                Label(item.name, systemImage: MySymbols.equipment)
                            }
                        }
                    }
                }
                if hasMasterDataResults {
                    // Each entry says which kind of master data it is, since names can repeat across kinds.
                    Section("Master data") {
                        ForEach(productResults) { product in
                            NavigationLink(value: product) {
                                masterDataRow(product.name, kind: "Product", systemImage: MySymbols.product)
                            }
                        }
                        ForEach(locationResults) { location in
                            NavigationLink(value: location) {
                                masterDataRow(location.name, kind: "Location", systemImage: MySymbols.location)
                            }
                        }
                        ForEach(storeResults) { store in
                            NavigationLink(value: store) {
                                masterDataRow(store.name, kind: "Store", systemImage: MySymbols.store)
                            }
                        }
                        ForEach(quantityUnitResults) { quantityUnit in
                            NavigationLink(value: quantityUnit) {
                                masterDataRow(quantityUnit.name, kind: "Quantity unit", systemImage: MySymbols.quantityUnit)
                            }
                        }
                        ForEach(productGroupResults) { productGroup in
                            NavigationLink(value: productGroup) {
                                masterDataRow(productGroup.name, kind: "Product group", systemImage: MySymbols.productGroup)
                            }
                        }
                        ForEach(choreResults) { chore in
                            NavigationLink(value: chore) {
                                masterDataRow(chore.name, kind: "Chore", systemImage: MySymbols.chores)
                            }
                        }
                        ForEach(taskCategoryResults) { taskCategory in
                            NavigationLink(value: taskCategory) {
                                masterDataRow(taskCategory.name, kind: "Task category", systemImage: MySymbols.tasks)
                            }
                        }
                        ForEach(batteryResults) { battery in
                            NavigationLink(value: battery) {
                                masterDataRow(battery.name, kind: "Battery", systemImage: MySymbols.batteries)
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
        .navigationDestination(for: MDLocation.self) { MDLocationFormView(existingLocation: $0) }
        .navigationDestination(for: MDStore.self) { MDStoreFormView(existingStore: $0) }
        .navigationDestination(for: MDQuantityUnit.self) { MDQuantityUnitFormView(existingQuantityUnit: $0) }
        .navigationDestination(for: MDProductGroup.self) { MDProductGroupFormView(existingProductGroup: $0) }
        .navigationDestination(for: MDChore.self) { MDChoreFormView(existingChore: $0) }
        .navigationDestination(for: MDTaskCategory.self) { MDTaskCategoryFormView(existingTaskCategory: $0) }
        .navigationDestination(for: MDBattery.self) { MDBatteryFormView(existingBattery: $0) }
        .navigationDestination(for: MDEquipment.self) { EquipmentDetailsView(equipment: $0) }
        .task {
            await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
        }
        .refreshable {
            await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
        }
    }

    private func masterDataRow(_ name: String, kind: LocalizedStringKey, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                Text(kind)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
        }
        .accessibilityElement(children: .combine)
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
