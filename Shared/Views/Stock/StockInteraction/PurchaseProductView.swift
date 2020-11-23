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
    
    @State private var productID: String = ""
    @State private var amount: Double = 0.0
    @State private var quantityUnitID: String = ""
    @State private var dueDate: Date = Date()
    @State private var productDoesntSpoil: Bool = false
    @State private var price: Double = 0
    @State private var isTotalPrice: Bool = false
    @State private var shoppingLocationID: String = ""
    @State private var locationID: String = ""
    
    @State private var searchProductTerm: String = ""
    
    private var filteredProducts: MDProducts {
        grocyVM.mdProducts.filter {
            searchProductTerm.isEmpty ? true : $0.name.lowercased().contains(searchProductTerm.lowercased())
        }
    }
    
    func getQuantityUnit() -> MDQuantityUnit? {
        let quIDP = grocyVM.mdProducts.first(where: {$0.id == productID})?.quIDPurchase
        let qu = grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
        return qu
    }
    private var currentQuantityUnit: MDQuantityUnit {
        getQuantityUnit() ?? MDQuantityUnit(id: "0", name: "Stück", mdQuantityUnitDescription: "", rowCreatedTimestamp: "", namePlural: "Stücke", pluralForms: nil, userfields: nil)
    }
    
    private let priceFormatter = NumberFormatter()
    
    var isFormValid: Bool {
        !(productID.isEmpty) && (amount > 0) && !(quantityUnitID.isEmpty)
    }
    
    private func purchaseProduct() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let strDueDate = productDoesntSpoil ? "2999-12-31" : dateFormatter.string(from: dueDate)
        let calculatedPrice = isTotalPrice ? price : amount * price
        let strPrice = calculatedPrice.isZero ? nil : String(format: "%.2f", calculatedPrice)
        let numLocationID = Int(locationID) ?? nil
        let numShoppingLocationID = Int(shoppingLocationID) ?? nil
        let purchaseInfo = ProductBuy(amount: amount, bestBeforeDate: strDueDate, transactionType: .purchase, price: strPrice, locationID: numLocationID, shoppingLocationID: numShoppingLocationID)
        grocyVM.postStockObject(id: productID, stockModePost: .add, content: purchaseInfo)
    }
    
    var body: some View {
        #if os(iOS)
        NavigationView {
            content
        }
        #else
        content
        #endif
    }
    
    var content: some View {
        Form {
            HStack{
                Image(systemName: "tag")
                Picker(selection: $productID, label: Text("str.stock.buy.product")) {
                    SearchBar(text: $searchProductTerm, placeholder: "str.search")
                    ForEach(filteredProducts, id: \.id) { productElement in
                        Text(productElement.name).tag(productElement.id)
                    }
                }
                .onChange(of: productID) { newProduct in
                        if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                            if locationID.isEmpty { locationID = selectedProduct.locationID }
                            if shoppingLocationID.isEmpty { shoppingLocationID = selectedProduct.shoppingLocationID ?? "" }
                            quantityUnitID = selectedProduct.quIDPurchase
                        }
                }
            }
            
            Section(header: Text("str.stock.buy.product.amount")) {
                HStack(alignment: .top) {
                    Image(systemName: "number.circle")
                    MyDoubleStepper(amount: $amount, description: "str.stock.buy.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: (amount == 1 ? currentQuantityUnit.name : currentQuantityUnit.namePlural), errorMessage: "str.stock.buy.product.amount.required")
                }
                
                Picker(selection: $quantityUnitID, label: Text("str.stock.buy.product.quantityUnit"), content: {
                    Text("").tag("")
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text(pickerQU.name).tag(pickerQU.id)
                    }
                }).disabled(true)
            }
            
            Section(header: Text("str.stock.buy.product.dueDate")) {
                HStack {
                    Image(systemName: "calendar")
                    DatePicker("str.stock.buy.product.dueDate".localized, selection: $dueDate, displayedComponents: .date)
                        .disabled(productDoesntSpoil)
                }
                
                HStack {
                    Image(systemName: "trash.slash")
                    Toggle("str.stock.buy.product.doesntSpoil", isOn: $productDoesntSpoil)
                }
            }
            
            Section(header: Text("str.stock.buy.product.price")) {
                HStack(alignment: .top) {
                    Image(systemName: "eurosign.circle")
                    MyDoubleStepper(amount: $price, description: "str.stock.buy.product.price", minAmount: 0, amountStep: 1.0, amountName: "Euro", errorMessage: "str.stock.buy.product.price.required")
                }
                
                Picker("", selection: $isTotalPrice, content: {
                    Text("str.stock.buy.product.price.perUnit").tag(false)
                    Text("str.stock.buy.product.price.summedUp").tag(true)
                }).pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("str.stock.buy.product.location")) {
                HStack{
                    Image(systemName: "cart")
                    Picker("str.stock.buy.product.shoppingLocation".localized, selection: $shoppingLocationID, content: {
                        Text("").tag("")
                        ForEach(grocyVM.mdShoppingLocations, id:\.id) { shoppingLocation in
                            Text(shoppingLocation.name).tag(shoppingLocation.id)
                        }
                    })
                }
                HStack{
                    Image(systemName: "location")
                    Picker("str.stock.buy.product.location".localized, selection: $locationID, content: {
                        Text("").tag("")
                        ForEach(grocyVM.mdLocations, id:\.id) { location in
                            Text(location.name).tag(location.id)
                        }
                    })
                }
            }
            
        }
        .animation(.default)
        .navigationTitle("str.stock.buy")
        .toolbar(content: {
            #if os(iOS)
            ToolbarItem(placement: .cancellationAction) {
                Button("str.cancel") {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("str.stock.buy.product.buy") {
                    purchaseProduct()
                    presentationMode.wrappedValue.dismiss()
                }.disabled(!isFormValid)
            }
            #endif
        })
    }
}

struct PurchaseProductView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseProductView()
    }
}
