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
    
    @AppStorage("devMode") private var devMode: Bool = false
    
    @State private var firstAppear: Bool = true
    @State private var isProcessingAction: Bool = false
    
#if os(iOS)
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
#endif
    
    var productToConsumeID: Int?
    
    @State private var productID: Int?
    @State private var amount: Double = 1.0
    @State private var quantityUnitID: Int?
    @State private var locationID: Int?
    @State private var spoiled: Bool = false
    @State private var useSpecificStockEntry: Bool = false
    @State private var stockEntryID: String?
    @State private var recipeID: Int?
    
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
    
    private let dataToUpdate: [ObjectEntities] = [.products, .quantity_units, .locations]
    
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productID})
    }
    private var currentQuantityUnitName: String? {
        let quIDP = grocyVM.mdProducts.first(where: {$0.id == productID})?.quIDPurchase
        let qu = grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
        return amount == 1 ? qu?.name : qu?.namePlural
    }
    private var productName: String {
        product?.name ?? ""
    }
    
    private var filteredLocations: MDLocations {
        var locIDs: Set<Int> = Set<Int>()
        if let productID = productID, let entries = grocyVM.stockProductEntries[productID] {
            for entry in entries {
                if let locID = entry.locationID {
                    locIDs.insert(locID)
                }
            }
            return grocyVM.mdLocations
                .filter{ locIDs.contains($0.id) }
        } else {
            return grocyVM.mdLocations
        }
    }
    
    private var maxAmount: Double? {
        if let entries = grocyVM.stockProductEntries[productID ?? 0] {
            var maxAmount: Double = 0
            let filtEntries = entries.filter{ $0.locationID == locationID }
            for filtEntry in filtEntries {
                maxAmount += filtEntry.amount
            }
            return maxAmount
        }
        return nil
    }
    
    private let priceFormatter = NumberFormatter()
    
    var isFormValid: Bool {
        (productID != nil) && (amount > 0) && (quantityUnitID != nil) && (locationID != nil) && !(useSpecificStockEntry && stockEntryID == nil) && !(useSpecificStockEntry && amount != 1.0) && !(amount > maxAmount ?? 0)
    }
    
    private func resetForm() {
        productID = firstAppear ? productToConsumeID : nil
        amount = 1.0
        quantityUnitID = firstAppear ? product?.quIDStock : nil
        locationID = nil
        spoiled = false
        useSpecificStockEntry = false
        stockEntryID = nil
        recipeID = nil
        searchProductTerm = ""
    }
    
    private func openProduct() {
        if let productID = productID {
            let openInfo = ProductOpen(amount: amount, stockEntryID: stockEntryID, allowSubproductSubstitution: nil)
            infoString = "\(formatAmount(amount)) \(currentQuantityUnitName ?? "") \(productName)"
            isProcessingAction = true
            grocyVM.postStockObject(id: productID, stockModePost: .open, content: openInfo) { result in
                switch result {
                case let .success(prod):
                    grocyVM.postLog(message: "Opening successful. \(prod)", type: .info)
                    toastType = .successOpen
                    grocyVM.requestData(additionalObjects: [.stock], ignoreCached: true)
                    resetForm()
                case let .failure(error):
                    grocyVM.postLog(message: "Opening failed: \(error)", type: .error)
                    toastType = .failOpen
                }
                isProcessingAction = false
            }
        }
    }
    
    private func consumeProduct() {
        if let productID = productID {
            let consumeInfo = ProductConsume(amount: amount, transactionType: .consume, spoiled: spoiled, stockEntryID: stockEntryID, recipeID: recipeID, locationID: locationID, exactAmount: nil, allowSubproductSubstitution: nil)
            infoString = "\(formatAmount(amount)) \(currentQuantityUnitName ?? "") \(productName)"
            isProcessingAction = true
            grocyVM.postStockObject(id: productID, stockModePost: .consume, content: consumeInfo) { result in
                switch result {
                case let .success(prod):
                    grocyVM.postLog(message: "Consume successful. \(prod)", type: .info)
                    toastType = .successConsume
                    resetForm()
                case let .failure(error):
                    grocyVM.postLog(message: "Consume failed: \(error)", type: .error)
                    toastType = .failConsume
                }
                isProcessingAction = false
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
            if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count > 0 {
                Section{
                    ServerOfflineView(isCompact: true)
                }
            }
            
            ProductField(productID: $productID, description: "str.stock.consume.product")
                .onChange(of: productID) { newProduct in
                    if let productID = productID {
                        grocyVM.getStockProductEntries(productID: productID)
                        if let product = product {
                            locationID = product.locationID
                            quantityUnitID = product.quIDStock
                        }
                    }
                }
            
            Section(header: Text(LocalizedStringKey("str.stock.consume.product.amount")).font(.headline)) {
                MyDoubleStepper(amount: $amount, description: "str.stock.consume.product.amount", minAmount: 0.0001, maxAmount: maxAmount, amountStep: 1.0, amountName: currentQuantityUnitName, errorMessage: "str.stock.consume.product.amount.invalid", errorMessageMax: "str.stock.consume.product.amount.locMax", systemImage: MySymbols.amount)
                Picker(selection: $quantityUnitID, label: Label(LocalizedStringKey("str.stock.consume.product.quantityUnit"), systemImage: MySymbols.quantityUnit), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id as Int?)
                    }
                }).disabled(true)
            }
            
            Picker(selection: $locationID, label: Label(LocalizedStringKey("str.stock.consume.product.location"), systemImage: MySymbols.location), content: {
                Text("").tag(nil as Int?)
                ForEach(filteredLocations, id:\.id) { location in
                    Text(product?.locationID == location.id ? LocalizedStringKey("str.stock.consume.product.location.default \(location.name)") : LocalizedStringKey(location.name)).tag(location.id as Int?)
                }
            })
            
            Section(header: Text(LocalizedStringKey("str.stock.consume.product.details")).font(.headline)) {
                
                MyToggle(isOn: $spoiled, description: "str.stock.consume.product.spoiled", icon: MySymbols.spoiled)
                
                if let productID = productID {
                    MyToggle(isOn: $useSpecificStockEntry, description: "str.stock.consume.product.useStockEntry", descriptionInfo: "str.stock.consume.product.useStockEntry.description", icon: "tag")
                    
                    if useSpecificStockEntry {
                        Picker(selection: $stockEntryID, label: Label(LocalizedStringKey("str.stock.consume.product.stockEntry"), systemImage: "tag"), content: {
                            Text("").tag(nil as String?)
                            ForEach(grocyVM.stockProductEntries[productID] ?? [], id: \.stockID) { stockProduct in
                                Text(stockProduct.stockEntryOpen == 0 ? LocalizedStringKey("str.stock.entry.description.notOpened \(formatAmount(stockProduct.amount)) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate ?? "") ?? "purchasedate error")") : LocalizedStringKey("str.stock.entry.description.opened \(formatAmount(stockProduct.amount)) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate ?? "") ?? "purchasedate error")"))
                                    .tag(stockProduct.stockID as String?)
                            }
                        })
                    }
                }
                
                if devMode {
                    HStack{
                        Picker(selection: $recipeID, label: Label(LocalizedStringKey("str.stock.consume.product.recipe"), systemImage: "tag"), content: {
                            Text("Not implemented").tag(nil as Int?)
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
        }
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: dataToUpdate, ignoreCached: false)
                resetForm()
                if let productID = productID {
                    grocyVM.getStockProductEntries(productID: productID)
                    if let product = product {
                        locationID = product.locationID
                        quantityUnitID = product.quIDStock
                    }
                }
                firstAppear = false
            }
        })
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successConsume || toastType == .successOpen), content: { item in
            switch item {
            case .successConsume:
                Label(LocalizedStringKey("str.stock.consume.product.consume.success \(infoString ?? "")"), systemImage: MySymbols.success)
            case .failConsume:
                Label(LocalizedStringKey("str.stock.consume.product.consume.fail"), systemImage: MySymbols.failure)
            case .successOpen:
                Label(LocalizedStringKey("str.stock.consume.product.open.success \(infoString ?? "")"), systemImage: MySymbols.success)
            case .failOpen:
                Label(LocalizedStringKey("str.stock.consume.product.open.fail"), systemImage: MySymbols.failure)
            }
        })
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction, content: {
                HStack {
                    if isProcessingAction {
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Button(action: resetForm, label: {
                            Label(LocalizedStringKey("str.clear"), systemImage: MySymbols.cancel)
                                .help(LocalizedStringKey("str.clear"))
                        })
                            .keyboardShortcut("r", modifiers: [.command])
                    }
                    Button(action: {
                        openProduct()
                    }, label: {
#if os(iOS)
                        if horizontalSizeClass == .compact && verticalSizeClass == .regular {
                            Label(LocalizedStringKey("str.stock.consume.product.open"), systemImage: MySymbols.open)
                        } else {
                            Label(LocalizedStringKey("str.stock.consume.product.open"), systemImage: MySymbols.open)
                                .labelStyle(TextIconLabelStyle())
                        }
#else
                        Label(LocalizedStringKey("str.stock.consume.product.open"), systemImage: MySymbols.open)
                            .labelStyle(TextIconLabelStyle())
#endif
                    })
                        .disabled(!isFormValid || isProcessingAction)
                        .keyboardShortcut("o", modifiers: [.command])
                    Button(action: {
                        consumeProduct()
                    }, label: {
#if os(iOS)
                        if horizontalSizeClass == .compact && verticalSizeClass == .regular {
                            Label(LocalizedStringKey("str.stock.consume.product.consume"), systemImage: MySymbols.consume)
                        } else {
                            Label(LocalizedStringKey("str.stock.consume.product.consume"), systemImage: MySymbols.consume)
                                .labelStyle(TextIconLabelStyle())
                        }
#else
                        Label(LocalizedStringKey("str.stock.consume.product.consume"), systemImage: MySymbols.consume)
                            .labelStyle(TextIconLabelStyle())
#endif
                    })
                        .disabled(!isFormValid || isProcessingAction)
                        .keyboardShortcut("s", modifiers: [.command])
                }
            })
        })
        .navigationTitle(LocalizedStringKey("str.stock.consume"))
    }
}

struct ConsumeProductView_Previews: PreviewProvider {
    static var previews: some View {
        ConsumeProductView()
    }
}
