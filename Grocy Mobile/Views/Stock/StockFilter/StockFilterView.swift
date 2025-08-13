//
//  StockFilterBarView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI
import SwiftData

struct StockFilterView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(filter: #Predicate<MDLocation>{$0.active}, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query(filter: #Predicate<MDProductGroup>{$0.active}, sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups
    
    @Binding var filteredLocationID: Int?
    @Binding var filteredProductGroupID: Int?
    @Binding var filteredStatus: ProductStatus
    
    var body: some View {
        List {
            Picker(selection: $filteredLocationID, content: {
                Text("All").tag(nil as Int?)
                ForEach(mdLocations, id:\.id) { location in
                    Text(location.name).tag(location.id as Int?)
                }
            }, label: {
                Label("Location", systemImage: MySymbols.filter)
                    .foregroundStyle(.primary)
            })
            Picker(selection: $filteredProductGroupID, content: {
                Text("All").tag(nil as Int?)
                ForEach(mdProductGroups, id:\.id) { productGroup in
                    Text(productGroup.name).tag(productGroup.id as Int?)
                }
            }, label: {
                Label("Product group", systemImage: MySymbols.filter)
                    .foregroundStyle(.primary)
            })
            
            Picker(selection: $filteredStatus, content: {
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
            }, label: {
                Label("Status", systemImage: MySymbols.filter)
                    .foregroundStyle(.primary)
            })
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
                        Color(.systemBackground)
                    }
                }
            )
        }
    }
}

//struct StockFilterBar_Previews: PreviewProvider {
//    static var previews: some View {
//        StockFilterBar(searchString: Binding.constant(""), filteredLocationID: Binding.constant(nil), filteredProductGroupID: Binding.constant(nil), filteredStatus: Binding.constant(ProductStatus.all))
//    }
//}
