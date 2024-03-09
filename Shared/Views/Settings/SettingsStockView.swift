//
//  SettingsStockView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 03.01.22.
//

import SwiftUI

struct SettingsStockView: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
    
    @State private var useQuickConsume: Bool = false
    
    @State private var isFirst: Bool = true
    
    @AppStorage("devMode") private var devMode: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.locations, .product_groups, .quantity_units]
    
    var body: some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            content
                .formStyle(.grouped)
        } else {
#if os(macOS)
            ScrollView {
                content
                    .padding()
            }
#else
            content
#endif
        }
    }
    
    var content: some View {
        Form {
            Section(header: Text(LocalizedStringKey("str.settings.stock.presets")).font(.title)) {
                ServerSettingsObjectPicker(
                    settingKey: GrocyUserSettings.CodingKeys.productPresetsLocationID.rawValue,
                    description: "str.settings.stock.presets.location",
                    icon: MySymbols.location,
                    objects: .location
                )
                ServerSettingsObjectPicker(
                    settingKey: GrocyUserSettings.CodingKeys.productPresetsProductGroupID.rawValue,
                    description: "str.settings.stock.presets.productGroup",
                    icon: MySymbols.productGroup,
                    objects: .productGroup
                )
                ServerSettingsObjectPicker(
                    settingKey: GrocyUserSettings.CodingKeys.productPresetsQuID.rawValue,
                    description: "str.settings.stock.presets.quantityUnit",
                    icon: MySymbols.quantityUnit,
                    objects: .quantityUnit
                )
                ServerSettingsIntStepper(
                    settingKey: GrocyUserSettings.CodingKeys.productPresetsDefaultDueDays.rawValue,
                    description: "str.settings.stock.presets.defaultDueDays",
                    icon: MySymbols.date
                )
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.productPresetsTreatOpenedAsOutOfStock.rawValue,
                    description: "str.settings.stock.presets.treatOpenedAsOutOfStock",
                    icon: MySymbols.stockOverview
                )
            }
            Section(header: Text(LocalizedStringKey("str.settings.stock.stockOverview")).font(.title)) {
                ServerSettingsIntStepper(
                    settingKey: GrocyUserSettings.CodingKeys.stockDueSoonDays.rawValue,
                    description: "str.settings.stock.stockOverview.dueSoonDays",
                    icon: MySymbols.date
                )
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.showIconOnStockOverviewPageWhenProductIsOnShoppingList.rawValue,
                    description: "str.settings.stock.stockOverview.showIconShoppingList",
                    icon: MySymbols.shoppingList
                )
            }
            Section(header: Text(LocalizedStringKey("str.settings.stock.purchase")).font(.title)) {
                ServerSettingsDoubleStepper(
                    settingKey: GrocyUserSettings.CodingKeys.stockDefaultPurchaseAmount.rawValue,
                    description: "str.settings.stock.purchase.defaultAmount",
                    icon: MySymbols.amount
                )
                if devMode {
                    ServerSettingsToggle(
                        settingKey: GrocyUserSettings.CodingKeys.showPurchasedDateOnPurchase.rawValue,
                        description: "str.settings.stock.purchase.showPurchasedDate",
                        icon: MySymbols.date
                    )
                    ServerSettingsToggle(
                        settingKey: GrocyUserSettings.CodingKeys.showWarningOnPurchaseWhenDueDateIsEarlierThanNext.rawValue,
                        description: "str.settings.stock.purchase.showWarningWhenEarlier",
                        icon: MySymbols.date
                    )
                }
            }
            Section(header: Text(LocalizedStringKey("str.settings.stock.consume")).font(.title)) {
                ServerSettingsDoubleStepper(
                    settingKey: GrocyUserSettings.CodingKeys.stockDefaultConsumeAmount.rawValue,
                    description: "str.settings.stock.consume.defaultAmount",
                    icon: MySymbols.amount
                )
                .disabled(useQuickConsume)
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.stockDefaultConsumeAmountUseQuickConsumeAmount.rawValue,
                    description: "str.settings.stock.consume.useQuickConsume",
                    icon: MySymbols.amount,
                    toggleFeedback: $useQuickConsume
                )
            }
            
            Section(header: Text(LocalizedStringKey("str.settings.stock.common")).font(.title)) {
                ServerSettingsIntStepper(
                    settingKey: GrocyUserSettings.CodingKeys.stockDecimalPlacesAmounts.rawValue,
                    description: "str.settings.stock.common.amountDecimalPlaces",
                    icon: MySymbols.decimalPlaces
                )
                ServerSettingsIntStepper(
                    settingKey: GrocyUserSettings.CodingKeys.stockDecimalPlacesPricesInput.rawValue,
                    description: "str.settings.stock.common.priceDecimalPlacesInput",
                    icon: MySymbols.decimalPlaces
                )
                ServerSettingsIntStepper(
                    settingKey: GrocyUserSettings.CodingKeys.stockDecimalPlacesPricesDisplay.rawValue,
                    description: "str.settings.stock.common.priceDecimalPlacesDisplay",
                    icon: MySymbols.decimalPlaces
                )
                if devMode {
                    ServerSettingsToggle(
                        settingKey: GrocyUserSettings.CodingKeys.stockAutoDecimalSeparatorPrices.rawValue,
                        description: "str.settings.stock.common.priceAddSeparatorAuto",
                        descriptionInfo: "str.settings.stock.common.priceAddSeparatorAuto.hint",
                        icon: MySymbols.price
                    )
                }
            }
        }
        .navigationTitle(LocalizedStringKey("str.settings.stock"))
        .task {
            if isFirst {
                Task {
                    await grocyVM.requestData(objects: dataToUpdate)
                    isFirst = false
                }
            }
        }
        .onDisappear(perform: {
            Task {
                await grocyVM.requestData(additionalObjects: [.user_settings])
            }
        })
    }
}

struct SettingsStockView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsStockView()
    }
}
