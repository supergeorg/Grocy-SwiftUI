//
//  StockFilterCapsuleView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 23.07.25.
//

import SwiftData
import SwiftUI

struct StockFilterCapsuleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        return userSettingsList.first
    }

    var num: Int?
    @Binding var filteredStatus: ProductStatus
    var ownFilteredStatus: ProductStatus
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
                Image(systemName: ownFilteredStatus.getIconName())
                if isSelected {
                    // Show full text
                    Text(ownFilteredStatus.getDescription(amount: num ?? 0, dueSoonDays: userSettings?.stockDueSoonDays ?? 5))
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
    @Previewable @State var filteredStatus: ProductStatus = .all

    StockFilterCapsuleView(filteredStatus: $filteredStatus, ownFilteredStatus: .all, color: .white, backgroundColor: Color(.GrocyColors.grocyBlue))
}
