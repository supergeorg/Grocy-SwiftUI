//
//  StockEntryFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 15.10.21.
//

import SwiftUI

struct StockEntryFormView: View {
    let grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    var stockEntry: StockEntry
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var bestBeforeDate: Date = Date()
    @State private var productDoesntSpoil: Bool = false
    @State private var amount: Double = 1.0
    @State private var price: Double?
    @State private var shoppingLocationID: Int?
    @State private var locationID: Int?
    @State private var purchasedDate: Date?
    @State private var stockEntryOpen: Bool = false
    
    private var product: MDProduct? {
        grocyVM.mdProducts.first(where: { $0.id == stockEntry.productID })
    }
    private var quantityUnitName: String {
        let quantityUnit = grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
        return amount == 1.0 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? quantityUnit?.name ?? ""
    }
    
    var isFormValid: Bool {
        amount > 0
    }
    
    private func finishForm() {
        #if os(iOS)
        self.dismiss()
        #elseif os(macOS)
        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        #endif
    }
    
    private func editEntryForm() {
        let entryFormPOST = StockEntry(id: stockEntry.id, productID: stockEntry.productID, amount: amount, bestBeforeDate: bestBeforeDate, purchasedDate: purchasedDate, stockID: stockEntry.stockID, price: price, stockEntryOpen: stockEntryOpen, openedDate: stockEntry.openedDate, rowCreatedTimestamp: stockEntry.rowCreatedTimestamp, locationID: locationID, shoppingLocationID: shoppingLocationID)
        isProcessing = true
        grocyVM.putStockProductEntry(id: stockEntry.id, content: entryFormPOST, completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog(message: "Stock entry edit successful. \(message)", type: .info)
//                toastType = .successEdit
                finishForm()
            case let .failure(error):
                grocyVM.postLog(message: "Stock entry edit failed. \(error)", type: .error)
//                toastType = .failEdit
            }
            isProcessing = false
        })
    }
    
    private func resetForm() {
        amount = stockEntry.amount
        bestBeforeDate = stockEntry.bestBeforeDate ?? Date()
        // TODO: Auto find if not spoiling
        purchasedDate = stockEntry.purchasedDate
        price = stockEntry.price
        stockEntryOpen = stockEntry.stockEntryOpen
        locationID = stockEntry.locationID
        shoppingLocationID = stockEntry.shoppingLocationID
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
#endif
    }
    
    var content: some View {
        Form {
            VStack(alignment: .trailing){
                HStack {
                    Image(systemName: MySymbols.date)
                    DatePicker(LocalizedStringKey("str.stock.buy.product.dueDate"), selection: $bestBeforeDate, displayedComponents: .date)
                        .disabled(productDoesntSpoil)
                }
                Text(getRelativeDateAsText(bestBeforeDate, localizationKey: localizationKey) ?? "")
                    .foregroundColor(.gray)
                    .italic()
                MyToggle(isOn: $productDoesntSpoil, description: "str.stock.buy.product.doesntSpoil", descriptionInfo: nil, icon: MySymbols.doesntSpoil)
            }
            
            MyDoubleStepper(amount: $amount, description: "str.stock.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: quantityUnitName, systemImage: MySymbols.amount)
            
            MyDoubleStepperOptional(amount: $price, description: "str.stock.buy.product.price", minAmount: 0, amountStep: 1.0, amountName: "", errorMessage: "str.stock.buy.product.price.invalid", systemImage: MySymbols.price, isCurrency: true)
            
            Picker(selection: $shoppingLocationID,
                   label: Label(LocalizedStringKey("str.stock.buy.product.shoppingLocation"), systemImage: MySymbols.shoppingLocation).foregroundColor(.primary),
                   content: {
                Text("").tag(nil as Int?)
                ForEach(grocyVM.mdShoppingLocations, id:\.id) { shoppingLocation in
                    Text(shoppingLocation.name).tag(shoppingLocation.id as Int?)
                }
            })
            
            Picker(selection: $locationID,
                   label: Label(LocalizedStringKey("str.stock.buy.product.location"), systemImage: MySymbols.location).foregroundColor(.primary),
                   content: {
                Text("").tag(nil as Int?)
                ForEach(grocyVM.mdLocations, id:\.id) { location in
                    Text(location.id == product?.locationID ? LocalizedStringKey("str.stock.buy.product.location.default \(location.name)") : LocalizedStringKey(location.name)).tag(location.id as Int?)
                }
            })
        }
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction, content: {
                Button(action: editEntryForm, label: {
                    Label(LocalizedStringKey("str.stock.entry.save"), systemImage: MySymbols.save)
                        .labelStyle(.titleAndIcon)
                })
                    .disabled(!isFormValid || isProcessing)
                    .keyboardShortcut("s", modifiers: [.command])
            })
        })
        .navigationTitle(LocalizedStringKey("str.stock.entry.edit"))
        .onAppear(perform: {
            if firstAppear {
                resetForm()
                firstAppear = false
            }
        })
    }
}

//struct StockEntryFormView_Previews: PreviewProvider {
//    static var previews: some View {
//        StockEntryFormView()
//    }
//}
