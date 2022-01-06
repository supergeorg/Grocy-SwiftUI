//
//  SettingsStockView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 03.01.22.
//

import SwiftUI

struct SettingsStockViewToggle: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var isOn: Bool = false
    
    @State private var isFirstShown: Bool = true
    
    let settingKey: String
    let description: String
    var descriptionInfo: String? = nil
    let icon: String? = nil
    
    var toggleFeedback: Binding<Bool>? = nil
    
    func getSetting() {
        grocyVM.getUserSettingsEntry(settingKey: settingKey) { (result: Result<GrocyUserSettingsBool, APIError>) in
            switch result {
            case let .success(userSettingsResult):
                self.isOn = userSettingsResult.value
                toggleFeedback?.wrappedValue = userSettingsResult.value
            case let .failure(error):
                grocyVM.grocyLog.error("Data request failed for getting the user settings entry. Message: \("\(error)")")
            }
            self.isFirstShown = false
        }
    }
    
    func putSetting() {
        grocyVM.putUserSettingsEntry(settingKey: settingKey, content: GrocyUserSettingsBool(value: isOn)) { (result: Result<Int, Error>) in
            switch result {
            case .success:
                getSetting()
            case let .failure(error):
                grocyVM.grocyLog.error("Failed to put setting key \(settingKey). Message: \("\(error)")")
            }
        }
    }
    
    var body: some View {
        MyToggle(isOn: $isOn, description: description, descriptionInfo: descriptionInfo, icon: icon)
            .onAppear(perform: getSetting)
            .disabled(isFirstShown)
            .onChange(of: isOn, perform: { value in
                if !self.isFirstShown {
                    putSetting()
                }
            })
    }
}

struct SettingsStockViewIntStepper: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var value: Int = 0
    
    @State private var isFirstShown: Bool = true
    
    let settingKey: String
    let description: String
    let descriptionInfo: String? = nil
    let icon: String? = nil
    
    func getSetting() {
        grocyVM.getUserSettingsEntry(settingKey: settingKey) { (result: Result<GrocyUserSettingsInt, APIError>) in
            switch result {
            case let .success(userSettingsResult):
                self.value = userSettingsResult.value ?? 0
            case let .failure(error):
                grocyVM.grocyLog.error("Data request failed for getting the user settings entry. Message: \("\(error)")")
            }
            self.isFirstShown = false
        }
    }
    
    func putSetting() {
        grocyVM.putUserSettingsEntry(settingKey: settingKey, content: GrocyUserSettingsInt(value: value)) { (result: Result<Int, Error>) in
            switch result {
            case .success:
                break
            case let .failure(error):
                grocyVM.grocyLog.error("Failed to put setting key \(settingKey). Message: \("\(error)")")
            }
        }
    }
    
    var body: some View {
        MyIntStepper(amount: $value, description: description, helpText: descriptionInfo, systemImage: icon)
            .onAppear(perform: getSetting)
            .disabled(isFirstShown)
            .onChange(of: value, perform: { value in
                if !self.isFirstShown {
                    putSetting()
                }
            })
    }
}

struct SettingsStockViewObjectPicker: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var objectID: Int? = nil
    
    @State private var isFirstShown: Bool = true
    
    enum Objects {
        case location, productGroup, quantityUnit
    }
    
    let settingKey: String
    let description: String
    let descriptionInfo: String? = nil
    let icon: String? = nil
    let objects: Objects
    
    func getSetting() {
        grocyVM.getUserSettingsEntry(settingKey: settingKey) { (result: Result<GrocyUserSettingsInt, APIError>) in
            switch result {
            case let .success(userSettingsResult):
                if userSettingsResult.value == 0 {
                    self.objectID = nil
                } else {
                    self.objectID = userSettingsResult.value
                }
            case let .failure(error):
                grocyVM.grocyLog.error("Data request failed for getting the user settings entry. Message: \("\(error)")")
            }
            self.isFirstShown = false
        }
    }
    
    func putSetting() {
        grocyVM.putUserSettingsEntry(settingKey: settingKey, content: GrocyUserSettingsInt(value: objectID)) { (result: Result<Int, Error>) in
            switch result {
            case .success:
                break
            case let .failure(error):
                grocyVM.grocyLog.error("Failed to put setting key \(settingKey). Message: \("\(error)")")
            }
        }
    }
    
    var body: some View {
        Picker(selection: $objectID, content: {
            Text("").tag(nil as Int?)
            Group {
                switch objects {
                case .location:
                    ForEach(grocyVM.mdLocations, id: \.id) { location in
                        Text(location.name).tag(location.id as Int?)
                    }
                case .productGroup:
                    ForEach(grocyVM.mdProductGroups, id: \.id) { productGroup in
                        Text(productGroup.name).tag(productGroup.id as Int?)
                    }
                case .quantityUnit:
                    ForEach(grocyVM.mdQuantityUnits, id: \.id) { quantityUnit in
                        Text(quantityUnit.name).tag(quantityUnit.id as Int?)
                    }
                }
            }
        }, label: {
            HStack{
                if let icon = icon {
                    Label(LocalizedStringKey(description), systemImage: icon)
                } else {
                    Text(LocalizedStringKey(description))
                }
                if let descriptionInfo = descriptionInfo {
                    FieldDescription(description: descriptionInfo)
                }
            }
        })
            .onAppear(perform: getSetting)
            .disabled(isFirstShown)
            .onChange(of: objectID, perform: { value in
                if !self.isFirstShown {
                    putSetting()
                }
            })
    }
}

