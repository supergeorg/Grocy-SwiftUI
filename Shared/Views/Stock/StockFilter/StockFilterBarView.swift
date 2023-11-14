//
//  StockFilterBarView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI
import SwiftData

struct StockFilterBar: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(filter: #Predicate<MDLocation>{$0.active}, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query(filter: #Predicate<MDProductGroup>{$0.active}, sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups

    @Binding var filteredLocation: Int?
    @Binding var filteredProductGroup: Int?
    @Binding var filteredStatus: ProductStatus
    
    var body: some View {
        HStack{
#if os(iOS)
            Menu {
                Picker("", selection: $filteredLocation, content: {
                    Text("All").tag(nil as Int?)
                    ForEach(mdLocations, id:\.id) { location in
                        Text(location.name).tag(location.id as Int?)
                    }
                })
                    .labelsHidden()
            } label: {
                HStack {
                    Image(systemName: MySymbols.filter)
                    VStack{
                        Text("Location")
                        if let locationName = mdLocations.first(where: { $0.id == filteredLocation })?.name {
                            Text(locationName)
                                .font(.caption)
                        }
                    }
                }
            }
#elseif os(macOS)
            Picker(selection: $filteredLocation,
                   label: Label("Location", systemImage: MySymbols.filter),
                   content: {
                Text("All").tag(nil as Int?)
                ForEach(mdLocations, id:\.id) { location in
                    Text(location.name).tag(location.id as Int?)
                }
            })
#endif
            Spacer()
#if os(iOS)
            Menu {
                Picker("", selection: $filteredProductGroup, content: {
                    Text("All").tag(nil as Int?)
                    ForEach(mdProductGroups, id:\.id) { productGroup in
                        Text(productGroup.name).tag(productGroup.id as Int?)
                    }
                })
                    .labelsHidden()
            } label: {
                HStack {
                    Image(systemName: MySymbols.filter)
                    VStack{
                        Text("Product group")
                        if let productGroupName = mdProductGroups.first(where: { $0.id == filteredProductGroup })?.name {
                            Text(productGroupName)
                                .font(.caption)
                        }
                    }
                }
            }
#elseif os(macOS)
            Picker(selection: $filteredProductGroup,
                   label: Label("Product group", systemImage: MySymbols.filter),
                   content: {
                Text("All").tag(nil as Int?)
                ForEach(mdProductGroups, id:\.id) { productGroup in
                    Text(productGroup.name).tag(productGroup.id as Int?)
                }
            })
#endif
            Spacer()
#if os(iOS)
            Menu {
                Picker("", selection: $filteredStatus, content: {
                    Text(LocalizedStringKey(ProductStatus.all.rawValue))
                        .tag(ProductStatus.all)
                    Text(LocalizedStringKey(ProductStatus.expiringSoon.rawValue))
                        .tag(ProductStatus.expiringSoon)
                        .background(Color(.GrocyColors.grocyYellowBackground))
                    Text(LocalizedStringKey(ProductStatus.overdue.rawValue))
                        .tag(ProductStatus.overdue)
                        .background(Color(.GrocyColors.grocyGrayBackground))
                    Text(LocalizedStringKey(ProductStatus.expired.rawValue))
                        .tag(ProductStatus.expired)
                        .background(Color(.GrocyColors.grocyRedBackground))
                    Text(LocalizedStringKey(ProductStatus.belowMinStock.rawValue))
                        .tag(ProductStatus.belowMinStock)
                        .background(Color(.GrocyColors.grocyBlueBackground))
                })
                    .labelsHidden()
            } label: {
                HStack {
                    Image(systemName: MySymbols.filter)
                    VStack{
                        Text("Status")
                        if filteredStatus != ProductStatus.all {
                            Text(LocalizedStringKey(filteredStatus.rawValue))
                                .font(.caption)
                        }
                    }
                }
            }
#elseif os(macOS)
            Picker(selection: $filteredStatus,
                   label: Label("Status", systemImage: MySymbols.filter),
                   content: {
                Text(LocalizedStringKey(ProductStatus.all.rawValue))
                    .tag(ProductStatus.all)
                Text(LocalizedStringKey(ProductStatus.expiringSoon.rawValue))
                    .tag(ProductStatus.expiringSoon)
                    .background(Color(.GrocyColors.grocyYellowBackground))
                Text(LocalizedStringKey(ProductStatus.overdue.rawValue))
                    .tag(ProductStatus.overdue)
                    .background(Color(.GrocyColors.grocyGrayBackground))
                Text(LocalizedStringKey(ProductStatus.expired.rawValue))
                    .tag(ProductStatus.expired)
//                    .background(Color.grocyRedLight)
                    .background(Color(.GrocyColors.grocyRed))
                Text(LocalizedStringKey(ProductStatus.belowMinStock.rawValue))
                    .tag(ProductStatus.belowMinStock)
                    .background(Color(.GrocyColors.grocyBlueBackground))
            })
#endif
        }
    }
}

//struct StockFilterBar_Previews: PreviewProvider {
//    static var previews: some View {
//        StockFilterBar(searchString: Binding.constant(""), filteredLocation: Binding.constant(nil), filteredProductGroup: Binding.constant(nil), filteredStatus: Binding.constant(ProductStatus.all))
//    }
//}
