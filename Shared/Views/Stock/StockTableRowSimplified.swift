//
//  StockTableRowSimplified.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 28.12.20.
//

import SwiftUI

struct StockTableRowSimplified: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("expiringDays") var expiringDays: Int = 5
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @Environment(\.colorScheme) var colorScheme
    
    var stockElement: StockElement
    @Binding var selectedStockElement: StockElement?
    #if os(iOS)
    @Binding var activeSheet: StockInteractionSheet?
    #elseif os(macOS)
    @Binding var activeSheet: StockInteractionPopover?
    #endif
    @Binding var toastType: RowActionToastType?
    
    @State private var showDetailView: Bool = false
    
    var caloriesSum: String {
        if let calories = Double(stockElement.product.calories ?? "") {
            let sum = calories * Double(stockElement.amount)!
            return String(format: "%.0f", sum)
        } else { return stockElement.product.calories ?? "" }
    }
    
    var quantityUnit: MDQuantityUnit {
        grocyVM.mdQuantityUnits.first(where: {$0.id == stockElement.product.quIDStock}) ?? MDQuantityUnit(id: "", name: "Error QU", mdQuantityUnitDescription: nil, rowCreatedTimestamp: "", namePlural: "Error QU", pluralForms: nil, userfields: nil)
    }
    
    var backgroundColor: Color {
        if ((0..<(expiringDays + 1)) ~= getTimeDistanceFromString(stockElement.bestBeforeDate) ?? 100) {
            return colorScheme == .light ? Color.grocyYellowLight : Color.grocyYellowDark
        }
        if (stockElement.dueType == "1" ? (getTimeDistanceFromString(stockElement.bestBeforeDate) ?? 100 < 0) : false) {
            return colorScheme == .light ? Color.grocyGrayLight : Color.grocyGrayDark
        }
        if (stockElement.dueType == "2" ? (getTimeDistanceFromString(stockElement.bestBeforeDate) ?? 100 < 0) : false) {
            return colorScheme == .light ? Color.grocyRedLight : Color.grocyRedDark
        }
        if (Int(stockElement.amount) ?? 1 < Int(stockElement.product.minStockAmount) ?? 0) {
            return colorScheme == .light ? Color.grocyBlueLight : Color.grocyBlueDark
        }
        return Color.clear
    }
    
    var formattedAmountAggregated: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter.string(from: Double(stockElement.amountAggregated)! as NSNumber) ?? "?"
    }
    
    var body: some View {
        HStack{
            StockTableRowActionsView(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, toastType: $toastType)
            VStack(alignment: .leading){
                Text(stockElement.product.name)
                    .font(.headline)
                    .onTapGesture {
                        showDetailView.toggle()
                        selectedStockElement = stockElement
                        activeSheet = .productOverview
                    }
                
                if let productGroup = grocyVM.mdProductGroups.first(where:{ $0.id == stockElement.product.productGroupID}) {
                    Text(productGroup.name)
                        .font(.caption)
                } else {Text("")}
                
                HStack{
                    if let formattedAmount = formatStringAmount(stockElement.amount) {
                        Text("\(formattedAmount) \(formattedAmount == "1" ? quantityUnit.name : quantityUnit.namePlural)")
                        if Double(stockElement.amountOpened) ?? 0 > 0 {
                            Text(LocalizedStringKey("str.stock.info.opened \(formatStringAmount(stockElement.amountOpened))"))
                                .font(.caption)
                                .italic()
                        }
                        if let formattedAmountAggregated = formatStringAmount(stockElement.amountAggregated) {
                            if formattedAmount != formattedAmountAggregated {
                                Text("Σ \(formattedAmountAggregated) \(formattedAmountAggregated == "1" ? quantityUnit.name : quantityUnit.namePlural)")
                                    .foregroundColor(colorScheme == .light ? Color.grocyGray : Color.grocyGrayLight)
                                if Double(stockElement.amountOpenedAggregated) ?? 0 > 0 {
                                    Text(LocalizedStringKey("str.stock.info.opened \(formatStringAmount(stockElement.amountOpenedAggregated))"))
                                        .foregroundColor(colorScheme == .light ? Color.grocyGray : Color.grocyGrayLight)
                                        .font(.caption)
                                        .italic()
                                }
                            }
                        }
                    }
                    if grocyVM.shoppingList.first(where: {$0.productID == stockElement.productID}) != nil {
                        Image(systemName: MySymbols.shoppingList)
                            .foregroundColor(colorScheme == .light ? Color.grocyGray : Color.grocyGrayLight)
                            .help(LocalizedStringKey("str.stock.info.onShoppingList"))
                    }
                }
                if let dueDate = getDateFromString(stockElement.bestBeforeDate) {
                    HStack{
                        Text(formatDateAsString(dueDate, showTime: false))
                        Text(getRelativeDateAsText(dueDate, localizationKey: localizationKey))
                            .font(.caption)
                            .italic()
                    }
                }
            }
            Spacer()
        }
        .background(backgroundColor)
        .sheet(isPresented: $showDetailView, content: {
            #if os(macOS)
            ProductOverviewView(productDetails: ProductDetailsModel(product: stockElement.product))
            #endif
        })
    }
}

//struct StockTableRowSimplified_Previews: PreviewProvider {
//    static var previews: some View {
//        StockTableRowSimplified()
//    }
//}
