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
    
    @Environment(\.colorScheme) var colorScheme
    
    var stockElement: StockElement
    @Binding var selectedStockElement: StockElement?
    @Binding var activeSheet: StockInteractionSheet
    @Binding var isShowingSheet: Bool
    
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
            return Color.grocyYellowLight
        }
        if (stockElement.dueType == "1" ? (getTimeDistanceFromString(stockElement.bestBeforeDate) ?? 100 < 0) : false) {
            return Color.grocyGrayLight
        }
        if (stockElement.dueType == "2" ? (getTimeDistanceFromString(stockElement.bestBeforeDate) ?? 100 < 0) : false) {
            return Color.grocyRedLight
        }
        if (Int(stockElement.amount) ?? 1 < Int(stockElement.product.minStockAmount) ?? 0) {
            return Color.grocyBlueLight
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
            StockTableRowActionsView(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, isShowingSheet: $isShowingSheet)
            VStack(alignment: .leading){
                Text(stockElement.product.name)
                    .font(.headline)
                    .onTapGesture {
                        showDetailView.toggle()
                    }
                Text(grocyVM.mdProductGroups.first(where:{ $0.id == stockElement.product.productGroupID})?.name ?? "Produkt group error")
                    .font(.caption)
                HStack{
                    Text("\(stockElement.amount) \(stockElement.amount == "1" ? quantityUnit.name : quantityUnit.namePlural)")
                        .font(.caption)
                    if stockElement.amount != formattedAmountAggregated {
                        Text("Σ \(formattedAmountAggregated) \(formattedAmountAggregated == "1" ? quantityUnit.name : quantityUnit.namePlural)")
                            .font(.caption)
                            .foregroundColor(Color.grocyGray)
                    }
                }
                Text(formatDateOutput(stockElement.bestBeforeDate) ?? "")
                    .font(.caption)
            }
            Spacer()
        }
        .background(backgroundColor)
        .foregroundColor((backgroundColor == Color.clear || colorScheme == .light) ? Color.primary : Color.black)
        .sheet(isPresented: $showDetailView, content: {
            #if os(macOS)
            ProductOverviewView(productDetails: ProductDetailsModel(product: stockElement.product))
            #elseif os(iOS)
            NavigationView{
                ProductOverviewView(productDetails: ProductDetailsModel(product: stockElement.product))
            }
            #endif
        })
    }
}

//struct StockTableRowSimplified_Previews: PreviewProvider {
//    static var previews: some View {
//        StockTableRowSimplified()
//    }
//}
