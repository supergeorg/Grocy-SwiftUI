//
//  QuickScanModeSelectProductView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 21.01.21.
//

import SwiftUI

struct QuickScanModeSelectProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("devMode") private var devMode: Bool = false
    @AppStorage("quickScanActionAfterAdd") private var quickScanActionAfterAdd: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstOpen: Bool = true
    
    var barcode: String?
    
    @State private var productID: Int?
    
    @Binding var toastTypeSuccess: QSToastTypeSuccess?
    @Binding var qsActiveSheet: QSActiveSheet?
    @State private var toastTypeFail: QSToastTypeFail?
    @State private var toastType: MDToastType?
    @Binding var newRecognizedBarcode: MDProductBarcode?
    @State var newProductBarcode: MDProductBarcode?
    
    private func resetForm() {
        productID = nil
    }
    
    private func updateData() {
        grocyVM.requestData(objects: [.product_barcodes])
    }
    
    private func finishForm() {
        dismiss()
    }
    
    private func addBarcodeForProduct() {
        if let barcode = barcode {
            if let productID = productID {
                let newBarcode = MDProductBarcode(
                    id: grocyVM.findNextID(.product_barcodes),
                    productID: productID,
                    barcode: barcode,
                    quID: nil,
                    amount: nil,
                    shoppingLocationID: nil,
                    lastPrice: nil,
                    rowCreatedTimestamp: Date().iso8601withFractionalSeconds,
                    note: nil
                )
                grocyVM.postMDObject(object: .product_barcodes, content: newBarcode, completion: { result in
                    switch result {
                    case let .success(message):
                        grocyVM.postLog("Add barcode successful. \(message)", type: .info)
                        grocyVM.requestData(objects: [.product_barcodes], ignoreCached: true)
                        newRecognizedBarcode = newBarcode
                        toastTypeSuccess = .successQSAddProduct
                        finishForm()
                    case let .failure(error):
                        grocyVM.postLog("Add barcode failed. \(error)", type: .error)
                        toastTypeFail = .failQSAddProduct
                    }
                })
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text(barcode ?? "Barcode error").font(.title)
                }
                ProductField(productID: $productID, description: "str.quickScan.add.product")
                
                if let barcode = barcode {
                    Section("Open Food Facts") {
                        NavigationLink(
                            destination: MDProductFormView(isNewProduct: true, openFoodFactsBarcode: barcode, showAddProduct: Binding.constant(false), toastType: $toastType, isPopup: false, mdBarcodeReturn: $newProductBarcode),
                            label: {
                                Label(LocalizedStringKey("str.quickScan.add.product.new.openfoodfacts"), systemImage: MySymbols.barcodeScan)
                            }
                        )
                        .onChange(of: newProductBarcode?.id, perform: { _ in
                            if newProductBarcode != nil {
                                toastTypeSuccess = .successQSAddProduct
                                finishForm()
                                newRecognizedBarcode = newProductBarcode
                            }
                        })
                    }
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button(LocalizedStringKey("str.cancel")) {
                        finishForm()
                    }
                    .keyboardShortcut(.cancelAction)
                })
                ToolbarItem(placement: .automatic, content: {
                    Button(action: addBarcodeForProduct, label: {
                        Label(LocalizedStringKey("str.quickScan.add.product.add"), systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(productID == nil)
                    .keyboardShortcut(.defaultAction)
                })
            })
        }
        .toast(item: $toastTypeFail, isSuccess: Binding.constant(false), text: { item in
            switch item {
            case .failQSAddProduct:
                return LocalizedStringKey("str.quickScan.add.product.add.fail")
            default:
                return LocalizedStringKey("")
            }
        })
    }
}

struct QuickScanModeSelectProductView_Previews: PreviewProvider {
    static var previews: some View {
        QuickScanModeSelectProductView(
            barcode: "12345",
            toastTypeSuccess: Binding.constant(QSToastTypeSuccess.successQSAddProduct),
            qsActiveSheet: Binding.constant(QSActiveSheet.selectProduct),
            newRecognizedBarcode: Binding.constant(nil)
        )
    }
}
