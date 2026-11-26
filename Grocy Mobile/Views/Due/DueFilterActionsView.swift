//
//  DueFilterActionsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// The quick filters of the due agenda: one capsule per kind with its count, in the kind's color.
struct DueFilterActionsView: View {
    @Binding var filteredKind: DueKind?
    var kinds: [DueKind]
    var counts: [DueKind: Int]

    var body: some View {
        FilterCapsuleBar {
            ForEach(kinds) { kind in
                let isSelected = filteredKind == kind
                Button {
                    withAnimation {
                        filteredKind = isSelected ? nil : kind
                    }
                } label: {
                    HStack(spacing: Spacing.xSmall) {
                        Image(systemName: kind.icon)
                        if isSelected {
                            Text("\(Text(kind.title)): \(counts[kind] ?? 0)")
                                .transition(.blurReplace)
                        } else {
                            Text(String(counts[kind] ?? 0))
                                .bold()
                                .transition(.blurReplace)
                        }
                    }
                    // The selected filter is filled with its color, the others are tinted with it.
                    .foregroundStyle(isSelected ? Color.white : kind.color)
                }
                .filterCapsuleStyle(tint: isSelected ? kind.color : kind.backgroundColor)
                .accessibilityLabel(Text(kind.title))
                .accessibilityValue(Text(String(counts[kind] ?? 0)))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

#Preview {
    @Previewable @State var filteredKind: DueKind? = nil

    DueFilterActionsView(filteredKind: $filteredKind, kinds: DueKind.allCases, counts: [.product: 2, .belowMinStock: 4, .chore: 3, .task: 1, .battery: 0])
}
