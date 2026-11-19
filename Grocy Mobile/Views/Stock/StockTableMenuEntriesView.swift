//
//  StockTableMenuEntriesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

import SwiftData
import SwiftUI

struct StockTableMenuEntriesView: View {
    @Environment(StockInteractionNavigationRouter.self) private var stockInteractionRouter
    @Environment(\.grocyFeatures) private var features

    @Environment(GrocyViewModel.self) private var grocyVM

    var stockElement: StockElement
    var quantityUnit: MDQuantityUnit?

    /// Like Grocy's stock overview: the quick consume amount, at most what's in stock.
    private var spoiledAmount: Double {
        min(stockElement.product?.quickConsumeAmount ?? 1.0, stockElement.amount)
    }

    private func consumeAsSpoiled() async {
        do {
            try await grocyVM.postStockObject(
                id: stockElement.productID,
                stockModePost: .consume,
                content: ProductConsume(
                    amount: spoiledAmount,
                    transactionType: .consume,
                    spoiled: true,
                    stockEntryID: nil,
                    recipeID: nil,
                    locationID: nil,
                    exactAmount: nil,
                    allowSubproductSubstitution: nil
                )
            )
            GrocyLogger.info("Consuming \(spoiledAmount) of product \(stockElement.productID) as spoiled was successful.")
            await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
        } catch {
            GrocyLogger.error("Consuming \(spoiledAmount) of product \(stockElement.productID) as spoiled failed. \(error)")
        }
    }

    var body: some View {
        Button(
            action: {
                stockInteractionRouter.present(.addToShL(stockElement: stockElement))
            },
            label: {
                Label("Add to shopping list", systemImage: MySymbols.addToShoppingList)
                    .labelStyle(.titleAndIcon)
            }
        )
        Divider()
        Group {
            Button(
                action: {
                    stockInteractionRouter.present(.productPurchase(stockElement: stockElement))
                },
                label: {
                    Label("Purchase", systemImage: MySymbols.purchase)
                        .labelStyle(.titleAndIcon)
                }
            )
            Button(
                action: {
                    stockInteractionRouter.present(.productConsume(stockElement: stockElement))
                },
                label: {
                    Label("Consume", systemImage: MySymbols.consume)
                        .labelStyle(.titleAndIcon)
                }
            )
            if features.locationTracking {
                Button(
                    action: {
                        stockInteractionRouter.present(.productTransfer(stockElement: stockElement))
                    },
                    label: {
                        Label("Transfer", systemImage: MySymbols.transfer)
                            .labelStyle(.titleAndIcon)
                    }
                )
            }
            Button(
                action: {
                    stockInteractionRouter.present(.productInventory(stockElement: stockElement))
                },
                label: {
                    Label("Inventory", systemImage: MySymbols.inventory)
                        .labelStyle(.titleAndIcon)
                }
            )
        }
        Divider()
        if stockElement.amount > 0 {
            Button(
                role: .destructive,
                action: {
                    Task {
                        await consumeAsSpoiled()
                    }
                },
                label: {
                    Label(
                        "Consume \(spoiledAmount.formattedAmount) \(quantityUnit?.getName(amount: spoiledAmount) ?? "") as spoiled",
                        systemImage: MySymbols.spoiled
                    )
                    .labelStyle(.titleAndIcon)
                }
            )
        }
        if features.recipes {
            Button(
                action: {
                    stockInteractionRouter.present(.productRecipes(stockElement: stockElement))
                },
                label: {
                    Label("Search for recipes which contain this product", systemImage: MySymbols.recipe)
                        .labelStyle(.titleAndIcon)
                }
            )
        }
        Divider()
        Button(
            action: {
                stockInteractionRouter.present(.productOverview(stockElement: stockElement))
            },
            label: {
                Label("Product overview", systemImage: MySymbols.info)
                    .labelStyle(.titleAndIcon)
            }
        )
        Button(
            action: {
                stockInteractionRouter.present(.productEntries(stockElement: stockElement))
            },
            label: {
                Label("Stock entries", systemImage: MySymbols.stockEntries)
                    .labelStyle(.titleAndIcon)
            }
        )
        Button(
            action: {
                stockInteractionRouter.present(.productJournal(stockElement: stockElement))
            },
            label: {
                Label("Stock journal", systemImage: MySymbols.stockJournal)
                    .labelStyle(.titleAndIcon)
            }
        )
        if stockElement.product != nil {
            Button(
                action: {
                    stockInteractionRouter.present(.editProduct(stockElement: stockElement))
                },
                label: {
                    Label("Edit product", systemImage: MySymbols.edit)
                        .labelStyle(.titleAndIcon)
                }
            )
        }
    }
}

#Preview(traits: .previewData) {
    Menu("Preview") {
        StockTableMenuEntriesView(stockElement: StockElement(product: MDProduct()), quantityUnit: MDQuantityUnit())
    }
}
