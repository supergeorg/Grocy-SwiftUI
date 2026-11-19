//
//  NestedRecipeFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 04.02.26.
//

import SwiftData
import SwiftUI

struct NestedRecipeFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \Recipe.name, order: .forward) var recipes: Recipes

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingRecipeNesting: RecipeNesting?
    var recipeID: Int
    @State var recipeNesting: RecipeNesting

    @State private var isFormCorrect: Bool = false
    private func checkFormCorrect() -> Bool {
        guard recipeNesting.recipeID != -1 else { return false }
        // A recipe can't include itself.
        guard recipeNesting.includesRecipeID != -1, recipeNesting.includesRecipeID != recipeNesting.recipeID else { return false }
        return recipeNesting.servings > 0
    }

    init(existingRecipeNesting: RecipeNesting? = nil, recipeID: Int) {
        self.existingRecipeNesting = existingRecipeNesting
        self.recipeID = recipeID
        self.recipeNesting = existingRecipeNesting ?? RecipeNesting(recipeID: recipeID)
    }

    private let dataToUpdate: [ObjectEntities] = [.recipes, .recipes_nestings]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func finishForm() {
        dismiss()
    }

    private func saveRecipeNesting() async {
        if recipeNesting.id == -1 {
            do {
                recipeNesting.id = try grocyVM.findNextID(.recipes_nestings)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            if existingRecipeNesting == nil {
                _ = try await grocyVM.postMDObject(object: .recipes_nestings, content: recipeNesting)
            } else {
                try await grocyVM.putMDObjectWithID(object: .recipes_nestings, id: recipeNesting.id, content: recipeNesting)
            }
            GrocyLogger.info("Saving included recipe \(recipeNesting.includesRecipeID) was successful.")
            await grocyVM.requestData(objects: [.recipes_nestings])
            isSuccessful = true
        } catch {
            GrocyLogger.error("Saving included recipe \(recipeNesting.includesRecipeID) failed. \(error)")
            isSuccessful = false
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage = errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            Picker(
                selection: $recipeNesting.includesRecipeID,
                content: {
                    Text("").tag(-1)
                    ForEach(recipes.filter { $0.id != recipeID }, id: \.id) { recipe in
                        Text(recipe.name).tag(recipe.id)
                    }
                },
                label: {
                    Label("Recipe", systemImage: MySymbols.recipe)
                        .foregroundStyle(.primary)
                }
            )
            MyDoubleStepper(amount: $recipeNesting.servings, description: "Servings", systemImage: MySymbols.amount)
        }
        .formStyle(.grouped)
        .onChange(of: recipeNesting.includesRecipeID) {
            isFormCorrect = checkFormCorrect()
        }
        .onChange(of: recipeNesting.servings) {
            isFormCorrect = checkFormCorrect()
        }
        .task {
            await updateData()
            self.isFormCorrect = checkFormCorrect()
        }
        .navigationTitle(existingRecipeNesting == nil ? "Add included recipe" : "Edit included recipe")
        .toolbar(content: {
            if existingRecipeNesting == nil {
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button(
                            role: .cancel,
                            action: {
                                finishForm()
                            }
                        )
                        .keyboardShortcut(.cancelAction)
                    }
                )
            }
            ToolbarItem(
                placement: .confirmationAction,
                content: {
                    Button(
                        role: .confirm,
                        action: {
                            Task {
                                await saveRecipeNesting()
                            }
                        },
                        label: {
                            // Label style is left to the system, so the confirm button gets the standard Liquid Glass look.
                            // While it runs, the icon becomes an animated progress symbol. It stays an image: with a ProgressView as its icon,
                            // the item loses its icon and leaves iPhone Duo's vertical bar for a text-only button at the bottom.
                            Label("Save", systemImage: isProcessing ? MySymbols.progress : MySymbols.save)
                                .symbolEffect(.variableColor.iterative, isActive: isProcessing)
                        }
                    )
                    .disabled(!isFormCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
            )
        })
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                finishForm()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        NestedRecipeFormView(recipeID: -1)
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        NestedRecipeFormView(existingRecipeNesting: RecipeNesting(servings: 1.0), recipeID: -1)
    }
}
