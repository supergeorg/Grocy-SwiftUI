//
//  StockFilterBarView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftData
import SwiftUI

struct StockFilterView: View {
    @Environment(\.colorScheme) var colorScheme

    @Query(filter: #Predicate<MDLocation> { $0.active }, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query(filter: #Predicate<MDProductGroup> { $0.active }, sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups

    @Binding var filteredLocationID: Int?
    @Binding var filteredProductGroupID: Int?
    @Binding var filteredStatus: ProductStatus

    var body: some View {
        List {
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
                selection: $filteredProductGroupID,
                content: {
                    Text("All").tag(nil as Int?)
                    ForEach(mdProductGroups, id: \.id) { productGroup in
                        Text(productGroup.name).tag(productGroup.id as Int?)
                    }
                },
                label: {
                    Label("Product group", systemImage: MySymbols.filter)
                        .foregroundStyle(.primary)
                }
            )

            Picker(
                selection: $filteredStatus,
                content: {
                    Text(ProductStatus.all.rawValue)
                        .tag(ProductStatus.all)
                    Text(ProductStatus.expiringSoon.rawValue)
                        .tag(ProductStatus.expiringSoon)
                    Text(ProductStatus.overdue.rawValue)
                        .tag(ProductStatus.overdue)
                    Text(ProductStatus.expired.rawValue)
                        .tag(ProductStatus.expired)
                    Text(ProductStatus.belowMinStock.rawValue)
                        .tag(ProductStatus.belowMinStock)
                },
                label: {
                    Label("Status", systemImage: MySymbols.filter)
                        .foregroundStyle(.primary)
                }
            )
            #if os(iOS)
                .listRowBackground(
                    Group {
                        switch filteredStatus {
                        case .expired:
                            Color(.GrocyColors.grocyRedBackground)
                        case .expiringSoon:
                            Color(.GrocyColors.grocyYellowBackground)
                        case .overdue:
                            Color(.GrocyColors.grocyGrayBackground)
                        case .belowMinStock:
                            Color(.GrocyColors.grocyBlueBackground)
                        case .all:
                            colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
                        }
                    }
                )
            #endif
        }
    }
}

#Preview {
    @Previewable @State var filteredStatus: ProductStatus = .all
    @Previewable @State var filteredLocationID: Int? = nil
    @Previewable @State var filteredProductGroupID: Int? = nil

    StockFilterView(filteredLocationID: $filteredLocationID, filteredProductGroupID: $filteredProductGroupID, filteredStatus: $filteredStatus)
        .environment(\.colorScheme, .light)
}

#Preview("Darkmode") {
    @Previewable @State var filteredStatus: ProductStatus = .all
    @Previewable @State var filteredLocationID: Int? = nil
    @Previewable @State var filteredProductGroupID: Int? = nil

    StockFilterView(filteredLocationID: $filteredLocationID, filteredProductGroupID: $filteredProductGroupID, filteredStatus: $filteredStatus)
        .environment(\.colorScheme, .dark)
}
