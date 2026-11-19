//
//  MealPlanSectionFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftData
import SwiftUI

struct MealPlanSectionFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query var mdMealPlanSections: MDMealPlanSections

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingMealPlanSection: MDMealPlanSection?
    @State private var section: MDMealPlanSection

    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundSection = mdMealPlanSections.first(where: { $0.name == section.name })
        return !(section.name.isEmpty || (foundSection != nil && foundSection!.id != section.id))
    }

    init(existingMealPlanSection: MDMealPlanSection? = nil) {
        self.existingMealPlanSection = existingMealPlanSection
        if let existingMealPlanSection {
            // A copy, so cancelling leaves the stored section unchanged.
            self.section = MDMealPlanSection(
                id: existingMealPlanSection.id,
                name: existingMealPlanSection.name,
                sortNumber: existingMealPlanSection.sortNumber,
                timeInfo: existingMealPlanSection.timeInfo,
                rowCreatedTimestamp: existingMealPlanSection.rowCreatedTimestamp
            )
        } else {
            self.section = MDMealPlanSection()
        }
    }

    private let dataToUpdate: [ObjectEntities] = [.meal_plan_sections]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private static let timeFormat = "HH:mm"

    private var time: Binding<Date> {
        Binding(
            get: {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = Self.timeFormat
                guard let parsed = formatter.date(from: section.timeInfo) else { return Calendar.current.startOfDay(for: Date()) }
                let components = Calendar.current.dateComponents([.hour, .minute], from: parsed)
                return Calendar.current.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = Self.timeFormat
                section.timeInfo = formatter.string(from: date)
            }
        )
    }

    private func finishForm() {
        self.dismiss()
    }

    private func saveSection() async {
        if section.id == -1 {
            do {
                section.id = try grocyVM.findNextID(.meal_plan_sections)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            if existingMealPlanSection == nil {
                _ = try await grocyVM.postMDObject(object: .meal_plan_sections, content: section)
            } else {
                try await grocyVM.putMDObjectWithID(object: .meal_plan_sections, id: section.id, content: section)
            }
            GrocyLogger.info("Meal plan section \(section.name) successful.")
            grocyVM.timeStampsObjects[.meal_plan_sections] = nil
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Meal plan section \(section.name) failed. \(error)")
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
                textToEdit: $section.name,
                description: "Name",
                isCorrect: $isNameCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: section.name) {
                isNameCorrect = checkNameCorrect()
            }
            MyIntStepperOptional(
                amount: $section.sortNumber,
                description: "Sort number",
                helpText: "Sections are shown in this order",
                minAmount: nil,
                systemImage: MySymbols.sortNumber
            )
            Toggle(
                isOn: Binding(
                    get: { !section.timeInfo.isEmpty },
                    set: { isOn in
                        if isOn {
                            time.wrappedValue = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
                        } else {
                            section.timeInfo = ""
                        }
                    }
                )
            ) {
                Label("Time", systemImage: MySymbols.sectionTime)
                    .foregroundStyle(.primary)
            }
            if !section.timeInfo.isEmpty {
                DatePicker("Time of day", selection: time, displayedComponents: .hourAndMinute)
            }
        }
        .formStyle(.grouped)
        .task {
            await updateData()
            self.isNameCorrect = checkNameCorrect()
        }
        .navigationTitle(existingMealPlanSection == nil ? "Create meal plan section" : "Edit meal plan section")
        .toolbar(content: {
            if existingMealPlanSection == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel, action: { finishForm() })
                        .keyboardShortcut(.cancelAction)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await saveSection()
                        }
                    },
                    label: {
                        // An image, not a ProgressView, so the item keeps its icon while it runs (see `TaskFormView`).
                        Label("Save", systemImage: isProcessing ? MySymbols.progress : MySymbols.save)
                            .symbolEffect(.variableColor.iterative, isActive: isProcessing)
                    }
                )
                .disabled(!isNameCorrect || isProcessing)
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
        MealPlanSectionFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        MealPlanSectionFormView(existingMealPlanSection: MDMealPlanSection(id: 1, name: "Breakfast", sortNumber: 10, timeInfo: "07:30"))
    }
}
