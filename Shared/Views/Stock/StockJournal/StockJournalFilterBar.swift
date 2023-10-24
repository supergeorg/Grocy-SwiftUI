//
//  StockJournalFilterBar.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.10.23.
//

import SwiftUI

struct StockJournalFilterBar: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Binding var searchString: String
    @Binding var filteredProductID: Int?
    @Binding var filteredTransactionType: TransactionType?
    @Binding var filteredLocationID: Int?
    @Binding var filteredUserID: Int?
    
#if os(iOS)
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
#endif
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150.0))], alignment: .leading, spacing: 5.0) {
            Picker(selection: $filteredProductID, label: Label("Product", systemImage: MySymbols.filter), content: {
                Text("All")
                    .tag(nil as Int?)
                ForEach(grocyVM.mdProducts.filter({$0.active}), id:\.id) { product in
                    Text(product.name)
                        .tag(product.id as Int?)
                }
            })
            Picker(selection: $filteredTransactionType, label: Label("Transaction type", systemImage: MySymbols.filter), content: {
                Text("All")
                    .tag(nil as TransactionType?)
                ForEach(TransactionType.allCases, id:\.rawValue) { transactionType in
                    Text(transactionType.formatTransactionType())
                        .tag(transactionType as TransactionType?)
                }
            })
            Picker(selection: $filteredLocationID, label: Label("Location", systemImage: MySymbols.filter), content: {
                Text("All")
                    .tag(nil as Int?)
                ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { location in
                    Text(location.name)
                        .tag(location.id as Int?)
                }
            })
            Picker(selection: $filteredUserID, label: Label("User", systemImage: MySymbols.filter), content: {
                Text("All")
                    .tag(nil as Int?)
                ForEach(grocyVM.users, id:\.id) { user in
                    Text(user.displayName)
                        .tag(user.id as Int?)
                }
            })
        }
    }
}

//#Preview {
//    StockJournalFilterBar()
//}
