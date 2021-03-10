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
    @State private var isProcessingAction: Bool = false
    
    var productToTransferID: String?
    
    @State private var productID: String?
    @State private var locationIDFrom: String?
    @State private var amount: Double?
    @State private var quantityUnitID: String?
    @State private var locationIDTo: String?
    @State private var useSpecificStockEntry: Bool = false
    @State private var stockEntryID: String?
    
    @State private var searchProductTerm: String = ""
    
    @State private var toastType: TransferToastType?
    private enum TransferToastType: Identifiable {
        case successTransfer, failTransfer
        
        var id: Int {
            self.hashValue
        }
    }
    @State private var infoString: String?
    
    private var currentQuantityUnitName: String? {
        let quIDP = grocyVM.mdProducts.first(where: {$0.id == productID})?.quIDPurchase
        let qu = grocyVM.mdQuantityUnits.first(where: {$0.id == quIDP})
        return amount == 1 ? qu?.name : qu?.namePlural
    }
    private var productName: String {
        grocyVM.mdProducts.first(where: {$0.id == productID})?.name ?? ""
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
        grocyVM.requestData(objects: [.products, .locations, .quantity_units])
    }
    
    private func transferProduct() {
        if let intLocationIDFrom = Int(locationIDFrom ?? "") {
            if let intLocationIDTo = Int(locationIDTo ?? "") {
                if let productID = productID {
                    if let amount = amount {
                        let transferInfo = ProductTransfer(amount: amount, locationIDFrom: intLocationIDFrom, locationIDTo: intLocationIDTo, stockEntryID: stockEntryID)
                        infoString = "\(formatAmount(amount)) \(currentQuantityUnitName ?? "") \(productName)"
                        isProcessingAction = true
                        grocyVM.postStockObject(id: productID, stockModePost: .transfer, content: transferInfo) { result in
                            switch result {
                            case let .success(prod):
                                grocyVM.postLog(message: "Transfer successful. \(prod)", type: .info)
                                toastType = .successTransfer
                                resetForm()
                            case let .failure(error):
                                grocyVM.postLog(message: "Transfer failed: \(error)", type: .error)
                                toastType = .failTransfer
                            }
                            isProcessingAction = false
                        }
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
                MyDoubleStepper(amount: $amount, description: "str.stock.transfer.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: currentQuantityUnitName, errorMessage: "str.stock.transfer.product.amount.invalid", systemImage: MySymbols.amount)
                Picker(selection: $quantityUnitID, label: Label("str.stock.transfer.product.quantityUnit", systemImage: MySymbols.quantityUnit), content: {
                    Text("").tag(nil as String?)
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { pickerQU in
                        Text("\(pickerQU.name) (\(pickerQU.namePlural))").tag(pickerQU.id as String?)
                    }
                }).disabled(true)
            }
            
            VStack(alignment: .leading) {
                Picker(selection: $locationIDTo, label: Label(LocalizedStringKey("str.stock.transfer.product.locationTo"), systemImage: "square.and.arrow.down").foregroundColor(.primary), content: {
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
                        Text(stockProduct.stockEntryOpen == "0" ? LocalizedStringKey("str.stock.entry.description.notOpened \(stockProduct.amount) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate) ?? "purchasedate error")") : LocalizedStringKey("str.stock.entry.description.opened \(stockProduct.amount) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate) ?? "purchasedate error")"))
                            .tag(stockProduct.stockID as String?)
                    }
                })
            }
        }
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: [.products, .locations, .quantity_units], ignoreCached: false)
                resetForm()
                firstAppear = false
            }
        })
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successTransfer), content: { item in
            switch item {
            case .successTransfer:
                Label(LocalizedStringKey("str.stock.transfer.product.transfer.success \(infoString ?? "")"), systemImage: MySymbols.success)
            case .failTransfer:
                Label(LocalizedStringKey("str.stock.transfer.product.transfer.fail"), systemImage: MySymbols.failure)
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
                    transferProduct()
                    resetForm()
                }, label: {
                    Label(LocalizedStringKey("str.stock.transfer.product.transfer"), systemImage: MySymbols.transfer)
                        .labelStyle(TextIconLabelStyle())
                })
                .disabled(!isFormValid || isProcessingAction)
                .keyboardShortcut("s", modifiers: [.command])
            })
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
