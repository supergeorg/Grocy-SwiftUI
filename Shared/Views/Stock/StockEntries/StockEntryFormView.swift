//
//  StockEntryFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 15.10.21.
//

import SwiftUI
import SwiftData

struct StockEntryFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(filter: #Predicate<MDProduct>{$0.active}, sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(filter: #Predicate<MDQuantityUnit>{$0.active}, sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(filter: #Predicate<MDStore>{$0.active}, sort: \MDStore.name, order: .forward) var mdStores: MDStores
    @Query(filter: #Predicate<MDLocation>{$0.active}, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    
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
        mdProducts.first(where: { $0.id == stockEntry.productID })
    }
    private var quantityUnit: MDQuantityUnit? {
        return mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
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
            await grocyVM.postLog("Stock entry edit successful.", type: .info)
            finishForm()
        } catch {
            await grocyVM.postLog("Stock entry edit failed. \(error)", type: .error)
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
                    DatePicker("Due date", selection: $bestBeforeDate, displayedComponents: .date)
                        .disabled(productDoesntSpoil)
                }
                Text(getRelativeDateAsText(bestBeforeDate, localizationKey: localizationKey) ?? "")
                    .foregroundStyle(.gray)
                    .italic()
                MyToggle(isOn: $productDoesntSpoil, description: "Never overdue", descriptionInfo: nil, icon: MySymbols.doesntSpoil)
            }
            
            MyDoubleStepper(amount: $amount, description: "Amount", minAmount: 0.0001, amountStep: 1.0, amountName: quantityUnit?.getName(amount: amount), systemImage: MySymbols.amount)
            
            MyDoubleStepperOptional(amount: $price, description: "Price", minAmount: 0, amountStep: 1.0, amountName: "", systemImage: MySymbols.price, currencySymbol: getCurrencySymbol())
            
            Picker(selection: $storeID,
                   label: Label("Store", systemImage: MySymbols.store).foregroundStyle(.primary),
                   content: {
                Text("").tag(nil as Int?)
                ForEach(mdStores, id:\.id) { store in
                    Text(store.name).tag(store.id as Int?)
                }
            })
            
            Picker(selection: $locationID,
                   label: Label("Location", systemImage: MySymbols.location).foregroundStyle(.primary),
                   content: {
                Text("").tag(nil as Int?)
                ForEach(mdLocations, id:\.id) { location in
                    Text(location.id == product?.locationID ? "\(location.name) (Default location)" : location.name)
                        .tag(location.id as Int?)
                }
            })
            
            MyTextField(textToEdit: $note, description: "Note", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
        }
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction, content: {
                Button(action: { Task { await editEntryForm() } }, label: {
                    Label("Save entry", systemImage: MySymbols.save)
                        .labelStyle(.titleAndIcon)
                })
                .disabled(!isFormValid || isProcessing)
                .keyboardShortcut("s", modifiers: [.command])
            })
        })
        .navigationTitle("Edit entry")
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
