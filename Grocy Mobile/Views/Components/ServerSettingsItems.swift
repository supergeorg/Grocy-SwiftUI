//
//  ServerSettingsItems.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 29.04.22.
//

import SwiftUI
import SwiftData

struct ServerSettingsToggle: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @State private var isOn: Bool = false
    
    @State private var isFirstShown: Bool = true
    
    let settingKey: String
    let description: LocalizedStringKey
    var descriptionInfo: LocalizedStringKey? = nil
    var icon: String? = nil
    
    var toggleFeedback: Binding<Bool>? = nil
    
    func getSetting() async {
        do {
            let userSettingsResult: GrocyUserSettingsBool = try await grocyVM.getUserSettingsEntry(settingKey: settingKey)
            self.isOn = userSettingsResult.value
            toggleFeedback?.wrappedValue = userSettingsResult.value
        } catch {
            GrocyLogger.error("Data request failed for getting the user settings entry. Message: \("\(error)")")
        }
        self.isFirstShown = false
    }
    
    func putSetting() async {
        do {
            try await grocyVM.putUserSettingsEntry(settingKey: settingKey, content: GrocyUserSettingsBool(value: isOn))
            await getSetting()
        } catch {
            GrocyLogger.error("Failed to put setting key \(settingKey). Message: \("\(error)")")
        }
    }
    
    var body: some View {
        MyToggle(isOn: $isOn, description: description, descriptionInfo: descriptionInfo, icon: icon)
            .task {
                if isFirstShown {
                    await getSetting()
                }
            }
            .disabled(isFirstShown)
            .onChange(of: isOn) {
                if !self.isFirstShown {
                    Task {
                        await putSetting()
                    }
                }
            }
    }
}

struct ServerSettingsIntStepper: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @State private var value: Int = 0
    
    @State private var isFirstShown: Bool = true
    
    let settingKey: String
    let description: LocalizedStringKey
    var descriptionInfo: LocalizedStringKey? = nil
    var icon: String? = nil
    
    func getSetting() async {
        do {
            let userSettingsResult: GrocyUserSettingsInt = try await grocyVM.getUserSettingsEntry(settingKey: settingKey)
            self.value = userSettingsResult.value ?? 0
        } catch {
            GrocyLogger.error("Data request failed for getting the user settings entry. Message: \("\(error)")")
        }
        self.isFirstShown = false
    }
    
    func putSetting() async {
        do {
            try await grocyVM.putUserSettingsEntry(settingKey: settingKey, content: GrocyUserSettingsInt(value: value))
        } catch {
            GrocyLogger.error("Failed to put setting key \(settingKey). Message: \("\(error)")")
        }
    }
    
    var body: some View {
        MyIntStepper(amount: $value, description: description, helpText: descriptionInfo, systemImage: icon)
            .task {
                if isFirstShown {
                    await getSetting()
                }
            }
            .disabled(isFirstShown)
            .onChange(of: value) {
                if !self.isFirstShown {
                    Task {
                        await putSetting()
                    }
                }
            }
    }
}

struct ServerSettingsDoubleStepper: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @State private var value: Double = 0
    
    @State private var isFirstShown: Bool = true
    
    let settingKey: String
    let description: LocalizedStringKey
    var descriptionInfo: LocalizedStringKey? = nil
    var icon: String? = nil
    
    func getSetting() async {
        do {
            let userSettingsResult: GrocyUserSettingsDouble = try await grocyVM.getUserSettingsEntry(settingKey: settingKey)
            self.value = userSettingsResult.value ?? 0.0
        } catch {
            GrocyLogger.error("Data request failed for getting the user settings entry. Message: \("\(error)")")
        }
        self.isFirstShown = false
    }
    
    func putSetting() async {
        do {
            try await grocyVM.putUserSettingsEntry(settingKey: settingKey, content: GrocyUserSettingsDouble(value: value))
        } catch {
            GrocyLogger.error("Failed to put setting key \(settingKey). Message: \("\(error)")")
        }
    }
    
    var body: some View {
        MyDoubleStepper(amount: $value, description: description, descriptionInfo: descriptionInfo, systemImage: icon)
            .task {
                if isFirstShown {
                    await getSetting()
                }
            }
            .disabled(isFirstShown)
            .onChange(of: value) {
                if !self.isFirstShown {
                    Task {
                        await putSetting()
                    }
                }
            }
    }
}

struct ServerSettingsObjectPicker: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(filter: #Predicate<MDLocation>{$0.active}, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query(filter: #Predicate<MDProductGroup>{$0.active}, sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups
    @Query(filter: #Predicate<MDQuantityUnit>{$0.active}, sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \ShoppingListDescription.id, order: .forward) var shoppingListDescriptions: ShoppingListDescriptions
    
    @State private var objectID: Int? = -1
    @State private var isFirstShown: Bool = true
    
    enum Objects {
        case location, productGroup, quantityUnit, shoppingLists
    }
    
    let settingKey: String
    let description: LocalizedStringKey
    var icon: String? = nil
    let objects: Objects
    
    func getSetting() async {
        do {
            let userSettingsResult: GrocyUserSettingsInt = try await grocyVM.getUserSettingsEntry(settingKey: settingKey)
            if userSettingsResult.value == 0 {
                self.objectID = nil
            } else {
                self.objectID = userSettingsResult.value
            }
        } catch {
            GrocyLogger.error("Data request failed for getting the user settings entry. Message: \("\(error)")")
        }
        self.isFirstShown = false
    }
    
    func putSetting() async {
        do {
            try await grocyVM.putUserSettingsEntry(settingKey: settingKey, content: GrocyUserSettingsInt(value: objectID))
        } catch {
            GrocyLogger.error("Failed to put setting key \(settingKey). Message: \("\(error)")")
        }
    }
    
    var body: some View {
        Picker(selection: $objectID, content: {
            Text("").tag(-1 as Int?)
            Group {
                switch objects {
                case .location:
                    ForEach(mdLocations, id: \.id) { location in
                        Text(location.name).tag(location.id as Int?)
                    }
                case .productGroup:
                    ForEach(mdProductGroups, id: \.id) { productGroup in
                        Text(productGroup.name).tag(productGroup.id as Int?)
                    }
                case .quantityUnit:
                    ForEach(mdQuantityUnits, id: \.id) { quantityUnit in
                        Text(quantityUnit.name).tag(quantityUnit.id as Int?)
                    }
                case .shoppingLists:
                    ForEach(shoppingListDescriptions, id: \.id) { shoppingList in
                        Text(shoppingList.name).tag(shoppingList.id as Int?)
                    }
                }
            }
        }, label: {
            if let icon = icon {
                Label(description, systemImage: icon)
                    .foregroundStyle(.primary)
            } else {
                Text(description)
            }
        })
        .task {
            if isFirstShown {
                await getSetting()
            }
        }
        .disabled(isFirstShown)
        .onChange(of: objectID) {
            if !self.isFirstShown {
                Task {
                    await putSetting()
                }
            }
        }
    }
}
