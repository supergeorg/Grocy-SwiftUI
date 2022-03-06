//
//  QuickScanOpenFoodFactsView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 14.12.21.
//

import SwiftUI

struct QuickScanOpenFoodFactsView: View {
    var barcode: String?
    
    var body: some View {
        if let barcode = barcode {
            OpenFoodFactsNewProductView(barcode: barcode)
        } else {
            Text("No Barcode")
        }
    }
}

struct QuickScanOpenFoodFactsView_Previews: PreviewProvider {
    static var previews: some View {
        QuickScanOpenFoodFactsView()
    }
}
