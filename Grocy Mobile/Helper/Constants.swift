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
        /// The cooking mode's sheet, large enough to read a step from a distance.
        static let macOSCookingMinWidth: CGFloat = 640.0
        static let macOSCookingMinHeight: CGFloat = 560.0
        /// Onboarding, login start and What's New, so the feature list and its buttons fit without scrolling.
        static let macOSIntroductionMinHeight: CGFloat = 620.0
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
    /// Picture in a recipe list row (scaled with Dynamic Type).
    static let recipeThumbnail: CGFloat = 64
    /// Narrowest card of the recipe gallery; the gallery shows as many columns as fit, but at least two.
    static let recipeCardMinWidth: CGFloat = 160
    /// Width-to-height ratio of a recipe picture in the gallery.
    static let recipeCardPictureRatio: CGFloat = 4 / 3
    static let recipeCardCornerRadius: CGFloat = 16
    static let recipeThumbnailCornerRadius: CGFloat = 10
    /// Picture of a meal plan entry in the list (scaled with Dynamic Type).
    static let mealPlanThumbnail: CGFloat = 44
    /// Narrowest day column of the meal plan's week grid; narrower, the meal plan shows the days as a list.
    static let mealPlanDayMinWidth: CGFloat = 120
    /// The column with the section names in the meal plan's week grid.
    static let mealPlanSectionLabelWidth: CGFloat = 96
    static let mealPlanCardCornerRadius: CGFloat = 12
    /// The circle around today's date in the week grid's header (scaled with Dynamic Type).
    static let mealPlanDayBadge: CGFloat = 34
    /// Height of the recipe picture above the details (iOS, scaled to the width on narrow screens).
    static let recipeHeaderPictureMaxHeight: CGFloat = 320
    static let parserTextHeight: CGFloat = 200
    static let parserResultMaxHeight: CGFloat = 300
    static let popoverFormSize: CGFloat = 500
    /// Widest line length of the cooking mode's pages, so long steps stay readable on iPad and Mac.
    static let cookingReadableWidth: CGFloat = 720
    /// Widest line length of the onboarding, login start and What's New screens, so the feature list stays compact on iPad and Mac.
    static let introductionReadableWidth: CGFloat = 520
    /// Width of the symbol column in an introduction feature row (scaled with Dynamic Type).
    static let introductionIconWidth: CGFloat = 44
    /// Height of the Grocy logo above the welcome title (scaled with Dynamic Type).
    static let introductionLogoHeight: CGFloat = 48
}
