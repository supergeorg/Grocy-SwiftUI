//
//  RecipeImportIngredientFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 14.11.26.
//

import SwiftData
import SwiftUI

/// Edits how an ingredient from a website is saved: its product, amount and unit.
/// Suggests products with a similar name, and creates a missing product or quantity unit.
struct RecipeImportIngredientFormView: View {
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(filter: #Predicate<MDQuantityUnit> { $0.active }, sort: \MDQuantityUnit.name, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query var userSettingsList: GrocyUserSettingsList
    @Query(filter: #Predicate<MDLocation> { $0.active }, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query(filter: #Predicate<MDProductGroup> { $0.active }, sort: \MDProductGroup.name, order: .forward) var mdProductGroups: MDProductGroups

    @Binding var ingredient: ImportedIngredient

    @State private var showCreateProduct: Bool = false
    @State private var createdProductID: Int? = nil
    @State private var showCreateQuantityUnit: Bool = false
    @State private var createdQuantityUnitID: Int? = nil
    @State private var showConnectUnit: Bool = false
    @State private var didConnectUnit: Bool = false
    /// Prepares the location, product group and unit of a new product while the person looks at the ingredient,
    /// so they are ready when the product form opens.
    @State private var productSuggester = ProductPropertySuggester()

    private var mapper: RecipeImportMapper {
        RecipeImportMapper(products: mdProducts, quantityUnits: mdQuantityUnits, conversions: mdQuantityUnitConversions)
    }

    private var product: MDProduct? {
        mdProducts.first(where: { $0.id == ingredient.productID })
    }

    private var quantityUnit: MDQuantityUnit? {
        mdQuantityUnits.first(where: { $0.id == ingredient.quID })
    }

    private var stockQuantityUnit: MDQuantityUnit? {
        mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }

    /// Products with a similar name, best first.
    private var productCandidates: [ProductMatchCandidate] {
        let candidates = mapper.productCandidates(for: ingredient.line.name, note: ingredient.line.note)
        // A product from Apple Intelligence has a different name, so it's listed first to confirm it with one tap
        if ingredient.productMatch == .intelligence, let product, !candidates.contains(where: { $0.product.id == product.id }) {
            return [ProductMatchCandidate(product: product, score: 0)] + candidates
        }
        return candidates
    }

    /// Similar products are only worth showing when there's something to choose or to confirm.
    private var showsSuggestions: Bool {
        let otherCandidates = productCandidates.contains { $0.product.id != ingredient.productID }
        return otherCandidates || ingredient.productMatch.needsCheck || showsCreateProduct
    }

    /// Creating a product is offered unless one with the ingredient's name exists.
    private var showsCreateProduct: Bool {
        !productCandidates.contains { $0.quality == .exact }
    }

    /// Starts Apple Intelligence on the properties of the product to create, unless they're ready or being prepared.
    private func prepareProductSuggestions() {
        guard ProductPropertySuggester.isEnabled, showsCreateProduct, ingredient.productID == nil || ingredient.productMatch.needsCheck,
            !productSuggester.isRunning, !productSuggester.isFinished(for: ingredient.line.name)
        else { return }
        // Presets of the user settings are already filled in by the product form
        let userSettings = userSettingsList.first
        var skipping: Set<ProductPropertySuggester.Step> = []
        if let locationID = userSettings?.productPresetsLocationID, locationID != -1 { skipping.insert(.location) }
        if let productGroupID = userSettings?.productPresetsProductGroupID, productGroupID != -1 { skipping.insert(.productGroup) }
        if let quantityUnitID = userSettings?.productPresetsQuID, quantityUnitID != -1 { skipping.insert(.quantityUnit) }
        productSuggester.start(
            productName: ingredient.line.name,
            locations: mdLocations,
            productGroups: mdProductGroups,
            quantityUnits: mdQuantityUnits,
            products: mdProducts,
            usage: ingredient.line.originalText,
            skipping: skipping
        )
    }

    /// Choosing a product or unit by hand marks it as the person's choice, so it isn't shown as a suggestion anymore.
    private var productSelection: Binding<Int?> {
        Binding(
            get: { ingredient.productID },
            set: { newValue in
                ingredient.productID = newValue
                ingredient.productMatch = .manual
            }
        )
    }

    private var unitSelection: Binding<Int?> {
        Binding(
            get: { ingredient.quID },
            set: { newValue in
                ingredient.quID = newValue
                ingredient.unitMatch = .manual
                mapper.unitChanged(&ingredient)
            }
        )
    }

    /// The unit as written on the website, e.g. "Bund".
    private var websiteUnit: String? {
        ingredient.line.unit
    }

    /// The amount in the product's stock unit, or `nil` when the units can't be converted.
    private var stockAmount: Double? {
        guard let product, let quID = ingredient.quID else { return nil }
        return mapper.stockAmount(for: ingredient.amount, quID: quID, product: product)
    }

    /// The selected unit exists, but there's no conversion to the product's stock unit, so it can be connected to the product.
    private var unitToConnect: MDQuantityUnit? {
        guard let product, let quantityUnit, !ingredient.hasUnmatchedUnit, stockAmount == nil else { return nil }
        return mapper.needsUnitConnection(ingredient, product: product) ? quantityUnit : nil
    }

    var body: some View {
        Form {
            Section {
                Text(ingredient.line.originalText)
                    .textSelection(.enabled)
            } header: {
                Text("On the website")
            }

            MyToggle(
                isOn: $ingredient.isIncluded,
                description: "Import this ingredient",
                icon: MySymbols.importRecipe
            )

            if ingredient.isIncluded {
                Section {
                    ProductField(productID: productSelection, description: "Product")
                        .onChange(of: ingredient.productID) {
                            mapper.productChanged(&ingredient)
                        }
                } footer: {
                    if ingredient.productID == nil {
                        Text("Grocy needs a product for every ingredient. Ingredients without a product aren't imported.")
                    } else if ingredient.productMatch == .intelligence {
                        Label {
                            Text("Suggested by Apple Intelligence. Check that it's the right product.")
                        } icon: {
                            Image(systemName: MySymbols.appleIntelligence)
                        }
                    } else if ingredient.productMatch == .suggested {
                        Label {
                            Text("Suggested because the names are similar. Check that it's the right product.")
                        } icon: {
                            Image(systemName: MySymbols.suggestedMatch)
                        }
                    }
                }

                if showsSuggestions {
                    suggestionsSection
                }

                if product != nil {
                    amountSection

                    MyToggle(
                        isOn: $ingredient.onlyCheckSingleUnitInStock,
                        description: "Only check if any amount is in stock",
                        descriptionInfo: "A different amount/unit can then be used below while for stock fulfillment checking it is sufficient when any amount of the product in stock",
                        icon: MySymbols.stockOverview
                    )

                    MyTextField(
                        textToEdit: $ingredient.variableAmount,
                        description: "Variable amount",
                        isCorrect: .constant(true),
                        leadingIcon: MySymbols.amount,
                        helpText: "When this is not empty, it will be shown instead of the amount entered above while the amount there will still be used for stock fulfillment checking"
                    )

                    MyTextField(
                        textToEdit: $ingredient.ingredientGroup,
                        description: "Group",
                        isCorrect: .constant(true),
                        leadingIcon: MySymbols.groupBy,
                        helpText: "This will be used as a headline to group ingredients together"
                    )

                    MyTextEditor(textToEdit: $ingredient.note, description: "Note", leadingIcon: MySymbols.description)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Edit recipe ingredient")
        .task {
            prepareProductSuggestions()
        }
        .onDisappear {
            // Also when a product is picked from the list; the task starts it again on return
            productSuggester.stop()
        }
        .sheet(isPresented: $showCreateProduct) {
            NavigationStack {
                MDProductFormView(userSettings: userSettingsList.first, productName: ingredient.line.name, createdProductID: $createdProductID, suggester: productSuggester)
            }
        }
        .sheet(
            isPresented: $showCreateQuantityUnit,
            onDismiss: {
                // A new unit has no conversions yet, so connecting it to the product is the next step.
                if createdQuantityUnitID != nil, unitToConnect != nil {
                    showConnectUnit = true
                }
            },
            content: {
                NavigationStack {
                    MDQuantityUnitFormView(name: ingredient.newUnitName, namePlural: ingredient.newUnitNamePlural, createdQuantityUnitID: $createdQuantityUnitID)
                }
            }
        )
        .sheet(isPresented: $showConnectUnit) {
            if let product, let quantityUnit {
                NavigationStack {
                    RecipeImportUnitConversionFormView(product: product, quantityUnit: quantityUnit, didSave: $didConnectUnit)
                }
            }
        }
        .onChange(of: createdProductID) {
            if let createdProductID {
                ingredient.productID = createdProductID
                ingredient.productMatch = .manual
            }
        }
        .onChange(of: createdQuantityUnitID) {
            if let createdQuantityUnitID {
                ingredient.quID = createdQuantityUnitID
                ingredient.unitMatch = .exact
                mapper.unitChanged(&ingredient)
            }
        }
        .onChange(of: didConnectUnit) {
            if didConnectUnit {
                mapper.unitChanged(&ingredient)
                didConnectUnit = false
            }
        }
    }

    /// Products with a similar name to pick with one tap, and creating a new product.
    private var suggestionsSection: some View {
        Section {
            ForEach(productCandidates, id: \.product.id) { candidate in
                Button(
                    action: {
                        productSelection.wrappedValue = candidate.product.id
                    },
                    label: {
                        HStack {
                            Label(candidate.product.name, systemImage: MySymbols.product)
                                .foregroundStyle(.primary)
                            Spacer()
                            if candidate.product.id == ingredient.productID {
                                Image(systemName: MySymbols.success)
                                    .foregroundStyle(.tint)
                                    .accessibilityLabel("Selected")
                            }
                        }
                        .contentShape(.rect)
                    }
                )
                .buttonStyle(.plain)
                .accessibilityAddTraits(candidate.product.id == ingredient.productID ? .isSelected : [])
            }

            if showsCreateProduct {
                Button(
                    action: {
                        showCreateProduct = true
                    },
                    label: {
                        // Apple Intelligence prepares the product's properties quietly in the background;
                        // the product form shows its progress and what it filled in.
                        Label {
                            VStack(alignment: .leading, spacing: Spacing.hairline) {
                                Text("Create product “\(ingredient.line.name)”")
                                if productSuggester.isFinished(for: ingredient.line.name), productSuggester.suggestions != ProductPropertySuggestions() {
                                    Text("With suggestions from Apple Intelligence")
                                        .font(.caption)
                                        // Gray: the button's own secondary style would tint it.
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: MySymbols.new)
                        }
                    }
                )
            }
        } header: {
            if !productCandidates.isEmpty {
                Text("Similar products")
            }
        } footer: {
            if ingredient.productMatch.needsCheck, productCandidates.contains(where: { $0.product.id == ingredient.productID }) {
                Text("Select the product to confirm it.")
            }
        }
    }

    private var amountSection: some View {
        Section {
            MyDoubleStepper(
                amount: $ingredient.amount,
                description: "Amount",
                minAmount: 0.0000001,
                amountStep: 1.0,
                amountName: quantityUnit?.getName(amount: ingredient.amount),
                systemImage: MySymbols.amount
            )

            Picker(
                selection: unitSelection,
                content: {
                    Text("")
                        .tag(Int?.none)
                    ForEach(mdQuantityUnits, id: \.id) { unit in
                        Text(unit.name)
                            .tag(Optional(unit.id))
                    }
                },
                label: {
                    Label("Quantity unit", systemImage: MySymbols.quantityUnit)
                        .foregroundStyle(.primary)
                }
            )

            if let websiteUnit, ingredient.hasUnmatchedUnit {
                Button(
                    action: {
                        createdQuantityUnitID = nil
                        showCreateQuantityUnit = true
                    },
                    label: {
                        Label("Create quantity unit “\(ingredient.newUnitName.isEmpty ? websiteUnit : ingredient.newUnitName)”", systemImage: MySymbols.new)
                    }
                )
            } else if let unitToConnect, let product {
                Button(
                    action: {
                        showConnectUnit = true
                    },
                    label: {
                        Label("Connect “\(unitToConnect.name)” to “\(product.name)”", systemImage: MySymbols.connectUnit)
                    }
                )
            }
        } header: {
            Text("Amount")
        } footer: {
            if let websiteUnit, ingredient.hasUnmatchedUnit {
                Label {
                    Text("No quantity unit matches “\(websiteUnit)” from the website. Create it, or choose another unit.")
                } icon: {
                    Image(systemName: MySymbols.warning)
                        .foregroundStyle(Color(.GrocyColors.grocyYellow))
                }
            } else if let websiteUnit, ingredient.unitMatch == .suggested, let quantityUnit {
                Label {
                    Text("“\(websiteUnit)” from the website was matched to the similar unit “\(quantityUnit.name)”.")
                } icon: {
                    Image(systemName: MySymbols.suggestedMatch)
                }
            } else if ingredient.quID == nil {
                Text("A quantity unit is required")
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
            } else if let stockAmount {
                if ingredient.quID != product?.quIDStock {
                    Text("This equals \(stockAmount.formatted(.number.precision(.fractionLength(0...8)))) \(stockQuantityUnit?.getName(amount: stockAmount) ?? "?")")
                }
            } else {
                Text("There's no unit conversion to the product's stock unit \"\(stockQuantityUnit?.name ?? "?")\". Only whether any amount is in stock can be checked.")
                if unitToConnect != nil {
                    Text("Connect the unit to the product to check the amount in stock.")
                }
            }
        }
    }
}

#Preview("Matched", traits: .previewData) {
    @Previewable @State var ingredient = ImportedIngredient(
        line: IngredientLineParser.parse("200 g Butter, weich"),
        productID: 1,
        amount: 200,
        quID: 1,
        note: "weich",
        ingredientGroup: "",
        variableAmount: "",
        onlyCheckSingleUnitInStock: false,
        productMatch: .exact,
        unitMatch: .exact
    )
    NavigationStack {
        RecipeImportIngredientFormView(ingredient: $ingredient)
    }
}

#Preview("Unknown unit", traits: .previewData) {
    @Previewable @State var ingredient = ImportedIngredient(
        line: IngredientLineParser.parse("1 Bund Petersilie"),
        productID: 1,
        amount: 1,
        quID: 1,
        note: "",
        ingredientGroup: "",
        variableAmount: "1 Bund",
        onlyCheckSingleUnitInStock: true,
        productMatch: .suggested,
        unitMatch: .none,
        newUnitName: "Bund",
        newUnitNamePlural: "Bund"
    )
    NavigationStack {
        RecipeImportIngredientFormView(ingredient: $ingredient)
    }
}
