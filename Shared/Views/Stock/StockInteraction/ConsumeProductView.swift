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
    
    @State private var toastType: ConsumeToastType?
    private enum ConsumeToastType: Identifiable {
        case successConsume, successOpen, failConsume, failOpen
        
        var id: Int {
            self.hashValue
        }
    }
    @State private var infoString: String?
    
    @State private var showRecipeInfo: Bool = false
    
    private var currentQuantityUnitName: String? {
        let quIDP = grocyVM.mdProducts.first(where: {$0.id == productID})?.quIDPurchase
        let qu = grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
        return amount == 1 ? qu?.name : qu?.namePlural
    }
    private var productName: String {
        grocyVM.mdProducts.first(where: {$0.id == productID})?.name ?? ""
    }
    
    private var selectedProduct: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productID})
    }
    
    private var filteredLocations: MDLocations {
        var locIDs: Set<String> = Set<String>()
        if let entries = grocyVM.stockProductEntries[productID ?? ""] {
            for entry in entries {
                locIDs.insert(entry.locationID)
            }
        }
        return grocyVM.mdLocations
            .filter{ locIDs.contains($0.id) }
    }
    
    private var maxAmount: Double? {
        if let entries = grocyVM.stockProductEntries[productID ?? ""] {
            var maxAmount: Double = 0
            let filtEntries = entries.filter{ $0.locationID == locationID }
            for filtEntry in filtEntries {
                maxAmount += Double(filtEntry.amount) ?? 0
            }
            return maxAmount
        }
        return nil
    }
    
    private let priceFormatter = NumberFormatter()
    
    var isFormValid: Bool {
        (productID != nil) && (amount != nil) && (amount ?? 0 > 0) && (quantityUnitID != nil) && (locationID != nil) && !(useSpecificStockEntry && stockEntryID == nil) && !(useSpecificStockEntry && amount != 1.0) && !(amount ?? 0 > maxAmount ?? 0)
    }
    
    private func resetForm() {
        productID = productToConsumeID
        amount = nil
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
                infoString = "\(amount) \(currentQuantityUnitName ?? "") \(productName)"
                grocyVM.postStockObject(id: productID, stockModePost: .open, content: openInfo) { result in
                    switch result {
                    case let .success(prod):
                        print(prod)
                        toastType = .successOpen
                        resetForm()
                    case let .failure(error):
                        print("\(error)")
                        toastType = .failOpen
                    }
                }
            }
        }
    }
    
    private func consumeProduct() {
        if let productID = productID {
            if let amount = amount {
                let intRecipeID = Int(recipeID ?? "")
                let intLocationID = Int(locationID ?? "")
                let consumeInfo = ProductConsume(amount: amount, transactionType: .consume, spoiled: spoiled, stockEntryID: stockEntryID, recipeID: intRecipeID, locationID: intLocationID, exactAmount: nil, allowSubproductSubstitution: nil)
                infoString = "\(amount) \(currentQuantityUnitName ?? "") \(productName)"
                grocyVM.postStockObject(id: productID, stockModePost: .consume, content: consumeInfo) { result in
                    switch result {
                    case let .success(prod):
                        print(prod)
                        toastType = .successConsume
                        resetForm()
                    case let .failure(error):
                        print("\(error)")
                        toastType = .failConsume
                    }
                }
            }
        }
    }
    
    private func updateData() {
        grocyVM.getMDProducts()
        grocyVM.getMDQuantityUnits()
        grocyVM.getMDLocations()
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
                    if let selectedProduct = selectedProduct {
                        locationID = selectedProduct.locationID
                        quantityUnitID = selectedProduct.quIDStock
                    }
                }
            
            Section(header: Text(LocalizedStringKey("str.stock.consume.product.amount")).font(.headline)) {
                MyDoubleStepper(amount: $amount, description: "str.stock.consume.product.amount", minAmount: 0.0001, maxAmount: maxAmount, amountStep: 1.0, amountName: currentQuantityUnitName, errorMessage: "str.stock.consume.product.amount.invalid", errorMessageMax: "str.stock.consume.product.amount.locMax", systemImage: "number.circle")
                Picker(selection: $quantityUnitID, label: Label(LocalizedStringKey("str.stock.consume.product.quantityUnit"), systemImage: "scalemass"), content: {
                    Text("").tag(nil as String?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id as String?)
                    }
                }).disabled(true)
            }
            
            Picker(selection: $locationID, label: Label(LocalizedStringKey("str.stock.consume.product.location"), systemImage: "location"), content: {
                Text("").tag(nil as String?)
                ForEach(filteredLocations, id:\.id) { location in
                    Text(selectedProduct?.locationID == location.id ? LocalizedStringKey("str.stock.consume.product.location.default \(location.name)") : LocalizedStringKey(location.name)).tag(location.id as String?)
                }
            })
            
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
                grocyVM.requestDataIfUnavailable(objects: [.products, .quantity_units, .locations])
                resetForm()
                firstAppear = false
            }
        })
        .animation(.default)
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successConsume || toastType == .successOpen), content: { item in
            switch item {
            case .successConsume:
                Label(LocalizedStringKey("str.stock.consume.product.consume.success \(infoString ?? "")"), systemImage: "checkmark")
            case .failConsume:
                Label(LocalizedStringKey("str.stock.consume.product.consume.fail"), systemImage: "xmark")
            case .successOpen:
                Label(LocalizedStringKey("str.stock.consume.product.open.success \(infoString ?? "")"), systemImage: "checkmark")
            case .failOpen:
                Label(LocalizedStringKey("str.stock.consume.product.open.fail"), systemImage: "xmark")
            }
        })
        .toolbar(content: {
            ToolbarItemGroup(placement: .confirmationAction) {
                HStack{
                    Button(action: {
                        openProduct()
                    }, label: {
                        Label(LocalizedStringKey("str.stock.consume.product.open"), systemImage: "envelope.open")
                            .labelStyle(TextIconLabelStyle())
                    })
                    .disabled(!isFormValid)
                    Button(action: {
                        consumeProduct()
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
