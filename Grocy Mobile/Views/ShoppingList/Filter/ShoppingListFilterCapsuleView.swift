//
//  ShoppingListFilterCapsuleView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 28.08.25.
//

import SwiftData
import SwiftUI

struct ShoppingListFilterCapsuleView: View {
    var num: Int?
    @Binding var filteredStatus: ShoppingListStatus
    var ownFilteredStatus: ShoppingListStatus
    var color: Color
    var backgroundColor: Color

    private var isSelected: Bool {
        filteredStatus == ownFilteredStatus
    }

    var body: some View {
        Button(action: {
            withAnimation {
                if filteredStatus == ownFilteredStatus {
                    filteredStatus = .all
                } else {
                    filteredStatus = ownFilteredStatus
                }
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: ownFilteredStatus.getIcon())
                if isSelected {
                    // Show full text
                    Text(ownFilteredStatus.getDescription(amount: num ?? 0))
                        .transition(.blurReplace)
                } else {
                    // Show only number
                    Text(String(num ?? 0))
                        .bold()
                        .transition(.blurReplace)
                }
            }
            .foregroundStyle(color)
        }
        .filterCapsuleStyle(tint: backgroundColor)
    }
}

#Preview {
    ShoppingListFilterCapsuleView(filteredStatus: .init(projectedValue: .constant(.all)), ownFilteredStatus: .all, color: .white, backgroundColor: Color(.GrocyColors.grocyBlue))
}
