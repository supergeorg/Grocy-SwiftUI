//
//  StockJournalFilterView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 04.08.25.
//

import SwiftData
import SwiftUI

struct StockJournalFilterView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @AppStorage("localizationKey") var localizationKey: String = "en"

    @Query(filter: #Predicate<MDProduct> { $0.active }, sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(filter: #Predicate<MDLocation> { $0.active }, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query(sort: \GrocyUser.id, order: .forward) var grocyUsers: GrocyUsers

    @Binding var filteredProductID: Int?
    @Binding var filteredTransactionType: TransactionType?
    @Binding var filteredLocationID: Int?
    @Binding var filteredUserID: Int?
    @Binding var filteredDateRangeMonths: Int?

    var body: some View {
        List {
            Picker(
                selection: $filteredProductID,
                content: {
                    Text("All").tag(nil as Int?)
                    ForEach(mdProducts, id: \.id) { product in
                        Text(product.name).tag(product.id as Int?)
                    }
                },
                label: {
                    Label("Product", systemImage: MySymbols.filter)
                        .foregroundStyle(.primary)
                }
            )

            Picker(
                selection: $filteredTransactionType,
                content: {
                    Text("All").tag(nil as TransactionType?)
                    ForEach(TransactionType.allCases, id: \.rawValue) { transactionType in
                        Text(transactionType.localizedName)
                            .tag(transactionType as TransactionType?)
                    }
                },
                label: {
                    Label("Transaction type", systemImage: MySymbols.filter)
                        .foregroundStyle(.primary)
                }
            )

            Picker(
                selection: $filteredLocationID,
                content: {
                    Text("All").tag(nil as Int?)
                    ForEach(mdLocations, id: \.id) { location in
                        Text(location.name).tag(location.id as Int?)
                    }
                },
                label: {
                    Label("Location", systemImage: MySymbols.filter)
                        .foregroundStyle(.primary)
                }
            )

            Picker(
                selection: $filteredUserID,
                content: {
                    Text("All").tag(nil as Int?)
                    ForEach(grocyUsers, id: \.id) { user in
                        Text(user.displayName).tag(user.id as Int?)
                    }
                },
                label: {
                    Label("User", systemImage: MySymbols.filter)
                        .foregroundStyle(.primary)
                }
            )
            Picker(
                selection: $filteredDateRangeMonths,
                content: {
                    Text(formatDuration(value: 1, unit: .month, localizationKey: localizationKey)!)
                        .tag(1)
                    Text(formatDuration(value: 6, unit: .month, localizationKey: localizationKey)!)
                        .tag(6)
                    Text(formatDuration(value: 1, unit: .year, localizationKey: localizationKey)!)
                        .tag(12)
                    Text(formatDuration(value: 2, unit: .year, localizationKey: localizationKey)!)
                        .tag(24)
                    Text("All").tag(nil as Int?)
                },
                label: {
                    Label("Date range", systemImage: MySymbols.date)
                        .foregroundStyle(.primary)
                }
            )
        }
    }
}

#Preview(traits: .previewData) {
    @Previewable @State var filteredProductID: Int? = nil
    @Previewable @State var filteredTransactionType: TransactionType? = nil
    @Previewable @State var filteredLocationID: Int? = nil
    @Previewable @State var filteredUserID: Int? = nil
    @Previewable @State var filteredDateRangeMonths: Int? = 12

    NavigationStack {
        StockJournalFilterView(
            filteredProductID: $filteredProductID,
            filteredTransactionType: $filteredTransactionType,
            filteredLocationID: $filteredLocationID,
            filteredUserID: $filteredUserID,
            filteredDateRangeMonths: $filteredDateRangeMonths
        )
    }
}
