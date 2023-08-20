//
//  StockFilterBarView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct StockFilterBar: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Binding var searchString: String
    @Binding var filteredLocation: Int?
    @Binding var filteredProductGroup: Int?
    @Binding var filteredStatus: ProductStatus
    
    var body: some View {
        HStack{
#if os(iOS)
            Menu {
                Picker("", selection: $filteredLocation, content: {
                    Text(LocalizedStringKey("str.stock.all")).tag(nil as Int?)
                    ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { location in
                        Text(location.name).tag(location.id as Int?)
                    }
                })
                    .labelsHidden()
            } label: {
                HStack {
                    Image(systemName: MySymbols.filter)
                    VStack{
                        Text(LocalizedStringKey("str.stock.location"))
                        if let locationName = grocyVM.mdLocations.first(where: { $0.id == filteredLocation })?.name {
                            Text(locationName)
                                .font(.caption)
                        }
                    }
                }
            }
#elseif os(macOS)
            Picker(selection: $filteredLocation,
                   label: Label(LocalizedStringKey("str.stock.location"), systemImage: MySymbols.filter),
                   content: {
                Text(LocalizedStringKey("str.stock.all")).tag(nil as Int?)
                ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { location in
                    Text(location.name).tag(location.id as Int?)
                }
            })
#endif
            Spacer()
#if os(iOS)
            Menu {
                Picker("", selection: $filteredProductGroup, content: {
                    Text(LocalizedStringKey("str.stock.all")).tag(nil as Int?)
                    ForEach(grocyVM.mdProductGroups.filter({$0.active}), id:\.id) { productGroup in
                        Text(productGroup.name).tag(productGroup.id as Int?)
                    }
                })
                    .labelsHidden()
            } label: {
                HStack {
                    Image(systemName: MySymbols.filter)
                    VStack{
                        Text(LocalizedStringKey("str.stock.productGroup"))
                        if let productGroupName = grocyVM.mdProductGroups.first(where: { $0.id == filteredProductGroup })?.name {
                            Text(productGroupName)
                                .font(.caption)
                        }
                    }
                }
            }
#elseif os(macOS)
            Picker(selection: $filteredProductGroup,
                   label: Label(LocalizedStringKey("str.stock.productGroup"), systemImage: MySymbols.filter),
                   content: {
                Text(LocalizedStringKey("str.stock.all")).tag(nil as Int?)
                ForEach(grocyVM.mdProductGroups.filter({$0.active}), id:\.id) { productGroup in
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
                        .background(Color.grocyYellowLight)
                    Text(LocalizedStringKey(ProductStatus.overdue.rawValue))
                        .tag(ProductStatus.overdue)
                        .background(Color.grocyGrayLight)
                    Text(LocalizedStringKey(ProductStatus.expired.rawValue))
                        .tag(ProductStatus.expired)
                        .background(Color.grocyRedLight)
                    Text(LocalizedStringKey(ProductStatus.belowMinStock.rawValue))
                        .tag(ProductStatus.belowMinStock)
                        .background(Color.grocyBlueLight)
                })
                    .labelsHidden()
            } label: {
                HStack {
                    Image(systemName: MySymbols.filter)
                    VStack{
                        Text(LocalizedStringKey("str.stock.status"))
                        if filteredStatus != ProductStatus.all {
                            Text(LocalizedStringKey(filteredStatus.rawValue))
                                .font(.caption)
                        }
                    }
                }
            }
#elseif os(macOS)
            Picker(selection: $filteredStatus,
                   label: Label(LocalizedStringKey("str.stock.status"), systemImage: MySymbols.filter),
                   content: {
                Text(LocalizedStringKey(ProductStatus.all.rawValue))
                    .tag(ProductStatus.all)
                Text(LocalizedStringKey(ProductStatus.expiringSoon.rawValue))
                    .tag(ProductStatus.expiringSoon)
                    .background(Color.grocyYellowLight)
                Text(LocalizedStringKey(ProductStatus.overdue.rawValue))
                    .tag(ProductStatus.overdue)
                    .background(Color.grocyGrayLight)
                Text(LocalizedStringKey(ProductStatus.expired.rawValue))
                    .tag(ProductStatus.expired)
                    .background(Color.grocyRedLight)
                Text(LocalizedStringKey(ProductStatus.belowMinStock.rawValue))
                    .tag(ProductStatus.belowMinStock)
                    .background(Color.grocyBlueLight)
            })
#endif
        }
    }
}

struct StockFilterBar_Previews: PreviewProvider {
    static var previews: some View {
        StockFilterBar(searchString: Binding.constant(""), filteredLocation: Binding.constant(nil), filteredProductGroup: Binding.constant(nil), filteredStatus: Binding.constant(ProductStatus.all))
    }
}
