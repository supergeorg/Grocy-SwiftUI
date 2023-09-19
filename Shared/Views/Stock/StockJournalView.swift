//
//  StockJournalView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import SwiftUI

struct StockJournalFilterBar: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Binding var searchString: String
    @Binding var filteredProductID: Int?
    @Binding var filteredTransactionType: TransactionType?
    @Binding var filteredLocationID: Int?
    @Binding var filteredUserID: Int?
    
#if os(iOS)
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
#endif
    
#if os(macOS)
    struct SearchField: NSViewRepresentable {
        // This is needed, since the .searchable modifier is not working on popovers.
        
        class Coordinator: NSObject, NSSearchFieldDelegate {
            var parent: SearchField
            
            init(_ parent: SearchField) {
                self.parent = parent
            }
            
            func controlTextDidChange(_ notification: Notification) {
                guard let searchField = notification.object as? NSSearchField else {
                    print("Unexpected control in update notification")
                    return
                }
                self.parent.text = searchField.stringValue
            }
        }
        
        @Binding var text: String
        
        func makeNSView(context: Context) -> NSSearchField {
            NSSearchField(frame: .zero)
        }
        func updateNSView(_ searchField: NSSearchField, context: Context) {
            searchField.stringValue = text
            searchField.delegate = context.coordinator
        }
        func makeCoordinator() -> Coordinator {
            return Coordinator(self)
        }
    }
#endif
    
    var body: some View {
        VStack{
#if os(iOS)
            let filterColumns = [GridItem](repeating: GridItem(.flexible()), count: (horizontalSizeClass == .compact && verticalSizeClass == .regular) ? 2 : 4)
#else
            let filterColumns = [GridItem](repeating: GridItem(.flexible()), count: 2)
#endif
#if os(macOS)
            HStack {
                SearchField(text: $searchString)
                RefreshButton(updateData: {
                    Task {
                        await grocyVM.requestData(objects: [.stock_log])
                    }
                })
            }
#endif
            LazyVGrid(columns: filterColumns, alignment: .leading, content: {
#if os(iOS)
                Menu {
                    Picker("", selection: $filteredProductID, content: {
                        Text("str.stock.all").tag(nil as Int?)
                        ForEach(grocyVM.mdProducts.filter({$0.active}), id:\.id) { product in
                            Text(product.name).tag(product.id as Int?)
                        }
                    })
                    .labelsHidden()
                } label: {
                    HStack {
                        Image(systemName: MySymbols.filter)
                        VStack{
                            Text(LocalizedStringKey("str.stock.journal.product"))
                            if let filteredProductID = filteredProductID, let filteredProductName = grocyVM.mdProducts.first(where: { $0.id == filteredProductID })?.name {
                                Text(filteredProductName)
                                    .font(.caption)
                            }
                        }
                    }
                }
                Menu {
                    Picker("", selection: $filteredTransactionType, content: {
                        Text("str.stock.all").tag(nil as TransactionType?)
                        ForEach(TransactionType.allCases, id:\.rawValue) { transactionType in
                            Text(transactionType.formatTransactionType()).tag(transactionType as TransactionType?)
                        }
                    })
                    .labelsHidden()
                } label: {
                    HStack {
                        Image(systemName: MySymbols.filter)
                        VStack{
                            Text(LocalizedStringKey("str.stock.journal.transactionType"))
                            if let filteredTransactionType = filteredTransactionType {
                                Text(filteredTransactionType.formatTransactionType())
                                    .font(.caption)
                            }
                        }
                    }
                }
                Menu {
                    Picker("", selection: $filteredLocationID, content: {
                        Text("str.stock.all").tag(nil as Int?)
                        ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { location in
                            Text(location.name).tag(location.id as Int?)
                        }
                    })               .labelsHidden()
                } label: {
                    HStack {
                        Image(systemName: MySymbols.filter)
                        VStack{
                            Text(LocalizedStringKey("str.stock.journal.location"))
                            if let filteredLocationID = filteredLocationID, let filteredLocationName = grocyVM.mdLocations.first(where: { $0.id == filteredLocationID })?.name {
                                Text(filteredLocationName)
                                    .font(.caption)
                            }
                        }
                    }
                }
                Menu {
                    Picker("", selection: $filteredUserID, content: {
                        Text("str.stock.all").tag(nil as Int?)
                        ForEach(grocyVM.users, id:\.id) { user in
                            Text(user.displayName).tag(user.id as Int?)
                        }
                    })               .labelsHidden()
                } label: {
                    HStack {
                        Image(systemName: MySymbols.filter)
                        VStack{
                            Text(LocalizedStringKey("str.stock.journal.user"))
                            if let filteredUserID = filteredUserID, let filteredUserName = grocyVM.users.first(where: { $0.id == filteredUserID })?.displayName {
                                Text(filteredUserName)
                                    .font(.caption)
                            }
                        }
                    }
                }
#else
                Picker(selection: $filteredProductID, label: Label(LocalizedStringKey("str.stock.journal.product"), systemImage: MySymbols.filter), content: {
                    Text("str.stock.all").tag(nil as Int?)
                    ForEach(grocyVM.mdProducts.filter({$0.active}), id:\.id) { product in
                        Text(product.name).tag(product.id as Int?)
                    }
                })
                Picker(selection: $filteredTransactionType, label: Label(LocalizedStringKey("str.stock.journal.transactionType"), systemImage: MySymbols.filter), content: {
                    Text("str.stock.all").tag(nil as TransactionType?)
                    ForEach(TransactionType.allCases, id:\.rawValue) { transactionType in
                        Text(transactionType.formatTransactionType()).tag(transactionType as TransactionType?)
                    }
                })
                Picker(selection: $filteredLocationID, label: Label(LocalizedStringKey("str.stock.journal.location"), systemImage: MySymbols.filter), content: {
                    Text("str.stock.all").tag(nil as Int?)
                    ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { location in
                        Text(location.name).tag(location.id as Int?)
                    }
                })
                Picker(selection: $filteredUserID, label: Label(LocalizedStringKey("str.stock.journal.user"), systemImage: MySymbols.filter), content: {
                    Text("str.stock.all").tag(nil as Int?)
                    ForEach(grocyVM.users, id:\.id) { user in
                        Text(user.displayName).tag(user.id as Int?)
                    }
                })
#endif
            })
        }
    }
}

