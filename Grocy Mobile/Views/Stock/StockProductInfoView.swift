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
    @Environment(\.dismiss) var dismiss

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
    var isPopup: Bool = false

    var body: some View {
        Form {
            if let productDetails = productDetails {
                LabeledContent(
                    content: {
                        Text(
                            "\(productDetails.stockAmount.formattedAmount) \(productDetails.quantityUnitStock?.getName(amount: productDetails.stockAmount) ?? "")"
                        )
                    },
                    label: {
                        Label("Stock amount", systemImage: MySymbols.amount)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text(grocyVM.getFormattedCurrency(amount: productDetails.stockValue ?? 0.0))
                    },
                    label: {
                        Label("Stock value", systemImage: MySymbols.price)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text(productDetails.location?.name ?? "")
                    },
                    label: {
                        Label("Default location", systemImage: MySymbols.location)
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
                        Label("Last purchased", systemImage: MySymbols.date)
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
                        Label("Last used", systemImage: MySymbols.date)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text(
                            productDetails.lastPrice != nil
                                ? "\(grocyVM.getFormattedCurrency(amount: productDetails.lastPrice ?? 0.0)) per \(productDetails.quantityUnitStock?.name ?? "")"
                                : "Unknown"
                        )
                    },
                    label: {
                        Label("Last price", systemImage: MySymbols.price)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text(
                            productDetails.avgPrice != nil
                                ? "\(grocyVM.getFormattedCurrency(amount: productDetails.avgPrice ?? 0.0)) per \(productDetails.quantityUnitStock?.name ?? "")"
                                : "Unknown"
                        )
                    },
                    label: {
                        Label("Average price", systemImage: MySymbols.price)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text(
                            productDetails.averageShelfLifeDays ?? 0 > 0
                                ? formatDays(daysToFormat: productDetails.averageShelfLifeDays) ?? "Unknown" : "Unknown"
                        )
                    },
                    label: {
                        Label("Average shelf life", systemImage: MySymbols.date)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text("\(productDetails.spoilRatePercent.formattedAmount) %")
                    },
                    label: {
                        Label("Spoil rate", systemImage: MySymbols.spoiled)
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
        .toolbar {
            if isPopup {
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button(
                            role: .cancel,
                            action: {
                                dismiss()
                            }
                        )
                        .keyboardShortcut(.cancelAction)
                    }
                )
            }
        }
    }
}

#Preview(traits: .previewData) {
    let container = PreviewContainer.shared
    let context = ModelContext(container)

    // Fetch one object from the preview store
    let descriptor = FetchDescriptor<StockElement>(sortBy: [SortDescriptor(\.productID)])
    let stockElement = (try? context.fetch(descriptor).first)

    if let stockElement {
        StockProductInfoView(stockElement: stockElement)
    } else {
        EmptyView()
    }
}
