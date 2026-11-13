//
//  MDChoreFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 10.12.25.
//
import SwiftData
import SwiftUI

struct MDChoreFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \MDChore.name, order: .forward) var mdChores: MDChores
    @Query var choreInfo: Chores
    @Query(sort: \GrocyUser.displayName, order: .forward) var grocyUsers: GrocyUsers

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingChore: MDChore? = nil
    var isPopup: Bool

    @State private var chore: MDChore

    init(existingChore: MDChore? = nil, isPopup: Bool = false) {
        self.existingChore = existingChore
        self.chore = existingChore ?? MDChore()
        self.isPopup = isPopup
    }

    private var foundChoreInfo: Chore? {
        choreInfo.first(where: { $0.choreID == chore.id })
    }
    private var choreWasTracked: Bool {
        return foundChoreInfo?.lastTrackedTime != nil
    }

    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundChore = mdChores.first(where: { $0.name == chore.name })
        return !(chore.name.isEmpty || (foundChore != nil && foundChore!.id != chore.id))
    }

    private let dataToUpdate: [ObjectEntities] = [.chores, .products]
    private let additionalDataToUpdate: [AdditionalEntities] = [.chores, .users]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    private var isFormValid: Bool {
        guard isNameCorrect else { return false }
        guard chore.assignmentType == .noAssignment || chore.assignmentConfig?.isEmpty == false else { return false }
        if [ChorePeriodType.hourly, ChorePeriodType.daily, ChorePeriodType.weekly, ChorePeriodType.monthly, ChorePeriodType.yearly].contains(chore.periodType) {
            guard chore.periodInterval > 0 else { return false }
        }
        if chore.assignmentType != .noAssignment {
            guard chore.assignmentConfig != nil else { return false }
            guard chore.assignmentConfig!.isEmpty == false else { return false }
        }
        return true
    }

    private func finishForm() {
        self.dismiss()
    }

    var periodIntervalInfoText: LocalizedStringKey {
        switch chore.periodType {
        case .hourly:
            return "This means the next execution of this chore is scheduled \(chore.periodInterval) hour after the last execution"
        case .daily:
            return "This means the next execution of this chore is scheduled at the same time (based on the start date) every \(chore.periodInterval) days"
        case .weekly:
            return "This means the next execution of this chore is scheduled every \(chore.periodInterval) weeks on the selected weekdays"
        case .monthly:
            return "This means the next execution of this chore is scheduled on the selected day every \(chore.periodInterval) months"
        case .yearly:
            return "This means the next execution of this chore is scheduled every \(chore.periodInterval) years on the same day (based on the start date)"
        case .manually:
            return "This means the next execution of this chore is not scheduled"
        case .adaptive:
            return "This means the next execution of this chore is scheduled dynamically based on the past average execution frequency"
        }
    }

    var assignmentTypeInfoText: LocalizedStringKey {
        switch chore.assignmentType {
        case .noAssignment:
            return "This means the next execution of this chore will not be assigned to anyone"
        case .whoLeastDidFirst:
            return "This means the next execution of this chore will be assigned to the one who executed it least"
        case .random:
            return "This means the next execution of this chore will be assigned randomly"
        case .inAlphabeticalOrder:
            return "This means the next execution of this chore will be assigned to the next one in alphabetical order"
        }
    }

    private func saveChore() async {
        if chore.id == -1 {
            do {
                chore.id = try grocyVM.findNextID(.chores)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            try chore.modelContext?.save()
            if existingChore == nil {
                _ = try await grocyVM.postMDObject(object: .chores, content: chore)
            } else {
                try await grocyVM.putMDObjectWithID(object: .chores, id: chore.id, content: chore)
            }
            GrocyLogger.info("Chore \(chore.name) successful.")
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Chore \(chore.name) failed. \(error)")
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
            isSuccessful = false
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage = errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }

            MyTextField(
                textToEdit: $chore.name,
                description: "Name",
                isCorrect: $isNameCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: chore.name) {
                isNameCorrect = checkNameCorrect()
            }

            MyToggle(
                isOn: $chore.active,
                description: "Active",
                icon: MySymbols.active
            )

            MyTextEditor(
                textToEdit: $chore.mdChoreDescription,
                description: "Description",
                leadingIcon: MySymbols.description
            )

            Section {
                VStack(alignment: .leading) {
                    Picker(
                        selection: $chore.periodType,
                        content: {
                            ForEach(ChorePeriodType.allCases, id: \.rawValue) { periodType in
                                Text(periodType.localizedName)
                                    .tag(periodType)
                            }
                        },
                        label: {
                            Label("Period type", systemImage: MySymbols.chorePeriodType)
                                .foregroundStyle(.primary)
                        }
                    )
                    if [ChorePeriodType.manually, ChorePeriodType.adaptive].contains(chore.periodType) {
                        Text(periodIntervalInfoText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if chore.periodType == ChorePeriodType.weekly {
                    WeekdayPicker(selection: $chore.periodConfig)
                }

                if [ChorePeriodType.hourly, ChorePeriodType.daily, ChorePeriodType.weekly, ChorePeriodType.monthly, ChorePeriodType.yearly].contains(chore.periodType) {
                    VStack(alignment: .leading) {
                        MyIntStepper(
                            amount: $chore.periodInterval,
                            description: "Period interval",
                            minAmount: 1,
                            systemImage: MySymbols.date,
                        )
                        Text(periodIntervalInfoText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if chore.periodType == .monthly {
                    MyIntStepperOptional(amount: $chore.periodDays, description: "Day of month", systemImage: MySymbols.choreDayOfMonth)
                }

                LabeledContent(
                    content: {
                        DatePicker("", selection: $chore.startDate)
                    },
                    label: {
                        Label {
                            HStack {
                                Text("Start date")
                                FieldDescription(description: "The start date cannot be changed when the chore was once tracked")
                            }
                        } icon: {
                            Image(systemName: MySymbols.date)
                                .foregroundStyle(.primary)
                        }
                    }
                )
                .disabled(choreWasTracked)
            }

            Section {
                VStack(alignment: .leading) {
                    Picker(
                        selection: $chore.assignmentType,
                        content: {
                            ForEach(ChoreAssignmentType.allCases, id: \.rawValue) { assignmentType in
                                Text(assignmentType.localizedName)
                                    .tag(assignmentType)
                            }
                        },
                        label: {
                            Label("Assignment type", systemImage: MySymbols.choreAssignmentType)
                                .foregroundStyle(.primary)
                        }
                    )
                    Text(assignmentTypeInfoText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                UserPicker(selection: $chore.assignmentConfig, users: grocyUsers)
            }

            Section {
                MyToggle(isOn: $chore.trackDateOnly, description: "Track date only", descriptionInfo: "When enabled only the day of an execution is tracked, not the time", icon: MySymbols.date)

                MyToggle(isOn: $chore.rollover, description: "Due date rollover", descriptionInfo: "When enabled the chore can never be overdue, the due date will shift forward each day when due", icon: MySymbols.choreRollover)
            }

            Section {
                MyToggle(isOn: $chore.consumeProductOnExecution, description: "Consume product on chore execution", icon: MySymbols.product)

                if chore.consumeProductOnExecution {
                    ProductField(productID: $chore.productID, description: "Product")

                    MyDoubleStepperOptional(
                        amount: $chore.productAmount,
                        description: "Amount",
                        systemImage: MySymbols.amount
                    )
                }
            }
        }
        .formStyle(.grouped)
        .task {
            await updateData()
            self.isNameCorrect = checkNameCorrect()
        }
        .navigationTitle(existingChore == nil ? "Create chore" : "Edit chore")
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
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await saveChore()
                        }
                    },
                    label: {
                        if !isProcessing {
                            // Label style is left to the system, so the confirm button gets the standard Liquid Glass look.
                            Label("Save", systemImage: MySymbols.save)
                        } else {
                            ProgressView().progressViewStyle(.circular)
                        }
                    }
                )
                .disabled(!isFormValid || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        })
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                finishForm()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        MDChoreFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        MDChoreFormView(existingChore: MDChore(name: "Example chore"))
    }
}
