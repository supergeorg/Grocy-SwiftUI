//
//  AmountSelectionView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 14.10.21.
//

import SwiftUI

struct AmountSelectionView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Binding var productID: Int?
    @Binding var amount: Double
    @Binding var quantityUnitID: Int?
    
    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        if let quIDStock = product?.quIDStock {
            return grocyVM.mdQuantityUnitConversions.filter({ $0.toQuID == quIDStock })
        } else { return [] }
    }

    private var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productID})
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
        Section(header: Text(LocalizedStringKey("str.stock.product.amount")).font(.headline)) {
            VStack(alignment: .leading) {
                MyDoubleStepper(amount: $amount, description: "str.stock.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: currentQuantityUnitName, errorMessage: "str.stock.product.amount.invalid", systemImage: MySymbols.amount)
                if factoredAmount != amount {
                    Text(LocalizedStringKey("str.stock.product.amount.factored \(factoredAmount.formattedAmount) \(stockQuantityUnitName ?? "")"))
                        .font(.caption)
                        .foregroundColor(Color.grocyTurquoise)
                }
            }
            
            Picker(selection: $quantityUnitID,
                   label: Label(LocalizedStringKey("str.stock.product.quantityUnit"), systemImage: MySymbols.quantityUnit),
                   content: {
                if let stockQU = grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDStock }) {
                    Text(stockQU.name).tag(stockQU.id as Int?)
                }
                ForEach(quantityUnitConversions, id:\.id, content: { quConversion in
                    Text(grocyVM.mdQuantityUnits.first(where: { $0.id == quConversion.fromQuID})?.name ?? String(quConversion.fromQuID))
                        .tag(quConversion.fromQuID as Int?)
                })
            }).disabled(quantityUnitConversions.isEmpty)
        }
    }
}

//struct AmountSelectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        AmountSelectionView()
//    }
//}
