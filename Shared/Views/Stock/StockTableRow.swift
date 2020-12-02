//
//  StockRowView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 29.10.20.
//

import SwiftUI

//struct StockTableRow: View {
//    @StateObject var grocyVM: GrocyViewModel = .shared
//    
//    var stockElement: StockElement
//    
//    var body: some View {
//        VStack(alignment: .leading){
//            Text(stockElement.product.name).font(.title)
//            HStack{
//                Text("\(stockElement.amount) (\(stockElement.amountOpened) geöffnet)")
//                Text("Nächstes MHD: \(formatDateOutput(stockElement.bestBeforeDate))")
////                Text("Standort: \(grocyVM.mdLocations.first(where: { $0.id ==  stockElement.product.locationID})?.name ?? "Fehler")")
//            }
//            .font(.caption)
//        }
//    }
//}

struct StockTableRow: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Binding var showProduct: Bool
    @Binding var showProductGroup: Bool
    @Binding var showAmount: Bool
    @Binding var showValue: Bool
    @Binding var showNextBestBeforeDate: Bool
    @Binding var showCaloriesPerStockQU: Bool
    @Binding var showCalories: Bool
    
    var stockElement: StockElement
    
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
    
    var body: some View {
        HStack{
            if showProduct {
                Text(stockElement.product.name)
            }
            if showProductGroup {
                Spacer()
                Text(grocyVM.mdProductGroups.first(where:{ $0.id == stockElement.product.productGroupID})?.name ?? "ProduktGruppe")
            }
            if showAmount {
                Spacer()
                Text("\(stockElement.amount) \(stockElement.amount == "1" ? quantityUnit.name : quantityUnit.namePlural)")
            }
            if showValue {
                Spacer()
                Text("\(stockElement.value) \(grocyVM.systemConfig?.currency ?? "[Currency]")")
            }
            if showNextBestBeforeDate {
                Spacer()
                Text(formatDateOutput(stockElement.bestBeforeDate) ?? "")
            }
            if showCaloriesPerStockQU {
                Spacer()
                Text(stockElement.product.calories)
            }
            if showCalories {
                Spacer()
                Text(caloriesSum)
            }
        }
        .onTapGesture {
            showDetailView.toggle()
        }
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

//struct StockRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        StockRowView(stockElement: StockElement(amount: 3, amountAggregated: "3", bestBeforeDate: "2020-12-12", amountOpened: "2", amountOpenedAggregated: "2", isAggregatedAmount: "false", productID: "3", product: MDProduct(id: <#T##String#>, name: <#T##String#>, mdProductDescription: <#T##String#>, locationID: <#T##String#>, quIDPurchase: <#T##String#>, quIDStock: <#T##String#>, quFactorPurchaseToStock: <#T##String#>, barcode: <#T##String#>, minStockAmount: <#T##String#>, defaultBestBeforeDays: <#T##String#>, rowCreatedTimestamp: <#T##String#>, productGroupID: <#T##String#>, pictureFileName: <#T##String?#>, defaultBestBeforeDaysAfterOpen: <#T##String#>, allowPartialUnitsInStock: <#T##String#>, enableTareWeightHandling: <#T##String#>, tareWeight: <#T##String#>, notCheckStockFulfillmentForRecipes: <#T##String#>, parentProductID: <#T##String?#>, calories: <#T##String#>, cumulateMinStockAmountOfSubProducts: <#T##String#>, defaultBestBeforeDaysAfterFreezing: <#T##String#>, defaultBestBeforeDaysAfterThawing: <#T##String#>, shoppingLocationID: <#T##String#>, userfields: <#T##String?#>)))
//    }
//}
