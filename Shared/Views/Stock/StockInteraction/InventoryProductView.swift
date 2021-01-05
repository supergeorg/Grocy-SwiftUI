//
//  InventoryProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI

struct InventoryProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    var productToInventoryID: String?
    
    @State private var productID: String = ""
    @State private var amount: Int = 0
    @State private var quantityUnitID: String = ""
    @State private var dueDate: Date = Date()
    @State private var productNeverOverdue: Bool = false
    @State private var price: Double = 0.0
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
    private func getQUString(amount: Int) -> String {
        return amount == 1 ? currentQuantityUnit.name : currentQuantityUnit.namePlural
    }
    
    private let priceFormatter = NumberFormatter()
    
    private var isFormValid: Bool {
        !(productID.isEmpty) && (amount > 0) && !(quantityUnitID.isEmpty) && !(locationID.isEmpty)
    }
    
    private var selectedProductStock: StockElement? {
        grocyVM.stock.first(where: {$0.product.id == productID})
    }
    
    private var stockAmountDifference: Int {
        if let intStockAmount = Int(selectedProductStock?.amount ?? "") {
            return amount - intStockAmount
        } else {return 0}
    }
    
    private func resetForm() {
        productID = productToInventoryID ?? ""
        amount = 0
        quantityUnitID = ""
        dueDate = Date()
        productNeverOverdue = false
        price = 0.0
        shoppingLocationID = ""
        locationID = ""
    }
    
    private func inventoryProduct() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let strDueDate = productNeverOverdue ? "2999-12-31" : dateFormatter.string(from: dueDate)
        let intShoppingLocation = shoppingLocationID.isEmpty ? nil : Int(shoppingLocationID)!
        let intLocationID = locationID.isEmpty ? nil : Int(locationID)!
        let inventoryInfo = ProductInventory(newAmount: amount, bestBeforeDate: strDueDate, shoppingLocationID: intShoppingLocation, locationID: intLocationID, price: price)
        grocyVM.postStockObject(id: productID, stockModePost: .inventory, content: inventoryInfo)
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
                            inventoryProduct()
                            resetForm()
                        }, label: {
                            HStack{
                                Text("str.stock.inventory.product.inventory".localized)
                                Image(systemName: "arrow.left.arrow.right")
                            }
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
                    Button("str.stock.inventory.product.inventory".localized) {
                        inventoryProduct()
                        resetForm()
                    }.disabled(!isFormValid)
                }
            })
        #endif
    }
    
    var content: some View {
        Form {
            Picker(selection: $productID, label: Label(LocalizedStringKey("str.stock.inventory.product"), systemImage: "tag"), content: {
                #if os(iOS)
                SearchBar(text: $searchProductTerm, placeholder: "str.search")
                #endif
                ForEach(filteredProducts, id: \.id) { productElement in
                    Text(productElement.name).tag(productElement.id)
                }
            })
            .onChange(of: productID) { newProduct in
                grocyVM.getStockProductEntries(productID: productID)
                if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                    shoppingLocationID = selectedProduct.shoppingLocationID ?? ""
                    locationID = selectedProduct.locationID
                    quantityUnitID = selectedProduct.quIDStock
                }
            }
            
            Section(header: Text(LocalizedStringKey("str.stock.inventory.product.amount")).font(.headline)) {
                MyIntStepper(amount: $amount, description: "str.stock.inventory.product.amount", amountName: getQUString(amount: amount), errorMessage: "str.stock.inventory.product.amount.required", systemImage: "number.circle")
                Picker(selection: $quantityUnitID, label: Label(LocalizedStringKey("str.stock.inventory.product.quantityUnit"), systemImage: "scalemass"), content: {
                    Text("").tag("")
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id)
                    }
                }).disabled(true)
                if stockAmountDifference != 0 {
                    Text(stockAmountDifference > 0 ? LocalizedStringKey("str.stock.inventory.product.amount.higher \("\(stockAmountDifference) \(getQUString(amount: stockAmountDifference))")") : LocalizedStringKey("str.stock.inventory.product.amount.lower \("\(-stockAmountDifference) \(getQUString(amount: -stockAmountDifference))")"))
                }
            }
            
            Section(header: Text(LocalizedStringKey("str.stock.inventory.product.dueDate")).font(.headline)) {
                HStack {
                    Image(systemName: "calendar")
                    DatePicker(LocalizedStringKey("str.stock.inventory.product.dueDate"), selection: $dueDate, displayedComponents: .date)
                        .disabled(productNeverOverdue)
                }
                
                MyToggle(isOn: $productNeverOverdue, description: "str.stock.inventory.product.neverOverdue", icon: "trash.slash")
            }
            
            MyDoubleStepper(amount: $price, description: "str.stock.inventory.product.price", descriptionInfo: "str.stock.inventory.product.price.info", minAmount: 0, amountStep: 1.0, amountName: grocyVM.getCurrencySymbol(), errorMessage: "str.stock.inventory.product.price.required", systemImage: "eurosign.circle")
            
            Section(header: Text(LocalizedStringKey("str.stock.inventory.product.location")).font(.headline)) {
                Picker(selection: $shoppingLocationID, label: Label(LocalizedStringKey("str.stock.inventory.product.shoppingLocation"), systemImage: "cart"), content: {
                    Text("").tag("")
                    ForEach(grocyVM.mdShoppingLocations, id:\.id) { shoppingLocation in
                        Text(shoppingLocation.name).tag(shoppingLocation.id)
                    }
                })
                
                Picker(selection: $locationID, label: Label(LocalizedStringKey("str.stock.inventory.product.location"), systemImage: "location"), content: {
                    ForEach(grocyVM.mdLocations, id:\.id) { location in
                        Text(location.name).tag(location.id)
                    }
                })
            }
        }
        .onAppear(perform: {
            if grocyVM.mdProducts.isEmpty {
                grocyVM.getMDProducts()
                grocyVM.getMDLocations()
                grocyVM.getMDQuantityUnits()
            }
        })
        .animation(.default)
        .navigationTitle(LocalizedStringKey("str.stock.inventory"))
    }
}

struct InventoryProductView_Previews: PreviewProvider {
    static var previews: some View {
        InventoryProductView()
    }
}
