//
//  StockEntryFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 15.10.21.
//

import SwiftUI

struct StockEntryFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    var stockEntry: StockEntry
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var bestBeforeDate: Date = Date()
    @State private var productDoesntSpoil: Bool = false
    @State private var amount: Double = 1.0
    @State private var price: Double?
    @State private var storeID: Int?
    @State private var locationID: Int?
    @State private var purchasedDate: Date?
    @State private var stockEntryOpen: Bool = false
    @State private var note: String = ""
    
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
#endif
    }
    
    private func editEntryForm() async {
        let noteText = note.isEmpty ? nil : note
        let realBestBeforeDate = productDoesntSpoil ? getNeverOverdueDate() : bestBeforeDate
        let entryFormPOST = StockEntry(
            id: stockEntry.id,
            productID: stockEntry.productID,
            amount: amount,
            bestBeforeDate: realBestBeforeDate,
            purchasedDate: purchasedDate,
            stockID: stockEntry.stockID,
            price: price,
            stockEntryOpen: stockEntryOpen,
            openedDate: stockEntry.openedDate,
            rowCreatedTimestamp: stockEntry.rowCreatedTimestamp,
            locationID: locationID,
            storeID: storeID,
            note: noteText
        )
        isProcessing = true
        do {
            _ = try await grocyVM.putStockProductEntry(id: stockEntry.id, content: entryFormPOST)
            grocyVM.postLog("Stock entry edit successful.", type: .info)
            finishForm()
        } catch {
            grocyVM.postLog("Stock entry edit failed. \(error)", type: .error)
        }
        isProcessing = false
    }
    
    private func resetForm() {
        amount = stockEntry.amount
        bestBeforeDate = stockEntry.bestBeforeDate ?? Date()
        productDoesntSpoil = (stockEntry.bestBeforeDate == getNeverOverdueDate())
        purchasedDate = stockEntry.purchasedDate
        price = stockEntry.price
        stockEntryOpen = stockEntry.stockEntryOpen
        locationID = stockEntry.locationID
        storeID = stockEntry.storeID
        note = stockEntry.note ?? ""
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
            VStack(alignment: .trailing, spacing: 5.0){
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
            
            MyDoubleStepperOptional(amount: $price, description: "str.stock.buy.product.price", minAmount: 0, amountStep: 1.0, amountName: "", systemImage: MySymbols.price, currencySymbol: grocyVM.getCurrencySymbol())
            
            Picker(selection: $storeID,
                   label: Label(LocalizedStringKey("str.stock.buy.product.store"), systemImage: MySymbols.store).foregroundColor(.primary),
                   content: {
                Text("").tag(nil as Int?)
                ForEach(grocyVM.mdStores, id:\.id) { store in
                    Text(store.name).tag(store.id as Int?)
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
            
            MyTextField(textToEdit: $note, description: "str.stock.buy.product.note", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
        }
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction, content: {
                Button(action: { Task { await editEntryForm() } }, label: {
                    Label(LocalizedStringKey("str.stock.entry.save"), systemImage: MySymbols.save)
                        .labelStyle(.titleAndIcon)
                })
                .disabled(!isFormValid || isProcessing)
                .keyboardShortcut("s", modifiers: [.command])
            })
        })
        .navigationTitle(LocalizedStringKey("str.stock.entry.edit"))
        .task {
            if firstAppear {
                resetForm()
                await grocyVM.requestData(additionalObjects: [.system_info])
                firstAppear = false
            }
        }
    }
}

//struct StockEntryFormView_Previews: PreviewProvider {
//    static var previews: some View {
//        StockEntryFormView()
//    }
//}
