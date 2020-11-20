//
//  StockJournalView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import SwiftUI

struct StockJournalFilterBar: View {
    @StateObject private var grocyVM = GrocyViewModel()
    
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
    @StateObject private var grocyVM = GrocyViewModel()
    
    var journalEntry: StockJournalEntry
    
    var body: some View {
        VStack(alignment: .leading){
            Text(grocyVM.mdProducts.first(where: { $0.id == journalEntry.productID })?.name ?? "Name Error").font(.title)
            Text("Menge: \(journalEntry.amount)").font(.caption)
            //Transaction Time?
            Text("Transaction Type: \(journalEntry.transactionType.rawValue)").font(.caption)
            Text("Location: \(grocyVM.mdLocations.first(where: {$0.id == journalEntry.locationID})?.name ?? "Location Error")").font(.caption)
        }
    }
}

struct StockJournalView: View {
    @StateObject private var grocyVM = GrocyViewModel()
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var searchString: String = ""
    
    @State private var filteredProduct: MDProduct? = nil
    @State private var filteredLocation: MDLocation? = nil
    @State private var filteredTransactionType: TransactionType? = nil
    @State private var filteredUser: GrocyUser? = nil
    
    var filteredJournal: StockJournal {
        grocyVM.stockJournal
    }
    
    private func updateData() {
        grocyVM.getStockJournal()
//        grocyVM.getMDProducts()
//        grocyVM.getMDLocations()
    }
    
    var body: some View {
        List() {
            StockJournalFilterBar(searchString: $searchString, filteredProduct: $filteredProduct, filteredTransactionType: $filteredTransactionType, filteredLocation: $filteredLocation, filteredUser: $filteredUser)
            if grocyVM.stockJournal.isEmpty {
                Text("str.stockJournal.empty").padding()
            }
            ForEach(filteredJournal, id: \.id) { journalEntry in
                StockJournalRowView(journalEntry: journalEntry)
            }
        }
        .onAppear(perform: updateData)
        .navigationTitle("Stock Journal")
        .toolbar(content: {
            ToolbarItem(placement: .automatic, content: {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "x.circle")
                })
            })
        })
    }
}

struct StockJournalView_Previews: PreviewProvider {
    static var previews: some View {
        StockJournalView()
    }
}
