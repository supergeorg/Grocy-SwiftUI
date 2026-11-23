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
    // For the stock rows, which are the stock overview's.
    @Query private var shoppingList: [ShoppingListItem]
    @Query private var volatileStockList: [VolatileStock]
    @Query private var userSettingsList: GrocyUserSettingsList
    @Query private var recipeFulfilments: RecipeFulfilments

    // The rows' actions are the overviews' ones.
    @State private var stockInteractionRouter = StockInteractionNavigationRouter()
    @State private var recipeActionsRouter = RecipeActionsRouter()

    /// Owned by the search tab, which puts `.searchable` on its navigation stack (needed for the search tab's field).
    @Binding var searchText: String

    private let dataToUpdate: [ObjectEntities] = [
        .products, .product_barcodes, .recipes, .quantity_units,
        .locations, .shopping_locations, .product_groups, .chores, .task_categories,
        .batteries, .equipment, .shopping_list,
    ]
    private let additionalDataToUpdate: [AdditionalEntities] = [.stock, .volatileStock, .user_settings, .recipeFulfillments]

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
                    // The stock overview's rows, with its context menu and swipe actions.
                    Section("Stock overview") {
                        ForEach(stockResults) { stockElement in
                            StockTableRow(
                                stockElement: stockElement,
                                mdQuantityUnits: quantityUnits,
                                shoppingList: shoppingList,
                                mdProductGroups: productGroups,
                                volatileStock: volatileStockList.first,
                                parentProduct: products.first(where: { $0.id == stockElement.product?.parentProductID }),
                                userSettings: userSettingsList.first
                            )
                        }
                    }
                }
                if !recipeResults.isEmpty {
                    Section("Recipes") {
                        ForEach(recipeResults) { recipe in
                            NavigationLink(value: RecipeInteraction.showRecipe(recipe: recipe)) {
                                RecipeRowView(recipe: recipe, fulfillment: recipeFulfilments.first(where: { $0.recipeID == recipe.id }))
                            }
                            .recipeRowActions(recipe)
                        }
                    }
                }
                if !equipmentResults.isEmpty {
                    Section("Equipment") {
                        ForEach(equipmentResults) { item in
                            NavigationLink(value: item) {
                                ListRowLabel(item.name, systemImage: MySymbols.equipment)
                            }
                        }
                    }
                }
                if hasMasterDataResults {
                    // Each entry says which kind of master data it is, since names can repeat across kinds.
                    Section("Master data") {
                        ForEach(productResults) { product in
                            NavigationLink(value: product) {
                                ListRowLabel(product.name, subtitle: "Product", systemImage: MySymbols.product)
                            }
                            // The stock overview's menu, also for a product that isn't in stock (as its "below min. stock" filter shows them).
                            .contextMenu {
                                StockTableMenuEntriesView(
                                    stockElement: stock.first(where: { $0.productID == product.id }) ?? StockElement(notInStock: product),
                                    quantityUnit: quantityUnits.first(where: { $0.id == product.quIDStock })
                                )
                            }
                        }
                        ForEach(locationResults) { location in
                            NavigationLink(value: location) {
                                ListRowLabel(location.name, subtitle: "Location", systemImage: MySymbols.location)
                            }
                        }
                        ForEach(storeResults) { store in
                            NavigationLink(value: store) {
                                ListRowLabel(store.name, subtitle: "Store", systemImage: MySymbols.store)
                            }
                        }
                        ForEach(quantityUnitResults) { quantityUnit in
                            NavigationLink(value: quantityUnit) {
                                ListRowLabel(quantityUnit.name, subtitle: "Quantity unit", systemImage: MySymbols.quantityUnit)
                            }
                        }
                        ForEach(productGroupResults) { productGroup in
                            NavigationLink(value: productGroup) {
                                ListRowLabel(productGroup.name, subtitle: "Product group", systemImage: MySymbols.productGroup)
                            }
                        }
                        ForEach(choreResults) { chore in
                            NavigationLink(value: chore) {
                                ListRowLabel(chore.name, subtitle: "Chore", systemImage: MySymbols.chores)
                            }
                        }
                        ForEach(taskCategoryResults) { taskCategory in
                            NavigationLink(value: taskCategory) {
                                ListRowLabel(taskCategory.name, subtitle: "Task category", systemImage: MySymbols.tasks)
                            }
                        }
                        ForEach(batteryResults) { battery in
                            NavigationLink(value: battery) {
                                ListRowLabel(battery.name, subtitle: "Battery", systemImage: MySymbols.batteries)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Search")
        .stockInteractionSheet(router: stockInteractionRouter)
        .recipeActions(router: recipeActionsRouter)
        .stockEntriesDestination()
        .navigationDestination(for: MDProduct.self) { product in
            MDProductFormView(existingProduct: product)
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
}

#Preview(traits: .previewData) {
    @Previewable @State var searchText: String = ""
    NavigationStack {
        GlobalSearchView(searchText: $searchText)
    }
    .searchable(text: $searchText)
}
