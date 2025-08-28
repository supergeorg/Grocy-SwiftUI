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
                    .foregroundColor(color)
                if filteredStatus == ownFilteredStatus {
                    Text(ownFilteredStatus.getDescription(amount: num ?? 0))
                        .foregroundColor(color)
                } else {
                    Text(String(num ?? 0))
                        .bold()
                        .foregroundColor(color)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .glassEffect(.regular.tint(backgroundColor).interactive())
        }
    }
}

#Preview {
    ShoppingListFilterCapsuleView(filteredStatus: .init(projectedValue: .constant(.all)), ownFilteredStatus: .all, color: .white, backgroundColor: Color(.GrocyColors.grocyBlue))
}
