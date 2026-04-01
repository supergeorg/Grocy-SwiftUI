//
//  RecipesView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 02.12.22.
//

import SwiftData
import SwiftUI

enum RecipeInteraction: Hashable, Identifiable {
    case showRecipe(recipe: Recipe)
    case editRecipe(recipe: Recipe)

    var id: Self { self }
}

enum RecipeSortOption: Hashable, RawRepresentable {
    case name
    case dueScore

    var rawValue: String {
        switch self {
        case .name:
            return "name"
        case .dueScore:
            return "dueScore"
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "name":
            self = .name
        case "dueScore":
            self = .dueScore
        default:
            return nil
        }
    }
}

struct RecipesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \Recipe.name, order: .forward) var recipes: Recipes
    @Query var recipeFulfilments: RecipeFulfilments

    @AppStorage("devMode") private var devMode: Bool = false

    @State private var initialLoadDone = false
    @State private var searchString: String = ""
    @State private var showAddRecipe: Bool = false
    @State private var recipeToDelete: Recipe? = nil
    @State private var showDeleteConfirmation: Bool = false
    @AppStorage("RecipesView.sortOption") private var sortOption: RecipeSortOption = .dueScore
    @AppStorage("RecipesView.sortOrder") private var sortOrderKey: String = "reverse"
    @State private var filteredStatus: RecipeStatus = .all

    private var sortOrder: SortOrder {
        sortOrderKey == "forward" ? .forward : .reverse
    }

    private var setSortOrder: ((SortOrder) -> Void) {
        { newValue in
            sortOrderKey = newValue == .forward ? "forward" : "reverse"
        }
    }

    private let dataToUpdate: [ObjectEntities] = [.recipes, .products]
    private let additionalDataToUpdate: [AdditionalEntities] = [.recipeFulfillments]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    private func deleteItem(itemToDelete: Recipe) {
        recipeToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }

    private func deleteRecipe(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .recipes, id: toDelID)
            GrocyLogger.info("Deleting recipe was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting recipe failed. \(error)")
        }
    }

    private func copyRecipe(recipeID: Int) async {
        do {
            try await grocyVM.copyRecipe(recipeID: recipeID)
            GrocyLogger.info("Copying recipe \(recipeID) was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Copying recipe failed. \(error)")
        }
    }

    private func getFilteredRecipes(for status: RecipeStatus) -> Recipes {
        recipes
            .filter({ $0.type == .normal })
            .filter({ searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString) })
            .filter({ recipe in
                let fulfillment = recipeFulfilments.first(where: { $0.recipeID == recipe.id })

                switch status {
                case .all:
                    return true
                case .enoughInStock:
                    return fulfillment?.needFulfilled == true
                case .alreadyOnShoppingList:
                    return fulfillment?.needFulfilledWithShoppingList == true && fulfillment?.needFulfilled != true
                case .notEnoughInStock:
                    return fulfillment?.needFulfilled != true && fulfillment?.needFulfilledWithShoppingList != true
                }
            })
    }

    var filteredRecipes: Recipes {
        let filtered = getFilteredRecipes(for: filteredStatus)

        switch sortOption {
        case .name:
            return filtered.sorted { recipe1, recipe2 in
                let comparison = recipe1.name.localizedCaseInsensitiveCompare(recipe2.name)
                let result = comparison == .orderedAscending
                return sortOrder == .forward ? result : !result
            }
        case .dueScore:
            return filtered.sorted { recipe1, recipe2 in
                let fulfillment1 = recipeFulfilments.first(where: { $0.recipeID == recipe1.id })?.dueScore ?? 0
                let fulfillment2 = recipeFulfilments.first(where: { $0.recipeID == recipe2.id })?.dueScore ?? 0
                let result = fulfillment1 < fulfillment2
                return sortOrder == .forward ? result : !result
            }
        }
    }

    private func getRecipeCount(for status: RecipeStatus) -> Int {
        getFilteredRecipes(for: status).count
    }

    var enoughInStockCount: Int {
        getRecipeCount(for: .enoughInStock)
    }

    var alreadyOnShoppingListCount: Int {
        getRecipeCount(for: .alreadyOnShoppingList)
    }

    var notEnoughInStockCount: Int {
        getRecipeCount(for: .notEnoughInStock)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Section {
                    RecipeFilterActionsView(filteredStatus: $filteredStatus, enoughInStockCount: enoughInStockCount, alreadyOnShoppingListCount: alreadyOnShoppingListCount, notEnoughInStockCount: notEnoughInStockCount)
                        .listRowInsets(EdgeInsets())
                }
                ForEach(filteredRecipes, id: \.id) { recipe in
                    NavigationLink(
                        value: RecipeInteraction.showRecipe(recipe: recipe),
                        label: {
                            RecipeRowView(recipe: recipe, fulfillment: recipeFulfilments.first(where: { $0.recipeID == recipe.id }))
                                .foregroundStyle(.foreground)
                        }
                    )
                    .contextMenu(menuItems: {
                        NavigationLink(
                            value: RecipeInteraction.editRecipe(recipe: recipe),
                            label: {
                                Label("Edit this item", systemImage: MySymbols.edit)
                            }
                        )
                        if devMode {
                            Button(
                                action: {
                                },
                                label: {
                                    Label("Add to meal plan", systemImage: MySymbols.new)
                                }
                            )
                        }
                        Button(
                            role: .destructive,
                            action: {
                                deleteItem(itemToDelete: recipe)
                            },
                            label: {
                                Label("Delete this item", systemImage: MySymbols.delete)
                            }
                        )
                        Button(
                            action: {
                                Task {
                                    await copyRecipe(recipeID: recipe.id)
                                }
                            },
                            label: {
                                Label("Copy recipe", systemImage: "document.on.document")
                            }
                        )
                    })
                }
            }
            .padding(8)
        }
        .navigationTitle("Recipes")
        .navigationDestination(for: RecipeInteraction.self) { interaction in
            switch interaction {
            case .showRecipe(let recipe):
                RecipeView(initialRecipe: recipe)
            case .editRecipe(let recipe):
                RecipeFormView(existingRecipe: recipe)
            }
        }
        .alert(
            "Are you sure you want to delete recipe \"\(recipeToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let toDelID = recipeToDelete?.id {
                        Task {
                            await deleteRecipe(toDelID: toDelID)
                        }
                    }
                }
            }
        )
        .sheet(isPresented: $showAddRecipe) {
            NavigationStack {
                RecipeFormView()
            }
        }
        .refreshable(action: {
            await updateData()
        })
        .task {
            await updateData()
            initialLoadDone = true
        }
        .onAppear {
            guard !initialLoadDone else { return }
            Task { await updateData() }
        }
        .searchable(text: $searchString, prompt: "Search")
        .animation(.default, value: filteredStatus)
        .animation(.default, value: sortOption)
        .animation(.default, value: sortOrderKey)
        .animation(.default, value: searchString)
        .toolbar {
            ToolbarItem(
                placement: .topBarLeading,
                content: {
                    sortMenu
                }
            )
            ToolbarItem(
                placement: .automatic,
                content: {
                    #if os(macOS)
                        RefreshButton(updateData: { Task { await updateData() } })
                    #endif
                }
            )
            ToolbarSpacer(.fixed)
            ToolbarItem(
                placement: .primaryAction,
                content: {
                    Button(
                        action: {
                            showAddRecipe = true
                        },
                        label: {
                            Label("Create recipe", systemImage: MySymbols.new)
                        }
                    )
                }
            )
        }
    }

    var sortMenu: some View {
        Menu(
            content: {
                Picker(
                    "Sort category",
                    systemImage: MySymbols.sortCategory,
                    selection: $sortOption,
                    content: {
                        Label("Name", systemImage: MySymbols.product)
                            .labelStyle(.titleAndIcon)
                            .tag(RecipeSortOption.name)
                        Label("Due score", systemImage: MySymbols.amount)
                            .labelStyle(.titleAndIcon)
                            .tag(RecipeSortOption.dueScore)
                    }
                )
                #if os(iOS)
                    .pickerStyle(.menu)
                #else
                    .pickerStyle(.inline)
                #endif

                Picker(
                    "Sort order",
                    systemImage: MySymbols.sortOrder,
                    selection: Binding(
                        get: { sortOrder },
                        set: { setSortOrder($0) }
                    ),
                    content: {
                        Label("Ascending", systemImage: MySymbols.sortForward)
                            .labelStyle(.titleAndIcon)
                            .tag(SortOrder.forward)
                        Label("Descending", systemImage: MySymbols.sortReverse)
                            .labelStyle(.titleAndIcon)
                            .tag(SortOrder.reverse)
                    }
                )
                #if os(iOS)
                    .pickerStyle(.menu)
                #else
                    .pickerStyle(.inline)
                #endif
            },
            label: {
                Label("Sort", systemImage: MySymbols.sort)
            }
        )
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        RecipesView()
    }
}
