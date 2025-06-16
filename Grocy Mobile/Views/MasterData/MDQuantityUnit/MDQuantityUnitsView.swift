//
//  MDQuantityUnitsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI
import SwiftData
internal import os

struct MDQuantityUnitsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchString: String = ""
    @State private var showAddQuantityUnit: Bool = false
    @State private var quantityUnitToDelete: MDQuantityUnit? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    // Fetch the data with a dynamic predicate
    var mdQuantityUnits: MDQuantityUnits {
        let sortDescriptor = SortDescriptor<MDQuantityUnit>(\.name)
        let predicate = searchString.isEmpty ? nil :
        #Predicate<MDQuantityUnit> { store in
            searchString == "" ? true : (store.name.localizedStandardContains(searchString) || store.namePlural.localizedStandardContains(searchString))
        }
        
        let descriptor = FetchDescriptor<MDQuantityUnit>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // Get the unfiltered count without fetching any data
    var mdQuantityUnitsCount: Int {
        var descriptor = FetchDescriptor<MDQuantityUnit>(
            sortBy: []
        )
        descriptor.fetchLimit = 0
        
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    private let dataToUpdate: [ObjectEntities] = [.quantity_units]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func deleteItem(itemToDelete: MDQuantityUnit) {
        quantityUnitToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    private func deleteQuantityUnit(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .quantity_units, id: toDelID)
            grocyVM.postLog("Deleting quantity unit was successful.", type: .info)
            await updateData()
        } catch {
            grocyVM.postLog("Deleting quantity unit failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if mdQuantityUnitsCount == 0 {
                ContentUnavailableView("No quantity units found.", systemImage: MySymbols.quantityUnit)
            } else if mdQuantityUnits.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(mdQuantityUnits, id:\.id) { quantityUnit in
                NavigationLink(value: quantityUnit) {
                    MDQuantityUnitRowView(quantityUnit: quantityUnit)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: quantityUnit) },
                           label: { Label("Delete", systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .navigationDestination(isPresented: $showAddQuantityUnit, destination: {
            MDQuantityUnitFormView()
        })
        .navigationDestination(for: MDQuantityUnit.self, destination: { quantityUnit in
            MDQuantityUnitFormView(existingQuantityUnit: quantityUnit)
        })
        .navigationTitle("Quantity units")
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .searchable(
            text: $searchString,
            prompt: "Search"
        )
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
#if os(macOS)
                RefreshButton(updateData: { Task { await updateData() } })
#endif
                Button(action: {
                    showAddQuantityUnit.toggle()
                }, label: {
                    Label("New quantity unit", systemImage: MySymbols.new)
                })
            }
        }
        .animation(
            .default,
            value: mdQuantityUnits.count
        )
        .confirmationDialog("Do you really want to delete this quantity unit?", isPresented: $showDeleteConfirmation, actions: {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let toDelID = quantityUnitToDelete?.id {
                    Task {
                        await deleteQuantityUnit(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(quantityUnitToDelete?.name ?? "Name not found") })
    }
}

#Preview {
    MDQuantityUnitsView()
}
