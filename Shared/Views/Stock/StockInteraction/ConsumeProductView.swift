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
    
    @State private var productID: String = ""
    @State private var amount: Double = 1.0
    @State private var quantityUnitID: String = ""
    @State private var locationID: String = ""
    @State private var spoiled: Bool = false
    @State private var useSpecificStockEntry: Bool = false
    @State private var stockEntryID: String = ""
    @State private var recipeID: String = ""
    
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
        !(productID.isEmpty) && (amount > 0) && !(quantityUnitID.isEmpty) && !(locationID.isEmpty) && !(useSpecificStockEntry && stockEntryID.isEmpty) && !(useSpecificStockEntry && amount != 1.0)
    }
    
    private func resetForm() {
        productID = ""
        amount = 1.0
        quantityUnitID = ""
        locationID = ""
        spoiled = false
        useSpecificStockEntry = false
        stockEntryID = ""
        recipeID = ""
    }
    
    private func openProduct() {
        let cStockEntryID = stockEntryID.isEmpty ? nil : stockEntryID
        let openInfo = ProductOpen(amount: amount, stockEntryID: cStockEntryID)
        grocyVM.postStockObject(id: productID, stockModePost: .open, content: openInfo)
    }
    
    private func consumeProduct() {
        let cStockEntryID = stockEntryID.isEmpty ? nil : stockEntryID
        let intRecipeID = Int(recipeID)
        let intLocationID = Int(locationID)
        let consumeInfo = ProductConsume(amount: amount, transactionType: .consume, spoiled: spoiled, stockEntryID: cStockEntryID, recipeID: intRecipeID, locationID: intLocationID, exactAmount: nil)
        grocyVM.postStockObject(id: productID, stockModePost: .consume, content: consumeInfo)
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
        content
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    HStack{
                        Button(action: {
                            openProduct()
                            resetForm()
                        }, label: {
                            HStack{
                                Text("str.stock.consume.product.open".localized)
                                Image(systemName: "envelope.open")
                            }
                            //                    Label("str.stock.buy.product.buy".localized, systemImage: "cart")
                        })
                        .disabled(!isFormValid)
                        Button(action: {
                            consumeProduct()
                            resetForm()
                        }, label: {
                            HStack{
                                Text("str.stock.consume.product.consume".localized)
                                Image(systemName: "tuningfork")
                            }
                            //                    Label("str.stock.buy.product.buy".localized, systemImage: "cart")
                        })
                        .disabled(!isFormValid)
                        .keyboardShortcut("s", modifiers: [.command])
                    }
                }
            })
        #else
        content
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("str.cancel") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
//                ToolbarItem(placement: .confirmationAction) {
//                    
//                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("str.stock.consume.product.open") {
                        openProduct()
                        resetForm()
                    }.disabled(!isFormValid)
                    Spacer()
                    Button("str.stock.consume.product.consume") {
                        consumeProduct()
                        resetForm()
                    }.disabled(!isFormValid)
                }
            })
        #endif
    }
    
    var content: some View {
        Form {
            Picker(selection: $productID, label: Label("str.stock.consume.product".localized, systemImage: "tag"), content: {
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
                    locationID = selectedProduct.locationID
                    quantityUnitID = selectedProduct.quIDStock
                }
            }
            
            Section(header: Text("str.stock.consume.product.amount".localized).font(.headline)) {
                MyDoubleStepper(amount: $amount, description: "str.stock.consume.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: (amount == 1 ? currentQuantityUnit.name : currentQuantityUnit.namePlural), errorMessage: "str.stock.consume.product.amount.required", systemImage: "number.circle")
                Picker(selection: $quantityUnitID, label: Label("str.stock.consume.product.quantityUnit".localized, systemImage: "scalemass"), content: {
                    Text("").tag("")
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id)
                    }
                }).disabled(true)
            }
            
            Section(header: Text("str.stock.consume.product.details".localized).font(.headline)) {
                
                MyToggle(isOn: $spoiled, description: "str.stock.consume.product.spoiled", icon: "trash")
                
                MyToggle(isOn: $useSpecificStockEntry, description: "str.stock.consume.product.useStockEntry", descriptionInfo: "str.stock.consume.product.useStockEntry.description", icon: "tag")
                
                
                if useSpecificStockEntry && !productID.isEmpty {
                    Picker(selection: $stockEntryID, label: Label("str.stock.consume.product.stockEntry", systemImage: "tag"), content: {
                        ForEach(grocyVM.stockProductEntries[productID] ?? [], id: \.id) { stockProduct in
                            Text("Anz.: \(stockProduct.amount) \(stockProduct.stockEntryOpen == "0" ? "" : " (\(stockProduct.stockEntryOpen) offen)"), MHD: \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error"), Ort: \(grocyVM.mdLocations.first(where: { $0.id == stockProduct.locationID })?.name ?? "Standortfehler")").tag(stockProduct.stockID)
                        }
                    })
                }
                
                Picker(selection: $recipeID, label: Label("str.stock.consume.product.recipe".localized, systemImage: "tag"), content: {
                    Text("Not implemented").tag("nI")
                })
            }
        }
        .onAppear(perform: {
            updateData()
        })
        .animation(.default)
        .navigationTitle("str.stock.consume".localized)
    }
}

struct ConsumeProductView_Previews: PreviewProvider {
    static var previews: some View {
        ConsumeProductView()
    }
}
