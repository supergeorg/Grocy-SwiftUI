//
//  BuyProductView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 20.10.20.
//

// Needs to create:

//amount -> number
//The amount to remove - please note that when tare weight handling for the product is enabled, this needs to be the amount including the container weight (gross), the amount to be posted will be automatically calculated based on what is in stock and the defined tare weight

//transaction_type    stringEnum: [ purchase, consume, inventory-correction, product-opened ]

//spoiled    boolean
//True when the given product was spoiled, defaults to false

//stock_entry_id    string
//A specific stock entry id to consume, if used, the amount has to be 1

//recipe_id    number($integer)
//A valid recipe id for which this product was used (for statistical purposes only)

//location_id    number($integer)
//A valid location id (if supplied, only stock at the given location is considered, if ommitted, stock of any location is considered)


import SwiftUI

struct BuyProductView: View {
    @StateObject private var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var productID: String = ""
    @State private var bestBeforeDate: Date = Date()
    @State private var amount: Int = 0
    @State private var price: Double = 0.0
    @State private var isSinglePrice: Bool = true
    @State private var shoppingLocationID: String = ""
    @State private var locationID: String = ""
    @State private var productDoesntSpoil: Bool = false
    
    @State private var searchProductTerm: String = ""
    private var filteredProducts: [MDProduct] {
        grocyVM.mdProducts.filter {
            searchProductTerm.isEmpty ? true : $0.name.lowercased().contains(searchProductTerm.lowercased())
        }
    }
    
    private var currentQuantityUnit: MDQuantityUnit {
        getQuantityUnit() ?? MDQuantityUnit(id: "0", name: "Stück", mdQuantityUnitDescription: "", rowCreatedTimestamp: "", namePlural: "Stücke", pluralForms: nil, userfields: nil)
    }

    private let priceFormatter = NumberFormatter()
    
//    init(isShown: Binding<Bool>) {
//        self._isShown = isShown
//        priceFormatter.numberStyle = .currency
//        priceFormatter.locale = Locale(identifier: "de_DE")
//    }
    
    func resetForm() {
        productID = ""
        amount = 0
        price = 0.0
        isSinglePrice = true
        productDoesntSpoil = false
        locationID = ""
        shoppingLocationID = ""
    }
    
    func buyProduct() {
        let numLocationID = Int(locationID) ?? nil
        let numShoppingLocationID = Int(shoppingLocationID) ?? nil
        let strPrice = price.isZero ? nil : String(format: "%.2f", price)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let strSpoilDate = productDoesntSpoil ? "2999-12-31" : dateFormatter.string(from: bestBeforeDate)
        let productToAdd = ProductBuy(amount: amount, bestBeforeDate: strSpoilDate, transactionType: "purchase", price: strPrice, locationID: numLocationID, shoppingLocationID: numShoppingLocationID)
        grocyVM.postStockObject(id: productID, stockModePost: .add, content: productToAdd)
    }
    
    func getQuantityUnit() -> MDQuantityUnit? {
        let quIDP = grocyVM.mdProducts.first(where: {$0.id == productID})?.quIDPurchase
        let qu = grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
        return qu
    }
    
    var body: some View {
        NavigationView() {
            Form {
                Section(header: Text("Produkt")){
                    HStack{
                        Image(systemName: "tag")
                        Picker(selection: $productID, label: Text("")) {
                            SearchBar(text: $searchProductTerm, placeholder: "Suche Produkt")
                            ForEach(filteredProducts, id: \.id) { product in
                                Text(product.name).tag(product.id)
                            }
                        }
                        .onChange(of: productID) { newID in
                            if (locationID.isEmpty || shoppingLocationID.isEmpty) {
                                if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                                    if locationID.isEmpty { locationID = selectedProduct.locationID }
                                    if shoppingLocationID.isEmpty { if let id = selectedProduct.shoppingLocationID {shoppingLocationID = id} }
                                }
                            }
                        }
                    }
                }
                Section(header: Text("Produktdaten")){
                    HStack{
                        Image(systemName: "calendar")
                        DatePicker("MHD", selection: $bestBeforeDate, displayedComponents: .date)
                    }
                    .disabled(productDoesntSpoil)
                    HStack{
                        Image(systemName: "trash.slash")
                        Toggle("Läuft nie ab", isOn: $productDoesntSpoil)
                    }
                    HStack{
                        Image(systemName: "number.circle")
                        Text("Menge: ")
                        TextField("", value: $amount, formatter: NumberFormatter())
                        Text(amount > 1 ? currentQuantityUnit.namePlural : currentQuantityUnit.name)
                        Stepper("", onIncrement: {
                            amount += 1
                        }, onDecrement: {
                            if amount > 0 {
                                amount -= 1
                            }
                        })
                    }
                }
                Section(header: Text("Preis und Standort")){
                    HStack{
                        Image(systemName: "eurosign.circle")
                        TextField("", value: $price, formatter: priceFormatter)
                            .keyboardType(.decimalPad)
                        Stepper("", onIncrement: {
                            price += 0.01
                        }, onDecrement: {
                            if price > 0 {
                                price -= 0.01
                            }
                        })
                    }
                    Picker("Preisart", selection: $isSinglePrice, content: {
                        Text("Einzelpreis").tag(true)
                        Text("Gesamtpreis").tag(false)
                    }).pickerStyle(SegmentedPickerStyle())
                    HStack{
                        Image(systemName: "cart")
                        Picker("Geschäft", selection: $shoppingLocationID, content: {
                            ForEach(grocyVM.mdShoppingLocations, id:\.id) { shoppingLocation in
                                Text(shoppingLocation.name).tag(shoppingLocation.id)
                            }
                        })
                    }
                    HStack{
                        Image(systemName: "location")
                        Picker("Standort", selection: $locationID, content: {
                            ForEach(grocyVM.mdLocations, id:\.id) { location in
                                Text(location.name).tag(location.id)
                            }
                        })
                    }
                }
            }
            .onAppear(perform: {
                grocyVM.getMDProducts()
                grocyVM.getMDQuantityUnits()
                grocyVM.getMDLocations()
                grocyVM.getMDShoppingLocations()
                priceFormatter.numberStyle = .currency
                priceFormatter.locale = Locale(identifier: "de_DE")
            })
            .navigationBarTitle("Einkauf")
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Einkaufen") {
                        buyProduct()
                        resetForm()
                        grocyVM.getMDProducts()
                    }.disabled(productID.isEmpty || amount < 1)
                }
            })
        }
    }
}

struct BuyProductView_Previews: PreviewProvider {
    static var previews: some View {
        BuyProductView()
    }
}
