//
//  Constants.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 29.01.21.
//

import Foundation

struct Constants {
#if os(macOS)
    static let macOSNavWidth: CGFloat = 300.0
    static let macOSSettingsWidth: CGFloat = 500.0
    static let macOSSettingsHeight: CGFloat = 400.0
    static let macOSMinWindowWidth: CGFloat = 500.0
    static let macOSStockEntriesMinWidth: CGFloat = 350.0
    /// Number fields next to a stepper; macOS text fields would otherwise take the whole row.
    static let macOSAmountFieldWidth: CGFloat = 90.0
#endif
}

/// The app's spacing scale, for the few places the system doesn't provide one
/// (tight groups inside rows, chips and cards). Prefer the system default (omit the value) wherever it fits,
/// and use these steps instead of ad-hoc numbers otherwise, so spacing stays consistent.
enum Spacing {
    static let hairline: CGFloat = 2
    static let xxSmall: CGFloat = 4
    static let xSmall: CGFloat = 6
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 20
}

/// Fixed sizes of elements whose size doesn't come from text (pictures, avatars, glass buttons, decorative bars).
enum Sizes {
    /// HIG minimum hit region for touch.
    static let minimumHitTarget: CGFloat = 44
    static let productThumbnail: CGFloat = 75
    static let picturePreview: CGFloat = 300
    static let avatar: CGFloat = 40
    /// Width of a leading row symbol column, so names line up although symbols differ in width (scaled with Dynamic Type).
    static let rowIconWidth: CGFloat = 30
    static let navigationLogoHeight: CGFloat = 28
    static let toolbarDividerHeight: CGFloat = 20
    static let colorIndicatorHeight: CGFloat = 4
    static let preparationEditorMinHeight: CGFloat = 400
    static let noteEditorMinHeight: CGFloat = 50
    static let recipeTitleFadeHeight: CGFloat = 110
    static let recipeScoreMinWidth: CGFloat = 60
    static let parserTextHeight: CGFloat = 200
    static let parserResultMaxHeight: CGFloat = 300
    static let popoverFormSize: CGFloat = 500
}
