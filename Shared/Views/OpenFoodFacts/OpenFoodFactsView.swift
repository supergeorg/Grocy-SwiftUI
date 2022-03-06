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
        Form {
            if let offData = offVM.offData {
                Text(offData.code)
                Text(offData.product.productName)
                Text(offData.product.productNameDe ?? "kein en name")
                Text(offData.product.productNameDe ?? "kein de name")
                Text(offData.product.productNameFr ?? "kein fr name")
                Text(offData.product.productNamePl ?? "kein pl name")
            } else {
                Text("NO OFF DATA FOUND")
            }
        }
        .navigationTitle(LocalizedStringKey("OPEN FOOD FACTS"))
    }
}

//struct OpenFoodFactsView_Previews: PreviewProvider {
//    static var previews: some View {
////        OpenFoodFactsView()
//    }
//}
