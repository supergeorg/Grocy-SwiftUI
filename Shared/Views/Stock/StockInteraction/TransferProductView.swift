//
//  TransferProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI

struct TransferProductView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessingAction: Bool = false
    
    var stockElement: Binding<StockElement?>? = nil
    var productToTransferID: Int? {
        return stockElement?.wrappedValue?.productID
    }
    var isPopup: Bool = false
    
    @State private var productID: Int?
    @State private var locationIDFrom: Int?
    @State private var amount: Double = 1.0
    @State private var quantityUnitID: Int?
    @State private var locationIDTo: Int?
    @State private var useSpecificStockEntry: Bool = false
    @State private var stockEntryID: String?
    
    @State private var searchProductTerm: String = ""
    
    private let dataToUpdate: [ObjectEntities] = [.products, .locations, .quantity_units, .quantity_unit_conversions]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productID})
    }
    private var currentQuantityUnit: MDQuantityUnit? {
        return grocyVM.mdQuantityUnits.first(where: {$0.id == quantityUnitID })
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
    
    private var locationTo: MDLocation? {
        grocyVM.mdLocations.first(where: {$0.id == locationIDTo})
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
    
    var isFormValid: Bool {
        (productID != nil) && (amount > 0) && (quantityUnitID != nil) && (locationIDFrom != nil) && (locationIDTo != nil) && !(useSpecificStockEntry && stockEntryID == nil) && !(useSpecificStockEntry && amount != 1.0) && !(locationIDFrom == locationIDTo)
    }
    
    private func resetForm() {
        productID = firstAppear ? productToTransferID : nil
        locationIDFrom = nil
        amount = 1.0
        quantityUnitID = firstAppear ? product?.quIDStock : nil
        locationIDTo = nil
        useSpecificStockEntry = false
        stockEntryID = nil
        searchProductTerm = ""
    }
    
    private func transferProduct() async {
        if let productID = productID, let locationIDFrom = locationIDFrom, let locationIDTo = locationIDTo {
            let transferInfo = ProductTransfer(amount: factoredAmount, locationIDFrom: locationIDFrom, locationIDTo: locationIDTo, stockEntryID: stockEntryID)
            isProcessingAction = true
            do {
                try await grocyVM.postStockObject(id: productID, stockModePost: .transfer, content: transferInfo)
                grocyVM.postLog("Transfer successful.", type: .info)
                await grocyVM.requestData(additionalObjects: [.stock])
                resetForm()
            } catch {
                grocyVM.postLog("Transfer failed: \(error)", type: .error)
            }
            isProcessingAction = false
        }
    }
    
    var body: some View {
        content
            .formStyle(.grouped)
            .toolbar(content: {
#if os(iOS)
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("Cancel", action: { self.dismiss() })
                })
#endif
                ToolbarItemGroup(placement: .automatic, content: { toolbarContent })
            })
    }
    
    var content: some View {
        Form {
            if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count > 0 {
                Section{
                    ServerProblemView(isCompact: true)
                }
            }
            
            ProductField(productID: $productID, description: "Product")
                .onChange(of: productID) {
                    Task {
                        try await grocyVM.getStockProductEntries(productID: productID ?? 0)
                        if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                            locationIDFrom = selectedProduct.locationID
                            quantityUnitID = selectedProduct.quIDStock
                        }
                    }
                }
            
            VStack(alignment: .leading) {
                Picker(selection: $locationIDFrom, label: Label("From location", systemImage: "square.and.arrow.up").foregroundStyle(.primary), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { locationFrom in
                        Text(locationFrom.name).tag(locationFrom.id as Int?)
                    }
                })
                
                if locationIDFrom == nil {
                    Text("A location is required")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            AmountSelectionView(productID: $productID, amount: $amount, quantityUnitID: $quantityUnitID)
            
            VStack(alignment: .leading) {
                Picker(
                    selection: $locationIDTo,
                    label: Label("To location", systemImage: "square.and.arrow.down").foregroundStyle(.primary),
                    content: {
                        Text("").tag(nil as Int?)
                        ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { locationTo in
                            Text(locationTo.name).tag(locationTo.id as Int?)
                        }
                    })
                if locationIDTo == nil {
                    Text("A location is required")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                if (locationIDFrom != nil) && (locationIDFrom == locationIDTo) {
                    Text("This cannot be the same as the "From" location")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                if product?.shouldNotBeFrozen == true,
                   locationTo?.isFreezer == true
                {
                    Text("This product shouldn't be frozen")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            if productID != nil {
                MyToggle(isOn: $useSpecificStockEntry, description: "Use a specific stock item", descriptionInfo: "The first item in this list would be picked by the default rule which is "Opened first, then first due first, then first in first out"", icon: "tag")
                
                if (useSpecificStockEntry) {
#if os(iOS)
                    stockEntryPicker
                        .pickerStyle(.navigationLink)
#else
                    stockEntryPicker
#endif
                }
            }
#if os(macOS)
            if isPopup {
                Button(action: { Task { await transferProduct() } }, label: {Text("Transfer product")})
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
        .navigationTitle("Transfer")
    }
    
    var stockEntryPicker: some View {
        Picker(selection: $stockEntryID, label: Label("Stock entry", systemImage: "tag"), content: {
            Text("").tag(nil as String?)
            ForEach(grocyVM.stockProductEntries[productID ?? 0] ?? [], id: \.stockID) { stockProduct in
                Group {
                    Text(stockProduct.stockEntryOpen == true ? "str.stock.entry.description.notOpened \(stockProduct.amount.formattedAmount) \(formatDateAsString(stockProduct.bestBeforeDate, localizationKey: localizationKey) ?? "best before error" \(formatDateAsString(stockProduct.purchasedDate, localizationKey: localizationKey) ?? "purchasedate error")") : "str.stock.entry.description.opened \(stockProduct.amount.formattedAmount) \(formatDateAsString(stockProduct.bestBeforeDate, localizationKey: localizationKey) ?? "best before error" \(formatDateAsString(stockProduct.purchasedDate, localizationKey: localizationKey) ?? "purchasedate error")"))
                    +
                    Text("; ")
                    +
                    Text(stockProduct.note != nil ? "str.stock.entries.note \(stockProduct.note ?? """) : LocalizedStringKey(""))
                }
                .tag(stockProduct.stockID as String?)
            }
        })
    }
    
    var toolbarContent: some View {
        Group {
            if isProcessingAction {
                ProgressView().progressViewStyle(.circular)
            } else {
                Button(action: resetForm, label: {
                    Label("Clear", systemImage: MySymbols.cancel)
                        .help("Clear")
                })
                .keyboardShortcut("r", modifiers: [.command])
            }
            Button(action: {
                Task {
                    await transferProduct()
                }
            }, label: {
                Label("Transfer product", systemImage: MySymbols.transfer)
                    .labelStyle(.titleAndIcon)
            })
            .disabled(!isFormValid || isProcessingAction)
            .keyboardShortcut("s", modifiers: [.command])
        }
    }
}

struct TransferProductView_Previews: PreviewProvider {
    static var previews: some View {
        TransferProductView()
    }
}
