//
//  TransferProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI

struct TransferProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    var productToTransferID: String?
    
    @State private var productID: String = ""
    @State private var locationIDFrom: String = ""
    @State private var amount: Double = 0.0
    @State private var quantityUnitID: String = ""
    @State private var locationIDTo: String = ""
    @State private var useSpecificStockEntry: Bool = false
    @State private var stockEntryID: String = ""
    
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
        !(productID.isEmpty) && (amount > 0) && !(quantityUnitID.isEmpty) && !(locationIDFrom.isEmpty) && !(locationIDTo.isEmpty) && !(useSpecificStockEntry && stockEntryID.isEmpty) && !(useSpecificStockEntry && amount != 1.0) && !(locationIDFrom == locationIDTo)
    }
    
    private func resetForm() {
        productID = productToTransferID ?? ""
        locationIDFrom = ""
        amount = 0.0
        quantityUnitID = ""
        locationIDTo = ""
        useSpecificStockEntry = false
        stockEntryID = ""
    }
    
    private func transferProduct() {
        
        if let intLocationIDFrom = Int(locationIDFrom) {
            if let intLocationIDTo = Int(locationIDTo) {
                let cStockEntryID = stockEntryID.isEmpty ? nil : stockEntryID
                let transferInfo = ProductTransfer(amount: amount, locationIDFrom: intLocationIDFrom, locationIDTo: intLocationIDTo, stockEntryID: cStockEntryID)
                grocyVM.postStockObject(id: productID, stockModePost: .transfer, content: transferInfo)
                
            }
        }
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
                            transferProduct()
                            resetForm()
                        }, label: {
                            HStack{
                                Text(LocalizedStringKey("str.stock.transfer.product.transfer"))
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
                    Button(LocalizedStringKey("str.stock.transfer.product.transfer")) {
                        transferProduct()
                        resetForm()
                    }.disabled(!isFormValid)
                }
            })
        #endif
    }
    
    //    "str.stock.transfer" = "Transfer";
    //    "str.stock.transfer.product" = "Product";
    //    "str.stock.transfer.product.transfer" = "Transfer product";
    //    "str.stock.transfer.product.required" = "You have to select a product";
    //    "str.stock.transfer.product.locationFrom" = "From location";
    //    "str.stock.transfer.product.locationFrom.required" = "A location is required";
    //    "str.stock.transfer.product.amount" = "Amount";
    //    "str.stock.transfer.product.amount.required" = "This cannot be lower than 0.0001 and needs to be a valid number with max. 4 decimal places";
    //    "str.stock.transfer.product.quantityUnit" = "Quantity unit";
    //    "str.stock.transfer.product.quantityUnit.required" = "A quantity unit is required";
    //    "str.stock.transfer.product.locationTo" = "To location";
    //    "str.stock.transfer.product.locationTO.required" = "A location is required";
    //    "str.stock.transfer.product.locationTO.same" = "This cannot be the same as the \"From\" location";
    //    "str.stock.transfer.product.useStockEntry" = "Use a specific stock item";
    //    "str.stock.transfer.product.useStockEntry.description" = "The first item in this list would be picked by the default rule which is \"Opened first, then first due first, then first in first out\"";
    
    var content: some View {
        Form {
            Picker(selection: $productID, label: Label(LocalizedStringKey("str.stock.transfer.product"), systemImage: "tag"), content: {
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
                    locationIDFrom = selectedProduct.locationID
                    quantityUnitID = selectedProduct.quIDStock
                }
            }
            
            Picker(selection: $locationIDFrom, label: Label(LocalizedStringKey("str.stock.transfer.product.locationFrom"), systemImage: "square.and.arrow.up"), content: {
                Text("").tag("")
                ForEach(grocyVM.mdLocations, id:\.id) { locationFrom in
                    Text(locationFrom.name).tag(locationFrom.id)
                }
            })
            
            Section(header: Text(LocalizedStringKey("str.stock.transfer.product.amount")).font(.headline)) {
                MyDoubleStepper(amount: $amount, description: "str.stock.transfer.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: (amount == 1 ? currentQuantityUnit.name : currentQuantityUnit.namePlural), errorMessage: "str.stock.transfer.product.amount.invalid", systemImage: "number.circle")
                Picker(selection: $quantityUnitID, label: Label("str.stock.transfer.product.quantityUnit", systemImage: "scalemass"), content: {
                    Text("").tag("")
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id)
                    }
                }).disabled(true)
            }
            
            VStack(alignment: .leading) {
                Picker(selection: $locationIDTo, label: Label(LocalizedStringKey("str.stock.transfer.product.locationTo"), systemImage: "square.and.arrow.down"), content: {
                    Text("").tag("")
                    ForEach(grocyVM.mdLocations, id:\.id) { locationTo in
                        Text(locationTo.name).tag(locationTo.id)
                    }
                })
                if !(locationIDFrom.isEmpty) && (locationIDFrom == locationIDTo) {
                    Text(LocalizedStringKey("str.stock.transfer.product.locationTO.same"))
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            MyToggle(isOn: $useSpecificStockEntry, description: "str.stock.transfer.product.useStockEntry", descriptionInfo: "str.stock.transfer.product.useStockEntry.description", icon: "tag")
            
            if useSpecificStockEntry && !productID.isEmpty {
                Picker(selection: $stockEntryID, label: Label(LocalizedStringKey("str.stock.transfer.product.stockEntry"), systemImage: "tag"), content: {
                    ForEach(grocyVM.stockProductEntries[productID] ?? [], id: \.id) { stockProduct in
                        Text(LocalizedStringKey("str.stock.entry.description \(stockProduct.amount) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate) ?? "purchasedate error") \(stockProduct.stockEntryOpen == "0" ? "str.stock.entry.status.notOpened".localized : "str.stock.entry.status.opened".localized)"))
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
        .navigationTitle(LocalizedStringKey("str.stock.transfer"))
    }
}

struct TransferProductView_Previews: PreviewProvider {
    static var previews: some View {
        TransferProductView()
    }
}
