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
/// Show it with `floatingTopBar { … }` on the list or scroll view. Apply the overview's `.refreshable` before
/// `floatingTopBar`. Applied after it, the refresh action reaches this scroll view through the environment as well,
/// and the capsules get pull-to-refresh.
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

#if os(iOS)
    /// See `floatingTopBar(content:)`.
    private struct FloatingTopBarModifier<Bar: View>: ViewModifier {
        let bar: Bar
        @State private var barHeight: CGFloat = 0
        /// How far the content is pulled down past its top (pull-to-refresh).
        @State private var overscroll: CGFloat = 0
        /// Whether content is scrolled under the bar.
        @State private var isContentUnderBar = false

        func body(content: Content) -> some View {
            content
                .contentMargins(.top, barHeight, for: .scrollContent)
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    // Zero at the top, negative while pulled down
                    (geometry.contentOffset.y + geometry.contentInsets.top).rounded()
                } action: { _, offset in
                    overscroll = max(0, -offset)
                    let isUnder = offset > 0
                    if isUnder != isContentUnderBar {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isContentUnderBar = isUnder
                        }
                    }
                }
                .overlay(alignment: .top) {
                    // The stack also reports a height of zero when the bar's content is empty
                    VStack(spacing: 0) {
                        bar
                    }
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        barHeight = height
                    }
                    .background {
                        if barHeight > 0 {
                            edgeBlur
                                .opacity(isContentUnderBar ? 1 : 0)
                        }
                    }
                    // Moves down with the content while pulling to refresh, so the bar stays below the search field
                    .offset(y: overscroll)
                }
        }

        /// Approximates the soft scroll edge effect of a `safeAreaBar`: the content blurs and fades out under the bar.
        /// It reaches up under the navigation bar, so there's no sharp edge between the two.
        private var edgeBlur: some View {
            Rectangle()
                .fill(.regularMaterial)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.6),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .padding(.bottom, -Spacing.small)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
        }
    }
#endif

extension View {
    /// Floats a bar (filter capsules, a period switcher) above the list or scroll view, below the navigation bar.
    ///
    /// On iOS the bar doesn't change the safe area. A bar in the safe area (`safeAreaBar`, and less often
    /// `safeAreaInset`) below a large title feeds back into the navigation bar's collapse: the scroll view's top inset
    /// follows the navigation bar's height, which follows the scroll offset. When scrolling back to the top, the title
    /// can get stuck half collapsed, flickering, with the search field hidden or half shown. So the bar is an overlay,
    /// and the scroll content gets a constant top margin of the bar's height. On macOS the title doesn't collapse, so
    /// the bar keeps the scroll edge effect of a `safeAreaBar`.
    func floatingTopBar(@ViewBuilder content: () -> some View) -> some View {
        #if os(iOS)
            modifier(FloatingTopBarModifier(bar: content()))
        #else
            safeAreaBar(edge: .top, content: content)
        #endif
    }

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
