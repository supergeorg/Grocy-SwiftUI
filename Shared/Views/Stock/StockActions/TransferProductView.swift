//
//  TransferProductView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 29.10.20.
//

import SwiftUI

struct TransferProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentation
    
    @State var productID: String = ""
    @State var amount: Int = 0
    @State var locationIDFrom: String = ""
    @State var locationIDTo: String = ""
    @State var stockEntryID: String = ""
    
    @State var useSpecialEntry: Bool = false
    
    @State var isCorrectAmount: Bool = false
    
    @State var searchProductTerm: String = ""
    var filteredProducts: [MDProduct] {
        grocyVM.mdProducts.filter {
            searchProductTerm.isEmpty ? true : $0.name.lowercased().contains(searchProductTerm.lowercased())
        }
    }
    
    private func transferProduct() {
        let intLocationIDFrom = Int(locationIDFrom)!
        let intLocationIDTo = Int(locationIDTo)!
        let strStockEntryID = (stockEntryID.isEmpty || !useSpecialEntry) ? nil : stockEntryID
        let productToTransfer = ProductTransfer(amount: amount, locationIDFrom: intLocationIDFrom, locationIDTo: intLocationIDTo, stockEntryID: strStockEntryID)
        grocyVM.postStockObject(id: productID, stockModePost: .transfer, content: productToTransfer)
    }
    
    func resetForm() {
        productID = ""
        amount = 0
        locationIDFrom = ""
        stockEntryID = ""
        useSpecialEntry = false
        isCorrectAmount = false
    }
    
    var currentQuantityUnit: MDQuantityUnit {
        getQuantityUnit() ?? MDQuantityUnit(id: "0", name: "Stück", mdQuantityUnitDescription: "", rowCreatedTimestamp: "", namePlural: "Stücke", pluralForms: nil, userfields: nil)
    }
    
    func getQuantityUnit() -> MDQuantityUnit? {
        let quIDP = grocyVM.mdProducts.first(where: {$0.id == productID})?.quIDPurchase
        let qu = grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
        return qu
    }
    
    func getMaxAmount() -> Int {
        var amount = 0
        let entries = grocyVM.stockProductEntries[productID]
        if entries != nil {
            for entry in entries! {
                amount += Int(entry.amount) ?? 0
            }
        }
        return amount
    }
    
    func getStandardLocationID() -> String {
        let product = grocyVM.mdProducts.first{ $0.id == productID }
        return product?.locationID ?? ""
    }
    
    var standardLocationID: String { getStandardLocationID() }
    
    func getLocations() -> MDLocations {
        var locationIDs = Set<String>()
        let entries = grocyVM.stockProductEntries[productID]
        if entries != nil {
            for entry in entries! {
                locationIDs.insert(entry.locationID)
            }
        }
        var locations: MDLocations = []
        for locationID in locationIDs {
            let location = grocyVM.mdLocations.first{ $0.id == locationID }
            if location != nil { locations.append(location!)} else { print("error in finding location") }
        }
        return locations
    }
    
    var locations: MDLocations { getLocations() }
    
    var maxAmount: Int { getMaxAmount() }
    
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
                        .onChange(of: productID, perform: { value in
                            grocyVM.getProductEntries(productID: productID)
                            locationIDFrom = standardLocationID
                        })
                    }
                    HStack{
                        Image(systemName: "number.circle")
                        //                        Text("Menge: ")
                        //                        TextField("", value: $amount, formatter: NumberFormatter())
                        MyNumberField(numToEdit: $amount, description: "Menge", isCorrect: $isCorrectAmount, helperText: maxAmount > 0 ? "Menge zwischen 1 und \(maxAmount)" : nil)
                        Text(amount > 1 ? currentQuantityUnit.namePlural : currentQuantityUnit.name)
                        Stepper("", onIncrement: {
                            if amount < maxAmount {amount += 1}
                        }, onDecrement: {
                            if amount > 0 {
                                amount -= 1
                            }
                        })
                    }
                    .onChange(of: amount, perform: { value in
                        if amount <= maxAmount && amount > 0 {
                            isCorrectAmount = true
                        } else { isCorrectAmount = false }
                    })
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
                Section(header: Text("Standort")){
                    HStack{
                        Image(systemName: "location")
                        Picker("Standort von", selection: $locationIDFrom, content: {
                            ForEach(locations, id:\.id) { location in
                                Text("\(location.name)\(location.id == standardLocationID ? " (Standard-Standort)" : "")").tag(location.id)
                            }
                        })
                    }
                    VStack(alignment: .leading){
                        HStack{
                            Image(systemName: "location")
                            Picker("Standort nach", selection: $locationIDTo, content: {
                                ForEach(grocyVM.mdLocations, id:\.id) { location in
                                    Text(location.name).tag(location.id)
                                }
                            })
                        }
                        if (locationIDFrom == locationIDTo) && (!locationIDFrom.isEmpty) && (!locationIDTo.isEmpty) {
                            Text("Standorte sind identisch!")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Transfer")
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        self.presentation.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Transfer") {
                                                transferProduct()
                                                resetForm()
                                                grocyVM.getMDProducts()
                    }.disabled(productID.isEmpty || amount < 1 || amount > maxAmount || (locationIDFrom == locationIDTo) || locationIDFrom.isEmpty || locationIDTo.isEmpty)
                }
            })
            .onAppear(perform: {
                grocyVM.getMDProducts()
                grocyVM.getMDLocations()
            })
        }
    }
}

struct TransferProductView_Previews: PreviewProvider {
    static var previews: some View {
        TransferProductView()
    }
}
