//
//  ProductOverviewView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 30.11.20.
//

import SwiftUI
import SwiftData

struct StockProductInfoView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query() var detailsList: [StockProductDetails]
    var productDetails: StockProductDetails? {
        return detailsList.first(where: { $0.productID == stockElement.productID })
    }
    @Query() var productList: [MDProduct]
    var product: MDProduct? {
        productList.first(where: { $0.id == stockElement.productID })
    }
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    var stockElement: StockElement
    
    var body: some View {
        List {
            if let productDetails = productDetails {
                Group {
                    (Text("Stock amount") + Text(": ")).bold()
                    +
                    Text("\(productDetails.stockAmount.formattedAmount) \(productDetails.quantityUnitStock?.getName(amount: productDetails.stockAmount) ?? "")")
                    
                    (Text("Stock value") + Text(": ")).bold()
                    +
                    Text(grocyVM.getFormattedCurrency(amount: productDetails.stockValue ?? 0.0))
                    
                    (Text("Default location") + Text(": ")).bold()
                    +
                    Text(productDetails.location?.name ?? "")
                }
                
                Group {
                    (Text("Last purchased") + Text(": ")).bold()
                    +
                    Text(LocalizedStringKey(formatDateAsString(productDetails.lastPurchased, localizationKey: localizationKey) ?? "Never"))
                    +
                    Text(" ")
                    +
                    Text(getRelativeDateAsText(productDetails.lastPurchased, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                    
                    (Text("Last used") + Text(": ")).bold()
                    +
                    Text(LocalizedStringKey(formatDateAsString(productDetails.lastUsed, localizationKey: localizationKey) ?? "Never"))
                    +
                    Text(" ")
                    +
                    Text(getRelativeDateAsText(productDetails.lastUsed, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
                
                Group {
                    (Text("Last price") + Text(": ")).bold()
                    +
                    Text(productDetails.lastPrice != nil ? "\(grocyVM.getFormattedCurrency(amount: productDetails.lastPrice ?? 0.0)) per \(productDetails.quantityUnitStock?.name ?? "")" : "Unknown")
                    
                    (Text("Average price") + Text(": ")).bold()
                    +
                    Text(productDetails.avgPrice != nil ? "\(grocyVM.getFormattedCurrency(amount: productDetails.avgPrice ?? 0.0)) per \(productDetails.quantityUnitStock?.name ?? "")" : "Unknown")
                }
                
                Group {
                    (Text("Average shelf life") + Text(": ")).bold()
                    +
                    Text(productDetails.averageShelfLifeDays  > 0 ? formatDays(daysToFormat: productDetails.averageShelfLifeDays) ?? "Unknown" : "Unknown")
                    
                    (Text("Spoil rate") + Text(": ")).bold()
                    +
                    Text("\(productDetails.spoilRatePercent.formattedAmount) %")
                }
                //
                //                if let pictureFileName = stockElement?.product.pictureFileName {
                //                    PictureView(pictureFileName: pictureFileName, pictureType: .productPictures, maxWidth: 200.0)
                //                }
            } else {
                Text("Retrieving Details failed.")
            }
        }
        .navigationTitle(product?.name ?? "Product overview")
        .task {
            do {
                try await grocyVM.requestStockInfo(stockModeGet: .details, productID: stockElement.productID)
            } catch {
                GrocyLogger.error("Get stock detail failed. \(error)")
            }
        }
    }
}

//struct ProductOverviewView_Previews: PreviewProvider {
//    static var previews: some View {
//            ProductOverviewView(product: MDProduct(id: "1", name: "Product name", mdProductDescription: "Product description", productGroupID: "1", active: "1", locationID: "1", storeID: "1", quIDPurchase: "1", quIDStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "0", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "TS", userfields: nil))
//    }
//}
