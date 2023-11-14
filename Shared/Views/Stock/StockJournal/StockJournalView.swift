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
    
    @Query(sort: \StockJournalEntry.id, order: .forward) var stockJournal: StockJournal
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \GrocyUser.id, order: .forward) var grocyUsers: GrocyUsers
    
    @State private var searchString: String = ""
    
    @State private var filteredProductID: Int?
    @State private var filteredLocationID: Int?
    @State private var filteredTransactionType: TransactionType?
    @State private var filteredUserID: Int?
    
    private let dataToUpdate: [ObjectEntities] = [.stock_log, .products, .locations]
    private let additionalDataToUpdate: [AdditionalEntities] = [.users]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    var stockElement: Binding<StockElement?>? = nil
    var selectedProductID: Int? {
        return stockElement?.wrappedValue?.productID
    }
    
    private func undoTransaction(stockJournalEntry: StockJournalEntry) async {
        do {
            try await grocyVM.undoBookingWithID(id: stockJournalEntry.id)
            await grocyVM.postLog("Undo transaction \(stockJournalEntry.id) successful.", type: .info)
            await grocyVM.requestData(objects: [.stock_log])
        } catch {
            await grocyVM.postLog("Undo transaction failed. \(error)", type: .error)
        }
    }
    
    var filteredJournal: StockJournal {
        stockJournal
            .filter { journalEntry in
                !searchString.isEmpty ? mdProducts.first(where: { product in
                    product.name.localizedCaseInsensitiveContains(searchString)
                })?.id == journalEntry.productID : true
            }
            .filter { journalEntry in
                filteredProductID == nil ? true : (journalEntry.productID == filteredProductID)
            }
            .filter { journalEntry in
                filteredLocationID == nil ? true : (journalEntry.locationID == filteredLocationID)
            }
            .filter { journalEntry in
                filteredTransactionType == nil ? true : (journalEntry.transactionType == filteredTransactionType)
            }
            .filter { journalEntry in
                filteredUserID == nil ? true : (journalEntry.userID == filteredUserID)
            }
            .sorted {
                $0.rowCreatedTimestamp > $1.rowCreatedTimestamp
            }
    }
    
    var body: some View {
        VStack {
            StockJournalFilterBar(filteredProductID: $filteredProductID, filteredTransactionType: $filteredTransactionType, filteredLocationID: $filteredLocationID, filteredUserID: $filteredUserID)
            List {
                if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                    ServerProblemView()
                } else if stockJournal.isEmpty {
                    ContentUnavailableView("No transactions found.", systemImage: MySymbols.stockJournal)
                } else if filteredJournal.isEmpty {
                    ContentUnavailableView.search
                }
                ForEach(filteredJournal, id: \.id) { journalEntry in
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
        }
        .navigationTitle("Stock journal")
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredJournal.count
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