struct StockJournalRowView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    var journalEntry: StockJournalEntry
    
    @Binding var showToastUndoFailed: Bool
    
    var quantityUnit: MDQuantityUnit? {
        let product = grocyVM.mdProducts.first(where: {$0.id == journalEntry.productID})
        return grocyVM.mdQuantityUnits.first(where: {$0.id == product?.quIDStock})
    }
    
    private func undoTransaction() async {
        do {
            try await grocyVM.undoBookingWithID(id: journalEntry.id)
            grocyVM.postLog("Undo transaction \(journalEntry.id) successful.", type: .info)
            await grocyVM.requestData(objects: [.stock_log])
        } catch {
            grocyVM.postLog("Undo transaction failed. \(error)", type: .error)
            showToastUndoFailed = true
        }
    }
    
    var body: some View {
        VStack(alignment: .leading){
            Text(grocyVM.mdProducts.first(where: { $0.id == journalEntry.productID })?.name ?? "Name Error")
                .font(.title)
                .strikethrough(journalEntry.undone == 1, color: .primary)
            if journalEntry.undone == 1 {
                if let date = getDateFromTimestamp(journalEntry.undoneTimestamp ?? "") {
                    HStack(alignment: .bottom){
                        Text(LocalizedStringKey("str.stock.journal.undo.date \(formatDateAsString(date, showTime: true, localizationKey: localizationKey) ?? "")"))
                            .font(.caption)
                        Text(getRelativeDateAsText(date, localizationKey: localizationKey) ?? "")
                            .font(.caption)
                            .italic()
                    }
                    .foregroundColor(journalEntry.undone == 1 ? Color.gray : Color.primary)
                }
            }
            Group {
                Text(LocalizedStringKey("str.stock.journal.amount.info \("\(journalEntry.amount.formattedAmount) \(journalEntry.amount == 1.0 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? "")")"))
                Text(LocalizedStringKey("str.stock.journal.transactionTime.info \(formatTimestampOutput(journalEntry.rowCreatedTimestamp, localizationKey: localizationKey) ?? "")"))
                Text(LocalizedStringKey("str.stock.journal.transactionType.info \("")"))
                    .font(.caption)
                +
                Text(journalEntry.transactionType.formatTransactionType())
                    .font(.caption)
                Text(LocalizedStringKey("str.stock.journal.location.info \(grocyVM.mdLocations.first(where: {$0.id == journalEntry.locationID})?.name ?? "Location Error")"))
                Text(LocalizedStringKey("str.stock.journal.user.info \(grocyVM.users.first(where: { $0.id == journalEntry.userID })?.displayName ?? "Username Error")"))
                if let note = journalEntry.note {
                    Text(LocalizedStringKey("str.stock.entries.note \(note)"))
                }
            }
            .foregroundColor(journalEntry.undone == 1 ? Color.gray : Color.primary)
            .font(.caption)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
            Button(action: { Task { await undoTransaction() } }, label: {
                Label(LocalizedStringKey("str.stock.journal.undo"), systemImage: MySymbols.undo)
            })
            .disabled(journalEntry.undone == 1)
        })
    }
}

