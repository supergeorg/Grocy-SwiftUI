//
//  StockTableView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct StockTableHeader: View {
    @Binding var isShown: Bool
    var description: String
    var stockColumn: StockColumn
    @Binding var sortedStockColumn: StockColumn
    @Binding var sortAscending: Bool
    var isFirst: Bool? = false
    
    var body: some View {
        if isShown {
            if !(isFirst ?? false) { Divider() }
            HStack{
                Text(description).bold()
                if stockColumn == sortedStockColumn {
                    Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                } else {
                Image(systemName: "arrow.up.arrow.down")
                }
            }
            .onTapGesture {
                if stockColumn != sortedStockColumn {
                    sortedStockColumn = stockColumn
                    sortAscending = true
                } else { sortAscending.toggle() }
            }
        }
    }
}

struct StockTable: View {
    @Binding var showProduct: Bool
    @Binding var showProductGroup: Bool
    @Binding var showAmount: Bool
    @Binding var showValue: Bool
    @Binding var showNextBestBeforeDate: Bool
    @Binding var showCaloriesPerStockQU: Bool
    @Binding var showCalories: Bool
    
    var filteredStock: Stock
    
    @Binding var sortedStockColumn: StockColumn
    @Binding var sortAscending: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack{
                StockTableHeader(isShown: $showProduct, description: "Product", stockColumn: .product, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending, isFirst: true)
                StockTableHeader(isShown: $showProductGroup, description: "Product group", stockColumn: .productGroup, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
                StockTableHeader(isShown: $showAmount, description: "Amount", stockColumn: .amount, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
                StockTableHeader(isShown: $showValue, description: "Value", stockColumn: .value, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
                StockTableHeader(isShown: $showNextBestBeforeDate, description: "Next best before date", stockColumn: .nextBestBeforeDate, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
                StockTableHeader(isShown: $showCaloriesPerStockQU, description: "Calories (per stock qu)", stockColumn: .caloriesPerStockQU, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
                StockTableHeader(isShown: $showCalories, description: "Calories", stockColumn: .calories, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
            }
            Divider()
            ForEach(filteredStock, id:\.productID) { stockElement in
                StockTableRow(showProduct: $showProduct, showProductGroup: $showProductGroup, showAmount: $showAmount, showValue: $showValue, showNextBestBeforeDate: $showNextBestBeforeDate, showCaloriesPerStockQU: $showCaloriesPerStockQU, showCalories: $showCalories, stockElement: stockElement)
            }
        }
    }
}

//struct StockTable_Previews: PreviewProvider {
//    static var previews: some View {
//        StockTable(showProduct: Binding.constant(true), showProductGroup: Binding.constant(false), showAmount: Binding.constant(true), showValue: Binding.constant(false), showNextBestBeforeDate: Binding.constant(true), showCaloriesPerStockQU: Binding.constant(false), showCalories: Binding.constant(false), filteredStock: [
//                    StockElement(amount: "1", amountAggregated: "1", bestBeforeDate: "date", amountOpened: "1", amountOpenedAggregated: "1", isAggregatedAmount: "1", productID: "1", product: MDProduct(id: "1", name: "Produktname", mdProductDescription: nil, locationID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", barcode: nil, minStockAmount: "0", defaultBestBeforeDays: "0", rowCreatedTimestamp: "ts", productGroupID: "1", pictureFileName: nil, defaultBestBeforeDaysAfterOpen: "", allowPartialUnitsInStock: "", enableTareWeightHandling: "", tareWeight: "", notCheckStockFulfillmentForRecipes: "", parentProductID: nil, calories: nil, cumulateMinStockAmountOfSubProducts: "", defaultBestBeforeDaysAfterFreezing: "", defaultBestBeforeDaysAfterThawing: "", shoppingLocationID: "1", userfields: nil))])
//    }
//}
