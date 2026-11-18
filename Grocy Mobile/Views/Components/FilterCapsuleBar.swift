//
//  FilterCapsuleBar.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 11.11.26.
//

import SwiftUI

/// A horizontally scrolling bar of glass filter capsules, shared by all `…FilterActionsView`s.
///
/// Uses a `GlassEffectContainer` so the capsules render as one consistent glass group on all platforms.
/// Style the capsules themselves with `filterCapsuleStyle(tint:)`.
///
/// Apply the overview's `.refreshable` before the `.safeAreaBar` holding this bar. Applied after it, the refresh
/// action reaches this scroll view through the environment as well, and the capsules get pull-to-refresh.
struct FilterCapsuleBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: Spacing.xxSmall) {
                HStack(spacing: Spacing.small) {
                    content
                }
            }
            .padding(.horizontal)
        }
        .scrollClipDisabled()
    }
}

extension View {
    /// Styles a filter capsule button with tinted, interactive Liquid Glass.
    ///
    /// The glass button style (instead of a `.glassEffect(...)` on the label) is required for the
    /// press/drag interaction, because the button consumes the touches itself.
    func filterCapsuleStyle(tint: Color) -> some View {
        self
            .buttonStyle(.glass(.regular.tint(tint)))
            .controlSize(.large)
    }
}

#Preview {
    @Previewable @State var filteredStatus: ProductStatus = .all

    List {
        Section {
            FilterCapsuleBar {
                StockFilterCapsuleView(
                    num: 1,
                    filteredStatus: $filteredStatus,
                    ownFilteredStatus: .expiringSoon,
                    color: Color(.GrocyColors.grocyYellow),
                    backgroundColor: Color(.GrocyColors.grocyYellowBackground)
                )
                StockFilterCapsuleView(
                    num: 2,
                    filteredStatus: $filteredStatus,
                    ownFilteredStatus: .expired,
                    color: Color(.GrocyColors.grocyRed),
                    backgroundColor: Color(.GrocyColors.grocyRedBackground)
                )
            }
            .listRowInsets(EdgeInsets())
        }
    }
}
