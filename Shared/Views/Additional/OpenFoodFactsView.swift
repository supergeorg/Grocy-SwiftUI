//
//  OpenFoodFactsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 15.02.21.
//

import SwiftUI

struct OpenFoodFactsView: View {
    @ObservedObject var offVM: OpenFoodFactsViewModel
    
    init(barcode: String) {
        offVM = OpenFoodFactsViewModel(barcode: barcode)
    }
    
    var body: some View {
        Form{
            if let offData = offVM.offData {
                Text(offData.code)
                Text(offData.product.productName)
                Text(offData.product.productNameDe ?? "kein de name")
            }
        }
    }
}

//struct OpenFoodFactsView_Previews: PreviewProvider {
//    static var previews: some View {
////        OpenFoodFactsView()
//    }
//}
