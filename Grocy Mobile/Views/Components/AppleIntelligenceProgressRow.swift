//
//  AppleIntelligenceProgressRow.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// Shows that Apple Intelligence is working, how far it is, and lets the person stop it.
/// The symbol animates and the bar fills in the Apple Intelligence gradient.
struct AppleIntelligenceProgressRow: View {
    var title: LocalizedStringKey
    /// What the model is doing, e.g. "3 of 8 ingredients".
    var detail: Text
    var completed: Int
    var total: Int
    var onStop: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
                AppleIntelligenceSymbol(isActive: true)
                    .font(.title3)
                VStack(alignment: .leading, spacing: Spacing.hairline) {
                    Text(title)
                        .font(.headline)
                    detail
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(completed)))
                }
                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer(minLength: Spacing.small)
                    stopButton
                }
            }
            ProgressView(value: Double(completed), total: Double(max(total, 1)))
                .progressViewStyle(AppleIntelligenceProgressViewStyle())
                .accessibilityLabel(Text(title))
                .accessibilityValue(detail)
            // With accessibility text sizes, the title needs the whole width; next to it, the button's title would break mid-word.
            if dynamicTypeSize.isAccessibilitySize {
                stopButton
            }
        }
        .padding(.vertical, Spacing.xxSmall)
        .animation(.default, value: completed)
    }

    private var stopButton: some View {
        Button("Stop", action: onStop)
            .buttonStyle(.bordered)
            .controlSize(.small)
            .fixedSize()
    }
}

#Preview {
    Form {
        AppleIntelligenceProgressRow(title: "Finding products with Apple Intelligence", detail: Text("\(3) of \(8) ingredients"), completed: 3, total: 8, onStop: {})
    }
}
