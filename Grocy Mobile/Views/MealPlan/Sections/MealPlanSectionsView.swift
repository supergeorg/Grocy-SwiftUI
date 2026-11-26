//
//  MealPlanSectionsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftData
import SwiftUI

/// The sections of the meal plan (breakfast, lunch, …), opened from the meal plan's menu. They're part of the meal plan,
/// not of the master data, as in the Grocy web app.
struct MealPlanSectionsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// The create sheet zooms out of its button.
    @Namespace private var createTransition

    @State private var showAddSection: Bool = false

    @State private var sectionToDelete: MDMealPlanSection? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var deleteErrorMessage: String? = nil

    private let dataToUpdate: [ObjectEntities] = [.meal_plan_sections]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    // Grocy's section without a name can't be edited, so it isn't listed. A household has a few sections, so there's no search.
    var mdMealPlanSections: MDMealPlanSections {
        let noSectionID = MDMealPlanSection.noSectionID
        let descriptor = FetchDescriptor<MDMealPlanSection>(
            predicate: #Predicate<MDMealPlanSection> { section in
                section.id != noSectionID
            }
        )
        return ((try? modelContext.fetch(descriptor)) ?? []).sortedForMealPlan
    }

    private func deleteItem(itemToDelete: MDMealPlanSection) {
        sectionToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    private func deleteSection(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .meal_plan_sections, id: toDelID)
            GrocyLogger.info("Deleting meal plan section was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting meal plan section failed. \(error)")
            if let apiError = error as? APIError {
                deleteErrorMessage = apiError.displayMessage
            } else {
                deleteErrorMessage = error.localizedDescription
            }
        }
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if mdMealPlanSections.isEmpty {
                ContentUnavailableView {
                    Label("No meal plan sections", systemImage: MySymbols.mealPlanSection)
                } description: {
                    Text("Sections group the meal plan's days, like breakfast, lunch and dinner.")
                } actions: {
                    Button("Create meal plan section") {
                        showAddSection = true
                    }
                }
            }
            ForEach(mdMealPlanSections, id: \.id) { section in
                NavigationLink(value: section) {
                    MealPlanSectionRowView(section: section)
                }
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true,
                    content: {
                        Button(
                            role: .destructive,
                            action: { deleteItem(itemToDelete: section) },
                            label: { Label("Delete", systemImage: MySymbols.delete) }
                        )
                    }
                )
            }
        }
        #if os(macOS)
            // A Mac sheet shows only its confirmation and cancellation buttons, not the toolbar's create button.
            .safeAreaBar(edge: .bottom) {
                HStack {
                    Button(
                        action: { showAddSection = true },
                        label: { Label("Create meal plan section", systemImage: MySymbols.new) }
                    )
                    .sheetTransitionSource(id: "create-showAddSection", in: createTransition)
                    .keyboardShortcut("n", modifiers: .command)
                    Spacer()
                }
                .padding(Spacing.medium)
            }
        #endif
        #if os(iOS)
            .sheet(
                isPresented: $showAddSection,
                content: {
                    NavigationStack {
                        MealPlanSectionFormView()
                    }
                    .sheetZoomTransition(sourceID: "create-showAddSection", in: createTransition)
                }
            )
        #else
            .navigationDestination(isPresented: $showAddSection, destination: { MealPlanSectionFormView() })
        #endif
        .navigationTitle("Meal plan sections")
        .navigationDestination(
            for: MDMealPlanSection.self,
            destination: { section in
                MealPlanSectionFormView(existingMealPlanSection: section)
            }
        )
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .toolbar(content: {
            // Opened as a sheet from the meal plan's menu.
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm, action: { dismiss() })
                    .keyboardShortcut(.defaultAction)
            }
            #if os(iOS)
                ToolbarItemGroup(
                    placement: .primaryAction,
                    content: {
                        Button(
                            action: {
                                showAddSection.toggle()
                            },
                            label: {
                                Label("Create meal plan section", systemImage: MySymbols.new)
                            }
                        )
                    }
                )
            #endif
        })
        .alert(
            "Are you sure you want to delete meal plan section \"\(sectionToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                // No destructive role: the person chose to delete, this button carries out their intent (HIG).
                Button("Delete") {
                    if let toDelID = sectionToDelete?.id {
                        Task {
                            await deleteSection(toDelID: toDelID)
                        }
                    }
                }
            },
            message: {
                Text("This can't be undone.")
            }
        )
        .alert(
            "Couldn't delete \"\(sectionToDelete?.name ?? "")\"",
            isPresented: Binding(
                get: { deleteErrorMessage != nil },
                set: { if !$0 { deleteErrorMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(deleteErrorMessage ?? "")
            }
        )
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        MealPlanSectionsView()
    }
}
