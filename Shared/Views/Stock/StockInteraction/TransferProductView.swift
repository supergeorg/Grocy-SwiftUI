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
    
    @State private var productID: String?
    @State private var locationIDFrom: String?
    @State private var amount: Double?
    @State private var quantityUnitID: String?
    @State private var locationIDTo: String?
    @State private var useSpecificStockEntry: Bool = false
    @State private var stockEntryID: String?
    
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
        (productID != nil) && (amount ?? 0 > 0) && (quantityUnitID != nil) && (locationIDFrom != nil) && (locationIDTo != nil) && !(useSpecificStockEntry && stockEntryID == nil) && !(useSpecificStockEntry && amount != 1.0) && !(locationIDFrom == locationIDTo)
    }
    
    private func resetForm() {
        productID = productToTransferID
        locationIDFrom = nil
        amount = nil
        quantityUnitID = nil
        locationIDTo = nil
        useSpecificStockEntry = false
        stockEntryID = nil
        searchProductTerm = ""
    }
    
    private func updateData() {
        grocyVM.getMDProducts()
        grocyVM.getMDLocations()
        grocyVM.getMDQuantityUnits()
    }
    
    private func transferProduct() {
        if let intLocationIDFrom = Int(locationIDFrom ?? "") {
            if let intLocationIDTo = Int(locationIDTo ?? "") {
                if let productID = productID {
                    if let amount = amount {
                        let transferInfo = ProductTransfer(amount: amount, locationIDFrom: intLocationIDFrom, locationIDTo: intLocationIDTo, stockEntryID: stockEntryID)
                        grocyVM.postStockObject(id: productID, stockModePost: .transfer, content: transferInfo)
                    }
                }
            }
        }
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
                    Button("str.cancel") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            })
        #endif
    }
    
    var content: some View {
        Form {
            ProductField(productID: $productID, description: "str.stock.transfer.product")
                .onChange(of: productID) { newProduct in
                    grocyVM.getStockProductEntries(productID: productID ?? "")
                    if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                        locationIDFrom = selectedProduct.locationID
                        quantityUnitID = selectedProduct.quIDStock
                    }
                }
            
            Picker(selection: $locationIDFrom, label: Label(LocalizedStringKey("str.stock.transfer.product.locationFrom"), systemImage: "square.and.arrow.up"), content: {
                Text("").tag(nil as String?)
                ForEach(grocyVM.mdLocations, id:\.id) { locationFrom in
                    Text(locationFrom.name).tag(locationFrom.id as String?)
                }
            })
            
            Section(header: Text(LocalizedStringKey("str.stock.transfer.product.amount")).font(.headline)) {
                MyDoubleStepper(amount: $amount, description: "str.stock.transfer.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: (amount == 1 ? currentQuantityUnit.name : currentQuantityUnit.namePlural), errorMessage: "str.stock.transfer.product.amount.invalid", systemImage: "number.circle")
                Picker(selection: $quantityUnitID, label: Label("str.stock.transfer.product.quantityUnit", systemImage: "scalemass"), content: {
                    Text("").tag(nil as String?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id as String?)
                    }
                }).disabled(true)
            }
            
            VStack(alignment: .leading) {
                Picker(selection: $locationIDTo, label: Label(LocalizedStringKey("str.stock.transfer.product.locationTo"), systemImage: "square.and.arrow.down"), content: {
                    Text("").tag(nil as String?)
                    ForEach(grocyVM.mdLocations, id:\.id) { locationTo in
                        Text(locationTo.name).tag(locationTo.id as String?)
                    }
                })
                if (locationIDFrom != nil) && (locationIDFrom == locationIDTo) {
                    Text(LocalizedStringKey("str.stock.transfer.product.locationTO.same"))
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            MyToggle(isOn: $useSpecificStockEntry, description: "str.stock.transfer.product.useStockEntry", descriptionInfo: "str.stock.transfer.product.useStockEntry.description", icon: "tag")
            
            if (useSpecificStockEntry) && (productID != nil) {
                Picker(selection: $stockEntryID, label: Label(LocalizedStringKey("str.stock.transfer.product.stockEntry"), systemImage: "tag"), content: {
                    ForEach(grocyVM.stockProductEntries[productID ?? ""] ?? [], id: \.stockID) { stockProduct in
                        Text(LocalizedStringKey("str.stock.entry.description \(stockProduct.amount) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate) ?? "purchasedate error") \(stockProduct.stockEntryOpen == "0" ? "str.stock.entry.status.notOpened".localized : "str.stock.entry.status.opened".localized)"))
                            .tag(stockProduct.stockID as String?)
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
                    transferProduct()
                    resetForm()
                }, label: {
                    Label(LocalizedStringKey("str.stock.transfer.product.transfer"), systemImage: "arrow.left.arrow.right")
                        .labelStyle(TextIconLabelStyle())
                })
                .disabled(!isFormValid)
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
