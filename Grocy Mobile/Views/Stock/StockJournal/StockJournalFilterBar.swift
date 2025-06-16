//
//  StockJournalFilterBar.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.10.23.
//

import SwiftUI
import SwiftData

struct StockJournalFilterBar: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(filter: #Predicate<MDProduct>{$0.active}, sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(filter: #Predicate<MDLocation>{$0.active}, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query(sort: \GrocyUser.id, order: .forward) var grocyUsers: GrocyUsers
    
    @Binding var filteredProductID: Int?
    @Binding var filteredTransactionType: TransactionType?
    @Binding var filteredLocationID: Int?
    @Binding var filteredUserID: Int?
    
#if os(iOS)
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
#endif
    
    var body: some View {
#if os(iOS)
        let filterColumns = [GridItem](repeating: GridItem(.flexible()), count: (horizontalSizeClass == .compact && verticalSizeClass == .regular) ? 2 : 4)
#else
        let filterColumns = [GridItem](repeating: GridItem(.flexible()), count: 2)
#endif
        LazyVGrid(columns: filterColumns, alignment: .leading, spacing: 5.0, content: {
#if os(iOS)
            Menu {
                Picker("", selection: $filteredProductID, content: {
                    Text("All").tag(nil as Int?)
                    ForEach(mdProducts, id:\.id) { product in
                        Text(product.name).tag(product.id as Int?)
                    }
                })
                .labelsHidden()
            } label: {
                HStack {
                    Image(systemName: MySymbols.filter)
                    VStack{
                        Text("Product")
                        if let filteredProductID = filteredProductID, let filteredProductName = mdProducts.first(where: { $0.id == filteredProductID })?.name {
                            Text(filteredProductName)
                                .font(.caption)
                        }
                    }
                }
            }
            Menu {
                Picker("", selection: $filteredTransactionType, content: {
                    Text("All")
                        .tag(nil as TransactionType?)
                    ForEach(TransactionType.allCases, id:\.rawValue) { transactionType in
                        Text(transactionType.formatTransactionType())
                            .tag(transactionType as TransactionType?)
                    }
                })
                .labelsHidden()
            } label: {
                HStack {
                    Image(systemName: MySymbols.filter)
                    VStack{
                        Text("Transaction type")
                        if let filteredTransactionType = filteredTransactionType {
                            Text(filteredTransactionType.formatTransactionType())
                                .font(.caption)
                        }
                    }
                }
            }
            Menu {
                Picker("", selection: $filteredLocationID, content: {
                    Text("All")
                        .tag(nil as Int?)
                    ForEach(mdLocations, id:\.id) { location in
                        Text(location.name)
                            .tag(location.id as Int?)
                    }
                })
                .labelsHidden()
            } label: {
                HStack {
                    Image(systemName: MySymbols.filter)
                    VStack{
                        Text("Location")
                        if let filteredLocationID = filteredLocationID, let filteredLocationName = mdLocations.first(where: { $0.id == filteredLocationID })?.name {
                            Text(filteredLocationName)
                                .font(.caption)
                        }
                    }
                }
            }
            Menu {
                Picker("", selection: $filteredUserID, content: {
                    Text("All").tag(nil as Int?)
                    ForEach(grocyVM.users, id:\.id) { user in
                        Text(user.displayName).tag(user.id as Int?)
                    }
                })
                .labelsHidden()
            } label: {
                HStack {
                    Image(systemName: MySymbols.filter)
                    VStack{
                        Text("User")
                        if let filteredUserID = filteredUserID, let filteredUserName = grocyUsers.first(where: { $0.id == filteredUserID })?.displayName {
                            Text(filteredUserName)
                                .font(.caption)
                        }
                    }
                }
            }
#else
            Picker(selection: $filteredProductID, label: Label("Product", systemImage: MySymbols.filter), content: {
                Text("All")
                    .tag(nil as Int?)
                ForEach(mdProducts, id:\.id) { product in
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
                ForEach(mdLocations, id:\.id) { location in
                    Text(location.name)
                        .tag(location.id as Int?)
                }
            })
            Picker(selection: $filteredUserID, label: Label("User", systemImage: MySymbols.filter), content: {
                Text("All")
                    .tag(nil as Int?)
                ForEach(grocyUsers, id:\.id) { user in
                    Text(user.displayName)
                        .tag(user.id as Int?)
                }
            })
#endif
        })
        .padding(.horizontal)
    }
}

//#Preview {
//    StockJournalFilterBar()
//}
