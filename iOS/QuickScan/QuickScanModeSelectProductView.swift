//
//  QuickScanModeSelectProductView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 21.01.21.
//

import SwiftUI
import SwiftData

struct QuickScanModeSelectProductView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @AppStorage("devMode") private var devMode: Bool = false
    @AppStorage("quickScanActionAfterAdd") private var quickScanActionAfterAdd: Bool = false
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstOpen: Bool = true
    
    var barcode: String?
    
    @State private var productID: Int?
    
    
    @Binding var qsActiveSheet: QSActiveSheet?
    @Binding var newRecognizedBarcode: MDProductBarcode?
    @State var newProductBarcode: MDProductBarcode?
    
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
        if
            let barcode = barcode,
            let productID = productID
        {
            let newBarcode = await MDProductBarcode(
                id: grocyVM.findNextID(.product_barcodes),
                productID: productID,
                barcode: barcode,
                rowCreatedTimestamp: Date().iso8601withFractionalSeconds
            )
            do {
                _ = try await grocyVM.postMDObject(object: .product_barcodes, content: newBarcode)
                await grocyVM.postLog("Add barcode successful.", type: .info)
                await grocyVM.requestData(objects: [.product_barcodes])
                newRecognizedBarcode = newBarcode
                finishForm()
            } catch {
                await grocyVM.postLog("Add barcode failed. \(error)", type: .error)
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                Text(barcode ?? "Barcode error").font(.title)
            }
            
            ProductField(productID: $productID, description: "Product for this barcode")
            
            if let barcode = barcode {
                Section("Open Food Facts") {
                    NavigationLink(
                        destination: MDProductFormView(userSettings: userSettings),
                        label: {
                            Label("Create new product with Open Food Facts", systemImage: MySymbols.barcodeScan)
                        }
                    )
                    .onChange(of: newProductBarcode?.id) {
                        if newProductBarcode != nil {
                            finishForm()
                            newRecognizedBarcode = newProductBarcode
                        }
                    }
                }
            }
        }
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("Cancel") {
                    finishForm()
                }
                .keyboardShortcut(.cancelAction)
            })
            ToolbarItem(placement: .automatic, content: {
                Button(action: { Task { await addBarcodeForProduct() } }, label: {
                    Text("Add barcode")
                })
                .disabled(productID == nil)
                .keyboardShortcut(.defaultAction)
            })
        })
    }
}

struct QuickScanModeSelectProductView_Previews: PreviewProvider {
    static var previews: some View {
        QuickScanModeSelectProductView(
            barcode: "12345",
            qsActiveSheet: Binding.constant(QSActiveSheet.selectProduct),
            newRecognizedBarcode: Binding.constant(nil)
        )
    }
}
