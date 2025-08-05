//
//  StockJournalView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import SwiftUI
import SwiftData

struct StockJournalView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchString: String = ""
    
    @State private var filteredProductID: Int?
    @State private var filteredLocationID: Int?
    @State private var filteredTransactionType: TransactionType?
    @State private var filteredUserID: Int?
    @State private var showingFilterSheet = false
    
    // Fetch the data with a dynamic predicate
    var stockJournal: StockJournal {
        let sortDescriptor = SortDescriptor<StockJournalEntry>(\.rowCreatedTimestamp, order: .reverse)
        // Find matching product IDs for search string
        var matchingProductIDs: [Int]? {
            let productPredicate = searchString.isEmpty ? nil :
            #Predicate<MDProduct> { product in
                product.name.localizedStandardContains(searchString)
            }
            let productDescriptor = FetchDescriptor<MDProduct>(predicate: productPredicate)
            let matchingProducts = try? modelContext.fetch(productDescriptor)
            return matchingProducts?.map(\.id) ?? []
        }
        var predicates: [Predicate<StockJournalEntry>] = []
        
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
            print("🔍 Creating predicate for type: \(transactionType)")
            
            // Debug: Print all entries before filtering
            do {
                let allEntries = try modelContext.fetch(FetchDescriptor<StockJournalEntry>())
                print("📝 All entries before filtering: \(allEntries.count)")
                allEntries.forEach { entry in
                    print("Entry ID: \(entry.id), Type: \(entry.transactionType), Raw Value: \(String(describing: entry.transactionType))")
                }
                
                // Create predicate with single expression
                let typePredicate = #Predicate<StockJournalEntry> { entry in
                    entry.transactionTypeRaw == transactionType.rawValue
                }
                predicates.append(typePredicate)
                
                // Debug: Test predicate results
                let testDescriptor = FetchDescriptor<StockJournalEntry>(predicate: typePredicate)
                do {
                    let filteredEntries = try modelContext.fetch(testDescriptor)
                    print("🎯 Filtered entries count: \(filteredEntries.count)")
                    filteredEntries.forEach { entry in
                        print("Matched entry ID: \(entry.id), Type: \(entry.transactionType)")
                    }
                } catch {
                    print("❌ Failed to fetch filtered entries with error: \(error)")
                }
            } catch {
                print("❌ Failed to fetch all entries with error: \(error)")
            }
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
    
    private let dataToUpdate: [ObjectEntities] = [.stock_log, .products, .locations]
    private let additionalDataToUpdate: [AdditionalEntities] = [.users]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    var stockElement: StockElement? = nil
    var selectedProductID: Int? {
        return stockElement?.productID
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
            ForEach(stockJournal, id: \.id) { (journalEntry: StockJournalEntry) in
                StockJournalRowView(journalEntry: journalEntry)
                    .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
                        Button(action: {
                            Task {
                                await undoTransaction(stockJournalEntry: journalEntry)
                            }
                        }, label: {
                            Label("Undo transaction", systemImage: MySymbols.undo)
                        })
                        .disabled(journalEntry.undone == 1)
                    })
            }
        }
        .navigationTitle("Stock journal")
        .searchable(text: $searchString)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingFilterSheet = true }) {
                    Image(systemName: MySymbols.filter)
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            NavigationStack {
                StockJournalFilterView(
                    filteredProductID: $filteredProductID,
                    filteredTransactionType: $filteredTransactionType,
                    filteredLocationID: $filteredLocationID,
                    filteredUserID: $filteredUserID
                )
                .navigationTitle("Filter")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction, content: {
                        Button(role: .confirm, action: {
                            showingFilterSheet = false
                        })
                    })
                    ToolbarItem(placement: .cancellationAction, content: {
                        Button(role: .destructive, action: {
                            filteredProductID = nil
                            filteredTransactionType = nil
                            filteredLocationID = nil
                            filteredUserID = nil
                            showingFilterSheet = false
                        })
                    })
                }
            }
            .presentationDetents([.medium])
        }
        .refreshable {
            await updateData()
        }
        .animation(
            .default,
            value: stockJournal.count
        )
        .task {
            await updateData()
            filteredProductID = selectedProductID
        }
    }
}

#Preview {
    StockJournalView()
}
