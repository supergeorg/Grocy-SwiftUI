//
//  SettingsStockView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 03.01.22.
//

import SwiftData
import SwiftUI

struct SettingsStockView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @AppStorage("devMode") private var devMode: Bool = false
    @Environment(\.grocyFeatures) private var features

    @Query private var systemConfigList: [SystemConfig]

    @State private var useQuickConsume: Bool = false
    @State private var isFirst: Bool = true

    private let dataToUpdate: [ObjectEntities] = [.locations, .product_groups, .quantity_units]

    var body: some View {
        Form {
            Section("Presets for new products") {
                if features.locationTracking {
                    ServerSettingsObjectPicker(
                        settingKey: GrocyUserSettings.CodingKeys.productPresetsLocationID.rawValue,
                        description: "Location",
                        icon: MySymbols.location,
                        objects: .location
                    )
                }
                ServerSettingsObjectPicker(
                    settingKey: GrocyUserSettings.CodingKeys.productPresetsProductGroupID.rawValue,
                    description: "Product group",
                    icon: MySymbols.productGroup,
                    objects: .productGroup
                )
                ServerSettingsObjectPicker(
                    settingKey: GrocyUserSettings.CodingKeys.productPresetsQuID.rawValue,
                    description: "Quantity unit",
                    icon: MySymbols.quantityUnit,
                    objects: .quantityUnit
                )
                if features.dueDateTracking {
                    ServerSettingsIntStepper(
                        settingKey: GrocyUserSettings.CodingKeys.productPresetsDefaultDueDays.rawValue,
                        description: "Default due days",
                        icon: MySymbols.date
                    )
                }
                if features.openedTracking {
                    ServerSettingsToggle(
                        settingKey: GrocyUserSettings.CodingKeys.productPresetsTreatOpenedAsOutOfStock.rawValue,
                        description: "Treat opened as out of stock",
                        icon: MySymbols.stockOverview
                    )
                }
            }
            Section("Stock overview") {
                if features.dueDateTracking {
                    ServerSettingsIntStepper(
                        settingKey: GrocyUserSettings.CodingKeys.stockDueSoonDays.rawValue,
                        description: "Due soon days",
                        icon: MySymbols.date
                    )
                }
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.showIconOnStockOverviewPageWhenProductIsOnShoppingList.rawValue,
                    description: "Show an icon if the product is already on the shopping list",
                    icon: MySymbols.shoppingList
                )
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.stockOverviewShowAllOutOfStockProducts.rawValue,
                    description: "Show all out of stock products",
                    descriptionInfo:
                        "By default the stock overview page lists all products which are currently in stock or below their min. stock amount - when this is enabled, all (active) products are always shown",
                    icon: MySymbols.stockOverview
                )
            }
            Section("Purchase") {
                ServerSettingsDoubleStepper(
                    settingKey: GrocyUserSettings.CodingKeys.stockDefaultPurchaseAmount.rawValue,
                    description: "Default amount for purchase",
                    icon: MySymbols.amount
                )
                if devMode {
                    ServerSettingsToggle(
                        settingKey: GrocyUserSettings.CodingKeys.showPurchasedDateOnPurchase.rawValue,
                        description: "Show purchased date on purchase and inventory page (otherwise the purchased date defaults to today)",
                        icon: MySymbols.date
                    )
                    ServerSettingsToggle(
                        settingKey: GrocyUserSettings.CodingKeys.showWarningOnPurchaseWhenDueDateIsEarlierThanNext.rawValue,
                        description: "Show a warning when the due date of the purchased product is earlier than the next due date in stock",
                        icon: MySymbols.date
                    )
                }
            }
            Section("Consume") {
                ServerSettingsDoubleStepper(
                    settingKey: GrocyUserSettings.CodingKeys.stockDefaultConsumeAmount.rawValue,
                    description: "Default amount for consume",
                    icon: MySymbols.amount
                )
                .disabled(useQuickConsume)
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.stockDefaultConsumeAmountUseQuickConsumeAmount.rawValue,
                    description: "Use the products \"Quick consume amount\"",
                    icon: MySymbols.amount,
                    toggleFeedback: $useQuickConsume
                )
            }

            Section("Common") {
                ServerSettingsIntStepper(
                    settingKey: GrocyUserSettings.CodingKeys.stockDecimalPlacesAmounts.rawValue,
                    description: "Decimal places allowed for amounts",
                    icon: MySymbols.decimalPlaces
                )
                // Prices only matter when the server tracks them, as in Grocy's own settings.
                if systemConfigList.first?.featureFlagStockPriceTracking != false {
                    ServerSettingsIntStepper(
                        settingKey: GrocyUserSettings.CodingKeys.stockDecimalPlacesPricesInput.rawValue,
                        description: "Decimal places allowed for prices (input)",
                        icon: MySymbols.decimalPlaces
                    )
                    ServerSettingsIntStepper(
                        settingKey: GrocyUserSettings.CodingKeys.stockDecimalPlacesPricesDisplay.rawValue,
                        description: "Decimal places allowed for prices (display)",
                        icon: MySymbols.decimalPlaces
                    )
                }
                if devMode && systemConfigList.first?.featureFlagStockPriceTracking != false {
                    ServerSettingsToggle(
                        settingKey: GrocyUserSettings.CodingKeys.stockAutoDecimalSeparatorPrices.rawValue,
                        description: "Add decimal separator automatically for price inputs",
                        descriptionInfo:
                            "When enabled, you always have to enter the value including decimal places, the decimal separator will be automatically added based on the amount of allowed decimal places",
                        icon: MySymbols.price
                    )
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Stock")
        .task {
            if isFirst {
                await grocyVM.requestData(objects: dataToUpdate)
                isFirst = false
            }
        }
        .onDisappear(perform: {
            Task {
                await grocyVM.requestData(additionalObjects: [.user_settings])
            }
        })
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        SettingsStockView()
    }
}
