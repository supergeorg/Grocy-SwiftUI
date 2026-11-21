//
//  RecipeMenuEntriesView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 21.11.26.
//

import SwiftData
import SwiftUI

/// What a recipe's actions ask the screen to show: the meal plan form, the delete confirmation and its error.
@Observable
class RecipeActionsRouter {
    var recipeToPlan: Recipe?
    var recipeToDelete: Recipe?
    var showDeleteConfirmation: Bool = false
    var deleteErrorMessage: String?

    func plan(_ recipe: Recipe) {
        recipeToPlan = recipe
    }

    func delete(_ recipe: Recipe) {
        recipeToDelete = recipe
        showDeleteConfirmation = true
    }
}

/// The entries of a recipe's context menu, in the recipe overview and the search.
struct RecipeMenuEntriesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(RecipeActionsRouter.self) private var router

    @Query private var systemConfigList: [SystemConfig]
    private var systemConfig: SystemConfig? { systemConfigList.first }

    var recipe: Recipe

    private func copyRecipe() async {
        do {
            try await grocyVM.copyRecipe(recipeID: recipe.id)
            GrocyLogger.info("Copying recipe \(recipe.id) was successful.")
            await grocyVM.requestData(objects: RecipeActions.dataToUpdate, additionalObjects: RecipeActions.additionalDataToUpdate)
        } catch {
            GrocyLogger.error("Copying recipe failed. \(error)")
        }
    }

    var body: some View {
        NavigationLink(value: RecipeInteraction.editRecipe(recipe: recipe)) {
            Label("Edit this item", systemImage: MySymbols.edit)
        }
        if systemConfig?.featureFlagRecipesMealplan != false {
            Button {
                router.plan(recipe)
            } label: {
                Label("Add to meal plan", systemImage: MySymbols.mealPlan)
            }
        }
        Button {
            Task { await copyRecipe() }
        } label: {
            Label("Copy recipe", systemImage: MySymbols.duplicate)
        }
        Button(role: .destructive) {
            router.delete(recipe)
        } label: {
            Label("Delete this item", systemImage: MySymbols.delete)
        }
    }
}

extension View {
    /// A recipe row's context menu and swipe actions (delete, edit), as in the recipe overview's list.
    /// Needs `recipeActions(router:)` further out.
    func recipeRowActions(_ recipe: Recipe) -> some View {
        self
            .contextMenu { RecipeMenuEntriesView(recipe: recipe) }
            .swipeActions(edge: .trailing) {
                RecipeDeleteButton(recipe: recipe)
            }
            .swipeActions(edge: .leading) {
                NavigationLink(value: RecipeInteraction.editRecipe(recipe: recipe)) {
                    Label("Edit", systemImage: MySymbols.edit)
                }
                .tint(Color(.GrocyColors.grocyTurquoise))
            }
    }

    /// Carries out the recipe actions of the rows below: provides the router to them, opens a recipe or its form,
    /// and shows the meal plan form and the delete confirmation.
    func recipeActions(router: RecipeActionsRouter) -> some View {
        modifier(RecipeActions(router: router))
    }
}

private struct RecipeDeleteButton: View {
    @Environment(RecipeActionsRouter.self) private var router

    var recipe: Recipe

    var body: some View {
        Button(role: .destructive) {
            router.delete(recipe)
        } label: {
            Label("Delete", systemImage: MySymbols.delete)
        }
    }
}

private struct RecipeActions: ViewModifier {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Bindable var router: RecipeActionsRouter

    /// What a change of a recipe makes outdated.
    static let dataToUpdate: [ObjectEntities] = [.recipes]
    static let additionalDataToUpdate: [AdditionalEntities] = [.recipeFulfillments]

    private func deleteRecipe(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .recipes, id: toDelID)
            GrocyLogger.info("Deleting recipe was successful.")
            await grocyVM.requestData(objects: Self.dataToUpdate, additionalObjects: Self.additionalDataToUpdate)
        } catch {
            GrocyLogger.error("Deleting recipe failed. \(error)")
            if let apiError = error as? APIError {
                router.deleteErrorMessage = apiError.displayMessage
            } else {
                router.deleteErrorMessage = error.localizedDescription
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .environment(router)
            .navigationDestination(for: RecipeInteraction.self) { interaction in
                switch interaction {
                case .showRecipe(let recipe):
                    RecipeView(initialRecipe: recipe)
                case .editRecipe(let recipe):
                    RecipeFormView(existingRecipe: recipe)
                }
            }
            .alert(
                "Are you sure you want to delete recipe \"\(router.recipeToDelete?.name ?? "")\"?",
                isPresented: $router.showDeleteConfirmation,
                actions: {
                    Button("Cancel", role: .cancel) {}
                    // No destructive role: the person chose to delete, this button carries out their intent (HIG).
                    Button("Delete") {
                        if let toDelID = router.recipeToDelete?.id {
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
                "Couldn't delete \"\(router.recipeToDelete?.name ?? "")\"",
                isPresented: Binding(
                    get: { router.deleteErrorMessage != nil },
                    set: { if !$0 { router.deleteErrorMessage = nil } }
                ),
                actions: {
                    Button("OK", role: .cancel) {}
                },
                message: {
                    Text(router.deleteErrorMessage ?? "")
                }
            )
            .sheet(item: $router.recipeToPlan) { recipe in
                NavigationStack {
                    MealPlanEntryFormView(recipeID: recipe.id)
                }
            }
    }
}

#Preview(traits: .previewData) {
    Menu("Preview") {
        RecipeMenuEntriesView(recipe: Recipe(name: "Pancakes"))
    }
    .environment(RecipeActionsRouter())
}
