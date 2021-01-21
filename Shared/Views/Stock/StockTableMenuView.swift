//
//  StockTableMenuView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

import SwiftUI

struct StockTableMenuView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var stockElement: StockElement
    @Binding var selectedStockElement: StockElement?
    @Binding var activeSheet: StockInteractionSheet?
    
    var quantityUnit: MDQuantityUnit {
        grocyVM.mdQuantityUnits.first(where: {$0.id == stockElement.product.quIDStock}) ?? MDQuantityUnit(id: "", name: "Error QU", mdQuantityUnitDescription: nil, rowCreatedTimestamp: "", namePlural: "Error QU", pluralForms: nil, userfields: nil)
    }
    var quString: String {
        return stockElement.product.quickConsumeAmount == "1" ? quantityUnit.name : quantityUnit.namePlural
    }
    
    var body: some View {
        VStack{
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .addToShL
            }, label: {
                Label(LocalizedStringKey("str.stock.tbl.menu.addToShL"), systemImage: "cart")
                    .labelStyle(TextIconLabelStyle())
            })
            Divider()
            Group{
                Button(action: {
                    selectedStockElement = stockElement
                    activeSheet = .productPurchase
                }, label: {
                    Label(LocalizedStringKey("str.stock.buy"), systemImage: "cart")
                        .labelStyle(TextIconLabelStyle())
                })
                Button(action: {
                    selectedStockElement = stockElement
                    activeSheet = .productConsume
                }, label: {
                    Label(LocalizedStringKey("str.stock.consume"), systemImage: "tuningfork")
                        .labelStyle(TextIconLabelStyle())
                })
                Button(action: {
                    selectedStockElement = stockElement
                    activeSheet = .productTransfer
                }, label: {
                    Label(LocalizedStringKey("str.stock.transfer"), systemImage: "arrow.left.arrow.right")
                        .labelStyle(TextIconLabelStyle())
                })
                Button(action: {
                    selectedStockElement = stockElement
                    activeSheet = .productInventory
                }, label: {
                    Label(LocalizedStringKey("str.stock.inventory"), systemImage: "list.bullet")
                        .labelStyle(TextIconLabelStyle())
                })
            }
            Divider()
            Group{
                Button(action: {
                    print("cas")
                }, label: {
                    Text(LocalizedStringKey("str.stock.tbl.menu.consumeAsSpoiled \("\(stockElement.amount) \(quString)")"))
                })
                
                Button(action: {
                    print("recip")
                }, label: {
                    Text(LocalizedStringKey("str.stock.tbl.menu.searchRecipes"))
                })
            }
            Divider()
            Group{
                Button(action: {
                    print("overv")
                }, label: {
                    Text(LocalizedStringKey("str.details.title"))
                })
                Button(action: {
                    print("stocken")
                }, label: {
                    Text(LocalizedStringKey("str.details.stockEntries"))
                })
                Button(action: {
                    print("stockj")
                }, label: {
                    Text(LocalizedStringKey("str.details.stockJournal"))
                })
                Button(action: {
                    print("summ")
                }, label: {
                    Text(LocalizedStringKey("str.stock.journal.summary"))
                })
                Button(action: {
                    print("edit")
                }, label: {
                    Text(LocalizedStringKey("str.details.edit"))
                })
            }
        }
    }
}

//struct StockTableMenuView_Previews: PreviewProvider {
//    static var previews: some View {
//        StockTableMenuView(stockElement: StockElement(amount: "3", amountAggregated: "3", value: "25", bestBeforeDate: "2020-12-12", amountOpened: "1", amountOpenedAggregated: "1", isAggregatedAmount: "0", dueType: "1", productID: "3", product: MDProduct(id: "3", name: "Productname", mdProductDescription: "Description", productGroupID: "1", active: "1", locationID: "1", shoppingLocationID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "1", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1233", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "ts", userfields: nil)))
//    }
//}
