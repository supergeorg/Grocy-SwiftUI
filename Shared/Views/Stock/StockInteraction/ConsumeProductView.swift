//
//  ConsumeProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI

struct ConsumeProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstAppear: Bool = true
    
    var productToConsumeID: String?
    
    @State private var productID: String?
    @State private var amount: Double?
    @State private var quantityUnitID: String?
    @State private var locationID: String?
    @State private var spoiled: Bool = false
    @State private var useSpecificStockEntry: Bool = false
    @State private var stockEntryID: String?
    @State private var recipeID: String?
    
    @State private var searchProductTerm: String = ""
    
    @State private var showRecipeInfo: Bool = false
    
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
        (productID != nil) && (amount != nil) && (amount ?? 0 > 0) && (quantityUnitID != nil) && (locationID != nil) && !(useSpecificStockEntry && stockEntryID == nil) && !(useSpecificStockEntry && amount != 1.0)
    }
    
    private func resetForm() {
        productID = productToConsumeID ?? ""
        amount = 0.0
        quantityUnitID = nil
        locationID = nil
        spoiled = false
        useSpecificStockEntry = false
        stockEntryID = nil
        recipeID = nil
        searchProductTerm = ""
    }
    
    private func openProduct() {
        if let amount = amount {
            if let productID = productID {
                let openInfo = ProductOpen(amount: amount, stockEntryID: stockEntryID, allowSubproductSubstitution: nil)
                grocyVM.postStockObject(id: productID, stockModePost: .open, content: openInfo)
            }
        }
    }
    
    private func consumeProduct() {
        if let productID = productID {
            if let amount = amount {
                let intRecipeID = Int(recipeID ?? "")
                let intLocationID = Int(locationID ?? "")
                let consumeInfo = ProductConsume(amount: amount, transactionType: .consume, spoiled: spoiled, stockEntryID: stockEntryID, recipeID: intRecipeID, locationID: intLocationID, exactAmount: nil, allowSubproductSubstitution: nil)
                grocyVM.postStockObject(id: productID, stockModePost: .consume, content: consumeInfo)
            }
        }
    }
    
    private func updateData() {
        if grocyVM.mdProducts.isEmpty {
            grocyVM.getMDProducts()
            grocyVM.getMDQuantityUnits()
            grocyVM.getMDLocations()
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
            ProductField(productID: $productID, description: "str.stock.consume.product")
                .onChange(of: productID) { newProduct in
                    grocyVM.getStockProductEntries(productID: productID ?? "")
                    if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                        locationID = selectedProduct.locationID
                        quantityUnitID = selectedProduct.quIDStock
                    }
                }
            
            Section(header: Text(LocalizedStringKey("str.stock.consume.product.amount")).font(.headline)) {
                MyDoubleStepper(amount: $amount, description: "str.stock.consume.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: (amount == 1 ? currentQuantityUnit.name : currentQuantityUnit.namePlural), errorMessage: "str.stock.consume.product.amount.invalid", systemImage: "number.circle")
                Picker(selection: $quantityUnitID, label: Label(LocalizedStringKey("str.stock.consume.product.quantityUnit"), systemImage: "scalemass"), content: {
                    Text("").tag(nil as String?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id as String?)
                    }
                }).disabled(true)
            }
            
            Section(header: Text(LocalizedStringKey("str.stock.consume.product.details")).font(.headline)) {
                
                MyToggle(isOn: $spoiled, description: "str.stock.consume.product.spoiled", icon: "trash")
                
                MyToggle(isOn: $useSpecificStockEntry, description: "str.stock.consume.product.useStockEntry", descriptionInfo: "str.stock.consume.product.useStockEntry.description", icon: "tag")
                
                if useSpecificStockEntry && productID != nil {
                    Picker(selection: $stockEntryID, label: Label(LocalizedStringKey("str.stock.consume.product.stockEntry"), systemImage: "tag"), content: {
                        Text("").tag(nil as String?)
                        ForEach(grocyVM.stockProductEntries[productID ?? ""] ?? [], id: \.stockID) { stockProduct in
                            Text(LocalizedStringKey("str.stock.entry.description \(stockProduct.amount) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate) ?? "purchasedate error") \(stockProduct.stockEntryOpen == "0" ? "str.stock.entry.status.notOpened".localized : "str.stock.entry.status.opened".localized)"))
                                .tag(stockProduct.stockID as String?)
                        }
                    })
                }
                
                HStack{
                    Picker(selection: $recipeID, label: Label(LocalizedStringKey("str.stock.consume.product.recipe"), systemImage: "tag"), content: {
                        Text("Not implemented").tag(nil as String?)
                    })
                    #if os(macOS)
                    Image(systemName: "questionmark.circle.fill")
                        .help(LocalizedStringKey("str.stock.consume.product.recipe.info"))
                    #elseif os(iOS)
                    Image(systemName: "questionmark.circle.fill")
                        .onTapGesture {
                            showRecipeInfo.toggle()
                        }
                        .help(LocalizedStringKey("str.stock.consume.product.recipe.info"))
                        .popover(isPresented: $showRecipeInfo, content: {
                            Text(LocalizedStringKey("str.stock.consume.product.recipe.info"))
                                .padding()
                        })
                    #endif
                }
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
        .toolbar(content: {
            ToolbarItemGroup(placement: .confirmationAction) {
                HStack{
                    Button(action: {
                        openProduct()
                        resetForm()
                    }, label: {
                        Label(LocalizedStringKey("str.stock.consume.product.open"), systemImage: "envelope.open")
                            .labelStyle(TextIconLabelStyle())
                    })
                    .disabled(!isFormValid)
                    Button(action: {
                        consumeProduct()
                        resetForm()
                    }, label: {
                        Label(LocalizedStringKey("str.stock.consume.product.consume"), systemImage: "tuningfork")
                            .labelStyle(TextIconLabelStyle())
                    })
                    .disabled(!isFormValid)
                    .keyboardShortcut("s", modifiers: [.command])
                }
            }
        })
        .navigationTitle(LocalizedStringKey("str.stock.consume"))
    }
}

struct ConsumeProductView_Previews: PreviewProvider {
    static var previews: some View {
        ConsumeProductView()
    }
}
