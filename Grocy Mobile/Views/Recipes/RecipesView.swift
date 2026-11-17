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

/// How the recipe overview shows the recipes.
enum RecipesLayout: String {
    /// Rows with a small picture.
    case list
    /// Cards with a large picture, in at least two columns.
    case gallery

    /// The list in compact width, where the screen is narrow; the gallery in regular width and on Mac, where there's room for pictures.
    /// From the size class rather than the device, so the inner display of iPhone Duo gets the gallery.
    static func defaultLayout(for horizontalSizeClass: UserInterfaceSizeClass?) -> RecipesLayout {
        horizontalSizeClass == .compact ? .list : .gallery
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
    @State private var showImportRecipe: Bool = false
    @State private var recipeToDelete: Recipe? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var deleteErrorMessage: String? = nil
    @AppStorage("RecipesView.sortOption") private var sortOption: RecipeSortOption = .dueScore
    @AppStorage("RecipesView.sortOrder") private var sortOrderKey: String = "reverse"
    @State private var filteredStatus: RecipeStatus = .all
    /// Only set once the user picks a layout; until then it follows the width (`RecipesLayout.defaultLayout(for:)`).
    @AppStorage("RecipesView.layout") private var storedLayout: RecipesLayout?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var layout: RecipesLayout {
        storedLayout ?? RecipesLayout.defaultLayout(for: horizontalSizeClass)
    }
    /// Width of the gallery, to fit as many columns as possible.
    @State private var galleryWidth: CGFloat = 0

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
            if let apiError = error as? APIError {
                deleteErrorMessage = apiError.displayMessage
            } else {
                deleteErrorMessage = error.localizedDescription
            }
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

    private func fulfillment(for recipe: Recipe) -> RecipeFulfilment? {
        recipeFulfilments.first(where: { $0.recipeID == recipe.id })
    }

    /// As many columns as fit, but at least two.
    private var galleryColumns: [GridItem] {
        let usableWidth = galleryWidth - 2 * Spacing.large + Spacing.medium
        let count = max(2, Int(usableWidth / (Sizes.recipeCardMinWidth + Spacing.medium)))
        return Array(repeating: GridItem(.flexible(), spacing: Spacing.medium, alignment: .top), count: count)
    }

    @ViewBuilder
    private var recipesContent: some View {
        switch layout {
        case .list:
            List {
                ForEach(filteredRecipes, id: \.id) { recipe in
                    NavigationLink(value: RecipeInteraction.showRecipe(recipe: recipe)) {
                        RecipeRowView(recipe: recipe, fulfillment: fulfillment(for: recipe))
                    }
                    .contextMenu { recipeMenuItems(recipe: recipe) }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteItem(itemToDelete: recipe)
                        } label: {
                            Label("Delete", systemImage: MySymbols.delete)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        NavigationLink(value: RecipeInteraction.editRecipe(recipe: recipe)) {
                            Label("Edit", systemImage: MySymbols.edit)
                        }
                        .tint(Color(.GrocyColors.grocyTurquoise))
                    }
                }
            }
        case .gallery:
            ScrollView {
                LazyVGrid(columns: galleryColumns, spacing: Spacing.medium) {
                    ForEach(filteredRecipes, id: \.id) { recipe in
                        NavigationLink(value: RecipeInteraction.showRecipe(recipe: recipe)) {
                            RecipeCardView(recipe: recipe, fulfillment: fulfillment(for: recipe))
                        }
                        .buttonStyle(.plain)
                        .contextMenu { recipeMenuItems(recipe: recipe) }
                    }
                }
                .padding(.horizontal, Spacing.large)
                .padding(.vertical, Spacing.small)
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                galleryWidth = width
            }
        }
    }

    @ViewBuilder
    private func recipeMenuItems(recipe: Recipe) -> some View {
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
            action: {
                Task {
                    await copyRecipe(recipeID: recipe.id)
                }
            },
            label: {
                Label("Copy recipe", systemImage: MySymbols.duplicate)
            }
        )
        Button(
            role: .destructive,
            action: {
                deleteItem(itemToDelete: recipe)
            },
            label: {
                Label("Delete this item", systemImage: MySymbols.delete)
            }
        )
    }

    var body: some View {
        recipesContent
            .overlay {
                if recipes.filter({ $0.type == .normal }).isEmpty {
                    ContentUnavailableView("No recipe defined. Please create one.", systemImage: MySymbols.recipe)
                } else if filteredRecipes.isEmpty {
                    ContentUnavailableView.search
                }
            }
        .refreshable(action: {
            await updateData()
        })
        // The capsules float in a bar above the recipes (the navigation layer), as in the other overviews
        .safeAreaBar(edge: .top) {
            RecipeFilterActionsView(filteredStatus: $filteredStatus, enoughInStockCount: enoughInStockCount, alreadyOnShoppingListCount: alreadyOnShoppingListCount, notEnoughInStockCount: notEnoughInStockCount)
                .padding(.vertical, Spacing.small)
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
                // No destructive role: the person chose to delete, this button carries out their intent (HIG).
                Button("Delete") {
                    if let toDelID = recipeToDelete?.id {
                        Task {
                            await deleteRecipe(toDelID: toDelID)
                        }
                    }
                }
            },
            message: {
                Text("This can't be undone.")
            }
        )
        .alert(
            "Couldn't delete \"\(recipeToDelete?.name ?? "")\"",
            isPresented: Binding(
                get: { deleteErrorMessage != nil },
                set: { if !$0 { deleteErrorMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(deleteErrorMessage ?? "")
            }
        )
        .sheet(isPresented: $showAddRecipe) {
            NavigationStack {
                RecipeFormView()
            }
        }
        #if os(iOS)
            .sheet(isPresented: $showImportRecipe) {
                NavigationStack {
                    RecipeImportView()
                }
            }
        #else
            .navigationDestination(isPresented: $showImportRecipe) {
                RecipeImportView()
            }
        #endif
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
            #if os(iOS)
                ToolbarItemGroup(placement: .topBarLeading) {
                    sortMenu
                    layoutPicker
                }
            #else
                ToolbarItemGroup(placement: .automatic) {
                    sortMenu
                    layoutPicker
                }
            #endif
            ToolbarSpacer(.fixed)
            ToolbarItem(
                placement: .primaryAction,
                content: {
                    Button(
                        action: {
                            showImportRecipe = true
                        },
                        label: {
                            Label("Import recipe from website", systemImage: MySymbols.importRecipe)
                        }
                    )
                }
            )
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

    /// Shows the current layout's symbol; choosing switches between the list and the gallery.
    var layoutPicker: some View {
        Picker("Layout", selection: Binding(get: { layout }, set: { storedLayout = $0 }).animation()) {
            Label("List", systemImage: MySymbols.layoutList)
                .tag(RecipesLayout.list)
            Label("Gallery", systemImage: MySymbols.layoutGallery)
                .tag(RecipesLayout.gallery)
        }
        #if os(macOS)
            // A menu picker in the macOS toolbar shows an empty title; a segmented control with symbols is the Mac's usual view switcher (like Finder).
            .pickerStyle(.segmented)
            .labelStyle(.iconOnly)
            .help("Layout")
        #else
            .pickerStyle(.menu)
        #endif
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
