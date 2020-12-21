//
//  StockRowView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 29.10.20.
//

import SwiftUI

struct StockTableRow: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("expiringDays") var expiringDays: Int = 5
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var showProduct: Bool
    @Binding var showProductGroup: Bool
    @Binding var showAmount: Bool
    @Binding var showValue: Bool
    @Binding var showNextBestBeforeDate: Bool
    @Binding var showCaloriesPerStockQU: Bool
    @Binding var showCalories: Bool
    
    var stockElement: StockElement
    @Binding var selectedStockElement: StockElement?
    @Binding var activeSheet: StockInteractionSheet
    @Binding var isShowingSheet: Bool
    
    @State private var showDetailView: Bool = false
    
    var caloriesSum: String {
        if let calories = Double(stockElement.product.calories) {
            let sum = calories * Double(stockElement.amount)!
            return String(format: "%.0f", sum)
        } else { return stockElement.product.calories }
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
        StockTableRowActionsView(stockElement: stockElement, selectedStockElement: $selectedStockElement, activeSheet: $activeSheet, isShowingSheet: $isShowingSheet)
        
        if showProduct {
            HStack{
                Divider()
                Spacer()
                Text(stockElement.product.name)
                    .onTapGesture {
                        showDetailView.toggle()
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
        
        if showProductGroup {
            HStack{
                Divider()
                Spacer()
                Text(grocyVM.mdProductGroups.first(where:{ $0.id == stockElement.product.productGroupID})?.name ?? "Produkt group error")
                Spacer()
            }
            .background(backgroundColor)
            .foregroundColor((backgroundColor == Color.clear || colorScheme == .light) ? Color.primary : Color.black)
        }
        
        if showAmount {
            HStack{
                Divider()
                Spacer()
                Text("\(stockElement.amount) \(stockElement.amount == "1" ? quantityUnit.name : quantityUnit.namePlural)")
                if stockElement.amount != formattedAmountAggregated {
                    Text("Σ \(formattedAmountAggregated) \(formattedAmountAggregated == "1" ? quantityUnit.name : quantityUnit.namePlural)")
                        .foregroundColor(Color.grocyGray)
                }
                Spacer()
            }
            .background(backgroundColor)
            .foregroundColor((backgroundColor == Color.clear || colorScheme == .light) ? Color.primary : Color.black)
        }
        
        if showValue {
            HStack{
                Divider()
                Spacer()
                Text("\(stockElement.value) \(grocyVM.getCurrencySymbol())")
                Spacer()
            }
            .background(backgroundColor)
            .foregroundColor((backgroundColor == Color.clear || colorScheme == .light) ? Color.primary : Color.black)
        }
        if showNextBestBeforeDate {
            HStack{
                Divider()
                Spacer()
                Text(formatDateOutput(stockElement.bestBeforeDate) ?? "")
                Spacer()
            }
            .background(backgroundColor)
            .foregroundColor((backgroundColor == Color.clear || colorScheme == .light) ? Color.primary : Color.black)
        }
        if showCaloriesPerStockQU {
            HStack{
                Divider()
                Spacer()
                Text(stockElement.product.calories)
                Spacer()
            }
            .background(backgroundColor)
            .foregroundColor((backgroundColor == Color.clear || colorScheme == .light) ? Color.primary : Color.black)
        }
        if showCalories {
            HStack {
                Divider()
                Spacer()
                Text(caloriesSum)
                Spacer()
            }
            .background(backgroundColor)
            .foregroundColor((backgroundColor == Color.clear || colorScheme == .light) ? Color.primary : Color.black)
        }
    }
}

//struct StockTableRow_Previews: PreviewProvider {
//    static var previews: some View {
//        StockTableRow(expiringDays: 5, showProduct: Binding.constant(true), showProductGroup: Binding.constant(true), showAmount: Binding.constant(true), showValue: Binding.constant(true), showNextBestBeforeDate: Binding.constant(true), showCaloriesPerStockQU: Binding.constant(true), showCalories: Binding.constant(true), stockElement: StockElement(amount: "3", amountAggregated: "3", value: "25", bestBeforeDate: "2020-12-12", amountOpened: "1", amountOpenedAggregated: "1", isAggregatedAmount: "0", dueType: "1", productID: "3", product: MDProduct(id: "3", name: "Productname", mdProductDescription: "Description", productGroupID: "1", active: "1", locationID: "1", shoppingLocationID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "1", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1233", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "ts", userfields: nil)))
//    }
//}