struct StockJournalView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var searchString: String = ""
    
    @State private var filteredProductID: Int?
    @State private var filteredLocationID: Int?
    @State private var filteredTransactionType: TransactionType?
    @State private var filteredUserID: Int?
    
    @State private var showToastUndoFailed: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.stock_log]
    private let additionalDataToUpdate: [AdditionalEntities] = [.users]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    var stockElement: Binding<StockElement?>? = nil
    var selectedProductID: Int? {
        return stockElement?.wrappedValue?.productID
    }
    
    var filteredJournal: StockJournal {
        grocyVM.stockJournal
            .filter { journalEntry in
                !searchString.isEmpty ? grocyVM.mdProducts.first(where: { product in
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
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 && grocyVM.failedToLoadAdditionalObjects.filter({additionalDataToUpdate.contains($0)}).count == 0 {
            bodyContent
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.stock.journal"))
        }
    }
    
    var bodyContent: some View {
#if os(iOS)
        NavigationView {
            content
                .toolbar(content: {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel,
                               action: { self.dismiss() },
                               label: { Text(LocalizedStringKey("str.close")) })
                    }
                })
        }
#else
        content
#endif
    }
    
    var content: some View {
        List {
            StockJournalFilterBar(searchString: $searchString, filteredProductID: $filteredProductID, filteredTransactionType: $filteredTransactionType, filteredLocationID: $filteredLocationID, filteredUserID: $filteredUserID)
            if grocyVM.stockJournal.isEmpty {
                ContentUnavailableView("str.stock.journal.empty", systemImage: MySymbols.stockJournal)
            } else if filteredJournal.isEmpty {
                ContentUnavailableView.search.padding()
            }
            ForEach(filteredJournal, id: \.id) { journalEntry in
                StockJournalRowView(journalEntry: journalEntry, showToastUndoFailed: $showToastUndoFailed)
            }
        }
        .navigationTitle(LocalizedStringKey("str.stock.journal"))
        .searchable(text: $searchString,
                    prompt: LocalizedStringKey("str.search"))
        .refreshable(action: {
            await updateData()
        })
        .animation(.default,
                   value: filteredJournal.count
        )
        .task {
            Task {
                await updateData()
                filteredProductID = selectedProductID
            }
        }
        .toast(isPresented: $showToastUndoFailed, isSuccess: false, text: LocalizedStringKey("str.stock.journal.undo.failed"))
    }
}

struct StockJournalView_Previews: PreviewProvider {
    static var previews: some View {
        StockJournalView()
    }
}
