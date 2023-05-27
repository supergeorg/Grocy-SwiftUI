//
//  ServerSettingsItems.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 29.04.22.
//

import SwiftUI

struct ServerSettingsToggle: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
    
    @State private var isOn: Bool = false
    
    @State private var isFirstShown: Bool = true
    
    let settingKey: String
    let description: String
    var descriptionInfo: String? = nil
    var icon: String? = nil
    
    var toggleFeedback: Binding<Bool>? = nil
    
    func getSetting() async {
        do {
            let userSettingsResult: GrocyUserSettingsBool = try await grocyVM.getUserSettingsEntry(settingKey: settingKey)
            self.isOn = userSettingsResult.value
            toggleFeedback?.wrappedValue = userSettingsResult.value
        } catch {
            grocyVM.grocyLog.error("Data request failed for getting the user settings entry. Message: \("\(error)")")
        }
        self.isFirstShown = false
    }
    
    func putSetting() async {
        do {
            try await grocyVM.putUserSettingsEntry(settingKey: settingKey, content: GrocyUserSettingsBool(value: isOn))
            await getSetting()
        } catch {
            grocyVM.grocyLog.error("Failed to put setting key \(settingKey). Message: \("\(error)")")
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
            .onChange(of: isOn, perform: { value in
                if !self.isFirstShown {
                    Task {
                        await putSetting()
                    }
                }
            })
    }
}

struct ServerSettingsIntStepper: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
    
    @State private var value: Int = 0
    
    @State private var isFirstShown: Bool = true
    
    let settingKey: String
    let description: String
    var descriptionInfo: String? = nil
    var icon: String? = nil
    
    func getSetting() async {
        do {
            let userSettingsResult: GrocyUserSettingsInt = try await grocyVM.getUserSettingsEntry(settingKey: settingKey)
            self.value = userSettingsResult.value ?? 0
        } catch {
            grocyVM.grocyLog.error("Data request failed for getting the user settings entry. Message: \("\(error)")")
        }
        self.isFirstShown = false
    }
    
    func putSetting() async {
        do {
            try await grocyVM.putUserSettingsEntry(settingKey: settingKey, content: GrocyUserSettingsInt(value: value))
        } catch {
            grocyVM.grocyLog.error("Failed to put setting key \(settingKey). Message: \("\(error)")")
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
            .onChange(of: value, perform: { value in
                if !self.isFirstShown {
                    Task {
                        await putSetting()
                    }
                }
            })
    }
}

struct ServerSettingsDoubleStepper: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
    
    @State private var value: Double = 0
    
    @State private var isFirstShown: Bool = true
    
    let settingKey: String
    let description: String
    var descriptionInfo: String? = nil
    var icon: String? = nil
    
    func getSetting() async {
        do {
            let userSettingsResult: GrocyUserSettingsDouble = try await grocyVM.getUserSettingsEntry(settingKey: settingKey)
            self.value = userSettingsResult.value ?? 0.0
        } catch {
            grocyVM.grocyLog.error("Data request failed for getting the user settings entry. Message: \("\(error)")")
        }
        self.isFirstShown = false
    }
    
    func putSetting() async {
        do {
            try await grocyVM.putUserSettingsEntry(settingKey: settingKey, content: GrocyUserSettingsDouble(value: value))
        } catch {
            grocyVM.grocyLog.error("Failed to put setting key \(settingKey). Message: \("\(error)")")
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
            .onChange(of: value, perform: { value in
                if !self.isFirstShown {
                    Task {
                        await putSetting()
                    }
                }
            })
    }
}

struct ServerSettingsObjectPicker: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
    
    @State private var objectID: Int? = nil
    
    @State private var isFirstShown: Bool = true
    
    enum Objects {
        case location, productGroup, quantityUnit, shoppingLists
    }
    
    let settingKey: String
    let description: String
    var descriptionInfo: String? = nil
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
            grocyVM.grocyLog.error("Data request failed for getting the user settings entry. Message: \("\(error)")")
        }
        self.isFirstShown = false
    }
    
    func putSetting() async {
        do {
            try await grocyVM.putUserSettingsEntry(settingKey: settingKey, content: GrocyUserSettingsInt(value: objectID))
        } catch {
            grocyVM.grocyLog.error("Failed to put setting key \(settingKey). Message: \("\(error)")")
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
            MyLabelWithSubtitle(title: description, subTitle: descriptionInfo, systemImage: icon, isProblem: false, isSubtitleProblem: false, hideSubtitle: false)
        })
        .task {
            if isFirstShown {
                await getSetting()
            }
        }
        .disabled(isFirstShown)
        .onChange(of: objectID, perform: { value in
            if !self.isFirstShown {
                Task {
                    await putSetting()
                }
            }
        })
    }
}
