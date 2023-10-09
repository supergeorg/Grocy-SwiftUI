//
//  AmountSelectionView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 14.10.21.
//

import SwiftUI

struct AmountSelectionView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Binding var productID: Int?
    @Binding var amount: Double
    @Binding var quantityUnitID: Int?
    
    private var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productID})
    }
    
    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        if let quIDStock = product?.quIDStock {
            return grocyVM.mdQuantityUnitConversions.filter({ $0.toQuID == quIDStock })
        } else { return [] }
    }
    
    private var currentQuantityUnit: MDQuantityUnit? {
        if let quantityUnitID = quantityUnitID {
            return grocyVM.mdQuantityUnits.first(where: {$0.id == quantityUnitID})
        } else { return nil }
    }
    private var currentQuantityUnitName: String? {
        return amount == 1 ? currentQuantityUnit?.name : currentQuantityUnit?.namePlural ?? currentQuantityUnit?.name
    }
    private var factoredAmount: Double {
        return amount * (quantityUnitConversions.first(where: { $0.fromQuID == quantityUnitID})?.factor ?? 1)
    }
    private var stockQuantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }
    private var stockQuantityUnitName: String? {
        return factoredAmount == 1 ? stockQuantityUnit?.name : stockQuantityUnit?.namePlural ?? stockQuantityUnit?.name
    }
    
    var body: some View {
        Section(header: Text("Amount").font(.headline)) {
            VStack(alignment: .leading) {
                MyDoubleStepper(
                    amount: $amount,
                    description: "Amount",
                    amountStep: 1.0,
                    amountName: currentQuantityUnitName,
                    systemImage: MySymbols.amount
                )
            }
            
            VStack(alignment: .leading) {
                Picker(selection: $quantityUnitID,
                       label: Label("Quantity unit", systemImage: MySymbols.quantityUnit).foregroundStyle(.primary),
                       content: {
                    Text("").tag(nil as Int?)
                    if let stockQU = grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDStock }) {
                        Text(stockQU.name).tag(stockQU.id as Int?)
                    }
                    ForEach(quantityUnitConversions, id:\.id, content: { quConversion in
                        Text(grocyVM.mdQuantityUnits.first(where: { $0.id == quConversion.fromQuID})?.name ?? String(quConversion.fromQuID))
                            .tag(quConversion.fromQuID as Int?)
                    })
                })
                .disabled(quantityUnitConversions.isEmpty)
                if quantityUnitID == nil {
                    Text("A quantity unit is required")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

//struct AmountSelectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        AmountSelectionView()
//    }
//}
