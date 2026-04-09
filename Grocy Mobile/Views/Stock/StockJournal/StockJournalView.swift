//
//  StockJournalView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import SwiftData
import SwiftUI

enum StockJournalSortOption: Hashable, Sendable {
    case byProductName
    case byAmount
    case byTransactionTime
    case byTransactionType
    case byLocationName
    case byUserName
}

struct StockJournalView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Query var mdProducts: MDProducts
    @Query var mdLocations: MDLocations
    @Query var mdQuantityUnits: MDQuantityUnits
    @Query var grocyUsers: GrocyUsers

    @State private var searchString: String = ""

    @State private var filteredProductID: Int?
    @State private var filteredLocationID: Int?
    @State private var filteredTransactionType: TransactionType?
    @State private var filteredUserID: Int?
    @State private var filteredDateRangeMonths: Int? = 12
    @State private var showingFilterSheet = false
    @State private var isFirstShown: Bool = true
    @State private var sortOption: StockJournalSortOption = .byTransactionTime
    @State private var sortOrder: SortOrder = .reverse

    var stockElement: StockElement? = nil
    var isPopup: Bool = false

    // Fetch the data with a dynamic predicate
    var stockJournal: StockJournal {
        let sortDescriptor = SortDescriptor<StockJournalEntry>(\.rowCreatedTimestamp, order: .reverse)

        var predicates: [Predicate<StockJournalEntry>] = []

        // Date range predicate
        if let filteredDateRangeMonths = filteredDateRangeMonths {
            let cutoffDate = Calendar.current.date(
                byAdding: .month,
                value: -filteredDateRangeMonths,
                to: Date.now
            )!
            let stockJournalPredicate = #Predicate<StockJournalEntry> { entry in
                return entry.rowCreatedTimestamp >= cutoffDate
            }
            predicates.append(stockJournalPredicate)
        }

        // Find matching product IDs for search string
        var matchingProductIDs: [Int]? {
            let productPredicate =
                searchString.isEmpty
                ? nil
                : #Predicate<MDProduct> { product in
                    product.name.localizedStandardContains(searchString)
                }
            let productDescriptor = FetchDescriptor<MDProduct>(predicate: productPredicate)
            let matchingProducts = try? modelContext.fetch(productDescriptor)
            return matchingProducts?.map(\.id) ?? []
        }

        // Product search predicate
        if !searchString.isEmpty, let productIDs = matchingProductIDs {
            let searchPredicate = #Predicate<StockJournalEntry> { entry in
                productIDs.contains(entry.productID)
            }
            predicates.append(searchPredicate)
        }

        // Filtered product predicate
        if let productID: Int = filteredProductID {
            let productPredicate = #Predicate<StockJournalEntry> { entry in
                entry.productID == productID
            }
            predicates.append(productPredicate)
        }

        // Location predicate
        if let locationID: Int = filteredLocationID {
            let locationPredicate = #Predicate<StockJournalEntry> { entry in
                entry.locationID == locationID
            }
            predicates.append(locationPredicate)
        }

        // Transaction type predicate
        if let transactionType: TransactionType = filteredTransactionType {
            let typePredicate = #Predicate<StockJournalEntry> { entry in
                entry.transactionTypeRaw == transactionType.rawValue
            }
            predicates.append(typePredicate)
        }

        // User predicate
        if let userID: Int = filteredUserID {
            let userPredicate = #Predicate<StockJournalEntry> { entry in
                entry.userID == userID
            }
            predicates.append(userPredicate)
        }

        // Combine predicates
        let finalPredicate = predicates.reduce(nil as Predicate<StockJournalEntry>?) { (result: Predicate<StockJournalEntry>?, predicate: Predicate<StockJournalEntry>) in
            if let existing = result {
                return #Predicate<StockJournalEntry> {
                    existing.evaluate($0) && predicate.evaluate($0)
                }
            }
            return predicate
        }

        let descriptor = FetchDescriptor<StockJournalEntry>(
            predicate: finalPredicate,
            sortBy: [sortDescriptor]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // Get the unfiltered count without fetching any data
    var stockJournalCount: Int {
        var descriptor = FetchDescriptor<StockJournalEntry>(
            sortBy: []
        )
        descriptor.fetchLimit = 0

        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    var stockJournalSorted: StockJournal {
        switch sortOption {
        case .byProductName:
            return stockJournal.sorted { fir, sec in
                let firstName = mdProducts.first(where: { $0.id == fir.productID })?.name ?? ""
                let secName = mdProducts.first(where: { $0.id == sec.productID })?.name ?? ""
                return sortOrder == .forward
                    ? firstName < secName
                    : firstName > secName
            }
        case .byAmount:
            return stockJournal.sorted {
                sortOrder == .forward ? $0.amount < $1.amount : $0.amount > $1.amount
            }
        case .byTransactionTime:
            return stockJournal.sorted {
                sortOrder == .forward ? $0.rowCreatedTimestamp < $1.rowCreatedTimestamp : $0.rowCreatedTimestamp > $1.rowCreatedTimestamp
            }
        case .byTransactionType:
            return stockJournal.sorted {
                sortOrder == .forward ? $0.transactionTypeRaw < $1.transactionTypeRaw : $0.transactionTypeRaw > $1.transactionTypeRaw
            }
        case .byLocationName:
            return stockJournal.sorted { fir, sec in
                let firstName = mdLocations.first(where: { $0.id == fir.locationID })?.name ?? ""
                let secName = mdLocations.first(where: { $0.id == sec.locationID })?.name ?? ""
                return sortOrder == .forward
                    ? firstName < secName
                    : firstName > secName
            }
        case .byUserName:
            return stockJournal.sorted { fir, sec in
                let firstName = grocyUsers.first(where: { $0.id == fir.userID })?.displayName ?? ""
                let secName = grocyUsers.first(where: { $0.id == sec.userID })?.displayName ?? ""
                return sortOrder == .forward
                    ? firstName < secName
                    : firstName > secName
            }
        }
    }

    private let dataToUpdate: [ObjectEntities] = [.stock_log, .products, .locations, .quantity_units]
    private let additionalDataToUpdate: [AdditionalEntities] = [.users]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    private func undoTransaction(stockJournalEntry: StockJournalEntry) async {
        do {
            try await grocyVM.undoBookingWithID(id: stockJournalEntry.id)
            GrocyLogger.info("Undo transaction \(stockJournalEntry.id) successful.")
            await grocyVM.requestData(objects: [.stock_log])
        } catch {
            GrocyLogger.error("Undo transaction failed. \(error)")
        }
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if stockJournalCount == 0 {
                ContentUnavailableView("No transactions found.", systemImage: MySymbols.stockJournal)
            } else if stockJournal.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(stockJournalSorted, id: \.id) { (journalEntry: StockJournalEntry) in
                StockJournalRowView(
                    journalEntry: journalEntry,
                    product: mdProducts.first(where: { $0.id == journalEntry.productID }),
                    location: mdLocations.first(where: { $0.id == journalEntry.locationID }),
                    quantityUnit: mdQuantityUnits.first(where: { $0.id == mdProducts.first(where: { $0.id == journalEntry.productID })?.quIDStock }),
                    grocyUser: grocyUsers.first(where: { $0.id == journalEntry.userID })
                )
                .swipeActions(
                    edge: .leading,
                    allowsFullSwipe: true,
                    content: {
                        Button(
                            action: {
                                Task {
                                    await undoTransaction(stockJournalEntry: journalEntry)
                                }
                            },
                            label: {
                                Label("Undo transaction", systemImage: MySymbols.undo)
                            }
                        )
                        .disabled(journalEntry.undone)
                    }
                )
            }
        }
        .navigationTitle("Stock journal")
        .toolbar {
            if isPopup {
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button(
                            role: .cancel,
                            action: {
                                dismiss()
                            }
                        )
                        .keyboardShortcut(.cancelAction)
                    }
                )
            }
            ToolbarItemGroup(placement: .automatic) {
                sortGroupMenu
                Button(action: { showingFilterSheet = true }) {
                    Label("Filter", systemImage: MySymbols.filter)
                }
            }
            #if os(iOS)
                ToolbarSpacer(.flexible, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
            #endif
        }
        .searchable(
            text: $searchString,
            placement: .toolbar,
        )
        .sheet(isPresented: $showingFilterSheet) {
            NavigationStack {
                StockJournalFilterView(
                    filteredProductID: $filteredProductID,
                    filteredTransactionType: $filteredTransactionType,
                    filteredLocationID: $filteredLocationID,
                    filteredUserID: $filteredUserID,
                    filteredDateRangeMonths: $filteredDateRangeMonths,
                )
                .navigationTitle("Filter")
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(
                        placement: .confirmationAction,
                        content: {
                            Button(
                                role: .confirm,
                                action: {
                                    showingFilterSheet = false
                                }
                            )
                        }
                    )
                    ToolbarItem(
                        placement: .cancellationAction,
                        content: {
                            Button(
                                role: .destructive,
                                action: {
                                    filteredProductID = nil
                                    filteredTransactionType = nil
                                    filteredLocationID = nil
                                    filteredUserID = nil
                                    showingFilterSheet = false
                                }
                            )
                        }
                    )
                }
            }
            .presentationDetents([.medium])
        }
        .refreshable {
            await updateData()
        }
        .task {
            await updateData()
            if isFirstShown {
                filteredProductID = stockElement?.productID
                isFirstShown = false
            }
        }
    }

    var sortGroupMenu: some View {
        Menu(
            content: {
                Picker(
                    "Sort category",
                    systemImage: MySymbols.sortCategory,
                    selection: $sortOption,
                    content: {
                        Label("Product", systemImage: MySymbols.product)
                            .labelStyle(.titleAndIcon)
                            .tag(StockJournalSortOption.byProductName)

                        Label("Amount", systemImage: MySymbols.amount)
                            .labelStyle(.titleAndIcon)
                            .tag(StockJournalSortOption.byAmount)

                        Label("Transaction time", systemImage: MySymbols.date)
                            .labelStyle(.titleAndIcon)
                            .tag(StockJournalSortOption.byTransactionTime)

                        Label("Transaction type", systemImage: MySymbols.consume)
                            .labelStyle(.titleAndIcon)
                            .tag(StockJournalSortOption.byTransactionType)

                        Label("Location", systemImage: MySymbols.location)
                            .labelStyle(.titleAndIcon)
                            .tag(StockJournalSortOption.byLocationName)

                        Label("Done by", systemImage: MySymbols.user)
                            .labelStyle(.titleAndIcon)
                            .tag(StockJournalSortOption.byUserName)
                    }
                )
                #if os(iOS)
                    .pickerStyle(.menu)
                #else
                    .pickerStyle(.inline)
                #endif
                Picker(
                    "Sort order",
                    systemImage: MySymbols.sortOrder,
                    selection: $sortOrder,
                    content: {
                        Label("Ascending", systemImage: MySymbols.sortForward)
                            .labelStyle(.titleAndIcon)
                            .tag(SortOrder.forward)

                        Label("Descending", systemImage: MySymbols.sortReverse)
                            .labelStyle(.titleAndIcon)
                            .tag(SortOrder.reverse)
                    }
                )
                #if os(iOS)
                    .pickerStyle(.menu)
                #else
                    .pickerStyle(.inline)
                #endif
            },
            label: {
                Label("Sort", systemImage: MySymbols.sort)
            }
        )
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        StockJournalView()
    }
}
