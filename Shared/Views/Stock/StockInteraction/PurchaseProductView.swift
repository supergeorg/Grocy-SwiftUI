//
//  PurchaseProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import SwiftUI

struct PurchaseProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @State private var firstAppear: Bool = true
    @State private var isProcessingAction: Bool = false
    
    var stockElement: Binding<StockElement?>? = nil
    var directProductToPurchaseID: Int? = nil
    var productToPurchaseID: Int? {
        return directProductToPurchaseID ?? stockElement?.wrappedValue?.productID
    }
    var productToPurchaseAmount: Double?
    
    @State private var productID: Int?
    @State private var amount: Double = 0.0
    @State private var quantityUnitID: Int?
    @State private var dueDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var productDoesntSpoil: Bool = false
    @State private var price: Double?
    @State private var isTotalPrice: Bool = false
    @State private var shoppingLocationID: Int?
    @State private var locationID: Int?
    
    @State private var searchProductTerm: String = ""
    
    @State private var toastType: PurchaseToastType?
    private enum PurchaseToastType: Identifiable {
        case successPurchase, failPurchase
        
        var id: Int {
            self.hashValue
        }
    }
    @State private var infoString: String?
    
    private let dataToUpdate: [ObjectEntities] = [.products, .quantity_units, .quantity_unit_conversions, .locations, .shopping_locations, .product_barcodes]
    private let additionalDataToUpdate: [AdditionalEntities] = [.system_config]
    
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    private var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productID})
    }
    private var currentQuantityUnit: MDQuantityUnit? {
        return grocyVM.mdQuantityUnits.first(where: {$0.id == quantityUnitID })
    }
    private var stockQuantityUnit: MDQuantityUnit? {
        return grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }
    private func getQUString(stockQU: Bool) -> String {
        if stockQU {
            return factoredAmount == 1.0 ? stockQuantityUnit?.name ?? "" : stockQuantityUnit?.namePlural ?? stockQuantityUnit?.name ?? ""
        } else {
            return amount == 1.0 ? currentQuantityUnit?.name ?? "" : currentQuantityUnit?.namePlural ?? currentQuantityUnit?.name ?? ""
        }
    }
    
    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        if let quIDStock = product?.quIDStock {
            return grocyVM.mdQuantityUnitConversions.filter({ $0.toQuID == quIDStock })
        } else { return [] }
    }
    private var factoredAmount: Double {
        return amount * (quantityUnitConversions.first(where: { $0.fromQuID == quantityUnitID})?.factor ?? 1)
    }
    
    var isFormValid: Bool {
        (productID != nil) && (amount > 0) && (quantityUnitID != nil)
    }
    
    private func resetForm() {
        
        self.amount = firstAppear ? productToPurchaseAmount ?? 1.0 : 1.0
        self.quantityUnitID = firstAppear ? product?.quIDPurchase : nil
        self.dueDate = Calendar.current.startOfDay(for: Date())
        self.productDoesntSpoil = false
        self.price = nil
        self.isTotalPrice = false
        self.shoppingLocationID = nil
        self.locationID = nil
        self.productID = firstAppear ? productToPurchaseID : nil
        self.searchProductTerm = ""
    }
    
    private func purchaseProduct() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let strDueDate = productDoesntSpoil ? "2999-12-31" : dateFormatter.string(from: dueDate)
        let purchaseInfo = ProductBuy(amount: factoredAmount, bestBeforeDate: strDueDate, transactionType: .purchase, price: price, locationID: locationID, shoppingLocationID: shoppingLocationID)
        if let productID = productID {
            infoString = "\(amount.formattedAmount) \(getQUString(stockQU: true)) \(product?.name ?? "")"
            isProcessingAction = true
            grocyVM.postStockObject(id: productID, stockModePost: .add, content: purchaseInfo) { result in
                switch result {
                case let .success(prod):
                    grocyVM.postLog("Purchase successful. \(prod)", type: .info)
                    toastType = .successPurchase
                    grocyVM.requestData(additionalObjects: [.stock], ignoreCached: true)
                    resetForm()
                case let .failure(error):
                    grocyVM.postLog("Purchase failed: \(error)", type: .error)
                    toastType = .failPurchase
                }
                isProcessingAction = false
            }
        }
    }
    
    var body: some View {
#if os(macOS)
        ScrollView{
            content
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        }
#else
        content
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("str.cancel")) {
                        self.dismiss()
                    }
                }
            })
