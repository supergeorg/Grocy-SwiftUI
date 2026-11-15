//
//  RecipeImportIngredientFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 14.11.26.
//

import SwiftData
import SwiftUI

/// Edits how an ingredient from a website is saved: its product, amount and unit.
struct RecipeImportIngredientFormView: View {
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(filter: #Predicate<MDQuantityUnit> { $0.active }, sort: \MDQuantityUnit.name, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query var userSettingsList: GrocyUserSettingsList

    @Binding var ingredient: ImportedIngredient

    @State private var showCreateProduct: Bool = false
    @State private var createdProductID: Int? = nil

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

    /// The amount in the product's stock unit, or `nil` when the units can't be converted.
    private var stockAmount: Double? {
        guard let product, let quID = ingredient.quID else { return nil }
        return mapper.stockAmount(for: ingredient.amount, quID: quID, product: product)
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
                    ProductField(productID: $ingredient.productID, description: "Product")
                        .onChange(of: ingredient.productID) {
                            mapper.productChanged(&ingredient)
                        }

                    if ingredient.productID == nil {
                        Button(
                            action: {
                                showCreateProduct = true
                            },
                            label: {
                                Label("Create product", systemImage: MySymbols.new)
                            }
                        )
                    }
                } footer: {
                    if ingredient.productID == nil {
                        Text("Grocy needs a product for every ingredient. Ingredients without a product aren't imported.")
                    }
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
        .sheet(isPresented: $showCreateProduct) {
            NavigationStack {
                MDProductFormView(userSettings: userSettingsList.first, productName: ingredient.line.name, createdProductID: $createdProductID)
            }
        }
        .onChange(of: createdProductID) {
            if let createdProductID {
                ingredient.productID = createdProductID
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
                selection: $ingredient.quID,
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
        } header: {
            Text("Amount")
        } footer: {
            if ingredient.quID == nil {
                Text("A quantity unit is required")
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
            } else if let stockAmount {
                if ingredient.quID != product?.quIDStock {
                    Text("This equals \(stockAmount.formatted(.number.precision(.fractionLength(0...8)))) \(stockQuantityUnit?.getName(amount: stockAmount) ?? "?")")
                }
            } else {
                Text("There's no unit conversion to the product's stock unit \"\(stockQuantityUnit?.name ?? "?")\". Only whether any amount is in stock can be checked.")
            }
        }
    }
}

#Preview(traits: .previewData) {
    @Previewable @State var ingredient = ImportedIngredient(
        line: IngredientLineParser.parse("200 g Butter, weich"),
        productID: 1,
        amount: 200,
        quID: 1,
        note: "weich",
        ingredientGroup: "",
        variableAmount: "",
        onlyCheckSingleUnitInStock: false
    )
    NavigationStack {
        RecipeImportIngredientFormView(ingredient: $ingredient)
    }
}
