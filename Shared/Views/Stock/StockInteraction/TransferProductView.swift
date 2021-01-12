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
    
    @State private var firstAppear: Bool = true
    
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
    
    private func updateData() {
        grocyVM.getMDProducts()
        grocyVM.getMDLocations()
        grocyVM.getMDQuantityUnits()
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
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button(LocalizedStringKey("str.stock.transfer.product.transfer")) {
                        transferProduct()
                        resetForm()
                    }.disabled(!isFormValid)
                }
            })
        #endif
    }
    
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
                    ForEach(grocyVM.stockProductEntries[productID] ?? [], id: \.stockID) { stockProduct in
                        Text(LocalizedStringKey("str.stock.entry.description \(stockProduct.amount) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate) ?? "purchasedate error") \(stockProduct.stockEntryOpen == "0" ? "str.stock.entry.status.notOpened".localized : "str.stock.entry.status.opened".localized)"))
                            .tag(stockProduct.stockID)
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
        .animation(.default)
        .navigationTitle(LocalizedStringKey("str.stock.transfer"))
    }
}

struct TransferProductView_Previews: PreviewProvider {
    static var previews: some View {
        TransferProductView()
    }
}
