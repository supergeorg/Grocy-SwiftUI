//
//  MealPlanEntryFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftData
import SwiftUI

/// Plans a recipe, a product or a note for a day and section, or edits a planned entry.
struct MealPlanEntryFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Recipe.name) private var recipesAll: Recipes
    @Query(sort: \MDProduct.name) private var products: MDProducts
    @Query private var quantityUnits: MDQuantityUnits
    @Query private var sectionsAll: MDMealPlanSections
    @Query private var systemConfigList: [SystemConfig]

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingEntry: MealPlanEntry?
    @State private var entry: MealPlanEntry

    /// - Parameters:
    ///   - day: The day of a new entry.
    ///   - sectionID: The section of a new entry.
    ///   - recipeID: Plans this recipe.
    init(existingEntry: MealPlanEntry? = nil, day: Date = Date(), sectionID: Int? = nil, recipeID: Int? = nil) {
        self.existingEntry = existingEntry
        if let existingEntry {
            self.entry = MealPlanEntry(copying: existingEntry)
        } else {
            self.entry = MealPlanEntry(
                day: Calendar.current.startOfDay(for: day),
                type: .recipe,
                recipeID: recipeID,
                sectionID: sectionID ?? MDMealPlanSection.noSectionID
            )
        }
    }

    private let dataToUpdate: [ObjectEntities] = [.meal_plan, .meal_plan_sections, .recipes, .products, .quantity_units]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: [.system_config])
    }

    private var systemConfig: SystemConfig? { systemConfigList.first }

    /// The internal recipes of the meal plan can't be planned.
    private var recipes: Recipes { recipesAll.filter { $0.type == .normal } }

    private var sections: MDMealPlanSections {
        let sorted = sectionsAll.sortedForMealPlan
        // Grocy always has the section without a name; offer it even before the sections are loaded.
        return sorted.contains(where: \.isNoSection) ? sorted : [MDMealPlanSection(id: MDMealPlanSection.noSectionID)] + sorted
    }

    /// Products can only be planned with stock management.
    private var availableTypes: [MealPlanEntryType] {
        systemConfig?.featureFlagStock == false ? [.recipe, .note] : MealPlanEntryType.allCases
    }

    private var selectedProduct: MDProduct? {
        guard let productID = entry.productID else { return nil }
        return products.first { $0.id == productID }
    }

    private var stockQuantityUnit: MDQuantityUnit? {
        guard let selectedProduct else { return nil }
        return quantityUnits.first { $0.id == selectedProduct.quIDStock }
    }

    private var isFormValid: Bool {
        switch entry.type {
        case .recipe: entry.recipeID != nil && entry.recipeServings > 0
        case .product: entry.productID != nil && entry.productAmount > 0
        case .note: !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func saveEntry() async {
        isProcessing = true
        isSuccessful = nil
        do {
            entry.day = Calendar.current.startOfDay(for: entry.day)
            if entry.type == .product {
                // Grocy keeps the amount in the stock unit.
                entry.productQuID = selectedProduct?.quIDStock
            }
            if existingEntry == nil {
                entry.id = try grocyVM.findNextID(.meal_plan)
                _ = try await grocyVM.postMDObject(object: .meal_plan, content: entry)
            } else {
                try await grocyVM.putMDObjectWithID(object: .meal_plan, id: entry.id, content: entry)
            }
            GrocyLogger.info("Saving meal plan entry was successful.")
            // Grocy creates or renames the entry's internal recipes, so they're reloaded too.
            grocyVM.timeStampsObjects[.meal_plan] = nil
            grocyVM.timeStampsObjects[.recipes] = nil
            grocyVM.timeStampsAdditionalObjects[.recipeFulfillments] = nil
            await grocyVM.requestData(objects: [.meal_plan, .recipes], additionalObjects: [.recipeFulfillments])
            isSuccessful = true
        } catch {
            GrocyLogger.error("Saving meal plan entry failed. \(error)")
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
            isSuccessful = false
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }

            Section {
                Picker("Type", selection: $entry.type) {
                    ForEach(availableTypes) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section {
                switch entry.type {
                case .recipe:
                    Picker(
                        selection: $entry.recipeID,
                        label: Label("Recipe", systemImage: MySymbols.recipe).foregroundStyle(.primary),
                        content: {
                            Text("").tag(nil as Int?)
                            ForEach(recipes, id: \.id) { recipe in
                                Text(recipe.name).tag(recipe.id as Int?)
                            }
                        }
                    )
                    MyDoubleStepper(
                        amount: $entry.recipeServings,
                        description: "Servings",
                        minAmount: 0,
                        amountStep: 1,
                        systemImage: MySymbols.servings
                    )
                case .product:
                    ProductField(productID: $entry.productID, description: "Product")
                    MyDoubleStepper(
                        amount: $entry.productAmount,
                        description: "Amount",
                        minAmount: 0,
                        amountStep: 1,
                        amountName: stockQuantityUnit?.getName(amount: entry.productAmount),
                        systemImage: MySymbols.amount
                    )
                case .note:
                    MyTextEditor(textToEdit: $entry.note, description: "Note", leadingIcon: MySymbols.mealPlanNote)
                }
            }

            Section {
                DatePicker(selection: $entry.day, displayedComponents: .date) {
                    Label("Day", systemImage: MySymbols.date)
                        .foregroundStyle(.primary)
                }
                Picker(
                    selection: $entry.sectionID,
                    label: Label("Section", systemImage: MySymbols.mealPlanSection).foregroundStyle(.primary),
                    content: {
                        ForEach(sections, id: \.id) { section in
                            Text(section.isNoSection ? String(localized: "No section") : section.name)
                                .tag(section.id)
                        }
                    }
                )
                if existingEntry != nil {
                    Toggle(isOn: $entry.done) {
                        Label("Done", systemImage: MySymbols.done)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .task {
            await updateData()
        }
        .navigationTitle(existingEntry == nil ? "Add to meal plan" : "Edit meal plan entry")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel, action: { dismiss() })
                    .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await saveEntry()
                        }
                    },
                    label: {
                        // An image, not a ProgressView, so the item keeps its icon while it runs (see `TaskFormView`).
                        Label("Save", systemImage: isProcessing ? MySymbols.progress : MySymbols.save)
                            .symbolEffect(.variableColor.iterative, isActive: isProcessing)
                    }
                )
                .disabled(!isFormValid || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        }
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                dismiss()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

extension MealPlanEntryType {
    var title: LocalizedStringKey {
        switch self {
        case .recipe: "Recipe"
        case .product: "Product"
        case .note: "Note"
        }
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        MealPlanEntryFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        MealPlanEntryFormView(existingEntry: MealPlanEntry(id: 1, type: .note, note: "Leftovers"))
    }
}
