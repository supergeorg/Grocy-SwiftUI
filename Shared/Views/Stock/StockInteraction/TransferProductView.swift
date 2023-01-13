//
//  TransferProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI

struct TransferProductView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
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
    
    @State private var toastType: ToastType?
    @State private var infoString: String?
    
    private let dataToUpdate: [ObjectEntities] = [.products, .locations, .quantity_units, .quantity_unit_conversions]
    
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
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
    
    private func transferProduct() {
        if let productID = productID, let locationIDFrom = locationIDFrom, let locationIDTo = locationIDTo {
            let transferInfo = ProductTransfer(amount: factoredAmount, locationIDFrom: locationIDFrom, locationIDTo: locationIDTo, stockEntryID: stockEntryID)
            infoString = "\(factoredAmount.formattedAmount) \(getQUString(stockQU: true)) \(productName)"
            isProcessingAction = true
            grocyVM.postStockObject(id: productID, stockModePost: .transfer, content: transferInfo) { result in
                switch result {
                case let .success(prod):
                    grocyVM.postLog("Transfer successful. \(prod)", type: .info)
                    toastType = .successTransfer
                    grocyVM.requestData(additionalObjects: [.stock])
                    resetForm()
                case let .failure(error):
                    grocyVM.postLog("Transfer failed: \(error)", type: .error)
                    toastType = .failTransfer
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
                        self.dismiss()
                    }
                }
            })
#endif
    }
    
    var content: some View {
        Form {
            if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count > 0 {
                Section{
                    ServerProblemView(isCompact: true)
                }
            }
            
            ProductField(productID: $productID, description: "str.stock.transfer.product")
                .onChange(of: productID) { newProduct in
                    grocyVM.getStockProductEntries(productID: productID ?? 0)
                    if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                        locationIDFrom = selectedProduct.locationID
                        quantityUnitID = selectedProduct.quIDStock
                    }
                }
            
            VStack(alignment: .leading) {
                Picker(selection: $locationIDFrom, label: Label(LocalizedStringKey("str.stock.transfer.product.locationFrom"), systemImage: "square.and.arrow.up").foregroundColor(.primary), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdLocations, id:\.id) { locationFrom in
                        Text(locationFrom.name).tag(locationFrom.id as Int?)
                    }
                })
                
                if locationIDFrom == nil {
                    Text(LocalizedStringKey("str.stock.transfer.product.locationFrom.required"))
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            AmountSelectionView(productID: $productID, amount: $amount, quantityUnitID: $quantityUnitID)
            
            VStack(alignment: .leading) {
                Picker(
                    selection: $locationIDTo,
                    label: Label(LocalizedStringKey("str.stock.transfer.product.locationTo"), systemImage: "square.and.arrow.down").foregroundColor(.primary),
                    content: {
                        Text("").tag(nil as Int?)
                        ForEach(grocyVM.mdLocations, id:\.id) { locationTo in
                            Text(locationTo.name).tag(locationTo.id as Int?)
                        }
                    })
                if locationIDTo == nil {
                    Text(LocalizedStringKey("str.stock.transfer.product.locationTo.required"))
                        .font(.caption)
                        .foregroundColor(.red)
                }
                if (locationIDFrom != nil) && (locationIDFrom == locationIDTo) {
                    Text(LocalizedStringKey("str.stock.transfer.product.locationTo.same"))
                        .font(.caption)
                        .foregroundColor(.red)
                }
                if product?.shouldNotBeFrozen == 1,
                   locationTo?.isFreezer == true
                {
                    Text(LocalizedStringKey("str.stock.transfer.product.shouldNotBeFrozen"))
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            if productID != nil {
                MyToggle(isOn: $useSpecificStockEntry, description: "str.stock.transfer.product.useStockEntry", descriptionInfo: "str.stock.transfer.product.useStockEntry.description", icon: "tag")
                
                if (useSpecificStockEntry) {
#if os(iOS)
                    if #available(iOS 16.0, *) {
                        stockEntryPicker
                            .pickerStyle(.navigationLink)
                    } else {
                        stockEntryPicker
                    }
#else
                    stockEntryPicker
#endif
                }
            }
#if os(macOS)
            if isPopup {
                Button(action: transferProduct, label: {Text(LocalizedStringKey("str.stock.transfer.product.transfer"))})
                    .disabled(!isFormValid || isProcessingAction)
                    .keyboardShortcut(.defaultAction)
            }
#endif
        }
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: dataToUpdate)
                resetForm()
                firstAppear = false
            }
        })
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(toastType == .successTransfer),
            isShown: [.successTransfer, .failTransfer].contains(toastType),
            text: { item in
                switch item {
                case .successTransfer:
                    return LocalizedStringKey("str.stock.transfer.product.transfer.success \(infoString ?? "")")
                case .failTransfer:
                    return LocalizedStringKey("str.stock.transfer.product.transfer.fail")
                default:
                    return LocalizedStringKey("str.error")
                }
            })
        .toolbar(content: {
#if os(iOS)
            ToolbarItem(placement: .confirmationAction, content: {
                HStack {
                    toolbarContent
                }
            })
#else
            ToolbarItemGroup(placement: .confirmationAction, content: {
                toolbarContent
            })
#endif
        })
        .navigationTitle(LocalizedStringKey("str.stock.transfer"))
    }
    
    var stockEntryPicker: some View {
        Picker(selection: $stockEntryID, label: Label(LocalizedStringKey("str.stock.transfer.product.stockEntry"), systemImage: "tag"), content: {
            Text("").tag(nil as String?)
            ForEach(grocyVM.stockProductEntries[productID ?? 0] ?? [], id: \.stockID) { stockProduct in
                Group {
                    Text(stockProduct.stockEntryOpen == true ? LocalizedStringKey("str.stock.entry.description.notOpened \(stockProduct.amount.formattedAmount) \(formatDateAsString(stockProduct.bestBeforeDate, localizationKey: localizationKey) ?? "best before error") \(formatDateAsString(stockProduct.purchasedDate, localizationKey: localizationKey) ?? "purchasedate error")") : LocalizedStringKey("str.stock.entry.description.opened \(stockProduct.amount.formattedAmount) \(formatDateAsString(stockProduct.bestBeforeDate, localizationKey: localizationKey) ?? "best before error") \(formatDateAsString(stockProduct.purchasedDate, localizationKey: localizationKey) ?? "purchasedate error")"))
                    +
                    Text("; ")
                    +
                    Text(stockProduct.note != nil ? LocalizedStringKey("str.stock.entries.note \(stockProduct.note ?? "")") : LocalizedStringKey(""))
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
                    Label(LocalizedStringKey("str.clear"), systemImage: MySymbols.cancel)
                        .help(LocalizedStringKey("str.clear"))
                })
                .keyboardShortcut("r", modifiers: [.command])
            }
            Button(action: {
                transferProduct()
                resetForm()
            }, label: {
                Label(LocalizedStringKey("str.stock.transfer.product.transfer"), systemImage: MySymbols.transfer)
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
