//
//  ShoppingListRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 13.09.25.
//

import SwiftData
import SwiftUI

struct ShoppingListRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups
    @Query(sort: \MDStore.id, order: .forward) var mdStores: MDStores

    @Environment(\.colorScheme) var colorScheme

    var shoppingListItem: ShoppingListItem
    var isBelowStock: Bool

    var product: MDProduct? {
        mdProducts.first(where: { $0.id == shoppingListItem.productID })
    }

    var quantityUnit: MDQuantityUnit? {
        mdQuantityUnits.first(where: { $0.id == product?.quIDPurchase })
    }

    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        mdQuantityUnitConversions.filter { $0.toQuID == shoppingListItem.quID }
    }

    private var factoredAmount: Double {
        shoppingListItem.amount * (quantityUnitConversions.first(where: { $0.fromQuID == shoppingListItem.quID })?.factor ?? 1)
    }

    var amountString: String {
        if let quantityUnit = quantityUnit {
            return "\(factoredAmount.formattedAmount) \(quantityUnit.getName(amount: factoredAmount))"
        } else {
            return "\(factoredAmount.formattedAmount)"
        }
    }

    var body: some View {
        HStack {
            #if os(macOS)
                ShoppingListRowActionsView(shoppingListItem: shoppingListItem)
            #endif
            VStack(alignment: .leading) {
                Text(product?.name ?? shoppingListItem.note ?? "?")
                    .font(.headline)
                    .strikethrough(shoppingListItem.done == 1)
                Text("\(Text("Amount")): \(amountString)")
                    .strikethrough(shoppingListItem.done == 1)
            }
            .foregroundStyle(shoppingListItem.done == 1 ? Color.gray : Color.primary)
        }
    }
}
