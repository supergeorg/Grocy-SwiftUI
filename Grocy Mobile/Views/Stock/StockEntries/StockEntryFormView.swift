//
//  StockEntryFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 15.10.21.
//

import SwiftData
import SwiftUI

struct StockEntryFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(filter: #Predicate<MDProduct> { $0.active }, sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(filter: #Predicate<MDQuantityUnit> { $0.active }, sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(filter: #Predicate<MDStore> { $0.active }, sort: \MDStore.name, order: .forward) var mdStores: MDStores
    @Query(filter: #Predicate<MDLocation> { $0.active }, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations

    @Environment(\.dismiss) var dismiss
    @AppStorage("localizationKey") var localizationKey: String = "en"

    var existingStockEntry: StockEntry
    @State var stockEntry: StockEntry

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    @State private var productDoesntSpoil: Bool = false

    private var product: MDProduct? {
        mdProducts.first(where: { $0.id == stockEntry.productID })
    }
    private var quantityUnit: MDQuantityUnit? {
        return mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }

    var isFormValid: Bool {
        stockEntry.amount > 0
    }

    init(existingStockEntry: StockEntry) {
        self.existingStockEntry = existingStockEntry
        self.productDoesntSpoil = existingStockEntry.bestBeforeDate == Date.neverOverdue
        self.stockEntry = existingStockEntry
    }

    private func updateData() async {
        await grocyVM.requestStockInfo(stockModeGet: .entries, productID: stockEntry.productID)
    }

    private func finishForm() {
        #if os(iOS)
            self.dismiss()
        #endif
    }

    private func saveStockEntry() async {
        isProcessing = true
        isSuccessful = nil
        do {
            stockEntry.bestBeforeDate = Calendar.current.startOfDay(for: self.stockEntry.bestBeforeDate)
            try stockEntry.modelContext?.save()
            _ = try await grocyVM.putStockProductEntry(id: stockEntry.id, content: stockEntry)
            GrocyLogger.info("Stock entry edit successful.")
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Stock entry edit failed.")
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
            isSuccessful = false
        }
        isProcessing = false
    }

    var body: some View {
        #if os(macOS)
            ScrollView {
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
            VStack(alignment: .trailing, spacing: 5.0) {
                if !productDoesntSpoil {
                    HStack {
                        DatePicker(
                            selection: $stockEntry.bestBeforeDate,
                            displayedComponents: .date,
                            label: {
                                Label("Due date", systemImage: MySymbols.date)
                                    .foregroundStyle(.primary)
                            }
                        )
                        DueDateScanner(dueDate: $stockEntry.bestBeforeDate)
                    }
                    Text(getRelativeDateAsText(stockEntry.bestBeforeDate, localizationKey: localizationKey) ?? "")
                        .foregroundStyle(.gray)
                        .italic()
                }
                MyToggle(isOn: $productDoesntSpoil, description: "Never overdue", descriptionInfo: nil, icon: MySymbols.doesntSpoil)
                    .onChange(
                        of: productDoesntSpoil,
                        {
                            if productDoesntSpoil == true {
                                self.stockEntry.bestBeforeDate = Date.neverOverdue
                            } else if productDoesntSpoil == false && self.stockEntry.bestBeforeDate == Date.neverOverdue {
                                self.stockEntry.bestBeforeDate = Date()
                            }
                        }
                    )
            }

            MyDoubleStepper(amount: $stockEntry.amount, description: "Amount", minAmount: 0.0001, amountStep: 1.0, amountName: quantityUnit?.getName(amount: stockEntry.amount), systemImage: MySymbols.amount)

            MyDoubleStepperOptional(amount: $stockEntry.price, description: "Price", minAmount: 0, amountStep: 1.0, amountName: "", systemImage: MySymbols.price, currencySymbol: grocyVM.getCurrencySymbol())

            Picker(
                selection: $stockEntry.storeID,
                label: Label("Store", systemImage: MySymbols.store).foregroundStyle(.primary),
                content: {
                    Text("").tag(nil as Int?)
                    ForEach(mdStores, id: \.id) { store in
                        Text(store.name).tag(store.id as Int?)
                    }
                }
            )

            Picker(
                selection: $stockEntry.locationID,
                label: Label("Location", systemImage: MySymbols.location).foregroundStyle(.primary),
                content: {
                    Text("").tag(nil as Int?)
                    ForEach(mdLocations, id: \.id) { location in
                        if location.id == product?.locationID {
                            Text("\(location.name) (\(Text("Default location")))")
                                .tag(location.id as Int?)
                        } else {
                            Text(location.name)
                                .tag(location.id as Int?)
                        }
                    }
                }
            )

            MyTextEditor(textToEdit: $stockEntry.note, description: "Note", leadingIcon: MySymbols.description)
        }
        .toolbar(content: {
            ToolbarItem(
                placement: .confirmationAction,
                content: {
                    Button(
                        action: { Task { await saveStockEntry() } },
                        label: {
                            Label("Save", systemImage: MySymbols.save)
                                .labelStyle(.titleAndIcon)
                        }
                    )
                    .disabled(!isFormValid || isProcessing)
                    .keyboardShortcut("s", modifiers: [.command])
                }
            )
        })
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                finishForm()
            }
        }
        .navigationTitle("Edit entry")
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        StockEntryFormView(existingStockEntry: StockEntry())
    }
}
