//
//  SettingsShoppingListView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 29.04.22.
//

import SwiftUI

struct SettingsShoppingListView: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("devMode") private var devMode: Bool = false
    @AppStorage("syncShoppingListToReminders") private var syncShoppingListToReminders: Bool = false
    @AppStorage("shoppingListToSyncID") private var shoppingListToSyncID: Int = 0
    
    @State private var useAutoAddBelowMinStockAmount: Bool = false
    
    @State private var isFirst: Bool = true
    
    private let dataToUpdate: [ObjectEntities] = [.shopping_lists]
    
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
            Section(header: Text(LocalizedStringKey("str.settings.shoppingList.shoppingList")).font(.title)) {
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.shoppingListAutoAddBelowMinStockAmount.rawValue,
                    description: "str.settings.shoppingList.autoAddToShL",
                    icon: MySymbols.amount,
                    toggleFeedback: $useAutoAddBelowMinStockAmount
                )
                ServerSettingsObjectPicker(
                    settingKey: GrocyUserSettings.CodingKeys.shoppingListAutoAddBelowMinStockAmountListID.rawValue,
                    description: "str.shL",
                    icon: MySymbols.shoppingList,
                    objects: .shoppingLists
                )
                .disabled(!useAutoAddBelowMinStockAmount)
            }
            Section(header: Text(LocalizedStringKey("str.settings.shoppingList.shLToStockWF")).font(.title)) {
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.shoppingListToStockWorkflowAutoSubmitWhenPrefilled.rawValue,
                    description: "str.settings.shoppingList.autoAddToStock",
                    icon: MySymbols.stockOverview
                )
            }
            if devMode {
                Section(header: Text(LocalizedStringKey("REMINDER SYNC")).font(.title)) {
                    MyToggle(isOn: $syncShoppingListToReminders, description: "SYNC SHOPPING LIST TO REMINDERS")
                    Picker("SHOPPING LIST", selection: $shoppingListToSyncID, content: {
                        Text("").tag(0)
                        ForEach(grocyVM.shoppingListDescriptions, id:\.id) { shoppingListDescription in
                            Text(shoppingListDescription.name).tag(shoppingListDescription.id)
                        }
                    })
                    .disabled(!syncShoppingListToReminders)
                    Button(action: {
                        Task {
                            do {
                                try await ReminderStore.shared.requestAccess()
                                ReminderStore.shared.initCalendar()
                            } catch {
                                print(error)
                            }
                        }
                    }, label: {
                        Text("INIT CALENDAR")
                    })
                    Button(action: {
                        do {
                            for shoppingListItem in grocyVM.shoppingList {
                                let title = "\(shoppingListItem.amount.formattedAmount) \(grocyVM.mdProducts.first(where: { $0.id == shoppingListItem.productID })?.name ?? "\(shoppingListItem.productID ?? 0)")"
                                try ReminderStore.shared.save(Reminder(title: title, isComplete: shoppingListItem.done == 1))
                            }
                        } catch {
                            print(error)
                        }
                    }, label: {
                        Text("ADD TO CALENDAR")
                    })
                    .disabled(!ReminderStore.shared.isAvailable_)
                    Button(action: {
                        Task {
                            do {
                                let allReminders = try await ReminderStore.shared.readAll()
                                await grocyVM.updateShoppingListFromReminders(reminders: allReminders)
                            } catch {
                                print(error)
                            }
                        }
                    }, label: {
                        Text("READ ALL")
                    })
                    .disabled(!ReminderStore.shared.isAvailable_)
                }
            }
        }
        .navigationTitle(LocalizedStringKey("str.settings.shoppingList"))
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

struct SettingsShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsShoppingListView()
    }
}
