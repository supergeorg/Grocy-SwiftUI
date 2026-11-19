//
//  ReminderSyncSection.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import SwiftUI

/// The settings of the automatic sync of the tasks or the chores with a list in Reminders.
struct ReminderSyncSection: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    let target: ReminderSyncTarget
    let footer: LocalizedStringKey

    @AppStorage private var isOn: Bool
    @State private var reminderStore = ReminderStore.shared
    @State private var syncError: String?
    @State private var showUnlinkConfirmation: Bool = false

    init(target: ReminderSyncTarget, footer: LocalizedStringKey) {
        self.target = target
        self.footer = footer
        self._isOn = AppStorage(wrappedValue: false, ReminderSyncTarget.settingKey(for: target.kind))
    }

    /// Turning the sync on asks for access just in time, and syncs once, so the list shows up in Reminders right away.
    private func sync() async {
        do {
            try await reminderStore.sync(target, grocyVM: grocyVM, requestAccess: true)
        } catch ReminderSyncError.accessDenied {
            isOn = false
        } catch {
            GrocyLogger.error("Syncing \(target.logName) with Reminders failed. \(error)")
            syncError = error.localizedDescription
        }
    }

    var body: some View {
        Section {
            if reminderStore.isAccessDenied || reminderStore.isAccessRestricted {
                RemindersAccessRow()
            } else {
                MyToggle(isOn: $isOn, description: "Sync automatically", icon: MySymbols.syncWithReminders)
                if isOn {
                    ReminderLastSyncRow(isSyncing: reminderStore.isSyncing(target), lastSync: reminderStore.lastSync(target))
                    Button {
                        Task { await sync() }
                    } label: {
                        Label("Sync Now", systemImage: MySymbols.syncNow)
                    }
                    .disabled(reminderStore.isSyncing(target))
                }
            }
            if reminderStore.hasLinkedList(of: target.kind) {
                Button("Unlink list in Reminders", role: .destructive) {
                    showUnlinkConfirmation = true
                }
                // On the button, so the dialog's popover points at it.
                .confirmationDialog("Unlink the list in Reminders?", isPresented: $showUnlinkConfirmation, titleVisibility: .visible) {
                    Button("Unlink") {
                        reminderStore.unlink(target.kind)
                    }
                } message: {
                    Text("Syncing stops. The list and its reminders stay in Reminders.")
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text(footer)
        }
        .onAppear {
            reminderStore.refreshAuthorizationStatus()
        }
        .onChange(of: isOn) {
            if isOn {
                Task { await sync() }
            }
        }
        .alert(
            "Couldn't sync with Reminders",
            isPresented: Binding(get: { syncError != nil }, set: { if !$0 { syncError = nil } }),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(syncError ?? "") }
        )
    }
}

/// Shown instead of the sync settings when the app has no access to Reminders.
struct RemindersAccessRow: View {
    @Environment(\.openURL) private var openURL
    @State private var reminderStore = ReminderStore.shared

    var body: some View {
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
    }
}

/// When the list was last synced, or a progress indicator while it syncs.
struct ReminderLastSyncRow: View {
    let isSyncing: Bool
    let lastSync: Date?

    var body: some View {
        LabeledContent {
            if isSyncing {
                ProgressView()
            } else if let lastSync {
                Text(lastSync, format: .relative(presentation: .named))
            } else {
                Text("Never")
            }
        } label: {
            Label("Last synced", systemImage: MySymbols.lastSync)
                .foregroundStyle(.primary)
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        Form {
            ReminderSyncSection(target: .tasks, footer: "Mirrors the tasks to a list in Reminders.")
        }
        .formStyle(.grouped)
    }
}
