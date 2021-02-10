//
//  StockTableRowActionsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

import SwiftUI

struct StockTableRowActionsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var stockElement: StockElement
    @Binding var selectedStockElement: StockElement?
    #if os(iOS)
    @Binding var activeSheet: StockInteractionSheet?
    #elseif os(macOS)
    @Binding var activeSheet: StockInteractionPopover?
    #endif
    @Binding var toastType: RowActionToastType?
    @State private var mdToastType: MDToastType?
    
    var quantityUnit: MDQuantityUnit {
        grocyVM.mdQuantityUnits.first(where: {$0.id == stockElement.product.quIDStock}) ?? MDQuantityUnit(id: "", name: "Error QU", mdQuantityUnitDescription: nil, rowCreatedTimestamp: "", namePlural: "Error QU", pluralForms: nil, userfields: nil)
    }
    var quString: String {
        return stockElement.product.quickConsumeAmount == "1" ? quantityUnit.name : quantityUnit.namePlural
    }
    
    var body: some View {
        HStack(spacing: 2){
            RowInteractionButton(title: formatStringAmount(stockElement.product.quickConsumeAmount), image: MySymbols.consume, backgroundColor: Color.grocyGreen, helpString: LocalizedStringKey("str.stock.tbl.action.consume \("\(stockElement.product.quickConsumeAmount) \(quString) \(stockElement.product.name)")"))
                .onTapGesture {
                    selectedStockElement = stockElement
                    grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .consume, content: ProductConsume(amount: Double(stockElement.product.quickConsumeAmount) ?? 1.0, transactionType: .consume, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil)) { result in
                        switch result {
                        case let .success(prod):
                            print(prod)
                            toastType = .successConsumeOne
                        case let .failure(error):
                            print("\(error)")
                            toastType = .fail
                        }
                    }
                }
            RowInteractionButton(title: "str.stock.tbl.action.all", image: MySymbols.consume, backgroundColor: Color.grocyDelete, helpString: LocalizedStringKey("str.stock.tbl.action.consume.all \(stockElement.product.name)"))
                .onTapGesture {
                    selectedStockElement = stockElement
                    grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .consume, content: ProductConsume(amount: Double(stockElement.amount) ?? 1.0, transactionType: .consume, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil)) { result in
                        switch result {
                        case let .success(prod):
                            print(prod)
                            toastType = .successConsumeAll
                        case let .failure(error):
                            print("\(error)")
                            toastType = .fail
                        }
                    }
                }
            RowInteractionButton(title: formatStringAmount(stockElement.product.quickConsumeAmount), image: "shippingbox", backgroundColor: Color.grocyGreen, helpString: LocalizedStringKey("str.stock.tbl.action.consume.open \("\(stockElement.product.quickConsumeAmount) \(quString) \(stockElement.product.name)")"))
                .onTapGesture {
                    selectedStockElement = stockElement
                    grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .open, content: ProductConsume(amount: Double(stockElement.product.quickConsumeAmount) ?? 1.0, transactionType: .productOpened, spoiled: false, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil)) { result in
                        switch result {
                        case let .success(prod):
                            print(prod)
                            toastType = .successOpenOne
                        case let .failure(error):
                            print("\(error)")
                            toastType = .fail
                        }
                    }
                }
            Menu(content: {
                StockTableMenuView(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, toastType: $toastType)
            }, label: {
                RowInteractionButton(image: "ellipsis", backgroundColor: .white, foregroundColor: Color.gray)
            })
            .frame(width: 35)
        }
    }
}

//struct StockTableRowActionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        StockTableRowActionsView(stockElement: StockElement(amount: "3", amountAggregated: "3", value: "25", bestBeforeDate: "2020-12-12", amountOpened: "1", amountOpenedAggregated: "1", isAggregatedAmount: "0", dueType: "1", productID: "3", product: MDProduct(id: "3", name: "Productname", mdProductDescription: "Description", productGroupID: "1", active: "1", locationID: "1", shoppingLocationID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "1", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1233", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "ts", userfields: nil)))
//    }
//}
