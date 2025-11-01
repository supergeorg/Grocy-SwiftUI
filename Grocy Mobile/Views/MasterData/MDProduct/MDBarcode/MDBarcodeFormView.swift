//
//  MDBarcodeFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 03.12.20.
//

import SwiftData
import SwiftUI

struct MDBarcodeFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MDProductBarcode.id, order: .forward) var mdProductBarcodes: MDProductBarcodes
    @Query(filter: #Predicate<MDStore> { $0.active }, sort: \MDStore.name, order: .forward) var mdStores: MDStores
    @Query(filter: #Predicate<MDQuantityUnit> { $0.active }, sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var product: MDProduct
    var existingBarcode: MDProductBarcode?
    @State var barcode: MDProductBarcode

    @State private var isBarcodeCorrect: Bool = false
    private func checkBarcodeCorrect() -> Bool {
        // check if Barcode is already used
        let foundBarcode = mdProductBarcodes.filter({ $0.barcode == barcode.barcode }).first
        return ((foundBarcode == nil || foundBarcode?.barcode == existingBarcode?.barcode) && (!barcode.barcode.isEmpty))
    }

    init(product: MDProduct, existingBarcode: MDProductBarcode? = nil) {
        self.product = product
        self.existingBarcode = existingBarcode
        let initialBarcode =
            existingBarcode
            ?? MDProductBarcode(
                id: 0,
                productID: product.id,
                barcode: "",
                quID: product.quIDPurchase,
                amount: nil,
                storeID: nil,
                lastPrice: nil,
                note: "",
                rowCreatedTimestamp: Date().iso8601withFractionalSeconds
            )
        _barcode = State(initialValue: initialBarcode)
        _isBarcodeCorrect = State(initialValue: true)
    }

    private let dataToUpdate: [ObjectEntities] = [.product_barcodes]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func finishForm() {
        self.dismiss()
    }

    private func saveBarcode() async {
        if barcode.id == 0 {
            barcode.id = grocyVM.findNextID(.product_barcodes)
        }
        isProcessing = true
        isSuccessful = nil
        do {
            try barcode.modelContext?.save()
            if existingBarcode == nil {
                _ = try await grocyVM.postMDObject(object: .product_barcodes, content: barcode)
            } else {
                try await grocyVM.putMDObjectWithID(object: .product_barcodes, id: barcode.id, content: barcode)
            }
            GrocyLogger.info("Barcode \(barcode.barcode) successful.")
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Barcode \(barcode.barcode) failed. \(error)")
            errorMessage = error.localizedDescription
            isSuccessful = false
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            HStack {
                MyTextField(
                    textToEdit: $barcode.barcode,
                    description: "Barcode",
                    isCorrect: $isBarcodeCorrect,
                    leadingIcon: MySymbols.barcode,
                    emptyMessage: "A barcode is required",
                    errorMessage: "The barcode is invalid or already in use.",
                    helpText: nil
                )
                #if os(iOS)
                    MDBarcodeScanner(barcode: $barcode.barcode)
                #endif
            }

            Section("Amount") {
                MyDoubleStepperOptional(amount: $barcode.amount, description: "Amount", minAmount: 0, amountName: "", systemImage: MySymbols.amount)
                Picker(
                    selection: $barcode.quID,
                    label: HStack {
                        Image(systemName: "scalemass")
                            .foregroundStyle(.primary)
                        Text("Quantity unit")
                    },
                    content: {
                        Text("")
                            .tag(nil as Int?)
                        ForEach(mdQuantityUnits, id: \.id) { pickerQU in
                            if !pickerQU.namePlural.isEmpty {
                                Text("\(pickerQU.name) (\(pickerQU.namePlural))")
                                    .tag(pickerQU.id as Int?)
                            } else {
                                Text("\(pickerQU.name)")
                                    .tag(pickerQU.id as Int?)
                            }
                        }
                    }
                )
            }

            Picker(
                selection: $barcode.storeID,
                label: HStack {
                    Image(systemName: MySymbols.store).foregroundStyle(.primary)
                    Text("Store")
                },
                content: {
                    Text("")
                        .tag(nil as Int?)
                    ForEach(mdStores, id: \.id) { grocyStore in
                        Text(grocyStore.name)
                            .tag(grocyStore.id as Int?)
                    }
                }
            )

            MyTextEditor(textToEdit: $barcode.note, description: "Note", leadingIcon: MySymbols.description)

        }
        .onChange(of: barcode.barcode) {
            isBarcodeCorrect = checkBarcodeCorrect()
        }
        .navigationTitle(existingBarcode == nil ? "Add barcode" : "Edit barcode")
        .toolbar(content: {
            if existingBarcode == nil {
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
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await saveBarcode()
                        }
                    }
                )
                .disabled(!isBarcodeCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        })
        .task {
            await updateData()
            isBarcodeCorrect = checkBarcodeCorrect()
        }
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                finishForm()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}
