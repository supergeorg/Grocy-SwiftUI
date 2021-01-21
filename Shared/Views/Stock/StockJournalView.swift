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
    @Binding var filteredProductID: String?
    @Binding var filteredTransactionType: TransactionType?
    @Binding var filteredLocationID: String?
    @Binding var filteredUserID: String?
    
    var body: some View {
        VStack{
            SearchBar(text: $searchString, placeholder: "str.search")
            HStack{
                Picker(selection: $filteredProductID, label: Label(LocalizedStringKey("str.stock.journal.product"), systemImage: "line.horizontal.3.decrease.circle"), content: {
                    Text("str.stock.all").tag(nil as String?)
                    ForEach(grocyVM.mdProducts, id:\.id) { product in
                        Text(product.name).tag(product.id as String?)
                    }
                }).pickerStyle(MenuPickerStyle())
                Spacer()
                
                Picker(selection: $filteredTransactionType, label: Label(LocalizedStringKey("str.stock.journal.transactionType"), systemImage: "line.horizontal.3.decrease.circle"), content: {
                    Text("str.stock.all").tag(nil as TransactionType?)
                    ForEach(TransactionType.allCases, id:\.rawValue) { transactionType in
                        Text(transactionType.formatTransactionType()).tag(transactionType as TransactionType?)
                    }
                }).pickerStyle(MenuPickerStyle())
                Spacer()
                
                Picker(selection: $filteredLocationID, label: Label(LocalizedStringKey("str.stock.journal.location"), systemImage: "line.horizontal.3.decrease.circle"), content: {
                    Text("str.stock.all").tag(nil as String?)
                    ForEach(grocyVM.mdLocations, id:\.id) { location in
                        Text(location.name).tag(location.id as String?)
                    }
                }).pickerStyle(MenuPickerStyle())
                Spacer()
                
                Picker(selection: $filteredUserID, label: Label(LocalizedStringKey("str.stock.journal.user"), systemImage: "line.horizontal.3.decrease.circle"), content: {
                    Text("str.stock.all").tag(nil as String?)
                    ForEach(grocyVM.users, id:\.id) { user in
                        Text(user.displayName).tag(user.id as String?)
                    }
                }).pickerStyle(MenuPickerStyle())
            }
        }
    }
}

struct StockJournalRowView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var journalEntry: StockJournalEntry
    
    var quantityUnit: MDQuantityUnit {
        let product = grocyVM.mdProducts.first(where: {$0.id == journalEntry.productID})
        return grocyVM.mdQuantityUnits.first(where: {$0.id == product?.quIDStock}) ?? MDQuantityUnit(id: "0", name: "QU Error", mdQuantityUnitDescription: nil, rowCreatedTimestamp: "", namePlural: "QU Error", pluralForms: nil, userfields: nil)
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "arrow.counterclockwise")
                .padding()
                .foregroundColor(Color.white)
                .background(journalEntry.undone == "1" ? Color.grocyGrayLight : Color.grocyGray)
                .cornerRadius(5)
                .onTapGesture {
                    if journalEntry.undone == "0" {
                        grocyVM.undoBookingWithID(id: journalEntry.id)
                        grocyVM.getStockJournal()
                    }
                }
            VStack(alignment: .leading){
                Text(grocyVM.mdProducts.first(where: { $0.id == journalEntry.productID })?.name ?? "Name Error")
                    .font(.title)
                    .strikethrough(journalEntry.undone == "1", color: .primary)
                Group {
                    Text(LocalizedStringKey("str.stock.journal.amount.info \("\(journalEntry.amount) \(journalEntry.amount == "1" ? quantityUnit.name : quantityUnit.namePlural)")"))
                    Text(LocalizedStringKey("str.stock.journal.transactionTime.info \(formatTimestampOutput(journalEntry.rowCreatedTimestamp))"))
                    Text(LocalizedStringKey("str.stock.journal.transactionType.info \("")"))
                        .font(.caption)
                        +
                        Text(journalEntry.transactionType.formatTransactionType())
                        .font(.caption)
                    Text(LocalizedStringKey("str.stock.journal.location.info \(grocyVM.mdLocations.first(where: {$0.id == journalEntry.locationID})?.name ?? "Location Error")"))
                    Text(LocalizedStringKey("str.stock.journal.user.info \(grocyVM.users.first(where: { $0.id == journalEntry.userID })?.displayName ?? "Username Error")"))
                }
                .foregroundColor(journalEntry.undone == "1" ? Color.gray : Color.primary)
                .font(.caption)
            }
        }
    }
}

struct StockJournalView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var searchString: String = ""
    
    @State private var filteredProductID: String?
    @State private var filteredLocationID: String?
    @State private var filteredTransactionType: TransactionType?
    @State private var filteredUserID: String?
    
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
    
    private func updateData() {
        grocyVM.getStockJournal()
        grocyVM.getUsers()
    }
    
    var body: some View {
        #if os(iOS)
        NavigationView {
            content
                .toolbar(content: {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(LocalizedStringKey("str.close")) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                })
        }
        #else
        content
        #endif
    }
    
    var content: some View {
        List() {
            StockJournalFilterBar(searchString: $searchString, filteredProductID: $filteredProductID, filteredTransactionType: $filteredTransactionType, filteredLocationID: $filteredLocationID, filteredUserID: $filteredUserID)
            if grocyVM.stockJournal.isEmpty {
                Text(LocalizedStringKey("str.stock.journal.empty")).padding()
            } else if filteredJournal.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult")).padding()
            }
            ForEach(filteredJournal, id: \.id) { journalEntry in
                StockJournalRowView(journalEntry: journalEntry)
            }
        }
        .onAppear(perform: updateData)
        .navigationTitle(LocalizedStringKey("str.stock.journal"))
    }
}

struct StockJournalView_Previews: PreviewProvider {
    static var previews: some View {
        StockJournalView()
    }
}