struct SettingsStockView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var useQuickConsume: Bool = false
    
    @State private var isFirst: Bool = true
    
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
                SettingsStockViewObjectPicker(settingKey: GrocyUserSettings.CodingKeys.productPresetsLocationID.rawValue, description: "str.settings.stock.presets.location", objects: .location)
                SettingsStockViewObjectPicker(settingKey: GrocyUserSettings.CodingKeys.productPresetsProductGroupID.rawValue, description: "str.settings.stock.presets.productGroup", objects: .productGroup)
                SettingsStockViewObjectPicker(settingKey: GrocyUserSettings.CodingKeys.productPresetsQuID.rawValue, description: "str.settings.stock.presets.quantityUnit", objects: .quantityUnit)
                SettingsStockViewIntStepper(settingKey: GrocyUserSettings.CodingKeys.productPresetsDefaultDueDays.rawValue, description: "str.settings.stock.presets.defaultDueDays")
            }
            Section(header: Text(LocalizedStringKey("str.settings.stock.stockOverview")).font(.title)) {
                SettingsStockViewIntStepper(settingKey: GrocyUserSettings.CodingKeys.stockDueSoonDays.rawValue, description: "str.settings.stock.stockOverview.dueSoonDays")
                SettingsStockViewToggle(settingKey: GrocyUserSettings.CodingKeys.showIconOnStockOverviewPageWhenProductIsOnShoppingList.rawValue, description: "str.settings.stock.stockOverview.showIconShoppingList")
            }
            Section(header: Text(LocalizedStringKey("str.settings.stock.purchase")).font(.title)) {
                SettingsStockViewIntStepper(settingKey: GrocyUserSettings.CodingKeys.stockDefaultPurchaseAmount.rawValue, description: "str.settings.stock.purchase.defaultAmount")
                SettingsStockViewToggle(settingKey: GrocyUserSettings.CodingKeys.showPurchasedDateOnPurchase.rawValue, description: "str.settings.stock.purchase.showPurchasedDate")
                SettingsStockViewToggle(settingKey: GrocyUserSettings.CodingKeys.showWarningOnPurchaseWhenDueDateIsEarlierThanNext.rawValue, description: "str.settings.stock.purchase.showWarningWhenEarlier")
            }
            Section(header: Text(LocalizedStringKey("str.settings.stock.consume")).font(.title)) {
                SettingsStockViewIntStepper(settingKey: GrocyUserSettings.CodingKeys.stockDefaultConsumeAmount.rawValue, description: "str.settings.stock.consume.defaultAmount")
                    .disabled(useQuickConsume)
                SettingsStockViewToggle(settingKey: GrocyUserSettings.CodingKeys.stockDefaultConsumeAmountUseQuickConsumeAmount.rawValue, description: "str.settings.stock.consume.useQuickConsume", toggleFeedback: $useQuickConsume)
            }
            Section(header: Text(LocalizedStringKey("str.settings.stock.common")).font(.title)) {
                SettingsStockViewIntStepper(settingKey: GrocyUserSettings.CodingKeys.stockDecimalPlacesAmounts.rawValue, description: "str.settings.stock.common.amountDecimalPlaces")
                SettingsStockViewIntStepper(settingKey: GrocyUserSettings.CodingKeys.stockDecimalPlacesPrices.rawValue, description: "str.settings.stock.common.priceDecimalPlaces")
                SettingsStockViewToggle(settingKey: GrocyUserSettings.CodingKeys.stockAutoDecimalSeparatorPrices.rawValue, description: "str.settings.stock.common.priceAddSeparatorAuto", descriptionInfo: "str.settings.stock.common.priceAddSeparatorAuto.hint")
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
