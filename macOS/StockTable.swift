//
//  StockTable.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

struct StockTable: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @AppStorage("stockTableShowProduct") var stockTableShowProduct: Bool = true
    @AppStorage("stockTableShowProductGroup") var stockTableShowProductGroup: Bool = false
    @AppStorage("stockTableShowAmount") var stockTableShowAmount: Bool = true
    @AppStorage("stockTableShowValue") var stockTableShowValue: Bool = false
    @AppStorage("stockTableShowNextBestBeforeDate") var stockTableShowNextBestBeforeDate: Bool = true
    @AppStorage("stockTableShowCaloriesPerStockQU") var stockTableShowCaloriesPerStockQU: Bool = false
    @AppStorage("stockTableShowCalories") var stockTableShowCalories: Bool = false
    @AppStorage("stockTableShowLastPurchasedDate") var stockTableShowLastPurchasedDate: Bool = false
    @AppStorage("stockTableShowLastPrice") var stockTableShowLastPrice: Bool = false
    @AppStorage("stockTableShowMinStockAmount") var stockTableShowMinStockAmount: Bool = false
    @AppStorage("stockTableShowProductDescription") var stockTableShowProductDescription: Bool = false
    @AppStorage("stockTableShowParentProduct") var stockTableShowParentProduct: Bool = false
    @AppStorage("stockTableShowDefaultLocation") var stockTableShowDefaultLocation: Bool = false
    @AppStorage("stockTableShowProductPicture") var stockTableShowProductPicture: Bool = false
    
    @State private var searchString: String = ""
    
    var filteredStock: Stock
    var searchedStock: Stock {
        filteredStock
            .filter {
                !searchString.isEmpty ? $0.product.name.localizedCaseInsensitiveContains(searchString) : true
            }
            .filter {
                $0.product.hideOnStockOverview == 0
            }
    }
    
    @Binding var selectedStockElement: StockElement?
    @Binding var activeSheet: StockInteractionPopover?
    @Binding var toastType: ToastType?
    //
    var body: some View {
        Table(searchedStock, columns: {
            TableColumn("", content: { stockElement in
                HStack {
                    StockTableRowActionsView(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, shownActions: [.consumeQA, .consumeAll, .openQA], toastType: $toastType)
                    Menu(content: {
                        StockTableMenuEntriesView(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, toastType: $toastType)
                    }, label: {
                        Image(systemName: "ellipsis")
                    })
                        .frame(width: 45)
                }
            })
            TableColumn(LocalizedStringKey("str.stock.tbl.product"), value: \.product.name)
            TableColumn(LocalizedStringKey("str.stock.tbl.productGroup"), content: { stockElement in
                Text(grocyVM.mdProductGroups.first(where:{ $0.id == stockElement.product.productGroupID })?.name ?? "")
            })
            TableColumn(LocalizedStringKey("str.stock.tbl.amount"), content: { stockElement in
                HStack(){
                    if let quantityUnit = grocyVM.mdQuantityUnits.first(where: { $0.id == stockElement.product.quIDStock }) {
                        Text("\(stockElement.amount.formattedAmount) \(stockElement.amount == 1 ? quantityUnit.name : quantityUnit.namePlural)")
                    } else {
                        Text("\(stockElement.amount.formattedAmount)")
                    }
                    if stockElement.amountOpened > 0 {
                        Text(LocalizedStringKey("str.stock.info.opened \(stockElement.amountOpened.formattedAmount)"))
                            .font(.caption)
                            .italic()
                    }
                    //                    if stockElement.amount != stockElement.amountAggregated {
                    //                        if let quantityUnit = grocyVM.mdQuantityUnits.first(where: { $0.id == stockElement.product.quIDStock }) {
                    //                            Text("Σ \(stockElement.amountAggregated.formattedAmount) \(stockElement.amountAggregated == 1 ? quantityUnit.name : quantityUnit.namePlural)")
                    //                                .foregroundColor(colorScheme == .light ? Color.grocyGray : Color.grocyGrayLight)
                    //                        } else {
                    //                            Text("Σ \(stockElement.amountAggregated.formattedAmount)")
                    //                                .foregroundColor(colorScheme == .light ? Color.grocyGray : Color.grocyGrayLight)
                    //                        }
                    //                        if stockElement.amountOpenedAggregated > 0 {
                    //                            Text(LocalizedStringKey("str.stock.info.opened \(stockElement.amountOpenedAggregated.formattedAmount)"))
                    //                                .foregroundColor(colorScheme == .light ? Color.grocyGray : Color.grocyGrayLight)
                    //                                .font(.caption)
                    //                                .italic()
                    //                        }
                    //                    }
                    //                    if grocyVM.userSettings?.showIconOnStockOverviewPageWhenProductIsOnShoppingList ?? true,
                    //                    grocyVM.shoppingList.first(where: {$0.productID == stockElement.productID}) != nil {
                    //                        Image(systemName: MySymbols.shoppingList)
                    //                            .foregroundColor(colorScheme == .light ? Color.grocyGray : Color.grocyGrayLight)
                    //                            .help(LocalizedStringKey("str.stock.info.onShoppingList"))
                    //                    }
                }
            })
            //            TableColumn(LocalizedStringKey("str.stock.tbl.value"), content: { stockElement in
            //                Text(stockElement.value == 0 ? "" : grocyVM.getFormattedCurrency(amount: stockElement.amount))
            //            })
            //
            //            TableColumn(LocalizedStringKey("str.stock.tbl.nextDueDate"), content: { stockElement in
            //                HStack {
            //                    if stockElement.bestBeforeDate == getNeverOverdueDate() {
            //                        Text(LocalizedStringKey("str.stock.buy.product.doesntSpoil"))
            //                    } else {
            //                        Text(formatDateAsString(stockElement.bestBeforeDate, showTime: false, localizationKey: localizationKey) ?? "")
            //                        Text(getRelativeDateAsText(stockElement.bestBeforeDate, localizationKey: localizationKey) ?? "")
            //                            .font(.caption)
            //                            .italic()
            //                    }
            //                }
            //            })
            //            TableColumn(LocalizedStringKey("str.stock.tbl.caloriesPerStockQU"), content: { stockElement in
            //                Text(stockElement.product.calories != 0.0 ? stockElement.product.calories?.formattedAmount ?? "" : "")
            //            })
            //            TableColumn(LocalizedStringKey("str.stock.tbl.calories"), content: { stockElement in
            //                Text((stockElement.product.calories ?? 0 * stockElement.amount).formattedAmount)
            //            })
            //            //            //            TableColumn(LocalizedStringKey("str.stock.tbl.lastPurchased"), content: { stockElement in
            //            //            //            })
            //            //            //            TableColumn(LocalizedStringKey("str.stock.tbl.lastPrice"), content: { stockElement in })
            //            TableColumn(LocalizedStringKey("str.stock.tbl.minStockAmount"), content: { stockElement in
            //                if let quantityUnit = grocyVM.mdQuantityUnits.first(where: { $0.id == stockElement.product.quIDStock }) {
            //                    Text("\(stockElement.product.minStockAmount.formattedAmount) \(stockElement.product.minStockAmount == 1 ? quantityUnit.name : quantityUnit.namePlural)")
            //                } else {
            //                    Text("\(stockElement.product.minStockAmount.formattedAmount)")
            //                }
            //            })
            //            TableColumn(LocalizedStringKey("str.stock.tbl.productDescription"), content: { stockElement in
            //                Text(stockElement.product.mdProductDescription ?? "")
            //                    .font(.caption)
            //            })
            //            TableColumn(LocalizedStringKey("str.stock.tbl.parentProduct"), content: { stockElement in
            //                Text(grocyVM.mdProducts.first(where: { $0.id == stockElement.product.parentProductID })?.name ?? "")
            //            })
            //            TableColumn(LocalizedStringKey("str.stock.tbl.defaultLocation"), content: { stockElement in
            //                Text(grocyVM.mdLocations.first(where: { $0.id == stockElement.product.locationID })?.name ?? "")
            //            })
            ////            TableColumn(LocalizedStringKey("str.stock.tbl.productPicture"), content: { stockElement in })
        })
        .onAppear(perform: { Task {
            await grocyVM.requestData(objects: [.product_groups, .shopping_list, .quantity_units, .products, .locations], additionalObjects: [.stock, .system_config])} })
            .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
            .animation(.default, value: searchedStock.count)
        //            .onChange(of: sortOrder, perform: { srt in
        //                filteredStock.sorted(by: { $0.product.name > $1.product.name })
        //            })
    }
}

//struct StockTable_Previews: PreviewProvider {
//    static var previews: some View {
//        StockTable(filteredStock: [                            StockElement(amount: "3", amountAggregated: "3", value: "25", bestBeforeDate: "2020-12-12", amountOpened: "1", amountOpenedAggregated: "1", isAggregatedAmount: "0", dueType: "1", productID: "3", product: MDProduct(id: "3", name: "Productname", mdProductDescription: "Description", productGroupID: "1", active: "1", locationID: "1", storeID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "1", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1233", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "ts", userfields: nil))])
//    }
//}
