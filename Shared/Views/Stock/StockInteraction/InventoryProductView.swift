//
//  InventoryProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI

struct InventoryProductView: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
    
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
    @State private var storeID: Int?
    @State private var locationID: Int?
    @State private var note: String = ""
    
    @State private var searchProductTerm: String = ""
    
    @State private var toastType: InventoryToastType?
    private enum InventoryToastType: Identifiable {
        case successInventory, failInventory
        
        var id: Int {
            self.hashValue
        }
    }
    @State private var infoString: String?
    
    private let dataToUpdate: [ObjectEntities] = [.products, .shopping_locations, .locations, .quantity_units, .quantity_unit_conversions]
    private let additionalDataToUpdate: [AdditionalEntities] = [.stock, .volatileStock, .system_config, .system_info]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
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
    private var quConversion: MDQuantityUnitConversion? {
        return quantityUnitConversions.first(where: { $0.fromQuID == quantityUnitID})
    }
    private var factoredAmount: Double {
        return amount * (quConversion?.factor ?? 1)
    }
    
    private let priceFormatter = NumberFormatter()
    
    private var isFormValid: Bool {
        (productID != nil) && (factoredAmount > 0) && (quantityUnitID != nil) && (locationID != nil) && factoredAmount != selectedProductStock?.amount
    }
    
    private var selectedProductStock: StockElement? {
        grocyVM.stock.first(where: {$0.product.id == productID})
    }
    
    private var stockAmountDifference: Double {
        if let stockAmount = selectedProductStock?.amount {
            return factoredAmount - stockAmount
        } else { return factoredAmount }
    }
    
    private func resetForm() {
        productID = firstAppear ? productToInventoryID : nil
        amount = selectedProductStock?.amount ?? 1.0
        quantityUnitID = firstAppear ? product?.quIDStock : nil
        dueDate = Date()
        productNeverOverdue = false
        price = nil
        storeID = nil
        locationID = nil
        note = ""
        searchProductTerm = ""
    }
    
    private func inventoryProduct() async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let strDueDate = productNeverOverdue ? "2999-12-31" : dateFormatter.string(from: dueDate)
        let noteText = note.isEmpty ? nil : note
        if let productID = productID {
            let inventoryInfo = ProductInventory(newAmount: factoredAmount, bestBeforeDate: strDueDate, storeID: storeID, locationID: locationID, price: price, note: noteText)
            infoString = "\(factoredAmount.formattedAmount) \(getQUString(stockQU: true)) \(productName)"
            isProcessingAction = true
            do {
                try await grocyVM.postStockObject(id: productID, stockModePost: .inventory, content: inventoryInfo)
                grocyVM.postLog("Inventory successful.", type: .info)
                toastType = .successInventory
                await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
                resetForm()
            } catch {
                grocyVM.postLog("Inventory failed: \(error)", type: .error)
                toastType = .failInventory
            }
            isProcessingAction = false
        }
    }
    
    var body: some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            content
                .formStyle(.grouped)
                .toolbar(content: {
#if os(iOS)
                    ToolbarItem(placement: .cancellationAction, content: {
                        Button(LocalizedStringKey("str.cancel"), action: { self.dismiss() })
                    })
#endif
                })
        } else {
#if os(iOS)
            content
                .toolbar(content: {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(LocalizedStringKey("str.cancel")) {
                            self.dismiss()
                        }
                    }
                })
#elseif os(macOS)
            ScrollView {
                content
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            }
#endif
        }
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
                    if let productID = productID {
                        Task {
                            try await grocyVM.getStockProductEntries(productID: productID)
                        }
                    }
                    if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                        storeID = selectedProduct.storeID
                        locationID = selectedProduct.locationID
                        quantityUnitID = selectedProduct.quIDStock
                    }
                    amount = selectedProductStock?.amount ?? 1
                }
            
            AmountSelectionView(productID: $productID, amount: $amount, quantityUnitID: $quantityUnitID)
            
            if productID != nil {
                if stockAmountDifference != 0 {
                    Text(stockAmountDifference > 0 ? LocalizedStringKey("str.stock.inventory.product.amount.higher \("\(stockAmountDifference.formattedAmount) \(getQUString(stockQU: true))")") : LocalizedStringKey("str.stock.inventory.product.amount.lower \("\((-stockAmountDifference).formattedAmount) \(getQUString(stockQU: true))")"))
                        .font(.caption)
                } else {
                    Text(LocalizedStringKey("str.stock.inventory.product.amount.equal"))
                        .font(.caption)
                        .foregroundColor(.red)
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
            
            MyDoubleStepperOptional(amount: $price, description: "str.stock.inventory.product.price", descriptionInfo: "str.stock.inventory.product.price.info", minAmount: 0, amountStep: 1.0, amountName: "", systemImage: MySymbols.price, currencySymbol: grocyVM.getCurrencySymbol())
            
            Section(header: Text(LocalizedStringKey("str.stock.inventory.product.location")).font(.headline)) {
                Picker(selection: $storeID, label: Label(LocalizedStringKey("str.stock.inventory.product.store"), systemImage: MySymbols.store).foregroundColor(.primary), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdStores, id:\.id) { store in
                        Text(store.name).tag(store.id as Int?)
                    }
                })
                
                Picker(selection: $locationID, label: Label(LocalizedStringKey("str.stock.inventory.product.location"), systemImage: MySymbols.location).foregroundColor(.primary), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdLocations, id:\.id) { location in
                        Text(location.name).tag(location.id as Int?)
                    }
                })
            }
            MyTextField(textToEdit: $note, description: "str.stock.buy.product.note", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            
#if os(macOS)
            if isPopup {
                Button(action: { Task { await inventoryProduct() } }, label: {Text(LocalizedStringKey("str.stock.inventory.product.inventory"))})
                    .disabled(!isFormValid || isProcessingAction)
                    .keyboardShortcut(.defaultAction)
            }
#endif
        }
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(toastType == .successInventory),
            isShown: [.successInventory, .failInventory].contains(toastType),
            text: { item in
                switch item {
                case .successInventory:
                    return LocalizedStringKey("str.stock.inventory.product.inventory.success \(infoString ?? "")")
                case .failInventory:
                    return LocalizedStringKey("str.stock.inventory.product.inventory.fail")
                }
            })
        .toolbar(content: {
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
                Task {
                    await inventoryProduct()
                }
            }, label: {
                Label(LocalizedStringKey("str.stock.inventory.product.inventory"), systemImage: MySymbols.inventory)
                    .labelStyle(.titleAndIcon)
            })
            .disabled(!isFormValid || isProcessingAction)
            .keyboardShortcut("s", modifiers: [.command])
        })
        .navigationTitle(LocalizedStringKey("str.stock.inventory"))
    }
}

struct InventoryProductView_Previews: PreviewProvider {
    static var previews: some View {
        InventoryProductView()
    }
}
