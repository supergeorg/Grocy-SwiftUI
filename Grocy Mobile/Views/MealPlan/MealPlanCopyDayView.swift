//
//  MealPlanCopyDayView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftUI

/// Picks the day to copy everything planned on a day to, as "Copy this day" in the Grocy web app.
struct MealPlanCopyDayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    let sourceDay: Date
    let onCopy: (Date) async -> Bool

    @State private var targetDay: Date
    @State private var isProcessing: Bool = false

    init(sourceDay: Date, onCopy: @escaping (Date) async -> Bool) {
        self.sourceDay = sourceDay
        self.onCopy = onCopy
        self.targetDay = Calendar.current.date(byAdding: .day, value: 1, to: sourceDay) ?? sourceDay
    }

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    Text(sourceDay.formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(locale)))
                } label: {
                    Label("Day", systemImage: MySymbols.date)
                        .foregroundStyle(.primary)
                }
                DatePicker(selection: $targetDay, displayedComponents: .date) {
                    Label("Copy to", systemImage: MySymbols.copyDay)
                        .foregroundStyle(.primary)
                }
            } footer: {
                Text("Everything planned on this day is copied to the chosen day, as not done.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Copy this day")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel, action: { dismiss() })
                    .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            isProcessing = true
                            if await onCopy(Calendar.current.startOfDay(for: targetDay)) {
                                dismiss()
                            }
                            isProcessing = false
                        }
                    },
                    label: {
                        Label("Copy", systemImage: isProcessing ? MySymbols.progress : MySymbols.copyDay)
                            .symbolEffect(.variableColor.iterative, isActive: isProcessing)
                    }
                )
                .disabled(isProcessing || Calendar.current.isDate(targetDay, inSameDayAs: sourceDay))
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MealPlanCopyDayView(sourceDay: Date(), onCopy: { _ in true })
    }
}
