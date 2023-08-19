//
//  ProductOverviewView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 30.11.20.
//

import SwiftUI

struct StockProductInfoView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @Binding var stockElement: StockElement?
    @State private var firstOpen: Bool = true
    @State private var productPictureURL: URL? = nil
    
    
    var productDetails: StockProductDetails? {
        if let productID = stockElement?.productID {
            Task {
                try await grocyVM.getStockProductDetails(productID: productID)
            }
            return grocyVM.stockProductDetails[productID]
        } else { return nil }
    }
    
    var body: some View {
        List {
            if let productDetails = productDetails {
                Text(productDetails.product.name)
                    .font(.title)
                
                Group {
                    Text(LocalizedStringKey("str.details.amount")).bold()
                    +
                    Text("\(productDetails.stockAmount.formattedAmount) \(productDetails.stockAmount == 1 ? productDetails.quantityUnitStock.name : productDetails.quantityUnitStock.namePlural)")
                    
                    Text(LocalizedStringKey("str.details.stockValue")).bold()
                    +
                    Text(grocyVM.getFormattedCurrency(amount: productDetails.stockValue ?? 0.0))
                    
                    Text(LocalizedStringKey("str.details.defaultLocation")).bold()
                    +
                    Text(productDetails.location.name)
                }
                
                Group {
                    Text(LocalizedStringKey("str.details.lastPurchaseDate")).bold()
                    +
                    Text(LocalizedStringKey(formatDateAsString(productDetails.lastPurchased, localizationKey: localizationKey) ?? "str.details.never"))
                    +
                    Text(" ")
                    +
                    Text(getRelativeDateAsText(productDetails.lastPurchased, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                    
                    Text(LocalizedStringKey("str.details.lastUseDate")).bold()
                    +
                    Text(LocalizedStringKey(formatDateAsString(productDetails.lastUsed, localizationKey: localizationKey) ?? "str.details.never"))
                    +
                    Text(" ")
                    +
                    Text(getRelativeDateAsText(productDetails.lastUsed, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
                
                Group {
                    Text(LocalizedStringKey("str.details.lastPrice")).bold()
                    +
                    Text(productDetails.lastPrice != nil ? LocalizedStringKey("str.details.relation \(grocyVM.getFormattedCurrency(amount: productDetails.lastPrice ?? 0.0)) \(productDetails.quantityUnitStock.name)") : LocalizedStringKey("str.details.unknown"))
                    
                    Text(LocalizedStringKey("str.details.averagePrice")).bold()
                    +
                    Text(productDetails.avgPrice != nil ? LocalizedStringKey("str.details.relation \(grocyVM.getFormattedCurrency(amount: productDetails.avgPrice ?? 0.0)) \(productDetails.quantityUnitStock.name)") : LocalizedStringKey("str.details.unknown"))
                }
                
                Group {
                    Text(LocalizedStringKey("str.details.averageShelfLife")).bold()
                    +
                    Text(productDetails.averageShelfLifeDays  > 0 ? LocalizedStringKey(formatDays(daysToFormat: productDetails.averageShelfLifeDays) ?? "str.details.unknown") : LocalizedStringKey("str.details.unknown"))
                    
                    Text(LocalizedStringKey("str.details.spoilRate")).bold()
                    +
                    Text("\(productDetails.spoilRatePercent.formattedAmount) %")
                }
                
                if let productPictureURL = productPictureURL {
                    AsyncImage(url: productPictureURL, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(Color.white)
                    }, placeholder: {
                        ProgressView()
                    })
                    .frame(width: 200)
                }
            } else { Text("Retrieving Details Failed. Please open another window first.") }
        }
        .navigationTitle(LocalizedStringKey("str.details.title"))
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button(LocalizedStringKey("str.close")) {
                    self.dismiss()
                }
            }
        })
        .task {
            do {
                if let pictureFileName = productDetails?.product.pictureFileName,
                   !pictureFileName.isEmpty,
                   let pictureFileNameUTF8 = pictureFileName.data(using: .utf8),
                   let pictureURLString = try await grocyVM.getPictureURL(
                    groupName: "productpictures",
                    fileName: pictureFileNameUTF8.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
                   ) {
                    self.productPictureURL = URL(string: pictureURLString)
                }
            } catch {
                grocyVM.postLog("Getting product picture failed. \(error)", type: .error)
            }
        }
    }
}

//struct ProductOverviewView_Previews: PreviewProvider {
//    static var previews: some View {
//            ProductOverviewView(product: MDProduct(id: "1", name: "Product name", mdProductDescription: "Product description", productGroupID: "1", active: "1", locationID: "1", storeID: "1", quIDPurchase: "1", quIDStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "0", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "TS", userfields: nil))
//    }
//}
