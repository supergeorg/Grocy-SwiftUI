//
//  RecipeImportUnitConversionFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftData
import SwiftUI

/// Connects a quantity unit to a product with a product-specific conversion to the product's stock unit,
/// e.g. "1 Bund Petersilie = 2 Pieces". Then a recipe ingredient in that unit can be converted, so Grocy can check the amount in stock.
struct RecipeImportUnitConversionFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<MDQuantityUnit> { $0.active }, sort: \MDQuantityUnit.name, order: .forward) var mdQuantityUnits: MDQuantityUnits

    var product: MDProduct
    var quantityUnit: MDQuantityUnit
    /// Set to `true` once the conversion was saved.
    @Binding var didSave: Bool

    @State private var factor: Double = 1.0
    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    private var stockQuantityUnit: MDQuantityUnit? {
        mdQuantityUnits.first(where: { $0.id == product.quIDStock })
    }

    private func saveConversion() async {
        isProcessing = true
        isSuccessful = nil
        do {
            let conversion = MDQuantityUnitConversion(
                id: try grocyVM.findNextID(.quantity_unit_conversions),
                fromQuID: quantityUnit.id,
                toQuID: product.quIDStock,
                factor: factor,
                productID: product.id
            )
            _ = try await grocyVM.postMDObject(object: .quantity_unit_conversions, content: conversion)
            GrocyLogger.info("Adding conversion from \(quantityUnit.name) for product \(product.name) was successful.")
            await grocyVM.requestData(objects: [.quantity_unit_conversions])
            didSave = true
            isSuccessful = true
        } catch {
            GrocyLogger.error("Adding conversion from \(quantityUnit.name) for product \(product.name) failed. \(error)")
            errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
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
                MyDoubleStepper(
                    amount: $factor,
                    description: "Factor",
                    minAmount: 0.0001,
                    amountStep: 1.0,
                    amountName: stockQuantityUnit?.getName(amount: factor),
                    systemImage: MySymbols.amount
                )
            } header: {
                Text("1 \(quantityUnit.name) \(product.name) is the same as")
            } footer: {
                Text("This conversion only applies to the product \"\(product.name)\". Then the amount of the ingredient can be checked against the stock.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Connect unit")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel, action: { dismiss() })
                    .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task { await saveConversion() }
                    },
                    label: {
                        Label("Save", systemImage: isProcessing ? MySymbols.progress : MySymbols.save)
                            .symbolEffect(.variableColor.iterative, isActive: isProcessing)
                    }
                )
                .disabled(factor <= 0 || isProcessing)
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

#Preview(traits: .previewData) {
    @Previewable @State var didSave = false
    NavigationStack {
        RecipeImportUnitConversionFormView(
            product: MDProduct(id: 1, name: "Petersilie", quIDPurchase: 2, quIDStock: 2, quIDConsume: 2),
            quantityUnit: MDQuantityUnit(id: 9, name: "Bund", namePlural: "Bund"),
            didSave: $didSave
        )
    }
}
