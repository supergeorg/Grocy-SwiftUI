//
//  SettingsShoppingListView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 29.04.22.
//

import SwiftData
import SwiftUI

struct SettingsShoppingListView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query var mdProducts: MDProducts
    @Query var shoppingList: [ShoppingListItem]
    @Query var shoppingListDescriptions: ShoppingListDescriptions

    @AppStorage("devMode") private var devMode: Bool = false
    @AppStorage("syncShoppingListToReminders") private var syncShoppingListToReminders: Bool = false
    @AppStorage("shoppingListToSyncID") private var shoppingListToSyncID: Int = 0

    @State private var useAutoAddBelowMinStockAmount: Bool = false

    @State private var isFirst: Bool = true
    @State var foundReminders: [Reminder] = []
    @State private var showFoundReminders: Bool = false

    private let dataToUpdate: [ObjectEntities] = [.shopping_lists]

    var selectedShoppingListItems: [ShoppingListItem] {
        shoppingList.filter({ $0.shoppingListID == shoppingListToSyncID })
    }

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
                    description:
                        "Automatically do the booking using the last price and the amount of the shopping list item, if the product has \"Default due days\" set",
                    icon: MySymbols.stockOverview
                )
            }
            if devMode {
                // Default header style, like every other section.
                Section(header: Text("Reminders")) {
                    MyToggle(isOn: $syncShoppingListToReminders, description: "Sync shopping list to Reminders")
                    if syncShoppingListToReminders {
                        Picker(
                            "Shopping list",
                            selection: $shoppingListToSyncID,
                            content: {
                                Text("").tag(0)
                                ForEach(shoppingListDescriptions, id: \.id) { shoppingListDescription in
                                    Text(shoppingListDescription.name).tag(shoppingListDescription.id)
                                }
                            }
                        )
                        Button(
                            action: {
                                Task {
                                    do {
                                        try await ReminderStore.shared.requestAccess()
                                        ReminderStore.shared.initCalendar(calendarName: "Grocy Mobile")
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
                                    for shoppingListItem in selectedShoppingListItems {
                                        let title =
                                            "\(shoppingListItem.amount.formattedAmount) \(mdProducts.first(where: { $0.id == shoppingListItem.productID })?.name ?? shoppingListItem.note)"
                                        try ReminderStore.shared.save(Reminder(title: title, isComplete: shoppingListItem.done))
                                    }
                                } catch {
                                    print(error)
                                }
                            },
                            label: {
                                Text("ADD TO CALENDAR")
                            }
                        )
                        .disabled(!ReminderStore.shared.isAvailable)
                        Button(
                            action: {
                                Task {
                                    do {
                                        let allReminders = try await ReminderStore.shared.readAll()
                                        foundReminders = allReminders
                                        showFoundReminders = true
                                    } catch {
                                        print(error)
                                    }
                                }
                            },
                            label: {
                                Text("READ ALL")
                            }
                        )
                        .disabled(!ReminderStore.shared.isAvailable)
                    }
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
        .sheet(
            isPresented: $showFoundReminders,
            content: {
                NavigationStack {
                    ShoppingListReminderReadView(reminders: foundReminders)
                }
            }
        )
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        SettingsShoppingListView()
    }
}
