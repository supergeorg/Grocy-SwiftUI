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
        return true
    }

    init(existingRecipeNesting: RecipeNesting? = nil, recipeID: Int) {
        self.existingRecipeNesting = existingRecipeNesting
        self.recipeID = recipeID
        self.recipeNesting = existingRecipeNesting ?? RecipeNesting(recipeID: recipeID)
    }

    private let dataToUpdate: [ObjectEntities] = [.recipes]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func finishForm() {
        dismiss()
    }

    private func saveRecipeNesting() async {
        //        if location.id == -1 {
        //            do {
        //                location.id = try grocyVM.findNextID(.locations)
        //            } catch {
        //                GrocyLogger.error("Failed to get next ID: \(error)")
        //                return
        //            }
        //        }
        //        isProcessing = true
        //        isSuccessful = nil
        //        do {
        //            try location.modelContext?.save()
        //            if existingLocation == nil {
        //                _ = try await grocyVM.postMDObject(object: .locations, content: location)
        //            } else {
        //                try await grocyVM.putMDObjectWithID(object: .locations, id: location.id, content: location)
        //            }
        //            GrocyLogger.info("Location \(location.name) successful.")
        //            await updateData()
        //            isSuccessful = true
        //        } catch {
        //            GrocyLogger.error("Location \(location.name) failed. \(error)")
        //            isSuccessful = false
        //            if let apiError = error as? APIError {
        //                errorMessage = apiError.displayMessage
        //            } else {
        //                errorMessage = error.localizedDescription
        //            }
        //        }
        //        isProcessing = false
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
                    ForEach(recipes, id: \.id) { recipe in
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
                            if !isProcessing {
                                // Label style is left to the system, so the confirm button gets the standard Liquid Glass look.
                                Label("Save", systemImage: MySymbols.save)
                            } else {
                                ProgressView().progressViewStyle(.circular)
                            }
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