#endif
    }
    
    var content: some View {
        Form {
            if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count > 0 || grocyVM.failedToLoadAdditionalObjects.filter({additionalDataToUpdate.contains($0)}).count > 0 {
                Section{
                    ServerProblemView(isCompact: true)
                }
            }
            
            ProductField(productID: $productID, description: "str.stock.buy.product")
                .onChange(of: productID) { newProduct in
                    if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                        if locationID == nil { locationID = selectedProduct.locationID }
                        if shoppingLocationID == nil { shoppingLocationID = selectedProduct.shoppingLocationID }
                        quantityUnitID = selectedProduct.quIDPurchase
                        dueDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: product?.defaultBestBeforeDays ?? 0, to: Date()) ?? Calendar.current.startOfDay(for: Date()))
                    }
                }
            
            AmountSelectionView(productID: $productID, amount: $amount, quantityUnitID: $quantityUnitID)
            
            Section(header: Text(LocalizedStringKey("str.stock.buy.product.dueDate")).font(.headline)) {
                VStack(alignment: .trailing){
                    HStack {
                        Image(systemName: MySymbols.date)
                        DatePicker(LocalizedStringKey("str.stock.buy.product.dueDate"), selection: $dueDate, displayedComponents: .date)
                            .disabled(productDoesntSpoil)
                    }
                    Text(getRelativeDateAsText(dueDate, localizationKey: localizationKey) ?? "")
                        .foregroundColor(.gray)
                        .italic()
                }
                
                MyToggle(isOn: $productDoesntSpoil, description: "str.stock.buy.product.doesntSpoil", descriptionInfo: nil, icon: MySymbols.doesntSpoil)
            }
            
            Section(header: Text(LocalizedStringKey("str.stock.buy.product.price")).font(.headline)) {
                MyDoubleStepperOptional(amount: $price, description: "str.stock.buy.product.price", minAmount: 0, amountStep: 1.0, amountName: "", errorMessage: "str.stock.buy.product.price.invalid", systemImage: MySymbols.price, currencySymbol: grocyVM.getCurrencySymbol())
                
                if price != nil {
                    Picker("", selection: $isTotalPrice, content: {
                        Text(LocalizedStringKey("str.stock.buy.product.price.unitPrice")).tag(false)
                        Text(LocalizedStringKey("str.stock.buy.product.price.totalPrice")).tag(true)
                    }).pickerStyle(SegmentedPickerStyle())
                }
            }
            
            Section(header: Text(LocalizedStringKey("str.stock.buy.product.location")).font(.headline)) {
                Picker(selection: $shoppingLocationID,
                       label: Label(LocalizedStringKey("str.stock.buy.product.shoppingLocation"), systemImage: MySymbols.shoppingLocation).foregroundColor(.primary),
                       content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdShoppingLocations, id:\.id) { shoppingLocation in
                        Text(shoppingLocation.name).tag(shoppingLocation.id as Int?)
                    }
                })
                
                Picker(selection: $locationID,
                       label: Label(LocalizedStringKey("str.stock.buy.product.location"), systemImage: MySymbols.location).foregroundColor(.primary),
                       content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdLocations, id:\.id) { location in
                        Text(location.id == product?.locationID ? LocalizedStringKey("str.stock.buy.product.location.default \(location.name)") : LocalizedStringKey(location.name)).tag(location.id as Int?)
                        //                            Text(location.name).tag(location.id as String?)
                    }
                })
            }
        }
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate, ignoreCached: false)
                resetForm()
                firstAppear = false
            }
        })
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successPurchase), text: { item in
            switch item {
            case .successPurchase:
                return LocalizedStringKey("str.stock.buy.product.buy.success \(infoString ?? "")")
            case .failPurchase:
                return LocalizedStringKey("str.stock.buy.product.buy.fail")
            }
        })
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction, content: {
                HStack {
                    if isProcessingAction {
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Button(action: resetForm, label: {
                            Label(LocalizedStringKey("str.clear"), systemImage: MySymbols.cancel)
                                .help(LocalizedStringKey("str.clear"))
                        })
                            .keyboardShortcut("r", modifiers: [.command])
                    }
                    Button(action: purchaseProduct, label: {
                        Label(LocalizedStringKey("str.stock.buy.product.buy"), systemImage: MySymbols.purchase)
                            .labelStyle(.titleAndIcon)
                    })
                        .disabled(!isFormValid || isProcessingAction)
                        .keyboardShortcut("s", modifiers: [.command])
                }
            })
        })
        .navigationTitle(LocalizedStringKey("str.stock.buy"))
    }
}

struct PurchaseProductView_Previews: PreviewProvider {
    static var previews: some View {
#if os(iOS)
        NavigationView{
            PurchaseProductView()
        }
#else
        PurchaseProductView()
#endif
    }
}
