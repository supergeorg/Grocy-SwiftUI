//
//  StockFilterCapsuleView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 23.07.25.
//

import SwiftData
import SwiftUI

struct StockFilterCapsuleView: View {
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        return userSettingsList.first
    }

    var num: Int?
    @Binding var filteredStatus: ProductStatus
    var ownFilteredStatus: ProductStatus
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
                Image(systemName: ownFilteredStatus.getIconName())
                    .foregroundColor(color)
                if filteredStatus == ownFilteredStatus {
                    // Show full text
                    Text(ownFilteredStatus.getDescription(amount: num ?? 0, dueSoonDays: userSettings?.stockDueSoonDays ?? 5))
                        .foregroundColor(color)
                } else {
                    // Show only number
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
    @Previewable @State var filteredStatus: ProductStatus = .all

    StockFilterCapsuleView(filteredStatus: $filteredStatus, ownFilteredStatus: .all, color: .white, backgroundColor: Color(.GrocyColors.grocyBlue))
}
