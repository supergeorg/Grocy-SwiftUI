//
//  MDBatteriesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftData
import SwiftUI

struct MDBatteriesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @State private var searchString: String = ""
    @State private var showAddBattery: Bool = false
    /// The form for a new object zooms out of the create button.
    @Namespace private var addTransition
    @State private var batteryToDelete: MDBattery? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var deleteErrorMessage: String? = nil

    var mdBatteries: MDBatteries {
        let predicate = #Predicate<MDBattery> { battery in
            searchString.isEmpty || battery.name.localizedStandardContains(searchString) || battery.usedIn.localizedStandardContains(searchString)
        }
        let descriptor = FetchDescriptor<MDBattery>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var batteriesCount: Int {
        var descriptor = FetchDescriptor<MDBattery>(sortBy: [])
        descriptor.fetchLimit = 0
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private let dataToUpdate: [ObjectEntities] = [.batteries]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func deleteItem(itemToDelete: MDBattery) {
        batteryToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }

    private func deleteBattery(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .batteries, id: toDelID)
            GrocyLogger.info("Deleting battery was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting battery failed. \(error)")
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
            ForEach(mdBatteries, id: \.id) { battery in
                NavigationLink(value: battery) {
                    MDBatteryRowView(battery: battery)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteItem(itemToDelete: battery)
                    } label: {
                        Label("Delete", systemImage: MySymbols.delete)
                    }
                }
            }
        }
        .overlay {
            if batteriesCount == 0 {
                ContentUnavailableView {
                    Label("No batteries", systemImage: MySymbols.batteries)
                } description: {
                    Text("No battery defined. Please create one.")
                } actions: {
                    Button("Create battery") {
                        showAddBattery = true
                    }
                }
            } else if mdBatteries.isEmpty {
                ContentUnavailableView.search
            }
        }
        #if os(iOS)
            .sheet(isPresented: $showAddBattery) {
                NavigationStack {
                    MDBatteryFormView(isPopup: true)
                }
                .navigationTransition(.zoom(sourceID: ZoomTransitionID.add, in: addTransition))
            }
        #else
            .navigationDestination(isPresented: $showAddBattery) { MDBatteryFormView() }
        #endif
        .navigationDestination(for: MDBattery.self) { battery in
            MDBatteryFormView(existingBattery: battery)
        }
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
        .alert(
            "Are you sure you want to delete battery \"\(batteryToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                // No destructive role: the person chose to delete, this button carries out their intent (HIG).
                Button("Delete") {
                    if let toDelID = batteryToDelete?.id {
                        Task {
                            await deleteBattery(toDelID: toDelID)
                        }
                    }
                }
            },
            message: {
                Text("This can't be undone.")
            }
        )
        .alert(
            "Couldn't delete \"\(batteryToDelete?.name ?? "")\"",
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
                    showAddBattery.toggle()
                } label: {
                    Label("Create battery", systemImage: MySymbols.new)
                }
            }
            #if os(iOS)
                .matchedTransitionSource(id: ZoomTransitionID.add, in: addTransition)
            #endif
        }
        .navigationTitle("Batteries")
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        MDBatteriesView()
    }
}
