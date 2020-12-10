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
    
    var productToPurchaseID: String?
    var productToPurchaseAmount: Double?
    
    @State private var productID: String = ""
    @State private var amount: Double = 0.0
    @State private var quantityUnitID: String = ""
    @State private var dueDate: Date = Date()
    @State private var productDoesntSpoil: Bool = false
    @State private var price: Double = 0.0
    @State private var isTotalPrice: Bool = false
    @State private var shoppingLocationID: String = ""
    @State private var locationID: String = ""
    
    @State private var searchProductTerm: String = ""
    
    private var filteredProducts: MDProducts {
        grocyVM.mdProducts.filter {
            searchProductTerm.isEmpty ? true : $0.name.lowercased().contains(searchProductTerm.lowercased())
        }
    }
    
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
        !(productID.isEmpty) && (amount > 0) && !(quantityUnitID.isEmpty)
    }
    
    //    init(productToPurchaseID: String? = nil, productToPurchaseAmount: Double? = nil) {
    //        self.productID = productToPurchaseID ?? ""
    //        self.amount = productToPurchaseAmount ?? 0
    //    }
    
    private func resetForm() {
        self.productID = productToPurchaseID ?? ""
        self.amount = productToPurchaseAmount ?? 0
        self.productID = ""
        self.amount = 0.0
        self.quantityUnitID = ""
        self.dueDate = Date()
        self.productDoesntSpoil = false
        self.price = 0.0
        self.isTotalPrice = false
        //        shoppingLocationID = ""
        //        locationID = ""
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
    
    private func updateData() {
        if grocyVM.mdProducts.isEmpty { grocyVM.getMDProducts() }
        if grocyVM.mdQuantityUnits.isEmpty { grocyVM.getMDQuantityUnits() }
        if grocyVM.mdLocations.isEmpty { grocyVM.getMDLocations() }
        if grocyVM.mdShoppingLocations.isEmpty { grocyVM.getMDShoppingLocations() }
    }
    
    var body: some View {
        #if os(macOS)
        ScrollView{
            content
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .toolbar(content: {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            purchaseProduct()
                            resetForm()
                        }, label: {
                            HStack{
                                Text("str.stock.buy.product.buy".localized)
                                Image(systemName: "cart")
                            }
                            //                    Label("str.stock.buy.product.buy".localized, systemImage: "cart")
                        })
                        .disabled(!isFormValid)
                    }
                })
        }
        #else
        content
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("str.cancel") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("str.stock.buy.product.buy") {
                        purchaseProduct()
                        resetForm()
                    }.disabled(!isFormValid)
                }
            })
        #endif
    }
    
    var content: some View {
        Form {
            Picker(selection: $productID, label: Label("str.stock.buy.product", systemImage: "tag"), content: {
                #if os(iOS)
                SearchBar(text: $searchProductTerm, placeholder: "str.search")
                #endif
                ForEach(filteredProducts, id: \.id) { productElement in
                    Text(productElement.name).tag(productElement.id)
                }
            })
            .onChange(of: productID) { newProduct in
                print(productID)
                if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                    if locationID.isEmpty { locationID = selectedProduct.locationID }
                    if shoppingLocationID.isEmpty { shoppingLocationID = selectedProduct.shoppingLocationID ?? "" }
                    quantityUnitID = selectedProduct.quIDPurchase
                }
            }
            
            Section(header: Text("str.stock.buy.product.amount").font(.headline)) {
                MyDoubleStepper(amount: $amount, description: "str.stock.buy.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: (amount == 1 ? currentQuantityUnit.name : currentQuantityUnit.namePlural), errorMessage: "str.stock.buy.product.amount.required", systemImage: "number.circle")
                Picker(selection: $quantityUnitID, label: Label("str.stock.buy.product.quantityUnit", systemImage: "scalemass"), content: {
                    Text("").tag("")
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id)
                    }
                }).disabled(true)
            }
            
            Section(header: Text("str.stock.buy.product.dueDate").font(.headline)) {
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
            
            Section(header: Text("str.stock.buy.product.price").font(.headline)) {
                MyDoubleStepper(amount: $price, description: "str.stock.buy.product.price", minAmount: 0, amountStep: 1.0, amountName: "Euro", errorMessage: "str.stock.buy.product.price.required", systemImage: "eurosign.circle")
                
                Picker("", selection: $isTotalPrice, content: {
                    Text("str.stock.buy.product.price.perUnit").tag(false)
                    Text("str.stock.buy.product.price.summedUp").tag(true)
                }).pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("str.stock.buy.product.location").font(.headline)) {
                Picker(selection: $shoppingLocationID, label: Label("str.stock.buy.product.shoppingLocation".localized, systemImage: "cart"), content: {
                    Text("").tag("")
                    ForEach(grocyVM.mdShoppingLocations, id:\.id) { shoppingLocation in
                        Text(shoppingLocation.name).tag(shoppingLocation.id)
                    }
                })
                
                Picker(selection: $locationID, label: Label("str.stock.buy.product.location".localized, systemImage: "location"), content: {
                    Text("").tag("")
                    ForEach(grocyVM.mdLocations, id:\.id) { location in
                        Text(location.name).tag(location.id)
                    }
                })
            }
        }
        .onAppear(perform: {
            updateData()
            resetForm()
        })
        .animation(.default)
        .navigationTitle("str.stock.buy".localized)
    }
}

struct PurchaseProductView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseProductView()
    }
}
