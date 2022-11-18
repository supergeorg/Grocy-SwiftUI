//
//  StockTableMenuEntriesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

import SwiftUI

struct StockTableMenuEntriesView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var stockElement: StockElement
    @Binding var selectedStockElement: StockElement?
#if os(iOS)
    @Binding var activeSheet: StockInteractionSheet?
#elseif os(macOS)
    @Binding var activeSheet: StockInteractionPopover?
#endif
    @Binding var toastType: ToastType?
    
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: {$0.id == stockElement.product.quIDStock})
    }
    var quString: String {
        return stockElement.product.quickConsumeAmount == 1.0 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? ""
    }
    
    func consumeAsSpoiled() {
        grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .consume, content: ProductConsume(amount: stockElement.amount, transactionType: .consume, spoiled: true, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil)) { result in
            switch result {
            case .success(_):
                toastType = .successConsumeAllSpoiled
                grocyVM.requestData(additionalObjects: [.stock])
            case let .failure(error):
                grocyVM.postLog("Consume all as spoiled failed. \(error)", type: .error)
                toastType = .shLActionFail
            }
        }
    }
    
    var body: some View {
        Button(action: {
            selectedStockElement = stockElement
            activeSheet = .addToShL
        }, label: {
            Label(LocalizedStringKey("str.stock.tbl.menu.addToShL"), systemImage: MySymbols.addToShoppingList)
                .labelStyle(.titleAndIcon)
        })
        Divider()
        Group{
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .productPurchase
            }, label: {
                Label(LocalizedStringKey("str.stock.buy"), systemImage: MySymbols.purchase)
                    .labelStyle(.titleAndIcon)
            })
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .productConsume
            }, label: {
                Label(LocalizedStringKey("str.stock.consume"), systemImage: MySymbols.consume)
                    .labelStyle(.titleAndIcon)
            })
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .productTransfer
            }, label: {
                Label(LocalizedStringKey("str.stock.transfer"), systemImage: MySymbols.transfer)
                    .labelStyle(.titleAndIcon)
            })
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .productInventory
            }, label: {
                Label(LocalizedStringKey("str.stock.inventory"), systemImage: MySymbols.inventory)
                    .labelStyle(.titleAndIcon)
            })
        }
        Divider()
        Group{
            Button(role: .destructive, action: {
                selectedStockElement = stockElement
                consumeAsSpoiled()
            }, label: {
                Label(LocalizedStringKey("str.stock.tbl.menu.consumeAsSpoiled \("\(stockElement.amount.formattedAmount) \(quString)")"), systemImage: MySymbols.clear)
            })
            
            //                Button(action: {
            //                    print("recip")
            //                }, label: {
            //                    Text(LocalizedStringKey("str.stock.tbl.menu.searchRecipes"))
            //                })
        }
        Divider()
        Group{
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .productOverview
            }, label: {
                Label(LocalizedStringKey("str.details.title"), systemImage: MySymbols.info)
            })
            //                Button(action: {
            //                    print("Stock entries are not accessed here")
            //                }, label: {
            //                    Text(LocalizedStringKey("str.details.stockEntries"))
            //                })
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .productJournal
            }, label: {
                Label(LocalizedStringKey("str.details.stockJournal"), systemImage: MySymbols.stockJournal)
            })
            //                Button(action: {
            //                    print("Stock Journal summary is not available yet")
            //                }, label: {
            //                    Text(LocalizedStringKey("str.stock.journal.summary"))
            //                })
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .editProduct
            }, label: {
                Label(LocalizedStringKey("str.details.edit"), systemImage: MySymbols.edit)
            })
        }
    }
}

//struct StockTableMenuView_Previews: PreviewProvider {
//    static var previews: some View {
////        StockTableMenuView(stockElement: StockElement(amount: "3", amountAggregated: "3", value: "25", bestBeforeDate: "2020-12-12", amountOpened: "1", amountOpenedAggregated: "1", isAggregatedAmount: "0", dueType: "1", productID: "3", product: MDProduct(id: "3", name: "Productname", mdProductDescription: "Description", productGroupID: "1", active: "1", locationID: "1", shoppingLocationID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "1", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1233", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "ts", hideOnStockOverview: "0", userfields: nil)), selectedStockElement)
//    }
//}
