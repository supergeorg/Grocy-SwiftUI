//
//  AppleIntelligenceSymbol.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// The colors that mark content and work from Apple Intelligence.
enum AppleIntelligenceStyle {
    static let gradient = LinearGradient(colors: [.blue, .purple, .pink], startPoint: .leading, endPoint: .trailing)
}

/// The Apple Intelligence symbol in its gradient. While `isActive`, it animates to show that the model is working.
struct AppleIntelligenceSymbol: View {
    var isActive: Bool = false

    var body: some View {
        Image(systemName: MySymbols.appleIntelligence)
            .symbolEffect(.variableColor.iterative.reversing, options: .speed(0.5), isActive: isActive)
            .foregroundStyle(AppleIntelligenceStyle.gradient)
            .accessibilityHidden(true)
    }
}

/// A progress bar in the Apple Intelligence gradient. The gradient spans the whole bar and is revealed as the work progresses.
struct AppleIntelligenceProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        let fraction = min(max(configuration.fractionCompleted ?? 0, 0), 1)
        Capsule()
            .fill(.quaternary)
            .overlay {
                AppleIntelligenceStyle.gradient
                    .mask(alignment: .leading) {
                        Rectangle()
                            .scaleEffect(x: fraction, anchor: .leading)
                    }
            }
            .clipShape(.capsule)
            .frame(height: Spacing.xxSmall)
            .animation(.default, value: fraction)
    }
}

#Preview {
    VStack(spacing: Spacing.large) {
        AppleIntelligenceSymbol()
        AppleIntelligenceSymbol(isActive: true)
        ProgressView(value: 0.4)
            .progressViewStyle(AppleIntelligenceProgressViewStyle())
    }
    .padding()
    .font(.largeTitle)
}
