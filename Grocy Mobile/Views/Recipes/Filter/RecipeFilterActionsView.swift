//
//  RecipeFilterActionsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 05.02.26.
//

import SwiftUI

struct RecipeFilterActionsView: View {
    @Binding var filteredStatus: RecipeStatus

    var enoughInStockCount: Int
    var alreadyOnShoppingListCount: Int
    var notEnoughInStockCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                RecipeFilterCapsuleView(num: enoughInStockCount, filteredStatus: $filteredStatus, ownFilteredStatus: .enoughInStock, color: Color(.GrocyColors.grocyGreen), backgroundColor: Color(.GrocyColors.grocyGreenBackground))
                RecipeFilterCapsuleView(num: alreadyOnShoppingListCount, filteredStatus: $filteredStatus, ownFilteredStatus: .alreadyOnShoppingList, color: Color(.GrocyColors.grocyYellow), backgroundColor: Color(.GrocyColors.grocyYellowBackground))
                RecipeFilterCapsuleView(num: notEnoughInStockCount, filteredStatus: $filteredStatus, ownFilteredStatus: .notEnoughInStock, color: Color(.GrocyColors.grocyRed), backgroundColor: Color(.GrocyColors.grocyRedBackground))
            }
            .padding(.horizontal)
        }
        .scrollClipDisabled()
    }
}

#Preview {
    @Previewable @State var filteredStatus: RecipeStatus = .all

    RecipeFilterActionsView(filteredStatus: $filteredStatus, enoughInStockCount: 1, alreadyOnShoppingListCount: 2, notEnoughInStockCount: 3)
}
