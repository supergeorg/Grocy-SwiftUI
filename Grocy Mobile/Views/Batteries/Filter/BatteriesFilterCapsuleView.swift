//
//  BatteriesFilterCapsuleView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftUI

struct BatteriesFilterCapsuleView: View {
    var num: Int?
    @Binding var filteredStatus: BatteryStatus
    var ownFilteredStatus: BatteryStatus
    var dueSoonDays: Int?

    private var isSelected: Bool {
        filteredStatus == ownFilteredStatus
    }

    var body: some View {
        Button(action: {
            withAnimation {
                filteredStatus = isSelected ? .all : ownFilteredStatus
            }
        }) {
            HStack(spacing: Spacing.xSmall) {
                Image(systemName: ownFilteredStatus.icon)
                if isSelected {
                    Text(ownFilteredStatus.getDescription(amount: num ?? 0, dueSoonDays: dueSoonDays ?? 5))
                        .transition(.blurReplace)
                } else {
                    Text(String(num ?? 0))
                        .bold()
                        .transition(.blurReplace)
                }
            }
            .foregroundStyle(ownFilteredStatus.color)
        }
        .filterCapsuleStyle(tint: ownFilteredStatus.backgroundColor ?? .clear)
        // Without the selected text, the capsule only shows a number, so VoiceOver gets the full description.
        .accessibilityLabel(Text(ownFilteredStatus.getDescription(amount: num ?? 0, dueSoonDays: dueSoonDays ?? 5)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var filteredStatus: BatteryStatus = .all

    BatteriesFilterCapsuleView(num: 2, filteredStatus: $filteredStatus, ownFilteredStatus: .overdue)
}
