//
//  RowIconLabelStyle.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// Puts a Label's icon in a column of fixed width, so the titles of several rows line up although symbols differ in width.
/// A List gives a row's Label such a column only when the Label is the row's direct content; a Label inside an HStack, a VStack
/// or a component (like `MyDoubleStepper`) gets the plain spacing. This style looks the same in either case.
struct RowIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        RowIconLabel(configuration: configuration)
    }

    private struct RowIconLabel: View {
        var configuration: LabelStyleConfiguration
        /// Follows the text size (Dynamic Type), so larger symbols still fit.
        @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = Sizes.rowIconWidth

        var body: some View {
            HStack(spacing: Spacing.medium) {
                // In the text color, like the row's title. Icons with their own color (status symbols) keep it.
                // In a List this isn't enough: it tints the icons of some rows; add `.listItemTint(Color.primary)` there.
                configuration.icon
                    .foregroundStyle(Color.primary)
                    .frame(width: iconWidth)
                configuration.title
            }
        }
    }
}

extension LabelStyle where Self == RowIconLabelStyle {
    /// See `RowIconLabelStyle`.
    static var rowIcon: RowIconLabelStyle { RowIconLabelStyle() }
}

#Preview {
    List {
        Label("Servings", systemImage: MySymbols.servings)
        Label("Energy", systemImage: MySymbols.energy)
        HStack {
            Label("Costs", systemImage: MySymbols.price)
        }
    }
    .labelStyle(.rowIcon)
}
