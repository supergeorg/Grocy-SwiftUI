//
//  ProductOverviewView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 30.11.20.
//

import SwiftData
import SwiftUI

struct StockProductInfoView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query() var detailsList: [StockProductDetails]
    var productDetails: StockProductDetails? {
        return detailsList.first(where: { $0.productID == stockElement.productID })
    }
    @Query var productList: [MDProduct]
    var product: MDProduct? {
        productList.first(where: { $0.id == stockElement.productID })
    }

    @AppStorage("localizationKey") var localizationKey: String = "en"

    var stockElement: StockElement

    var body: some View {
        Form {
            if let productDetails = productDetails {
                LabeledContent(
                    content: {
                        Text("\(productDetails.stockAmount.formattedAmount) \(productDetails.quantityUnitStock?.getName(amount: productDetails.stockAmount) ?? "")")
                    },
                    label: {
                        Label("\(Text("Stock amount")): ", systemImage: MySymbols.amount)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text(grocyVM.getFormattedCurrency(amount: productDetails.stockValue ?? 0.0))
                    },
                    label: {
                        Label("\(Text("Stock value")): ", systemImage: MySymbols.price)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text(productDetails.location?.name ?? "")
                    },
                    label: {
                        Label("\(Text("Default location")): ", systemImage: MySymbols.location)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        VStack(alignment: .trailing) {
                            Text(LocalizedStringKey(formatDateAsString(productDetails.lastPurchased, localizationKey: localizationKey) ?? "Never"))
                            Text(getRelativeDateAsText(productDetails.lastPurchased, localizationKey: localizationKey) ?? "")
                                .font(.caption)
                                .italic()
                        }
                    },
                    label: {
                        Label("\(Text("Last purchased")): ", systemImage: MySymbols.date)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        VStack {
                            Text(LocalizedStringKey(formatDateAsString(productDetails.lastUsed, localizationKey: localizationKey) ?? "Never"))
                            Text(getRelativeDateAsText(productDetails.lastUsed, localizationKey: localizationKey) ?? "")
                                .font(.caption)
                                .italic()
                        }
                    },
                    label: {
                        Label("\(Text("Last used")): ", systemImage: MySymbols.date)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text(productDetails.lastPrice != nil ? "\(grocyVM.getFormattedCurrency(amount: productDetails.lastPrice ?? 0.0)) per \(productDetails.quantityUnitStock?.name ?? "")" : "Unknown")
                    },
                    label: {
                        Label("\(Text("Last price")): ", systemImage: MySymbols.price)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text(productDetails.avgPrice != nil ? "\(grocyVM.getFormattedCurrency(amount: productDetails.avgPrice ?? 0.0)) per \(productDetails.quantityUnitStock?.name ?? "")" : "Unknown")
                    },
                    label: {
                        Label("\(Text("Average price")): ", systemImage: MySymbols.price)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text(productDetails.averageShelfLifeDays > 0 ? formatDays(daysToFormat: productDetails.averageShelfLifeDays) ?? "Unknown" : "Unknown")
                    },
                    label: {
                        Label("\(Text("Average shelf life")): ", systemImage: MySymbols.date)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text("\(productDetails.spoilRatePercent.formattedAmount) %")
                    },
                    label: {
                        Label("\(Text("Spoil rate")): ", systemImage: MySymbols.spoiled)
                            .foregroundStyle(.primary)
                    }
                )
                if let pictureFileName = stockElement.product?.pictureFileName {
                    PictureView(pictureFileName: pictureFileName, pictureType: .productPictures)
                        .clipShape(.rect(cornerRadius: 5.0))
                        .aspectRatio(contentMode: .fill)
                }
            } else {
                Text("Retrieving Details failed.")
            }
        }
        .navigationTitle(product?.name ?? "Product overview")
        .task {
            await grocyVM.requestStockInfo(stockModeGet: .details, productID: stockElement.productID)
        }
    }
}

//struct ProductOverviewView_Previews: PreviewProvider {
//    static var previews: some View {
//            ProductOverviewView(product: MDProduct(id: "1", name: "Product name", mdProductDescription: "Product description", productGroupID: "1", active: "1", locationID: "1", storeID: "1", quIDPurchase: "1", quIDStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "0", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "TS", userfields: nil))
//    }
//}
