//
//  StockTableRow.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 28.12.20.
//

import SwiftUI

struct StockTableRow: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @Environment(\.colorScheme) var colorScheme
#if os(iOS)
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
#endif
    
    var stockElement: StockElement
//    @Binding var selectedStockElement: StockElement?
    
    @State private var showDetailView: Bool = false
    
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: {$0.id == stockElement.product.quIDStock})
    }
    
    var backgroundColor: Color {
        if grocyVM.volatileStock?.dueProducts.map({$0.product.id}).contains(stockElement.product.id) ?? false {
            return Color(.GrocyColors.grocyYellowBackground)
        }
        if grocyVM.volatileStock?.expiredProducts.map({$0.product.id}).contains(stockElement.product.id) ?? false {
            return Color(.GrocyColors.grocyRedBackground)
        }
        if grocyVM.volatileStock?.overdueProducts.map({$0.product.id}).contains(stockElement.product.id) ?? false {
            return Color(.GrocyColors.grocyGrayBackground)
        }
        if grocyVM.volatileStock?.missingProducts.map({$0.id}).contains(stockElement.product.id) ?? false {
            return Color(.GrocyColors.grocyBlueBackground)
        }
#if os(iOS)
        return colorScheme == .light ? Color.white : Color.black
#elseif os(macOS)
        return colorScheme == .light ? Color.white : Color.gray.opacity(0.05)
#endif
    }
    
    var body: some View {
        content
//            .contextMenu(menuItems: {
//                StockTableMenuEntriesView(stockElement: stockElement, selectedStockElement: $selectedStockElement)
//            })
//            .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
//                if stockElement.amount > 0 {
//                    StockTableRowActionsView(stockElement: stockElement, selectedStockElement: $selectedStockElement, shownActions: [.consumeQA, .openQA])
//                }
//            })
//            .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
//                if stockElement.amount > 0 {
//                    StockTableRowActionsView(stockElement: stockElement, selectedStockElement: $selectedStockElement, shownActions: [.consumeAll])
//                }
//            })
//#if os(macOS)
//            .listRowBackground(backgroundColor.clipped().cornerRadius(5))
//            .foregroundStyle(colorScheme == .light ? Color.black : Color.white)
//#else
            .listRowBackground(backgroundColor)
//#endif
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
#elseif os(macOS)
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
                Text("\(stockElement.amount.formattedAmount) \(quantityUnit?.getName(amount: stockElement.amount) ?? "")")
                if stockElement.amountOpened > 0 {
                    Text("\(stockElement.amountOpened.formattedAmount) opened")
                        .font(.caption)
                        .italic()
                }
                if stockElement.amount != stockElement.amountAggregated {
                    Text("Σ \(stockElement.amountAggregated.formattedAmount) \(quantityUnit?.getName(amount: stockElement.amountAggregated) ?? "")")
                        .foregroundStyle(Color(.GrocyColors.grocyGray))
                    if stockElement.amountOpenedAggregated > 0 {
                        Text("\(stockElement.amountOpenedAggregated.formattedAmount) opened")
                            .foregroundStyle(Color(.GrocyColors.grocyGray))
                            .font(.caption)
                            .italic()
                    }
                }
                if grocyVM.userSettings?.showIconOnStockOverviewPageWhenProductIsOnShoppingList ?? true,
                   grocyVM.shoppingList.first(where: {$0.productID == stockElement.productID}) != nil {
                    Image(systemName: MySymbols.shoppingList)
                        .foregroundStyle(Color(.GrocyColors.grocyGray))
                        .help("This product is currently on a shopping list.")
                }
            }
            if let dueDate = stockElement.bestBeforeDate {
                HStack {
                    if dueDate == getNeverOverdueDate() {
                        Text("Never overdue")
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
//        StockTableRow(stockElement: StockElement(amount: "2", amountAggregated: "5", value: "1.0", bestBeforeDate: "12.12.2021", amountOpened: "1", amountOpenedAggregated: "2", isAggregatedAmount: "0", dueType: "1", productID: "1", product: MDProduct(id: "1", name: "Product", mdProductDescription: "", productGroupID: "1", active: "1", locationID: "1", storeID: "1", quIDPurchase: "1", quIDStock: "1", minStockAmount: "0", defaultBestBeforeDays: "0", defaultBestBeforeDaysAfterOpen: "0", defaultBestBeforeDaysAfterFreezing: "0", defaultBestBeforeDaysAfterThawing: "0", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "0", notCheckStockFulfillmentForRecipes: "0", parentProductID: nil, calories: "13", cumulateMinStockAmountOfSubProducts: "1", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "ts", hideOnStockOverview: nil, userfields: nil)), selectedStockElement: Binding.constant(nil), activeSheet: Binding.constant(nil))
//    }
//}
