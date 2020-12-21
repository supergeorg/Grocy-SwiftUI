//
//  StockTableConfigView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

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
            Toggle(LocalizedStringKey("str.stock.tbl.product"), isOn: $showProduct)
            Toggle(LocalizedStringKey("str.stock.tbl.productGroup"), isOn: $showProductGroup)
            Toggle(LocalizedStringKey("str.stock.tbl.amount"), isOn: $showAmount)
            Toggle(LocalizedStringKey("str.stock.tbl.value"), isOn: $showValue)
            Toggle(LocalizedStringKey("str.stock.tbl.nextBestBefore"), isOn: $showNextBestBeforeDate)
            Toggle(LocalizedStringKey("str.stock.tbl.caloriesPerStockQU"), isOn: $showCaloriesPerStockQU)
            Toggle(LocalizedStringKey("str.stock.tbl.calories"), isOn: $showCalories)
        }
    }
}

struct StockTableConfigView_Previews: PreviewProvider {
    static var previews: some View {
        StockTableConfigView(showProduct: Binding.constant(true), showProductGroup: Binding.constant(true), showAmount: Binding.constant(true), showValue: Binding.constant(true), showNextBestBeforeDate: Binding.constant(true), showCaloriesPerStockQU: Binding.constant(true), showCalories: Binding.constant(true))
    }
}
