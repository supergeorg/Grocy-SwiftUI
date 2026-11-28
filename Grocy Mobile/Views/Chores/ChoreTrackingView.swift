//
//  ChoreTrackingView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 12.12.25.
//

import SwiftData
import SwiftUI

struct ChoreTrackingView: View {
    /// Skipping is the secondary action on iOS. A Mac window shows secondary actions at the left, away from tracking.
    private static var skipPlacement: ToolbarItemPlacement {
        #if os(macOS)
            .primaryAction
        #else
            .secondaryAction
        #endif
    }

    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Query(sort: \MDChore.name, order: .forward) var mdChores: MDChores
    @Query(sort: \GrocyUser.displayName) var grocyUsers: GrocyUsers

    @AppStorage("localizationKey") var localizationKey: String = "en"

    @State private var firstAppear: Bool = true
    @State private var actionPending: Bool = true
    @State private var isProcessingAction: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var mdChoreID: Int? = nil
    var isPopup: Bool = false

    @State private var choreID: Int?
    @State private var trackedTime: Date = Date()
    @State private var userID: Int?

    private let dataToUpdate: [ObjectEntities] = [.chores]
    private let additionalDataToUpdate: [AdditionalEntities] = [.users]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    private func finishForm() {
        self.dismiss()
    }

    private var isFormValid: Bool {
        return (choreID != nil)
    }

    private func resetForm() {
        choreID = actionPending ? mdChoreID : nil
        trackedTime = Date()
        userID = nil
    }

    private func trackChore(skipped: Bool = false) async {
        if let choreID {
            let executeInfo = ChoreExecuteModel(trackedTime: trackedTime.grocyDateTimeString, doneBy: userID, skipped: skipped)
            isProcessingAction = true
            isSuccessful = nil
            do {
                _ = try await grocyVM.executeChore(id: choreID, content: executeInfo)
                GrocyLogger.info("Tracking chore successful.")
                await grocyVM.requestData(additionalObjects: [.chores])
                isSuccessful = true
                actionPending = false
                if mdChoreID != nil {
                    finishForm()
                }
                resetForm()
            } catch {
                GrocyLogger.error("Tracking chore failed: \(error)")
                isSuccessful = false
                if let apiError = error as? APIError {
                    errorMessage = apiError.displayMessage
                } else {
                    errorMessage = error.localizedDescription
                }
            }
            isProcessingAction = false
        }
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage = errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                Section {
                    ServerProblemView(isCompact: true)
                }
            }

            Picker(selection: $choreID) {
                Text("")
                    .tag(nil as Int?)
                ForEach(mdChores) { chore in
                    Text(chore.name)
                        .tag(chore.id)
                }
            } label: {
                Label("Chore", systemImage: MySymbols.chores)
                    .foregroundStyle(.primary)
            }

            LabeledContent(
                content: {
                    DatePicker(
                        selection: $trackedTime,
                        label: {
                            Text(getRelativeDateAsText(trackedTime, localizationKey: localizationKey) ?? "")
                                .font(.caption)
                                .italic()
                        }
                    )
                },
                label: {
                    Label("Tracked time", systemImage: MySymbols.date)
                        .foregroundStyle(.primary)
                }
            )

            Picker(
                selection: $userID,
                content: {
                    Text("")
                        .tag(nil as Int?)
                    ForEach(grocyUsers, id: \.id) { user in
                        Text(user.displayName)
                            .tag(user.id as Int?)
                    }
                },
                label: {
                    Label("Done by", systemImage: MySymbols.user)
                        .foregroundStyle(.primary)
                }
            )
        }
        .navigationTitle("Chore tracking")
        .formStyle(.grouped)
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
        .toolbar(content: {
            if isPopup {
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button(
                            role: .cancel,
                            action: {
                                finishForm()
                            }
                        )
                        .keyboardShortcut(.cancelAction)
                    }
                )
            }
            // On the Mac, both at the right like the other forms' actions, skipping before tracking, apart.
            ToolbarItem(placement: Self.skipPlacement) {
                Button(
                    action: {
                        Task {
                            await trackChore(skipped: true)
                        }
                    },
                    label: {
                        // While it runs, the icon becomes an animated progress symbol. It stays an image: with a ProgressView as its icon,
                        // the item loses its icon and leaves iPhone Duo's vertical bar for a text-only button at the bottom.
                        Label("Skip next chore schedule", systemImage: isProcessingAction ? MySymbols.progress : MySymbols.choreSkipNext)
                            .macHelp("Skip next chore schedule")
                            .symbolEffect(.variableColor.iterative, isActive: isProcessingAction)
                    }
                )
                .accentColor(.gray)
                .disabled(!isFormValid || isProcessingAction)
                .keyboardShortcut("s", modifiers: [.command])
            }
            #if os(macOS)
                ToolbarSpacer(.fixed, placement: .primaryAction)
            #endif
            ToolbarItem(placement: .primaryAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await trackChore()
                        }
                    },
                    label: {
                        // While it runs, the icon becomes an animated progress symbol. It stays an image: with a ProgressView as its icon,
                        // the item loses its icon and leaves iPhone Duo's vertical bar for a text-only button at the bottom.
                        Label("Track next chore schedule", systemImage: isProcessingAction ? MySymbols.progress : MySymbols.choreTrackNext)
                            .macHelp("Track next chore schedule")
                            .symbolEffect(.variableColor.iterative, isActive: isProcessingAction)
                    }
                )
                .disabled(!isFormValid || isProcessingAction)
                .keyboardShortcut("t", modifiers: [.command])
            }
        })
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        ChoreTrackingView()
    }
}
