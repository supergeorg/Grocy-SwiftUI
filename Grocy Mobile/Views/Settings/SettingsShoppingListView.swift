//
//  SettingsShoppingListView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 29.04.22.
//

import SwiftUI

struct SettingsShoppingListView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @AppStorage("devMode") private var devMode: Bool = false
    @AppStorage("syncShoppingListToReminders") private var syncShoppingListToReminders: Bool = false
    @AppStorage("shoppingListToSyncID") private var shoppingListToSyncID: Int = 0

    @State private var useAutoAddBelowMinStockAmount: Bool = false

    @State private var isFirst: Bool = true

    private let dataToUpdate: [ObjectEntities] = [.shopping_lists]

    var body: some View {
        Form {
            Section("Shopping list") {
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.shoppingListAutoAddBelowMinStockAmount.rawValue,
                    description: "Automatically add products that are below their defined min. stock amount to the shopping list",
                    icon: MySymbols.amount,
                    toggleFeedback: $useAutoAddBelowMinStockAmount
                )
                if useAutoAddBelowMinStockAmount {
                    ServerSettingsObjectPicker(
                        settingKey: GrocyUserSettings.CodingKeys.shoppingListAutoAddBelowMinStockAmountListID.rawValue,
                        description: "Shopping list",
                        icon: MySymbols.shoppingList,
                        objects: .shoppingLists
                    )
                }
            }
            Section("Shopping list to stock workflow") {
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.shoppingListToStockWorkflowAutoSubmitWhenPrefilled.rawValue,
                    description: "Automatically do the booking using the last price and the amount of the shopping list item, if the product has \"Default due days\" set",
                    icon: MySymbols.stockOverview
                )
            }
            if devMode {
                Section(header: Text("REMINDER SYNC").font(.title)) {
                    MyToggle(isOn: $syncShoppingListToReminders, description: "SYNC SHOPPING LIST TO REMINDERS")
                    Picker(
                        "SHOPPING LIST",
                        selection: $shoppingListToSyncID,
                        content: {
                            Text("").tag(0)
                            ForEach(grocyVM.shoppingListDescriptions, id: \.id) { shoppingListDescription in
                                Text(shoppingListDescription.name).tag(shoppingListDescription.id)
                            }
                        }
                    )
                    .disabled(!syncShoppingListToReminders)
                    Button(
                        action: {
                            Task {
                                do {
                                    try await ReminderStore.shared.requestAccess()
                                    ReminderStore.shared.initCalendar()
                                } catch {
                                    print(error)
                                }
                            }
                        },
                        label: {
                            Text("INIT CALENDAR")
                        }
                    )
                    Button(
                        action: {
                            do {
                                for shoppingListItem in grocyVM.shoppingList {
                                    let title = "\(shoppingListItem.amount.formattedAmount) \(grocyVM.mdProducts.first(where: { $0.id == shoppingListItem.productID })?.name ?? "\(shoppingListItem.productID ?? 0)")"
                                    try ReminderStore.shared.save(Reminder(title: title, isComplete: shoppingListItem.done == 1))
                                }
                            } catch {
                                print(error)
                            }
                        },
                        label: {
                            Text("ADD TO CALENDAR")
                        }
                    )
                    .disabled(!ReminderStore.shared.isAvailable_)
                    Button(
                        action: {
                            Task {
                                do {
                                    let allReminders = try await ReminderStore.shared.readAll()
                                    await grocyVM.updateShoppingListFromReminders(reminders: allReminders)
                                } catch {
                                    print(error)
                                }
                            }
                        },
                        label: {
                            Text("READ ALL")
                        }
                    )
                    .disabled(!ReminderStore.shared.isAvailable_)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Shopping list settings")
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
    SettingsShoppingListView()
}
