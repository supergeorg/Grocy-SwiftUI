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
            Toggle("Product", isOn: $showProduct)
            Toggle("Product group", isOn: $showProductGroup)
            Toggle("Amount", isOn: $showAmount)
            Toggle("Value", isOn: $showValue)
            Toggle("Next due date", isOn: $showNextBestBeforeDate)
            Toggle("Calories (Per stock quantity unit)", isOn: $showCaloriesPerStockQU)
            Toggle("Calories", isOn: $showCalories)
        }
    }
}

struct StockTableConfigView_Previews: PreviewProvider {
    static var previews: some View {
        StockTableConfigView(showProduct: Binding.constant(true), showProductGroup: Binding.constant(true), showAmount: Binding.constant(true), showValue: Binding.constant(true), showNextBestBeforeDate: Binding.constant(true), showCaloriesPerStockQU: Binding.constant(true), showCalories: Binding.constant(true))
    }
}
