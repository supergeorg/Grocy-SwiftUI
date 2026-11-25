//
//  QuickScanModeSelectProductView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 21.01.21.
//

import SwiftData
import SwiftUI

struct QuickScanModeSelectProductView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) var dismiss

    @AppStorage("quickScanActionAfterAdd") private var quickScanActionAfterAdd: Bool = false
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }

    var barcode: String?

    @State private var firstOpen: Bool = true
    @State private var createdProductID: Int? = nil
    @State private var productID: Int?

    @Binding var newRecognizedBarcode: MDProductBarcode?

    @State private var showProductForm: Bool = false

    private func resetForm() {
        productID = nil
    }

    private func updateData() async {
        await grocyVM.requestData(objects: [.product_barcodes])
    }

    private func finishForm() {
        dismiss()
    }

    private func addBarcodeForProduct() async {
        if let barcode = barcode,
            let productID = productID
        {
            do {
                let newBarcode = MDProductBarcode(
                    id: try grocyVM.findNextID(.product_barcodes),
                    productID: productID,
                    barcode: barcode
                )
                _ = try await grocyVM.postMDObject(object: .product_barcodes, content: newBarcode)
                GrocyLogger.info("Add barcode successful.")
                await grocyVM.requestData(objects: [.product_barcodes])
                newRecognizedBarcode = newBarcode
                finishForm()
            } catch {
                GrocyLogger.error("Add barcode failed. \(error)")
            }
        }
    }

    var body: some View {
        Form {
            Section {
                Text(barcode ?? "Barcode error").font(.title)
            }

            Section {
                ProductField(productID: $productID, description: "Product for this barcode", excludeNoOwnStock: true)
                Button(
                    action: {
                        showProductForm = true
                    },
                    label: {
                        Label("Create product", systemImage: MySymbols.new)
                    }
                )
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle("Add barcode")
        .onChange(of: createdProductID) {
            self.productID = createdProductID
        }
        .sheet(isPresented: $showProductForm) {
            NavigationStack {
                MDProductFormView(userSettings: userSettings, queuedBarcode: barcode, createdProductID: $createdProductID)
            }
        }
        .toolbar(content: {
            ToolbarItem(
                placement: .cancellationAction,
                content: {
                    Button(role: .cancel) {
                        finishForm()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            )
            ToolbarItem(
                placement: .automatic,
                content: {
                    Button(
                        role: .confirm,
                        action: { Task { await addBarcodeForProduct() } },
                    )
                    .disabled(productID == nil)
                    .keyboardShortcut(.defaultAction)
                }
            )
        })
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        QuickScanModeSelectProductView(
            barcode: "12345",
            newRecognizedBarcode: Binding.constant(nil)
        )
    }
}
