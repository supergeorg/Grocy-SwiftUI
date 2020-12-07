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
    
    var quantityUnit: MDQuantityUnit {
        grocyVM.mdQuantityUnits.first(where: {$0.id == stockElement.product.quIDStock}) ?? MDQuantityUnit(id: "", name: "Error QU", mdQuantityUnitDescription: nil, rowCreatedTimestamp: "", namePlural: "Error QU", pluralForms: nil, userfields: nil)
    }
    var quString: String {
        return stockElement.product.quickConsumeAmount == "1" ? quantityUnit.name : quantityUnit.namePlural
    }
    
    var body: some View {
        HStack(spacing: 2){
            RowInteractionButton(title: stockElement.product.quickConsumeAmount, image: "tuningfork", backgroundColor: Color.grocyGreen, helpString: LocalizedStringKey("str.stock.tbl.action.consume \("\(stockElement.product.quickConsumeAmount) \(quString) \(stockElement.product.name)")"))
            RowInteractionButton(title: "str.stock.tbl.action.all".localized, image: "tuningfork", backgroundColor: Color.grocyDelete, helpString: LocalizedStringKey("str.stock.tbl.action.consume.all \(stockElement.product.name)"))
            RowInteractionButton(title: stockElement.product.quickConsumeAmount, image: "shippingbox", backgroundColor: Color.grocyGreen, helpString: LocalizedStringKey("str.stock.tbl.action.consume.open \("\(stockElement.product.quickConsumeAmount) \(quString) \(stockElement.product.name)")"))
            Menu(content: {
                StockTableMenuView()
            }, label: {
                    RowInteractionButton(image: "ellipsis", backgroundColor: .white, foregroundColor: Color.gray)
            })
            .frame(width: 35)
        }
    }
}

struct StockTableRowActionsView_Previews: PreviewProvider {
    static var previews: some View {
        StockTableRowActionsView(stockElement: StockElement(amount: "3", amountAggregated: "3", value: "25", bestBeforeDate: "2020-12-12", amountOpened: "1", amountOpenedAggregated: "1", isAggregatedAmount: "0", dueType: "1", productID: "3", product: MDProduct(id: "3", name: "Productname", mdProductDescription: "Description", productGroupID: "1", active: "1", locationID: "1", shoppingLocationID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "1", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1233", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "ts", userfields: nil)))
    }
}
