//
//  ServerSettingsItems.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 29.04.22.
//

import SwiftUI

struct ServerSettingsToggle: View {
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
            .onAppear(perform: {
                if isFirstShown {
                    getSetting()
                }
            })
            .disabled(isFirstShown)
            .onChange(of: isOn, perform: { value in
                if !self.isFirstShown {
                    putSetting()
                }
            })
    }
}

struct ServerSettingsIntStepper: View {
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
            .onAppear(perform: {
                if isFirstShown {
                    getSetting()
                }
            })
            .disabled(isFirstShown)
            .onChange(of: value, perform: { value in
                if !self.isFirstShown {
                    putSetting()
                }
            })
    }
}

struct ServerSettingsDoubleStepper: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var value: Double = 0
    
    @State private var isFirstShown: Bool = true
    
    let settingKey: String
    let description: String
    let descriptionInfo: String? = nil
    let icon: String? = nil
    
    func getSetting() {
        grocyVM.getUserSettingsEntry(settingKey: settingKey) { (result: Result<GrocyUserSettingsDouble, APIError>) in
            switch result {
            case let .success(userSettingsResult):
                self.value = userSettingsResult.value ?? 0.0
            case let .failure(error):
                grocyVM.grocyLog.error("Data request failed for getting the user settings entry. Message: \("\(error)")")
            }
            self.isFirstShown = false
        }
    }
    
    func putSetting() {
        grocyVM.putUserSettingsEntry(settingKey: settingKey, content: GrocyUserSettingsDouble(value: value)) { (result: Result<Int, Error>) in
            switch result {
            case .success:
                break
            case let .failure(error):
                grocyVM.grocyLog.error("Failed to put setting key \(settingKey). Message: \("\(error)")")
            }
        }
    }
    
    var body: some View {
        MyDoubleStepper(amount: $value, description: description, descriptionInfo: descriptionInfo, systemImage: icon)
            .onAppear(perform: {
                if isFirstShown {
                    getSetting()
                }
            })
            .disabled(isFirstShown)
            .onChange(of: value, perform: { value in
                if !self.isFirstShown {
                    putSetting()
                }
            })
    }
}

struct ServerSettingsObjectPicker: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var objectID: Int? = nil
    
    @State private var isFirstShown: Bool = true
    
    enum Objects {
        case location, productGroup, quantityUnit, shoppingLists
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
                case .shoppingLists:
                    ForEach(grocyVM.shoppingListDescriptions, id: \.id) { shoppingList in
                        Text(shoppingList.name).tag(shoppingList.id as Int?)
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
        .onAppear(perform: {
            if isFirstShown {
                getSetting()
            }
        })
        .disabled(isFirstShown)
        .onChange(of: objectID, perform: { value in
            if !self.isFirstShown {
                putSetting()
            }
        })
    }
}
