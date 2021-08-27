//
//  InventoryProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI

struct InventoryProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstAppear: Bool = true
    @State private var isProcessingAction: Bool = false
    
    var productToInventoryID: Int?
    
    @State private var productID: Int?
    @State private var amount: Double?
    @State private var quantityUnitID: Int?
    @State private var dueDate: Date = Date()
    @State private var productNeverOverdue: Bool = false
    @State private var price: Double?
    @State private var shoppingLocationID: Int?
    @State private var locationID: Int?
    
    @State private var searchProductTerm: String = ""
    
    @State private var toastType: InventoryToastType?
    private enum InventoryToastType: Identifiable {
        case successInventory, failInventory
        
        var id: Int {
            self.hashValue
        }
    }
    @State private var infoString: String?
    
    private let dataToUpdate: [ObjectEntities] = [.products, .locations, .quantity_units]
    private let additionalDataToUpdate: [AdditionalEntities] = [.system_config]
    
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    private var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productID})
    }
    private var currentQuantityUnit: MDQuantityUnit? {
        let quIDP = product?.quIDPurchase
        return grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
    }
    private func getQUString(amount: Double) -> String {
        return amount == 1.0 ? currentQuantityUnit?.name ?? "" : currentQuantityUnit?.namePlural ?? ""
    }
    private var productName: String {
        product?.name ?? ""
    }
    
    private let priceFormatter = NumberFormatter()
    
    private var isFormValid: Bool {
        (productID != nil) && (amount ?? 0 > 0) && (quantityUnitID != nil) && (locationID != nil)
    }
    
    private var selectedProductStock: StockElement? {
        grocyVM.stock.first(where: {$0.product.id == productID})
    }
    
    private var stockAmountDifference: Double {
        if let stockAmount = selectedProductStock?.amount {
            return amount ?? 0 - stockAmount
        } else { return 0 }
    }
    
    private func resetForm() {
        productID = firstAppear ? productToInventoryID : nil
        amount = selectedProductStock?.amount
        quantityUnitID = firstAppear ? product?.quIDStock : nil
        dueDate = Date()
        productNeverOverdue = false
        price = nil
        shoppingLocationID = nil
        locationID = nil
        searchProductTerm = ""
    }
    
    private func inventoryProduct() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let strDueDate = productNeverOverdue ? "2999-12-31" : dateFormatter.string(from: dueDate)
        if let amount = amount {
            if let productID = productID {
                let inventoryInfo = ProductInventory(newAmount: amount, bestBeforeDate: strDueDate, shoppingLocationID: shoppingLocationID, locationID: locationID, price: price)
                infoString = "\(formatAmount(amount)) \(getQUString(amount: amount)) \(productName)"
                isProcessingAction = true
                grocyVM.postStockObject(id: productID, stockModePost: .inventory, content: inventoryInfo) { result in
                    switch result {
                    case let .success(prod):
                        grocyVM.postLog(message: "Inventory successful. \(prod)", type: .info)
                        toastType = .successInventory
                        grocyVM.requestData(additionalObjects: [.stock], ignoreCached: true)
                        resetForm()
                    case let .failure(error):
                        grocyVM.postLog(message: "Inventory failed: \(error)", type: .error)
                        toastType = .failInventory
                    }
                    isProcessingAction = false
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
                    Button(LocalizedStringKey("str.cancel")) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            })
        #endif
    }
    
    var content: some View {
        Form {
            if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count > 0 && grocyVM.failedToLoadAdditionalObjects.filter({additionalDataToUpdate.contains($0)}).count > 0 {
                Section{
                    ServerOfflineView(isCompact: true)
                }
            }
            
            ProductField(productID: $productID, description: "str.stock.inventory.product")
                .onChange(of: productID) { newProduct in
                    // TODO Edit
                    if let productID = productID {
                        grocyVM.getStockProductEntries(productID: productID)
                    }
                    if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                        shoppingLocationID = selectedProduct.shoppingLocationID
                        locationID = selectedProduct.locationID
                        quantityUnitID = selectedProduct.quIDStock
                        if let productStock = selectedProductStock {
                            amount = productStock.amount
                        }
                    }
                }
            
            Section(header: Text(LocalizedStringKey("str.stock.inventory.product.amount")).font(.headline)) {
                MyDoubleStepperOptional(amount: $amount, description: "str.stock.inventory.product.amount", amountName: getQUString(amount: amount ?? 0), errorMessage: "str.stock.inventory.product.amount.required", systemImage: MySymbols.amount)
                Picker(selection: $quantityUnitID, label: Label(LocalizedStringKey("str.stock.inventory.product.quantityUnit"), systemImage: MySymbols.quantityUnit), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id as Int?)
                    }
                }).disabled(true)
                if stockAmountDifference != 0 {
                    Text(stockAmountDifference > 0 ? LocalizedStringKey("str.stock.inventory.product.amount.higher \("\(formatAmount(stockAmountDifference)) \(getQUString(amount: stockAmountDifference))")") : LocalizedStringKey("str.stock.inventory.product.amount.lower \("\(-stockAmountDifference) \(getQUString(amount: -stockAmountDifference))")"))
                }
            }
            
            Section(header: Text(LocalizedStringKey("str.stock.inventory.product.dueDate")).font(.headline)) {
                HStack {
                    Image(systemName: MySymbols.date)
                    DatePicker(LocalizedStringKey("str.stock.inventory.product.dueDate"), selection: $dueDate, displayedComponents: .date)
                        .disabled(productNeverOverdue)
                }
                
                MyToggle(isOn: $productNeverOverdue, description: "str.stock.inventory.product.neverOverdue", icon: MySymbols.doesntSpoil)
            }
            
            MyDoubleStepperOptional(amount: $price, description: "str.stock.inventory.product.price", descriptionInfo: "str.stock.inventory.product.price.info", minAmount: 0, amountStep: 1.0, amountName: "", errorMessage: "str.stock.inventory.product.price.required", systemImage: MySymbols.price, currencySymbol: grocyVM.getCurrencySymbol())
            
            Section(header: Text(LocalizedStringKey("str.stock.inventory.product.location")).font(.headline)) {
                Picker(selection: $shoppingLocationID, label: Label(LocalizedStringKey("str.stock.inventory.product.shoppingLocation"), systemImage: MySymbols.shoppingLocation).foregroundColor(.primary), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdShoppingLocations, id:\.id) { shoppingLocation in
                        Text(shoppingLocation.name).tag(shoppingLocation.id as Int?)
                    }
                })
                
                Picker(selection: $locationID, label: Label(LocalizedStringKey("str.stock.inventory.product.location"), systemImage: MySymbols.location).foregroundColor(.primary), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdLocations, id:\.id) { location in
                        Text(location.name).tag(location.id as Int?)
                    }
                })
            }
        }
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate, ignoreCached: false)
                resetForm()
                firstAppear = false
            }
        })
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successInventory), content: { item in
            switch item {
            case .successInventory:
                Label(LocalizedStringKey("str.stock.inventory.product.inventory.success \(infoString ?? "")"), systemImage: MySymbols.success)
            case .failInventory:
                Label(LocalizedStringKey("str.stock.inventory.product.inventory.fail"), systemImage: MySymbols.failure)
            }
        })
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction, content: {
                if isProcessingAction {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                } else {
                    Button(action: resetForm, label: {
                        Label(LocalizedStringKey("str.clear"), systemImage: MySymbols.cancel)
                            .help(LocalizedStringKey("str.clear"))
                    })
                    .keyboardShortcut("r", modifiers: [.command])
                }
            })
            ToolbarItem(placement: .confirmationAction, content: {
                Button(action: {
                    inventoryProduct()
                    resetForm()
                }, label: {
                    Label(LocalizedStringKey("str.stock.inventory.product.inventory"), systemImage: MySymbols.inventory)
                        .labelStyle(TextIconLabelStyle())
                })
                .disabled(!isFormValid || isProcessingAction)
                .keyboardShortcut("s", modifiers: [.command])
            })
        })
        .animation(.default)
        .navigationTitle(LocalizedStringKey("str.stock.inventory"))
    }
}

struct InventoryProductView_Previews: PreviewProvider {
    static var previews: some View {
        InventoryProductView()
    }
}
