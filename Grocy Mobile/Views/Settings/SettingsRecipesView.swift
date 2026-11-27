//
//  SettingsRecipesView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import SwiftUI

/// Grocy's recipes settings that apply to the app: the ingredient checkboxes and the grouping of the ingredients.
struct SettingsRecipesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var body: some View {
        Form {
            Section("Recipes") {
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.recipesShowIngredientCheckbox.rawValue,
                    description: "Show a little checkbox next to each ingredient to mark it as done",
                    descriptionInfo:
                        "The ingredient is crossed out when clicked, the status is not saved, means reset when the page is reloaded",
                    icon: MySymbols.miseEnPlace
                )
            }
            Section("Recipe card") {
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.recipeIngredientsGroupByProductGroup.rawValue,
                    description: "Group ingredients by their product group",
                    icon: MySymbols.productGroup
                )
            }
        }
        .formStyle(.grouped)
        .navigationTitle(SettingsNavigationItem.recipesSettings.title)
        .onDisappear {
            Task {
                await grocyVM.requestData(additionalObjects: [.user_settings])
            }
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        SettingsRecipesView()
    }
}
