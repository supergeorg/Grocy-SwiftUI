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
    let descriptionInfo: String? = nil
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
            .onChange(of: value, perform: { value in
                if !self.isFirstShown {
                    putSetting()
                }
            })
    }
}

struct SettingsStockView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var useQuickConsume: Bool = false
    
    var body: some View {
        Form {
            Section(header: Text(LocalizedStringKey("str.settings.stock.consume")).font(.title)) {
                SettingsStockViewIntStepper(settingKey: GrocyUserSettings.CodingKeys.stockDefaultConsumeAmount.rawValue, description: "str.settings.stock.consume.defaultAmount")
                    .disabled(useQuickConsume)
                SettingsStockViewToggle(settingKey: GrocyUserSettings.CodingKeys.stockDefaultConsumeAmountUseQuickConsumeAmount.rawValue, description: "str.settings.stock.consume.useQuickConsume", toggleFeedback: $useQuickConsume)
            }
        }
        .navigationTitle(LocalizedStringKey("str.settings.stock"))
    }
}

struct SettingsStockView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsStockView()
    }
}
