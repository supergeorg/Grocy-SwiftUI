//
//  ShoppingListFilterActionView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 27.11.20.
//

import SwiftUI

private struct ShoppingListFilterItemView: View {
    @Binding var filteredStatus: ShoppingListStatus

    var ownFilteredStatus: ShoppingListStatus
    var num: Int
    var color: Color
    var backgroundColor: Color

    var body: some View {
        VStack(spacing: 0.0) {
            Divider()
                .hidden()
                .frame(height: 10.0)
                .background(color)
            HStack {
                if filteredStatus == ownFilteredStatus {
                    Image(systemName: MySymbols.filter)
                }
                Text(ownFilteredStatus.getDescription(amount: num))
                    .bold()
                    .foregroundStyle(color)
            }
            .padding(.horizontal, 10.0)
            .padding(.top, 10.0)
            .padding(.bottom, 10.0)
            .background(backgroundColor)
        }
        .fixedSize()
        .cornerRadius(5.0)
        .onTapGesture {
            if filteredStatus != ownFilteredStatus {
                filteredStatus = ownFilteredStatus
            } else {
                filteredStatus = ShoppingListStatus.all
            }
        }
    }
}

struct ShoppingListFilterActionView: View {
    @Binding var filteredStatus: ShoppingListStatus

    var numBelowStock: Int
    var numDone: Int
    var numUndone: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
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
                        color: Color(.GrocyColors.grocyGray),
                        backgroundColor: Color(.GrocyColors.grocyBlueBackground)
                    )
                    .animation(.default, value: numBelowStock)
                }
            }
        }
    }
}

#Preview {
    ShoppingListFilterActionView(filteredStatus: Binding.constant(.all), numBelowStock: 1, numDone: 1, numUndone: 1)
}
