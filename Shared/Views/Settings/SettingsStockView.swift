//
//  SettingsStockView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 03.01.22.
//

import SwiftUI

struct SettingsStockView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var useQuickConsume: Bool = false
    
    @State private var isFirst: Bool = true
    
    @AppStorage("devMode") private var devMode: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.locations, .product_groups, .quantity_units]
    
    var body: some View {
#if os(macOS)
        ScrollView {
            content
                .padding()
        }
#else
        content
#endif
    }
    
    var content: some View {
        Form {
            Section(header: Text(LocalizedStringKey("str.settings.stock.presets")).font(.title)) {
                ServerSettingsObjectPicker(settingKey: GrocyUserSettings.CodingKeys.productPresetsLocationID.rawValue, description: "str.settings.stock.presets.location", objects: .location)
                ServerSettingsObjectPicker(settingKey: GrocyUserSettings.CodingKeys.productPresetsProductGroupID.rawValue, description: "str.settings.stock.presets.productGroup", objects: .productGroup)
                ServerSettingsObjectPicker(settingKey: GrocyUserSettings.CodingKeys.productPresetsQuID.rawValue, description: "str.settings.stock.presets.quantityUnit", objects: .quantityUnit)
                ServerSettingsIntStepper(settingKey: GrocyUserSettings.CodingKeys.productPresetsDefaultDueDays.rawValue, description: "str.settings.stock.presets.defaultDueDays")
            }
            Section(header: Text(LocalizedStringKey("str.settings.stock.stockOverview")).font(.title)) {
                ServerSettingsIntStepper(settingKey: GrocyUserSettings.CodingKeys.stockDueSoonDays.rawValue, description: "str.settings.stock.stockOverview.dueSoonDays")
                ServerSettingsToggle(settingKey: GrocyUserSettings.CodingKeys.showIconOnStockOverviewPageWhenProductIsOnShoppingList.rawValue, description: "str.settings.stock.stockOverview.showIconShoppingList")
            }
            Section(header: Text(LocalizedStringKey("str.settings.stock.purchase")).font(.title)) {
                ServerSettingsDoubleStepper(settingKey: GrocyUserSettings.CodingKeys.stockDefaultPurchaseAmount.rawValue, description: "str.settings.stock.purchase.defaultAmount")
                if devMode {
                    ServerSettingsToggle(settingKey: GrocyUserSettings.CodingKeys.showPurchasedDateOnPurchase.rawValue, description: "str.settings.stock.purchase.showPurchasedDate")
                    ServerSettingsToggle(settingKey: GrocyUserSettings.CodingKeys.showWarningOnPurchaseWhenDueDateIsEarlierThanNext.rawValue, description: "str.settings.stock.purchase.showWarningWhenEarlier")
                }
            }
            Section(header: Text(LocalizedStringKey("str.settings.stock.consume")).font(.title)) {
                ServerSettingsDoubleStepper(settingKey: GrocyUserSettings.CodingKeys.stockDefaultConsumeAmount.rawValue, description: "str.settings.stock.consume.defaultAmount")
                    .disabled(useQuickConsume)
                ServerSettingsToggle(settingKey: GrocyUserSettings.CodingKeys.stockDefaultConsumeAmountUseQuickConsumeAmount.rawValue, description: "str.settings.stock.consume.useQuickConsume", toggleFeedback: $useQuickConsume)
            }
            if devMode {
                Section(header: Text(LocalizedStringKey("str.settings.stock.common")).font(.title)) {
                    ServerSettingsIntStepper(settingKey: GrocyUserSettings.CodingKeys.stockDecimalPlacesAmounts.rawValue, description: "str.settings.stock.common.amountDecimalPlaces")
                    ServerSettingsIntStepper(settingKey: GrocyUserSettings.CodingKeys.stockDecimalPlacesPrices.rawValue, description: "str.settings.stock.common.priceDecimalPlaces")
                    ServerSettingsToggle(settingKey: GrocyUserSettings.CodingKeys.stockAutoDecimalSeparatorPrices.rawValue, description: "str.settings.stock.common.priceAddSeparatorAuto", descriptionInfo: "str.settings.stock.common.priceAddSeparatorAuto.hint")
                }
            }
        }
        .navigationTitle(LocalizedStringKey("str.settings.stock"))
        .onAppear(perform: {
            if isFirst {
                grocyVM.requestData(objects: dataToUpdate)
                isFirst = false
            }
        })
        .onDisappear(perform: {
            grocyVM.requestData(additionalObjects: [.user_settings])
        })
    }
}

struct SettingsStockView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsStockView()
    }
}
