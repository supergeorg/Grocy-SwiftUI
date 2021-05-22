//
//  PurchaseProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import SwiftUI

struct PurchaseProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @State private var firstAppear: Bool = true
    @State private var isProcessingAction: Bool = false
    
    var productToPurchaseID: String?
    var productToPurchaseAmount: Double?
    
    @State private var productID: String?
    @State private var amount: Double = 0.0
    @State private var quantityUnitID: String?
    @State private var dueDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var productDoesntSpoil: Bool = false
    @State private var price: Double?
    @State private var isTotalPrice: Bool = false
    @State private var shoppingLocationID: String?
    @State private var locationID: String?
    
    @State private var searchProductTerm: String = ""
    
    @State private var toastType: PurchaseToastType?
    private enum PurchaseToastType: Identifiable {
        case successPurchase, failPurchase
        
        var id: Int {
            self.hashValue
        }
    }
    @State private var infoString: String?
    
    private var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productID})
    }
    private var currentQuantityUnitName: String? {
        let quIDP = product?.quIDPurchase
        let qu = grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
        return amount == 1 ? qu?.name : qu?.namePlural
    }
    private var productName: String {
        product?.name ?? ""
    }
    
    private let priceFormatter = NumberFormatter()
    
    var isFormValid: Bool {
        (productID != nil) && (amount > 0) && (quantityUnitID != nil)
    }
    
    private func resetForm() {
        self.productID = firstAppear ? productToPurchaseID : nil
        self.amount = firstAppear ? (productToPurchaseAmount ?? 1.0) : 0.0
        self.quantityUnitID = nil
        self.dueDate = Calendar.current.startOfDay(for: Date())
        self.productDoesntSpoil = false
        self.price = nil
        self.isTotalPrice = false
        self.shoppingLocationID = nil
        self.locationID = nil
        self.searchProductTerm = ""
    }
    
    private func purchaseProduct() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let strDueDate = productDoesntSpoil ? "2999-12-31" : dateFormatter.string(from: dueDate)
        let calculatedPrice = isTotalPrice ? price : (amount) * (price ?? 0.0)
        let strPrice = (calculatedPrice == nil || (calculatedPrice ?? 0).isZero) ? nil : String(format: "%.2f", calculatedPrice!)
        let numLocationID = Int(locationID ?? "")
        let numShoppingLocationID = Int(shoppingLocationID ?? "")
        let purchaseInfo = ProductBuy(amount: amount, bestBeforeDate: strDueDate, transactionType: .purchase, price: strPrice, locationID: numLocationID, shoppingLocationID: numShoppingLocationID)
        if let productID = productID {
            infoString = "\(formatAmount(amount)) \(currentQuantityUnitName ?? "") \(productName)"
            isProcessingAction = true
            grocyVM.postStockObject(id: productID, stockModePost: .add, content: purchaseInfo) { result in
                switch result {
                case let .success(prod):
                    grocyVM.postLog(message: "Purchase successful. \(prod)", type: .info)
                    toastType = .successPurchase
                    resetForm()
                case let .failure(error):
                    grocyVM.postLog(message: "Purchase failed: \(error)", type: .error)
                    toastType = .failPurchase
                }
                isProcessingAction = false
            }
        }
    }
    
    private func updateData() {
        grocyVM.requestData(objects: [.products, .quantity_units, .locations, .shopping_locations, .product_barcodes], additionalObjects: [.system_config])
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
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            })
        #endif
    }
    
    var content: some View {
        Form {
            if grocyVM.failedToLoadObjects.count > 0 && grocyVM.failedToLoadAdditionalObjects.count > 0 {
                Section{
                    ServerOfflineView(isCompact: true)
                }
            }
            
            ProductField(productID: $productID, description: "str.stock.buy.product")
                .onChange(of: productID) { newProduct in
                    if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                        if locationID == nil { locationID = selectedProduct.locationID }
                        if shoppingLocationID == nil { shoppingLocationID = selectedProduct.shoppingLocationID ?? "" }
                        quantityUnitID = selectedProduct.quIDPurchase
                    }
                }
            
            Section(header: Text(LocalizedStringKey("str.stock.buy.product.amount")).font(.headline)) {
                MyDoubleStepper(amount: $amount, description: "str.stock.buy.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: currentQuantityUnitName, errorMessage: "str.stock.buy.product.amount.invalid", systemImage: MySymbols.amount)
                Picker(selection: $quantityUnitID, label: Label(LocalizedStringKey("str.stock.buy.product.quantityUnit"), systemImage: MySymbols.quantityUnit), content: {
                    Text("").tag(nil as String?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id as String?)
                    }
                }).disabled(true)
            }
            
            Section(header: Text(LocalizedStringKey("str.stock.buy.product.dueDate")).font(.headline)) {
                VStack(alignment: .trailing){
                    HStack {
                        Image(systemName: MySymbols.date)
                        DatePicker(LocalizedStringKey("str.stock.buy.product.dueDate"), selection: $dueDate, displayedComponents: .date)
                            .disabled(productDoesntSpoil)
                    }
                    Text(getRelativeDateAsText(dueDate, localizationKey: localizationKey))
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
                        Text("").tag(nil as String?)
                        ForEach(grocyVM.mdShoppingLocations, id:\.id) { shoppingLocation in
                            Text(shoppingLocation.name).tag(shoppingLocation.id as String?)
                        }
                       })
                
                Picker(selection: $locationID,
                       label: Label(LocalizedStringKey("str.stock.buy.product.location"), systemImage: MySymbols.location).foregroundColor(.primary),
                       content: {
                        Text("").tag(nil as String?)
                        ForEach(grocyVM.mdLocations, id:\.id) { location in
                            Text(location.id == product?.locationID ? LocalizedStringKey("str.stock.buy.product.location.default \(location.name)") : LocalizedStringKey(location.name)).tag(location.id as String?)
//                            Text(location.name).tag(location.id as String?)
                        }
                       })
            }
        }
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: [.products, .quantity_units, .locations, .shopping_locations, .product_barcodes], additionalObjects: [.system_config], ignoreCached: false)
                resetForm()
                firstAppear = false
            }
        })
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successPurchase), content: { item in
            switch item {
            case .successPurchase:
                Label(LocalizedStringKey("str.stock.buy.product.buy.success \(infoString ?? "")"), systemImage: MySymbols.success)
            case .failPurchase:
                Label(LocalizedStringKey("str.stock.buy.product.buy.fail"), systemImage: MySymbols.failure)
            }
        })
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction, content: {
                if isProcessingAction {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                } else {
                    Button(action: resetForm, label: {
                        Label(LocalizedStringKey("str.clear"), systemImage: MySymbols.cancel)
                            .help(LocalizedStringKey("str.clear"))
                    })
                    .keyboardShortcut("r", modifiers: [.command])
                }
            })
            ToolbarItem(placement: .confirmationAction, content: {
                Button(action: purchaseProduct, label: {
                    Label(LocalizedStringKey("str.stock.buy.product.buy"), systemImage: MySymbols.purchase)
                        .labelStyle(TextIconLabelStyle())
                })
                .disabled(!isFormValid || isProcessingAction)
                .keyboardShortcut("s", modifiers: [.command])
            })
        })
        .animation(.default)
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
