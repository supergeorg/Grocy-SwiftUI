//
//  MDQuantityUnitsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI
import SwiftData

struct MDQuantityUnitsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    
    @State private var searchString: String = ""
    @State private var showAddQuantityUnit: Bool = false
    
    @State private var quantityUnitToDelete: MDQuantityUnit? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.quantity_units]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredQuantityUnits: MDQuantityUnits {
        mdQuantityUnits
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
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
            } else  if mdQuantityUnits.isEmpty {
                ContentUnavailableView("No quantity units found.", systemImage: MySymbols.quantityUnit)
            } else if filteredQuantityUnits.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(filteredQuantityUnits, id:\.id) { quantityUnit in
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
        .navigationDestination(for: String.self, destination: { _ in
            MDQuantityUnitFormView()
        })
        .navigationDestination(for: MDQuantityUnit.self, destination: { quantityUnit in
            MDQuantityUnitFormView(existingQuantityUnit: quantityUnit)
            EmptyView()
        })
        .navigationTitle("Quantity units")
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
#if os(macOS)
                RefreshButton(updateData: { Task { await updateData() } })
#endif
                Button(action: {
                    showAddQuantityUnit.toggle()
                }, label: {Image(systemName: MySymbols.new)})
            }
        }
        .animation(.default, value: filteredQuantityUnits.count)
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

struct MDQuantityUnitsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDQuantityUnitRowView(quantityUnit: MDQuantityUnit(id: 0, name: "QU NAME", namePlural: "QU NAME PLURAL", active: true, mdQuantityUnitDescription: "Description", rowCreatedTimestamp: ""))
#if os(macOS)
            MDQuantityUnitsView()
#else
            NavigationView() {
                MDQuantityUnitsView()
            }
#endif
        }
    }
}
