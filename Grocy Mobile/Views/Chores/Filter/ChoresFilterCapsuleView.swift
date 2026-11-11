//
//  ChoresFilterCapsuleView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 10.12.25.
//

import SwiftData
import SwiftUI

struct ChoresFilterCapsuleView: View {
    var num: Int?
    @Binding var filteredStatus: ChoreStatus
    var ownFilteredStatus: ChoreStatus
    var color: Color
    var backgroundColor: Color
    var dueSoonDays: Int?

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
                Image(systemName: ownFilteredStatus.icon)
                if isSelected {
                    // Show full text
                    Text(ownFilteredStatus.getDescription(amount: num ?? 0, dueSoonDays: dueSoonDays ?? 5))
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
