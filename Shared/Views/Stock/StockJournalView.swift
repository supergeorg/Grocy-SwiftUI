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
    @Binding var filteredProduct: MDProduct?
    @Binding var filteredTransactionType: TransactionType?
    @Binding var filteredLocation: MDLocation?
    @Binding var filteredUser: GrocyUser?
    
    var body: some View {
        HStack{
            HStack{
                Image(systemName: "magnifyingglass")
                TextField("Search", text: $searchString)
            }
            Spacer()
            //            HStack{
            //                Image(systemName: "line.horizontal.3.decrease.circle")
            //                Picker(selection: $filteredLocation, label: Text("Standort"), content: {
            //                    Text("str.stock.all").tag("")
            //                    ForEach(grocyVM.mdLocations, id:\.id) { location in
            //                        Text(location.name).tag(location.id)
            //                    }
            //                }).pickerStyle(MenuPickerStyle())
            //            }
            //            Spacer()
            //            HStack{
            //                Image(systemName: "line.horizontal.3.decrease.circle")
            //                Picker(selection: $filteredProductGroup, label: Text("Produktgruppe"), content: {
            //                    Text("str.stock.all").tag("")
            //                    ForEach(grocyVM.mdProductGroups, id:\.id) { productGroup in
            //                        Text(productGroup.name).tag(productGroup.id)
            //                    }
            //                }).pickerStyle(MenuPickerStyle())
            //            }
            //            Spacer()
            //            HStack{
            //                Image(systemName: "line.horizontal.3.decrease.circle")
            //                Picker(selection: $filteredStatus, label: Text("Status"), content: {
            //                    Text(ProductStatus.all.rawValue.localized).tag(ProductStatus.all)
            //                    Text(ProductStatus.expiringSoon.rawValue.localized).tag(ProductStatus.expiringSoon)
            //                    Text(ProductStatus.expired.rawValue.localized).tag(ProductStatus.expired)
            //                    Text(ProductStatus.belowMinStock.rawValue.localized).tag(ProductStatus.belowMinStock)
            //                }).pickerStyle(MenuPickerStyle())
            //            }
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
                    Text("\("str.stock.journal.amount".localized): \(journalEntry.amount) \(journalEntry.amount == "1" ? quantityUnit.name : quantityUnit.namePlural)")
                    Text("\("str.stock.journal.transactionTime".localized): \(formatTimestampOutput(journalEntry.rowCreatedTimestamp))")
                    Text("\("str.stock.journal.transactionType".localized): \(formatTransactionType(journalEntry.transactionType))").font(.caption)
                    Text("\("str.stock.journal.location".localized): \(grocyVM.mdLocations.first(where: {$0.id == journalEntry.locationID})?.name ?? "Location Error")")
                    Text("\("str.stock.journal.user".localized): \(grocyVM.users.first(where: { $0.id == journalEntry.userID })?.displayName ?? "Username Error")")
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
    
    @State private var filteredProduct: MDProduct? = nil
    @State private var filteredLocation: MDLocation? = nil
    @State private var filteredTransactionType: TransactionType? = nil
    @State private var filteredUser: GrocyUser? = nil
    
    var filteredJournal: StockJournal {
        grocyVM.stockJournal
            .filter { journalEntry in
                !searchString.isEmpty ? grocyVM.mdProducts.first(where: { product in
                    product.name.localizedCaseInsensitiveContains(searchString)
                })?.id == journalEntry.productID : true
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
        }
        .toolbar(content: {
            ToolbarItem(placement: .automatic, content: {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "x.circle")
                })
            })
        })
        #else
        content
        #endif
    }
    
    var content: some View {
        List() {
            StockJournalFilterBar(searchString: $searchString, filteredProduct: $filteredProduct, filteredTransactionType: $filteredTransactionType, filteredLocation: $filteredLocation, filteredUser: $filteredUser)
            if grocyVM.stockJournal.isEmpty {
                Text("str.stock.journal.empty").padding()
            } else if filteredJournal.isEmpty {
                Text("str.noSearchResult").padding()
            }
            ForEach(filteredJournal, id: \.id) { journalEntry in
                StockJournalRowView(journalEntry: journalEntry)
            }
        }
        .onAppear(perform: updateData)
        .navigationTitle("str.stock.journal".localized)
    }
}

struct StockJournalView_Previews: PreviewProvider {
    static var previews: some View {
        StockJournalView()
    }
}
