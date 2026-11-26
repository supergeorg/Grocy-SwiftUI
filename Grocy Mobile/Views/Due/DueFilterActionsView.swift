//
//  DueFilterActionsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// The quick filters of the due agenda: one capsule per kind (products, below min. stock, chores, tasks, batteries) with its count.
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
                    // Each kind in its own color, as the stock overview's filters; the selected one also shows its name.
                    .foregroundStyle(kind.color)
                }
                .filterCapsuleStyle(tint: kind.backgroundColor)
                .accessibilityLabel(Text(kind.title))
                .accessibilityValue(Text(String(counts[kind] ?? 0)))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

#Preview {
    @Previewable @State var filteredKind: DueKind? = nil

    DueFilterActionsView(filteredKind: $filteredKind, kinds: DueKind.allCases, counts: [.chore: 3, .task: 1, .battery: 0])
}
