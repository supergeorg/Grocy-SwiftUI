//
//  InventoryProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI

struct InventoryProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessingAction: Bool = false
    
    var stockElement: Binding<StockElement?>? = nil
    var productToInventoryID: Int? {
        return stockElement?.wrappedValue?.productID
    }
    var isPopup: Bool = false
    
    @State private var productID: Int?
    @State private var amount: Double = 1.0
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
    
    private let dataToUpdate: [ObjectEntities] = [.products, .locations, .quantity_units, .quantity_unit_conversions]
    private let additionalDataToUpdate: [AdditionalEntities] = [.system_config]
    
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    private var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productID})
    }
    private var currentQuantityUnit: MDQuantityUnit? {
        return grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDPurchase })
    }
    private var stockQuantityUnit: MDQuantityUnit? {
        return grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }
    private func getQUString(stockQU: Bool) -> String {
        if stockQU {
            return factoredAmount == 1.0 ? stockQuantityUnit?.name ?? "" : stockQuantityUnit?.namePlural ?? stockQuantityUnit?.name ?? ""
        } else {
            return amount == 1.0 ? currentQuantityUnit?.name ?? "" : currentQuantityUnit?.namePlural ?? currentQuantityUnit?.name ?? ""
        }
    }
    private var productName: String {
        product?.name ?? ""
    }
    
    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        if let quIDStock = product?.quIDStock {
            return grocyVM.mdQuantityUnitConversions.filter({ $0.toQuID == quIDStock })
        } else { return [] }
    }
    private var factoredAmount: Double {
        return amount * (quantityUnitConversions.first(where: { $0.fromQuID == quantityUnitID})?.factor ?? 1)
    }
    
    private let priceFormatter = NumberFormatter()
    
    private var isFormValid: Bool {
        (productID != nil) && (factoredAmount > 0) && (quantityUnitID != nil) && (locationID != nil)
    }
    
    private var selectedProductStock: StockElement? {
        grocyVM.stock.first(where: {$0.product.id == productID})
    }
    
    private var stockAmountDifference: Double {
        if let stockAmount = selectedProductStock?.amount {
            return factoredAmount - stockAmount
        } else { return 0 }
    }
    
    private func resetForm() {
        productID = firstAppear ? productToInventoryID : nil
        amount = selectedProductStock?.amount ?? 1.0
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
        if let productID = productID {
            let inventoryInfo = ProductInventory(newAmount: factoredAmount, bestBeforeDate: strDueDate, shoppingLocationID: shoppingLocationID, locationID: locationID, price: price)
            infoString = "\(factoredAmount.formattedAmount) \(getQUString(stockQU: true)) \(productName)"
            isProcessingAction = true
            grocyVM.postStockObject(id: productID, stockModePost: .inventory, content: inventoryInfo) { result in
                switch result {
                case let .success(prod):
                    grocyVM.postLog("Inventory successful. \(prod)", type: .info)
                    toastType = .successInventory
                    grocyVM.requestData(additionalObjects: [.stock], ignoreCached: true)
                    resetForm()
                case let .failure(error):
                    grocyVM.postLog("Inventory failed: \(error)", type: .error)
                    toastType = .failInventory
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
                    Button(LocalizedStringKey("str.cancel")) {
                        self.dismiss()
                    }
                }
            })
#endif
    }
    
    var content: some View {
        Form {
            if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count > 0 || grocyVM.failedToLoadAdditionalObjects.filter({additionalDataToUpdate.contains($0)}).count > 0 {
                Section{
                    ServerProblemView(isCompact: true)
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
            
            AmountSelectionView(productID: $productID, amount: $amount, quantityUnitID: $quantityUnitID)
            
            if stockAmountDifference != 0 {
                Text(stockAmountDifference > 0 ? LocalizedStringKey("str.stock.inventory.product.amount.higher \("\(stockAmountDifference.formattedAmount) \(getQUString(stockQU: true))")") : LocalizedStringKey("str.stock.inventory.product.amount.lower \("\((-stockAmountDifference).formattedAmount) \(getQUString(stockQU: true))")"))
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
#if os(macOS)
            if isPopup {
                Button(action: inventoryProduct, label: {Text(LocalizedStringKey("str.stock.inventory.product.inventory"))})
                    .disabled(!isFormValid || isProcessingAction)
                    .keyboardShortcut(.defaultAction)
            }
#endif
        }
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate, ignoreCached: false)
                resetForm()
                firstAppear = false
            }
        })
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successInventory), text: { item in
            switch item {
            case .successInventory:
                return LocalizedStringKey("str.stock.inventory.product.inventory.success \(infoString ?? "")")
            case .failInventory:
                return LocalizedStringKey("str.stock.inventory.product.inventory.fail")
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
                        inventoryProduct()
                        resetForm()
                    }, label: {
                        Label(LocalizedStringKey("str.stock.inventory.product.inventory"), systemImage: MySymbols.inventory)
                            .labelStyle(.titleAndIcon)
                    })
                        .disabled(!isFormValid || isProcessingAction)
                        .keyboardShortcut("s", modifiers: [.command])
                }
            })
        })
        .navigationTitle(LocalizedStringKey("str.stock.inventory"))
    }
}

struct InventoryProductView_Previews: PreviewProvider {
    static var previews: some View {
        InventoryProductView()
    }
}
