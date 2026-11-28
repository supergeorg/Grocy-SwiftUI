//
//  EquipmentView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftData
import SwiftUI

/// Grocy's equipment list. Selecting an item shows its instruction manual and notes.
struct EquipmentView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @State private var searchString: String = ""
    @State private var showAddEquipment: Bool = false
    /// The form for a new object zooms out of the create button.
    @Namespace private var addTransition
    @State private var equipmentToDelete: MDEquipment? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var deleteErrorMessage: String? = nil

    var equipment: MDEquipments {
        let predicate = #Predicate<MDEquipment> { item in
            searchString.isEmpty || item.name.localizedStandardContains(searchString)
        }
        let descriptor = FetchDescriptor<MDEquipment>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var equipmentCount: Int {
        var descriptor = FetchDescriptor<MDEquipment>(sortBy: [])
        descriptor.fetchLimit = 0
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private let dataToUpdate: [ObjectEntities] = [.equipment]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func deleteEquipment(_ item: MDEquipment) async {
        let manualFileName = item.instructionManualFileName
        do {
            try await grocyVM.deleteMDObject(object: .equipment, id: item.id)
            GrocyLogger.info("Deleting equipment was successful.")
            // The manual isn't referenced anymore, so its file goes too.
            if let manualFileName {
                do {
                    try await grocyVM.deleteInstructionManual(fileName: manualFileName)
                } catch {
                    GrocyLogger.warning("Deleting the instruction manual failed. \(error)")
                }
            }
            await updateData()
        } catch {
            GrocyLogger.error("Deleting equipment failed. \(error)")
            if let apiError = error as? APIError {
                deleteErrorMessage = apiError.displayMessage
            } else {
                deleteErrorMessage = error.localizedDescription
            }
        }
    }

    var body: some View {
        if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count == 0 {
            content
        } else {
            ServerProblemView()
        }
    }

    var content: some View {
        List {
            ForEach(equipment, id: \.id) { item in
                NavigationLink(value: item) {
                    EquipmentRowView(equipment: item)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        equipmentToDelete = item
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: MySymbols.delete)
                    }
                }
            }
        }
        .overlay {
            if equipmentCount == 0 {
                ContentUnavailableView {
                    Label("No equipment", systemImage: MySymbols.equipment)
                } description: {
                    Text("No equipment defined. Please create one.")
                } actions: {
                    Button("Create equipment") {
                        showAddEquipment = true
                    }
                }
            } else if equipment.isEmpty {
                ContentUnavailableView.search
            }
        }
        .sheet(isPresented: $showAddEquipment) {
            NavigationStack {
                EquipmentFormView(isPopup: true)
            }
            #if os(iOS)
                .navigationTransition(.zoom(sourceID: ZoomTransitionID.add, in: addTransition))
            #else
                .presentationSizing(.form)
            #endif
        }
        .navigationDestination(for: MDEquipment.self) { item in
            EquipmentDetailsView(equipment: item)
        }
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
        .alert(
            "Are you sure you want to delete equipment \"\(equipmentToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                // No destructive role: the person chose to delete, this button carries out their intent (HIG).
                Button("Delete") {
                    if let equipmentToDelete {
                        Task {
                            await deleteEquipment(equipmentToDelete)
                        }
                    }
                }
            },
            message: {
                Text("This can't be undone.")
            }
        )
        .alert(
            "Couldn't delete \"\(equipmentToDelete?.name ?? "")\"",
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddEquipment.toggle()
                } label: {
                    Label("Create equipment", systemImage: MySymbols.new)
                        .macHelp("Create equipment")
                }
            }
            #if os(iOS)
                .matchedTransitionSource(id: ZoomTransitionID.add, in: addTransition)
            #endif
        }
        .navigationTitle("Equipment")
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        EquipmentView()
    }
}
