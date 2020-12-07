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
    var filteredStock: Stock
    
    @State private var showTableSettings: Bool = false
    @AppStorage("stockShowProduct") var stockShowProduct: Bool = true
    @AppStorage("stockShowProductGroup") var stockShowProductGroup: Bool = false
    @AppStorage("stockShowAmount") var stockShowAmount: Bool = true
    @AppStorage("stockShowValue") var stockShowValue: Bool = false
    @AppStorage("stockShowNextBestBeforeDate") var stockShowNextBestBeforeDate: Bool = true
    @AppStorage("stockShowCaloriesPerStockQU") var stockShowCaloriesPerStockQU: Bool = false
    @AppStorage("stockShowCalories") var stockShowCalories: Bool = false
    @State private var sortedStockColumn: StockColumn = .product
    @State private var sortAscending: Bool = true
    
    var sortedStock: Stock {
        filteredStock
            .sorted {
                switch sortedStockColumn {
                case .product:
                    return sortAscending ? ($0.product.name < $1.product.name) : ($0.product.name > $1.product.name)
                case .productGroup:
                    return sortAscending ? ($0.product.productGroupID < $1.product.productGroupID) : ($0.product.productGroupID > $1.product.productGroupID)
                case .amount:
                    return sortAscending ? ($0.amount < $1.amount) : ($0.amount > $1.amount)
                case .nextBestBeforeDate:
                    return sortAscending ? ($0.bestBeforeDate < $1.bestBeforeDate) : ($0.bestBeforeDate > $1.bestBeforeDate)
                default:
                    return ($0.productID < $1.productID)
                }
            }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack{
                Button(action: {
                    showTableSettings.toggle()
                }, label: {
                    Image(systemName: "eye.fill")
                })
                .popover(isPresented: $showTableSettings, content: {
                    StockTableConfigView(showProduct: $stockShowProduct, showProductGroup: $stockShowProductGroup, showAmount: $stockShowAmount, showValue: $stockShowValue, showNextBestBeforeDate: $stockShowNextBestBeforeDate, showCaloriesPerStockQU: $stockShowCaloriesPerStockQU, showCalories: $stockShowCalories)
                        .padding()
                })
                StockTableHeader(isShown: $stockShowProduct, description: "str.stock.tbl.product".localized, stockColumn: .product, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending, isFirst: true)
                StockTableHeader(isShown: $stockShowProductGroup, description: "str.stock.tbl.productGroup".localized, stockColumn: .productGroup, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
                StockTableHeader(isShown: $stockShowAmount, description: "str.stock.tbl.amount".localized, stockColumn: .amount, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
                StockTableHeader(isShown: $stockShowValue, description: "str.stock.tbl.value".localized, stockColumn: .value, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
                StockTableHeader(isShown: $stockShowNextBestBeforeDate, description: "str.stock.tbl.nextBestBefore".localized, stockColumn: .nextBestBeforeDate, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
                StockTableHeader(isShown: $stockShowCaloriesPerStockQU, description: "str.stock.tbl.caloriesPerStockQU".localized, stockColumn: .caloriesPerStockQU, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
                StockTableHeader(isShown: $stockShowCalories, description: "str.stock.tbl.calories".localized, stockColumn: .calories, sortedStockColumn: $sortedStockColumn, sortAscending: $sortAscending)
            }
            Divider()
            ForEach(filteredStock, id:\.productID) { stockElement in
                StockTableRow(showProduct: $stockShowProduct, showProductGroup: $stockShowProductGroup, showAmount: $stockShowAmount, showValue: $stockShowValue, showNextBestBeforeDate: $stockShowNextBestBeforeDate, showCaloriesPerStockQU: $stockShowCaloriesPerStockQU, showCalories: $stockShowCalories, stockElement: stockElement)
            }
        }
    }
}

struct StockTable_Previews: PreviewProvider {
    static var previews: some View {
        StockTable(filteredStock: [                            StockElement(amount: "3", amountAggregated: "3", value: "25", bestBeforeDate: "2020-12-12", amountOpened: "1", amountOpenedAggregated: "1", isAggregatedAmount: "0", dueType: "1", productID: "3", product: MDProduct(id: "3", name: "Productname", mdProductDescription: "Description", productGroupID: "1", active: "1", locationID: "1", shoppingLocationID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "1", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1233", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "ts", userfields: nil))])
    }
}
