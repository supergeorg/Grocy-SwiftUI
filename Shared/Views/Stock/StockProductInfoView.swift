//
//  ProductOverviewView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 30.11.20.
//

import SwiftUI

struct StockProductInfoView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @Binding var stockElement: StockElement?
    @State private var firstOpen: Bool = true
    @State private var productDetails: StockProductDetails? = nil
    
    var body: some View {
        List {
            if let productDetails = productDetails {
                Text(productDetails.product.name)
                    .font(.title)
                
                Group {
                    Text("Stock amount: ").bold()
                    +
                    Text("\(productDetails.stockAmount.formattedAmount) \(productDetails.quantityUnitStock.getName(amount: productDetails.stockAmount) ?? "")")
                    
                    Text("Stock value: ").bold()
                    +
                    Text(grocyVM.getFormattedCurrency(amount: productDetails.stockValue ?? 0.0))
                    
                    Text("Default location: ").bold()
                    +
                    Text(productDetails.location.name)
                }
                
                Group {
                    Text("Last purchased: ").bold()
                    +
                    Text(LocalizedStringKey(formatDateAsString(productDetails.lastPurchased, localizationKey: localizationKey) ?? "Never"))
                    +
                    Text(" ")
                    +
                    Text(getRelativeDateAsText(productDetails.lastPurchased, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                    
                    Text("Last used: ").bold()
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
                    Text("Last price: ").bold()
                    +
                    Text(productDetails.lastPrice != nil ? "\(grocyVM.getFormattedCurrency(amount: productDetails.lastPrice ?? 0.0)) per \(productDetails.quantityUnitStock.name)" : "Unknown")
                    
                    Text("Average price: ").bold()
                    +
                    Text(productDetails.avgPrice != nil ? "\(grocyVM.getFormattedCurrency(amount: productDetails.avgPrice ?? 0.0)) per \(productDetails.quantityUnitStock.name)" : "Unknown")
                }
                
                Group {
                    Text("Average shelf life: ").bold()
                    +
                    Text(productDetails.averageShelfLifeDays  > 0 ? formatDays(daysToFormat: productDetails.averageShelfLifeDays) ?? "Unknown" : "Unknown")
                    
                    Text("Spoil rate: ").bold()
                    +
                    Text("\(productDetails.spoilRatePercent.formattedAmount) %")
                }
                
                if let pictureFileName = stockElement?.product.pictureFileName {
                    PictureView(pictureFileName: pictureFileName, pictureType: .productPictures, maxWidth: 200.0)
                }
            } else { Text("Retrieving Details Failed. Please open another window first.") }
        }
        .navigationTitle("Product overview")
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    self.dismiss()
                }
            }
        })
        .task {
            do {
                if let productID = stockElement?.productID {
                    try await grocyVM.getStockProductDetails(productID: productID)
                    productDetails = grocyVM.stockProductDetails[productID]
                }
            } catch {
                grocyVM.postLog("Get stock detail failed. \(error)", type: .error)
            }
        }
    }
}

//struct ProductOverviewView_Previews: PreviewProvider {
//    static var previews: some View {
//            ProductOverviewView(product: MDProduct(id: "1", name: "Product name", mdProductDescription: "Product description", productGroupID: "1", active: "1", locationID: "1", storeID: "1", quIDPurchase: "1", quIDStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "0", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "TS", userfields: nil))
//    }
//}
