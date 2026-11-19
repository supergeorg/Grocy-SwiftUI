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
    @Environment(\.openURL) private var openURL

    @Query(sort: \ShoppingListDescription.id) var shoppingListDescriptions: ShoppingListDescriptions

    @AppStorage("syncShoppingListToReminders") private var syncShoppingListToReminders: Bool = false
    @AppStorage("shoppingListToSyncID") private var shoppingListToSyncID: Int = 0

    @State private var useAutoAddBelowMinStockAmount: Bool = false

    @State private var isFirst: Bool = true
    @State private var reminderStore = ReminderStore.shared
    @State private var reminderSyncError: String?
    @State private var showUnlinkConfirmation: Bool = false

    private let dataToUpdate: [ObjectEntities] = [.shopping_lists]

    /// Turning the sync on asks for access just in time, and syncs once, so the list shows up in Reminders right away.
    private func startAutomaticSync() async {
        if shoppingListToSyncID == 0 || !shoppingListDescriptions.contains(where: { $0.id == shoppingListToSyncID }) {
            shoppingListToSyncID = shoppingListDescriptions.first?.id ?? 0
        }
        guard let shoppingList = shoppingListDescriptions.first(where: { $0.id == shoppingListToSyncID }) else { return }
        do {
            try await reminderStore.sync(shoppingList: shoppingList, grocyVM: grocyVM, requestAccess: true)
        } catch ReminderSyncError.accessDenied {
            syncShoppingListToReminders = false
        } catch {
            GrocyLogger.error("Syncing the shopping list with Reminders failed. \(error)")
            reminderSyncError = error.localizedDescription
        }
    }

    var body: some View {
        Form {
            Section("Shopping list") {
                ServerSettingsToggle(
                    settingKey: GrocyUserSettings.CodingKeys.shoppingListRoundUp.rawValue,
                    description: "Round up quantity amounts to the nearest whole number",
                    icon: MySymbols.amount
                )
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
            remindersSection
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
        .onChange(of: syncShoppingListToReminders) {
            if syncShoppingListToReminders {
                Task { await startAutomaticSync() }
            }
        }
        .onChange(of: shoppingListToSyncID) {
            if syncShoppingListToReminders {
                Task { await startAutomaticSync() }
            }
        }
        .alert(
            "Couldn't sync with Reminders",
            isPresented: Binding(get: { reminderSyncError != nil }, set: { if !$0 { reminderSyncError = nil } }),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(reminderSyncError ?? "") }
        )
    }

    private var remindersSection: some View {
        Section {
            if reminderStore.isAccessDenied || reminderStore.isAccessRestricted {
                LabeledContent {
                    if reminderStore.isAccessDenied {
                        Button("Open Settings") {
                            if let url = ReminderStore.privacySettingsURL {
                                openURL(url)
                            }
                        }
                    }
                } label: {
                    Label(
                        reminderStore.isAccessDenied ? "Reminders access is off" : "This device doesn't allow access to Reminders.",
                        systemImage: MySymbols.warning
                    )
                }
            } else {
                MyToggle(isOn: $syncShoppingListToReminders, description: "Sync automatically", icon: MySymbols.syncWithReminders)
                if syncShoppingListToReminders {
                    Picker(
                        selection: $shoppingListToSyncID,
                        content: {
                            ForEach(shoppingListDescriptions, id: \.id) { shoppingListDescription in
                                Text(shoppingListDescription.name).tag(shoppingListDescription.id)
                            }
                        },
                        label: {
                            Label("Shopping list", systemImage: MySymbols.shoppingList)
                                .foregroundStyle(.primary)
                        }
                    )
                    LabeledContent {
                        if reminderStore.syncingListIDs.contains(shoppingListToSyncID) {
                            ProgressView()
                        } else if let lastSync = reminderStore.lastSync(shoppingListID: shoppingListToSyncID) {
                            Text(lastSync, format: .relative(presentation: .named))
                        } else {
                            Text("Never")
                        }
                    } label: {
                        Label("Last synced", systemImage: MySymbols.lastSync)
                            .foregroundStyle(.primary)
                    }
                    Button {
                        Task { await startAutomaticSync() }
                    } label: {
                        Label("Sync Now", systemImage: MySymbols.syncNow)
                    }
                    .disabled(reminderStore.syncingListIDs.contains(shoppingListToSyncID))
                }
            }
            if !reminderStore.calendarIdentifiers.isEmpty {
                Button("Unlink lists in Reminders", role: .destructive) {
                    showUnlinkConfirmation = true
                }
                // On the button, so the dialog's popover points at it.
                .confirmationDialog("Unlink all lists in Reminders?", isPresented: $showUnlinkConfirmation, titleVisibility: .visible) {
                    Button("Unlink") {
                        syncShoppingListToReminders = false
                        reminderStore.unlinkAll()
                    }
                } message: {
                    Text("Syncing stops. The lists and their reminders stay in Reminders.")
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text(
                "Mirrors a shopping list to a list in Reminders. Items you check off or add there are brought into Grocy. It syncs when the list or its reminders change, every few minutes while the app is open, and from time to time in the background. Any shopping list can also be synced from its title menu."
            )
        }
        .onAppear {
            reminderStore.refreshAuthorizationStatus()
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        SettingsShoppingListView()
    }
}
