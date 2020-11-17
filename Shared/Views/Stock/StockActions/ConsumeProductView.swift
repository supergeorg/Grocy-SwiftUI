//
//  ConsumeProductView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 23.10.20.
//

import SwiftUI

struct ConsumeProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentation
    
    @State var productID: String = ""
    @State var amount: Int = 0
    @State var locationID: String = ""
    @State var isSpoiled: Bool = false
    @State var useSpecialEntry: Bool = false
    @State var stockEntryID: String = ""
    
    @State var searchProductTerm: String = ""
    var filteredProducts: [MDProduct] {
        grocyVM.mdProducts.filter {
            searchProductTerm.isEmpty ? true : $0.name.lowercased().contains(searchProductTerm.lowercased())
        }
    }
    
    var currentQuantityUnit: MDQuantityUnit {
        getQuantityUnit() ?? MDQuantityUnit(id: "0", name: "Stück", mdQuantityUnitDescription: "", rowCreatedTimestamp: "", namePlural: "Stücke", pluralForms: nil, userfields: nil)
    }
    
    func getQuantityUnit() -> MDQuantityUnit? {
        let quIDP = grocyVM.mdProducts.first(where: {$0.id == productID})?.quIDPurchase
        let qu = grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
        return qu
    }
    
    func openProduct() {
        let strStockEntryID: String? = (stockEntryID.isEmpty || !useSpecialEntry) ? nil : stockEntryID
        let intRecipeID: Int? = nil
        let intLocationID = Int(locationID)
        let productToConsume = ProductConsume(amount: amount, transactionType: StockTransactionType.consume.rawValue, spoiled: isSpoiled, stockEntryID: strStockEntryID, recipeID: intRecipeID, locationID: intLocationID)
        grocyVM.postStockObject(id: productID, stockModePost: .consume, content: productToConsume)
        print(grocyVM.lastErrors.last?.errorMessage ?? "no last error")
    }
    
    func consumeProduct() {
        let strStockEntryID: String? = (stockEntryID.isEmpty || !useSpecialEntry) ? nil : stockEntryID
        let intRecipeID: Int? = nil
        let intLocationID = Int(locationID)
        let productToConsume = ProductConsume(amount: amount, transactionType: StockTransactionType.consume.rawValue, spoiled: isSpoiled, stockEntryID: strStockEntryID, recipeID: intRecipeID, locationID: intLocationID)
        grocyVM.postStockObject(id: productID, stockModePost: .consume, content: productToConsume)
        print(grocyVM.lastErrors.last?.errorMessage ?? "no last error")
    }
    
    func resetForm() {
        
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
                        }.onChange(of: productID, perform: { value in
                            if let newLoc = grocyVM.mdProducts.first(where: { $0.id == productID })?.locationID {
                                locationID = newLoc
                            }
                            grocyVM.getProductEntries(productID: productID)
                        })
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
                    }//.foregroundColor((useSpecialEntry && amount > Int(grocyVM.stockProductEntries[productID]![stockEntryID].amount)) ? .red : .primary)
                    HStack{
                        Image(systemName: "trash")
                        Toggle("Verdorben", isOn: $isSpoiled)
                    }
                }
                Section(header: Text("Standort und Bestand")){
                    HStack{
                        Image(systemName: "location")
                        Picker("Standort", selection: $locationID, content: {
                            ForEach(grocyVM.mdLocations, id:\.id) { location in
                                Text(location.name).tag(location.id)
                            }
                        })
                    }
                    HStack{
                        Image(systemName: "selection.pin.in.out")
                        Toggle("Einen bestimmten Bestandseintrag verwenden", isOn: $useSpecialEntry)
                    }
                    Text("Der erste Eintrag in dieser Liste würde von der Standardregel 'Zuerst ablaufende zuerst, dann First In - First Out' ausgewählt werden").font(.caption)
                    if useSpecialEntry && !productID.isEmpty {
                        HStack{
                            Image(systemName: "tag")
                            Picker(selection: $stockEntryID, label: Text("")) {
                                ForEach(grocyVM.stockProductEntries[productID] ?? [], id: \.id) { stockProduct in
                                    Text("\(stockProduct.stockID) Anz.: \(stockProduct.amount) \(stockProduct.stockEntryOpen == "0" ? "" : " (\(stockProduct.stockEntryOpen) offen)"), MHD: \(formatDateOutput(stockProduct.bestBeforeDate)), Ort: \(grocyVM.mdLocations.first(where: { $0.id == stockProduct.locationID })?.name ?? "Standortfehler")").tag(stockProduct.stockID)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Produkt verbrauchen")
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        presentation.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Öffnen") {
                        openProduct()
                        resetForm()
                        grocyVM.getMDProducts()
                    }.disabled(productID.isEmpty || amount < 1 || (amount > 1 && useSpecialEntry))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Verbrauchen") {
                        consumeProduct()
                        resetForm()
                        grocyVM.getMDProducts()
                    }.disabled(productID.isEmpty || amount < 1 || (amount > 1 && useSpecialEntry))
                }
            })
            .onAppear(perform: {
                grocyVM.getMDProducts()
                grocyVM.getMDQuantityUnits()
                grocyVM.getMDLocations()
            })
        }
    }
}

struct ConsumeProductView_Previews: PreviewProvider {
    static var previews: some View {
        ConsumeProductView()
    }
}
