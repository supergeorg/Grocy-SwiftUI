//
//  MDProductRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 22.10.23.
//

import SwiftUI
import SwiftData

struct MDProductRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDLocation.id, order: .forward) var mdLocations: MDLocations
    @Query(sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups
    
    var product: MDProduct
    
    var body: some View {
        HStack{
            if let pictureFileName = product.pictureFileName {
                PictureView(pictureFileName: pictureFileName, pictureType: .productPictures, maxWidth: 75.0, maxHeight: 75.0)
            }
            VStack(alignment: .leading) {
                Text(product.name)
                    .font(.title)
                    .foregroundStyle(product.active ? .primary : .secondary)
                HStack(alignment: .top){
                    if let locationID = mdLocations.firstIndex(where: { $0.id == product.locationID }) {
                        Text("Location") + Text(": \(mdLocations[locationID].name)")
                            .font(.caption)
                    }
                    if let productGroup = mdProductGroups.firstIndex(where: { $0.id == product.productGroupID }) {
                        Text("Product group") + Text(": \(mdProductGroups[productGroup].name)")
                            .font(.caption)
                    }
                }
                if !product.mdProductDescription.isEmpty {
                    Text(product.mdProductDescription)
                        .font(.caption)
                        .italic()
                }
            }
        }
    }
}

#Preview {
    MDProductRowView(product: MDProduct(id: 1, name: "Product", mdProductDescription: "Description", productGroupID: nil, active: true, locationID: 1, storeID: nil, quIDPurchase: 1, quIDStock: 1, quIDConsume: 1, quIDPrice: 1, minStockAmount: 1.0, defaultDueDays: 1, defaultDueDaysAfterOpen: 1, defaultDueDaysAfterFreezing: 1, defaultDueDaysAfterThawing: 1, pictureFileName: nil, enableTareWeightHandling: false, tareWeight: nil, notCheckStockFulfillmentForRecipes: false, parentProductID: nil, calories: nil, cumulateMinStockAmountOfSubProducts: false, dueType: 1, quickConsumeAmount: nil, quickOpenAmount: nil, hideOnStockOverview: false, defaultStockLabelType: nil, shouldNotBeFrozen: false, treatOpenedAsOutOfStock: false, noOwnStock: false, defaultConsumeLocationID: nil, moveOnOpen: false, autoReprintStockLabel: false, rowCreatedTimestamp: ""))
}
