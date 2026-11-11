//
//  RecipeFilterCapsuleView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 05.02.26.
//

import SwiftData
import SwiftUI

struct RecipeFilterCapsuleView: View {
    var num: Int?
    @Binding var filteredStatus: RecipeStatus
    var ownFilteredStatus: RecipeStatus
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
                Text(String(num ?? 0))
                    .bold()
                if isSelected {
                    // Show full text
                    Text(ownFilteredStatus.rawValue)
                        .transition(.blurReplace)
                }
            }
            .foregroundStyle(color)
        }
        .filterCapsuleStyle(tint: backgroundColor)
    }
}

#Preview {
    @Previewable @State var filteredStatus: RecipeStatus = .all

    RecipeFilterCapsuleView(filteredStatus: $filteredStatus, ownFilteredStatus: .all, color: .white, backgroundColor: Color(.GrocyColors.grocyBlue))
}
