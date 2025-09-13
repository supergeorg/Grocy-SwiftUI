//
//  SettingsStockView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 03.01.22.
//

import SwiftUI

struct SettingsStockView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @AppStorage("devMode") private var devMode: Bool = false

    @State private var useQuickConsume: Bool = false
    @State private var isFirst: Bool = true

    private let dataToUpdate: [ObjectEntities] = [.locations, .product_groups, .quantity_units]

    var body: some View {
        Form {
            Section("Presets for new products") {
                ServerSettingsObjectPicker(
                    settingKey: GrocyUserSettings.CodingKeys.productPresetsLocationID.rawValue,
                    description: "Location",
                    icon: MySymbols.location,
                    objects: .location
                )
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
                ServerSettingsIntStepper(
                    settingKey: GrocyUserSettings.CodingKeys.productPresetsDefaultDueDays.rawValue,
                    description: "Default due days",
                    icon: MySymbols.date
                )
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.productPresetsTreatOpenedAsOutOfStock.rawValue,
                    description: "Treat opened as out of stock",
                    icon: MySymbols.stockOverview
                )
            }
            Section("Stock overview") {
                ServerSettingsIntStepper(
                    settingKey: GrocyUserSettings.CodingKeys.stockDueSoonDays.rawValue,
                    description: "Due soon days",
                    icon: MySymbols.date
                )
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.showIconOnStockOverviewPageWhenProductIsOnShoppingList.rawValue,
                    description: "Show an icon if the product is already on the shopping list",
                    icon: MySymbols.shoppingList
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
                    description: "Use the products \"Quick consume amount\" ",
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
                if devMode {
                    ServerSettingsToggle(
                        settingKey: GrocyUserSettings.CodingKeys.stockAutoDecimalSeparatorPrices.rawValue,
                        description: "Add decimal separator automatically for price inputs",
                        descriptionInfo: "When enabled, you always have to enter the value including decimal places, the decimal separator will be automatically added based on the amount of allowed decimal places",
                        icon: MySymbols.price
                    )
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Stock settings")
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

#Preview {
    SettingsStockView()
}
