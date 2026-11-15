//
//  ShoppingListFilterActionView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 27.11.20.
//

import SwiftUI

struct ShoppingListFilterActionView: View {
    @Binding var filteredStatus: ShoppingListStatus

    var numBelowStock: Int
    var numDone: Int
    var numUndone: Int

    var body: some View {
        FilterCapsuleBar {
            if numUndone > 0 {
                // Undone items
                ShoppingListFilterCapsuleView(num: numUndone, filteredStatus: $filteredStatus, ownFilteredStatus: ShoppingListStatus.undone, color: Color(.GrocyColors.grocyGray), backgroundColor: Color(.GrocyColors.grocyGrayBackground))
                    .animation(.default, value: numUndone)
            }
            if numDone > 0 {
                // Done items
                ShoppingListFilterCapsuleView(num: numDone, filteredStatus: $filteredStatus, ownFilteredStatus: ShoppingListStatus.done, color: .white, backgroundColor: Color(.GrocyColors.grocyGreen))
                    .animation(.default, value: numDone)
            }
            if numBelowStock > 0 {
                // Below stock
                ShoppingListFilterCapsuleView(
                    num: numBelowStock,
                    filteredStatus: $filteredStatus,
                    ownFilteredStatus: ShoppingListStatus.belowMinStock,
                    color: Color(.GrocyColors.grocyBlue),
                    backgroundColor: Color(.GrocyColors.grocyBlueBackground)
                )
                .animation(.default, value: numBelowStock)
            }
        }
    }
}

#Preview {
    ShoppingListFilterActionView(filteredStatus: Binding.constant(.all), numBelowStock: 1, numDone: 1, numUndone: 1)
}
