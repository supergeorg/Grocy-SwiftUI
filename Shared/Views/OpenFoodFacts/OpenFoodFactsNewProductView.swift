//
//  OpenFoodFactsNewProductView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 06.03.22.
//

import SwiftUI

struct OpenFoodFactsNewProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    @ObservedObject var offVM: OpenFoodFactsViewModel
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var productName: String = ""
    @State private var locationID: Int?
    @State private var quIDStock: Int?
    @State private var quIDPurchase: Int?
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundProduct = grocyVM.mdProducts.first(where: {$0.name == productName})
        return (foundProduct == nil)
    }
    
    init(barcode: String) {
        offVM = OpenFoodFactsViewModel(barcode: barcode)
    }
    
    private var isFormValid: Bool {
        !(productName.isEmpty) && isNameCorrect && (locationID != nil) && (quIDStock != nil) && (quIDPurchase != nil)
    }
    
    private let dataToUpdate: [ObjectEntities] = [.products, .quantity_units, .locations]
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func resetForm() {
        productName = ""
        locationID = grocyVM.userSettings?.productPresetsLocationID
        quIDStock = grocyVM.userSettings?.productPresetsQuID
        quIDPurchase = grocyVM.userSettings?.productPresetsQuID
    }
    
    private func finishForm() {
        self.dismiss()
    }
    
    private func saveProduct() {
        if let locationID = locationID, let quIDPurchase = quIDPurchase, let quIDStock = quIDStock {
            let id = grocyVM.findNextID(.products)
            let timeStamp = Date().iso8601withFractionalSeconds
            let productPOST = MDProduct(id: id, name: productName, mdProductDescription: "", productGroupID: nil, active: 1, locationID: locationID, shoppingLocationID: nil, quIDPurchase: quIDPurchase, quIDStock: quIDStock, quFactorPurchaseToStock: nil, minStockAmount: 0, defaultBestBeforeDays: 0, defaultBestBeforeDaysAfterOpen: 0, defaultBestBeforeDaysAfterFreezing: 0, defaultBestBeforeDaysAfterThawing: 0, pictureFileName: nil, enableTareWeightHandling: 0, tareWeight: nil, notCheckStockFulfillmentForRecipes: 0, parentProductID: nil, calories: nil, cumulateMinStockAmountOfSubProducts: 0, dueType: DueType.bestBefore.rawValue, quickConsumeAmount: 1, hideOnStockOverview: 0, rowCreatedTimestamp: timeStamp)
            isProcessing = true
            grocyVM.postMDObject(object: .products, content: productPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog("Product add successful. \(message)", type: .info)
                    if let barcode = offVM.offData?.code {
                        let barcodePOST = MDProductBarcode(id: grocyVM.findNextID(.product_barcodes), productID: productPOST.id, barcode: barcode, quID: nil, amount: nil, shoppingLocationID: nil, lastPrice: nil, rowCreatedTimestamp: timeStamp, note: nil)
                        grocyVM.postMDObject(object: .product_barcodes, content: barcodePOST, completion: { barcodeResult in
                            switch barcodeResult {
                            case let .success(barcodeMessage):
                                grocyVM.postLog("Barcode add successful. \(barcodeMessage)", type: .info)
                            case let .failure(barcodeError):
                                grocyVM.postLog("Barcode add failed. \(barcodeError)", type: .error)
                            }
                            grocyVM.requestData(objects: [.product_barcodes])
                            isProcessing = false
                            finishForm()
                        })
                    }
                    //                        toastType = .successAdd
                    grocyVM.requestData(objects: [.products], ignoreCached: true)
                case let .failure(error):
                    grocyVM.postLog("Product add failed. \(error)", type: .error)
                    //                        toastType = .failAdd
                    isProcessing = false
                }
            })
        }
    }
    
    var productNames: [String: String] {
        if let offData = offVM.offData {
            let allProductNames = [
                "generic": offData.product.productName,
                "en": offData.product.productNameEn,
                "de": offData.product.productNameDe,
                "fr": offData.product.productNameFr,
                "pl": offData.product.productNamePl
            ]
            return allProductNames.compactMapValues({ $0 })
        } else {
            return [:]
        }
    }
    
    
    var body: some View {
        Form {
            VStack {
                if let imageLink = offVM.offData?.product.imageThumbURL, let imageURL = URL(string: imageLink) {
                    AsyncImage(url: imageURL, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(Color.white)
                    }, placeholder: {
                        ProgressView()
                    })
                    .frame(maxWidth: 150.0, maxHeight: 150.0)
                }
                MyTextField(textToEdit: Binding.constant(offVM.offData?.code ?? "?"), description: "str.md.barcode", isCorrect: Binding.constant(true), leadingIcon: MySymbols.barcode)
                    .disabled(true)
            }
            
            Picker(selection: $productName, content: {
                ForEach(productNames.sorted(by: >), id: \.key) { key, value in
                    Text("\(value) (\(key))").tag(value)
                }
            }, label: {
                HStack{
                    Image(systemName: "tag")
                    VStack(alignment: .leading){
                        Text(LocalizedStringKey("str.md.product.name"))
                        if productName.isEmpty {
                            Text(LocalizedStringKey("str.md.product.name.required"))
                                .font(.caption)
                                .foregroundColor(Color.red)
                        } else if !isNameCorrect {
                            Text("str.md.product.name.exists")
                                .font(.caption)
                                .foregroundColor(Color.red)
                        }
                    }
                }
            })
            .onChange(of: productName, perform: { value in
                isNameCorrect = checkNameCorrect()
            })
            Picker(selection: $locationID, label: MyLabelWithSubtitle(title: "str.md.product.location", subTitle: "str.md.product.location.required", systemImage: MySymbols.location, isSubtitleProblem: true, hideSubtitle: locationID != nil), content: {
                ForEach(grocyVM.mdLocations, id:\.id) { grocyLocation in
                    Text(grocyLocation.name).tag(grocyLocation.id as Int?)
                }
            })
            HStack{
                Picker(selection: $quIDStock, label: MyLabelWithSubtitle(title: "str.md.product.quStock", subTitle: "str.md.product.quStock.required", systemImage: MySymbols.quantityUnit, isSubtitleProblem: true, hideSubtitle: quIDStock != nil), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as Int?)
                    }
                })
                .onChange(of: quIDStock, perform: { newValue in
                    if quIDPurchase == nil { quIDPurchase = quIDStock }
                })
                
                FieldDescription(description: "str.md.product.quStock.info")
            }
            
            HStack{
                Picker(selection: $quIDPurchase, label: MyLabelWithSubtitle(title: "str.md.product.quPurchase", subTitle: "str.md.product.quPurchase.required", systemImage: MySymbols.quantityUnit, isSubtitleProblem: true, hideSubtitle: quIDPurchase != nil), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as Int?)
                    }
                })
                FieldDescription(description: "str.md.product.quPurchase.info")
            }
        }
        .navigationTitle(LocalizedStringKey("str.md.product.new"))
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: dataToUpdate, ignoreCached: false)
                resetForm()
                firstAppear = false
            }
        })
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: saveProduct, label: {
                    Label(LocalizedStringKey("str.md.product.save"), systemImage: MySymbols.save)
                        .labelStyle(.titleAndIcon)
                })
                .disabled(!isNameCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        })
    }
}

//struct OpenFoodFactsNewProductView_Previews: PreviewProvider {
//    static var previews: some View {
//        OpenFoodFactsNewProductView()
//    }
//}
