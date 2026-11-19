//
//  GrocyFeatures.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import SwiftData
import SwiftUI

/// The server's stock, shopping list and chore feature flags (`FEATURE_FLAG_*` in Grocy's `config.php`).
///
/// Views read it with `@Environment(\.grocyFeatures)`; `grocyFeatures()` provides it from the stored `SystemConfig`.
/// Without a config (not synced yet), every feature is on, like Grocy's defaults.
struct GrocyFeatures: Equatable {
    /// Stock locations: location fields, transfers, stock per location.
    var locationTracking = true
    /// Due dates: due date fields, due filters, the products in the due agenda.
    var dueDateTracking = true
    /// Opening products: the open action, opened amounts and due days after opening.
    var openedTracking = true
    /// Freezing: freezer locations and due days after freezing and thawing.
    var freezing = true
    /// More than one shopping list.
    var multipleShoppingLists = true
    /// Chore assignments to users.
    var choreAssignments = true
    /// Recipes and the meal plan.
    var recipes = true

    init() {}

    init(_ config: SystemConfig?) {
        guard let config else { return }
        locationTracking = config.featureFlagStockLocationTracking
        dueDateTracking = config.featureFlagStockBestBeforeDateTracking
        openedTracking = config.featureFlagStockProductOpenedTracking
        freezing = config.featureFlagStockProductFreezing
        multipleShoppingLists = config.featureFlagShoppinglistMultipleLists
        choreAssignments = config.featureFlagChoresAssignments
        recipes = config.featureFlagRecipes
    }
}

extension EnvironmentValues {
    @Entry var grocyFeatures = GrocyFeatures()
}

/// Reads the stored config once, so the views below don't each need a `@Query`.
private struct GrocyFeaturesProvider: ViewModifier {
    @Query private var systemConfigList: [SystemConfig]

    func body(content: Content) -> some View {
        content.environment(\.grocyFeatures, GrocyFeatures(systemConfigList.first))
    }
}

extension View {
    /// Provides `\.grocyFeatures` from the server's config. Needs the main model container.
    func grocyFeatures() -> some View {
        modifier(GrocyFeaturesProvider())
    }
}
