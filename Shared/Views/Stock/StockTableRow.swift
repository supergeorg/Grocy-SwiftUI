//
//  StockTableRow.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 28.12.20.
//

import SwiftUI

struct StockTableRow: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("expiringDays") var expiringDays: Int = 5
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @Environment(\.colorScheme) var colorScheme
#if os(iOS)
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
#endif
    
    var stockElement: StockElement
    @Binding var selectedStockElement: StockElement?
#if os(iOS)
    @Binding var activeSheet: StockInteractionSheet?
#elseif os(macOS)
    @Binding var activeSheet: StockInteractionPopover?
#endif
    @Binding var toastType: RowActionToastType?
    
    @State private var showDetailView: Bool = false
    
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: {$0.id == stockElement.product.quIDStock})
    }
    private func getQUString(amount: Double) -> String {
        return amount == 1.0 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? ""
    }
    
    var backgroundColor: Color {
        if ((0..<(expiringDays + 1)) ~= getTimeDistanceFromNow(date: stockElement.bestBeforeDate) ?? 100) {
            return colorScheme == .light ? Color.grocyYellowLight : Color.grocyYellowDark
        }
        if (stockElement.dueType == 1 ? (getTimeDistanceFromNow(date: stockElement.bestBeforeDate) ?? 100 < 0) : false) {
            return colorScheme == .light ? Color.grocyGrayLight : Color.grocyGrayDark
        }
        if (stockElement.dueType == 2 ? (getTimeDistanceFromNow(date: stockElement.bestBeforeDate) ?? 100 < 0) : false) {
            return colorScheme == .light ? Color.grocyRedLight : Color.grocyRedDark
        }
        if (stockElement.amount < stockElement.product.minStockAmount) {
            return colorScheme == .light ? Color.grocyBlueLight : Color.grocyBlueDark
        }
        return colorScheme == .light ? Color.white : Color.black
    }
    
    var body: some View {
        NavigationLink(destination: {
            StockEntriesView(stockElement: stockElement, activeSheet: $activeSheet)
        }, label: {
            content
            // The padding is to make space displaying the swipe action labels
                .padding(.bottom)
        })
            .contextMenu(menuItems: {
                StockTableMenuEntriesView(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, toastType: $toastType)
            })
            .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
                StockTableRowActionsView(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, shownActions: [.consumeQA, .openQA], toastType: $toastType)
            })
            .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                StockTableRowActionsView(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, shownActions: [.consumeAll], toastType: $toastType)
            })
            .listRowBackground(backgroundColor)
    }
    
    var content: some View {
#if os(iOS)
        Group {
            if horizontalSizeClass == .compact && verticalSizeClass == .regular {
                HStack{
                    VStack(alignment: .leading){
                        stockElementNameAndActions
                        stockElementDetails
                    }
                    Spacer()
                }
            } else {
                HStack{
                    stockElementNameAndActions
                    stockElementDetails
                    Spacer()
                }
            }
        }
#else
        HStack{
            stockElementNameAndActions
            stockElementDetails
            Spacer()
        }
#endif
    }
    
    var stockElementNameAndActions: some View {
        Text(stockElement.product.name)
            .font(.headline)
    }
    
    var stockElementDetails: some View {
        VStack(alignment: .leading){
            if let productGroup = grocyVM.mdProductGroups.first(where:{ $0.id == stockElement.product.productGroupID}) {
                Text(productGroup.name)
                    .font(.caption)
            } else {Text("")}
            
            HStack{
                Text("\(formatAmount(stockElement.amount)) \(getQUString(amount: stockElement.amount))")
                if stockElement.amountOpened > 0 {
                    Text(LocalizedStringKey("str.stock.info.opened \(formatAmount(stockElement.amountOpened))"))
                        .font(.caption)
                        .italic()
                }
                if stockElement.amount != stockElement.amountAggregated {
                    Text("Σ \(formatAmount(stockElement.amountAggregated)) \(getQUString(amount: stockElement.amountAggregated))")
                        .foregroundColor(colorScheme == .light ? Color.grocyGray : Color.grocyGrayLight)
                    if stockElement.amountOpenedAggregated > 0 {
                        Text(LocalizedStringKey("str.stock.info.opened \(formatAmount(stockElement.amountOpenedAggregated))"))
                            .foregroundColor(colorScheme == .light ? Color.grocyGray : Color.grocyGrayLight)
                            .font(.caption)
                            .italic()
                    }
                }
                if grocyVM.shoppingList.first(where: {$0.productID == stockElement.productID}) != nil {
                    Image(systemName: MySymbols.shoppingList)
                        .foregroundColor(colorScheme == .light ? Color.grocyGray : Color.grocyGrayLight)
                        .help(LocalizedStringKey("str.stock.info.onShoppingList"))
                }
            }
            if let dueDate = stockElement.bestBeforeDate {
                HStack {
                    if dueDate == getNeverOverdueDate() {
                        Text(LocalizedStringKey("str.stock.buy.product.doesntSpoil"))
                    } else {
                        Text(formatDateAsString(dueDate, showTime: false, localizationKey: localizationKey) ?? "")
                        Text(getRelativeDateAsText(dueDate, localizationKey: localizationKey) ?? "")
                            .font(.caption)
                            .italic()
                    }
                }
            }
        }
    }
}

//struct StockTableRow_Previews: PreviewProvider {
//    static var previews: some View {
//        StockTableRow(stockElement: StockElement(amount: "2", amountAggregated: "5", value: "1.0", bestBeforeDate: "12.12.2021", amountOpened: "1", amountOpenedAggregated: "2", isAggregatedAmount: "0", dueType: "1", productID: "1", product: MDProduct(id: "1", name: "Product", mdProductDescription: "", productGroupID: "1", active: "1", locationID: "1", shoppingLocationID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "0", defaultBestBeforeDays: "0", defaultBestBeforeDaysAfterOpen: "0", defaultBestBeforeDaysAfterFreezing: "0", defaultBestBeforeDaysAfterThawing: "0", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "0", notCheckStockFulfillmentForRecipes: "0", parentProductID: nil, calories: "13", cumulateMinStockAmountOfSubProducts: "1", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "ts", hideOnStockOverview: nil, userfields: nil)), selectedStockElement: Binding.constant(nil), activeSheet: Binding.constant(nil), toastType: Binding.constant(nil))
//    }
//}
