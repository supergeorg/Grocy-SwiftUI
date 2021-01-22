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
    
    @State private var firstAppear: Bool = true
    
    var productToPurchaseID: String?
    var productToPurchaseAmount: Double?
    
    @State private var productID: String?
    @State private var amount: Double?
    @State private var quantityUnitID: String?
    @State private var dueDate: Date = Date()
    @State private var productDoesntSpoil: Bool = false
    @State private var price: Double?
    @State private var isTotalPrice: Bool = false
    @State private var shoppingLocationID: String?
    @State private var locationID: String?
    
    @State private var searchProductTerm: String = ""
    
    private func getQuantityUnit() -> MDQuantityUnit? {
        let quIDP = grocyVM.mdProducts.first(where: {$0.id == productID})?.quIDPurchase
        let qu = grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
        return qu
    }
    private var currentQuantityUnit: MDQuantityUnit {
        getQuantityUnit() ?? MDQuantityUnit(id: "0", name: "Stück", mdQuantityUnitDescription: "", rowCreatedTimestamp: "", namePlural: "Stücke", pluralForms: nil, userfields: nil)
    }
    
    private let priceFormatter = NumberFormatter()
    
    var isFormValid: Bool {
        (productID != nil) && (amount != nil) && (amount ?? 0 > 0) && (quantityUnitID != nil)
    }
    
    private func resetForm() {
        self.productID = productToPurchaseID
        self.amount = productToPurchaseAmount
        self.productID = nil
        self.amount = nil
        self.quantityUnitID = nil
        self.dueDate = Date()
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
        let calculatedPrice = isTotalPrice ? price : (amount ?? 0.0) * (price ?? 0.0)
        //        let strPrice = calculatedPrice?.isZero ?? nil ? nil : String(format: "%.2f", calculatedPrice)
        let strPrice = (calculatedPrice == nil || (calculatedPrice ?? 0).isZero) ? nil : String(format: "%.2f", calculatedPrice!)
        let numLocationID = Int(locationID ?? "")
        let numShoppingLocationID = Int(shoppingLocationID ?? "")
        if let amount = amount {
            let purchaseInfo = ProductBuy(amount: amount, bestBeforeDate: strDueDate, transactionType: .purchase, price: strPrice, locationID: numLocationID, shoppingLocationID: numShoppingLocationID)
            if let productID = productID {
                grocyVM.postStockObject(id: productID, stockModePost: .add, content: purchaseInfo)
            }
        }
    }
    
    private func updateData() {
        grocyVM.getMDProducts()
        grocyVM.getMDQuantityUnits()
        grocyVM.getMDLocations()
        grocyVM.getMDShoppingLocations()
        grocyVM.getMDProductBarcodes()
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
            ProductField(productID: $productID, description: "str.stock.buy.product")
                .onChange(of: productID) { newProduct in
                    if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                        if locationID == nil { locationID = selectedProduct.locationID }
                        if shoppingLocationID == nil { shoppingLocationID = selectedProduct.shoppingLocationID ?? "" }
                        quantityUnitID = selectedProduct.quIDPurchase
                    }
                }
            
            Section(header: Text(LocalizedStringKey("str.stock.buy.product.amount")).font(.headline)) {
                MyDoubleStepper(amount: $amount, description: "str.stock.buy.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: (amount == 1 ? currentQuantityUnit.name : currentQuantityUnit.namePlural), errorMessage: "str.stock.buy.product.amount.invalid", systemImage: "number.circle")
                Picker(selection: $quantityUnitID, label: Label(LocalizedStringKey("str.stock.buy.product.quantityUnit"), systemImage: "scalemass"), content: {
                    Text("").tag(nil as String?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id as String?)
                    }
                }).disabled(true)
            }
            
            Section(header: Text(LocalizedStringKey("str.stock.buy.product.dueDate")).font(.headline)) {
                HStack {
                    Image(systemName: "calendar")
                    DatePicker(LocalizedStringKey("str.stock.buy.product.dueDate"), selection: $dueDate, displayedComponents: .date)
                        .disabled(productDoesntSpoil)
                }
                
                MyToggle(isOn: $productDoesntSpoil, description: "str.stock.buy.product.doesntSpoil", descriptionInfo: nil, icon: "trash.slash")
            }
            
            Section(header: Text(LocalizedStringKey("str.stock.buy.product.price")).font(.headline)) {
                MyDoubleStepper(amount: $price, description: "str.stock.buy.product.price", minAmount: 0, amountStep: 1.0, amountName: grocyVM.getCurrencySymbol(), errorMessage: "str.stock.buy.product.price.invalid", systemImage: "eurosign.circle")
                
                Picker("", selection: $isTotalPrice, content: {
                    Text(LocalizedStringKey("str.stock.buy.product.price.unitPrice")).tag(false)
                    Text(LocalizedStringKey("str.stock.buy.product.price.totalPrice")).tag(true)
                }).pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text(LocalizedStringKey("str.stock.buy.product.location")).font(.headline)) {
                Picker(selection: $shoppingLocationID, label: Label(LocalizedStringKey("str.stock.buy.product.shoppingLocation"), systemImage: "cart"), content: {
                    Text("").tag(nil as String?)
                    ForEach(grocyVM.mdShoppingLocations, id:\.id) { shoppingLocation in
                        Text(shoppingLocation.name).tag(shoppingLocation.id as String?)
                    }
                })
                
                Picker(selection: $locationID, label: Label(LocalizedStringKey("str.stock.buy.product.location"), systemImage: "location"), content: {
                    Text("").tag(nil as String?)
                    ForEach(grocyVM.mdLocations, id:\.id) { location in
                        Text(location.name).tag(location.id as String?)
                    }
                })
            }
        }
        .onAppear(perform: {
            if firstAppear {
                updateData()
                resetForm()
                firstAppear = false
            }
        })
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    purchaseProduct()
                    resetForm()
                }, label: {
                    Label(LocalizedStringKey("str.stock.buy.product.buy"), systemImage: "cart")
                        .labelStyle(TextIconLabelStyle())
                })
                .disabled(!isFormValid)
            }
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
