//
//  StockTableConfigView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

//    var showProduct = true
//    var showProductGroup = false
//    var showAmount = true
//    var showValue = false
//    var showNextBestBeforeDate = true
//    var showCaloriesPerStockQU = false
//    var showCalories = false

struct StockTableConfigView: View {
    @Binding var showProduct: Bool
    @Binding var showProductGroup: Bool
    @Binding var showAmount: Bool
    @Binding var showValue: Bool
    @Binding var showNextBestBeforeDate: Bool
    @Binding var showCaloriesPerStockQU: Bool
    @Binding var showCalories: Bool
    
    var body: some View {
        Form() {
            Toggle("str.stock.tbl.product", isOn: $showProduct)
            Toggle("str.stock.tbl.productGroup", isOn: $showProductGroup)
            Toggle("str.stock.tbl.amount", isOn: $showAmount)
            Toggle("str.stock.tbl.value", isOn: $showValue)
            Toggle("str.stock.tbl.nextBestBefore", isOn: $showNextBestBeforeDate)
            Toggle("str.stock.tbl.caloriesPerStockQU", isOn: $showCaloriesPerStockQU)
            Toggle("str.stock.tbl.calories", isOn: $showCalories)
        }
    }
}

//struct StockTableConfigView_Previews: PreviewProvider {
//    static var previews: some View {
//        StockTableConfigView(shownColumns: Binding.constant([(.product, false)]))
//    }
//}
