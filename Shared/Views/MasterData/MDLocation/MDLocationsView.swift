//
//  MDLocationsView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 13.10.20.
//

import SwiftUI
import SwiftData

struct MDLocationsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    
    @State private var searchString: String = ""
    @State private var showAddLocation: Bool = false
    @State private var locationToDelete: MDLocation? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredLocations: MDLocations {
        mdLocations
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDLocation) {
        locationToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    private func deleteLocation(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .locations, id: toDelID)
            grocyVM.postLog("Deleting location was successful.", type: .info)
            await updateData()
        } catch {
            grocyVM.postLog("Deleting location failed. \(error)", type: .error)
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
            if mdLocations.isEmpty {
                ContentUnavailableView("No locations", systemImage: MySymbols.location)
            } else if filteredLocations.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(filteredLocations, id:\.id) { location in
                NavigationLink(value: location) {
                    MDLocationRowView(location: location)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: location) },
                           label: { Label("Delete", systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .navigationDestination(isPresented: $showAddLocation, destination: {
            MDLocationFormView()
        })
        .navigationDestination(for: MDLocation.self, destination: { location in
            MDLocationFormView(existingLocation: location)
        })
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
        .animation(
            .default,
            value: filteredLocations.count
        )
        .confirmationDialog(
            "Do you really want to delete this location?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible,
            actions: {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let toDelID = locationToDelete?.id {
                        Task {
                            await deleteLocation(toDelID: toDelID)
                        }
                    }
                }
            }, message: {
                Text(locationToDelete?.name ?? "")
            })
        .toolbar(content: {
            ToolbarItemGroup(placement: .primaryAction, content: {
#if os(macOS)
                RefreshButton(updateData: { Task { await updateData() } })
#endif
                Button(action: {
                    showAddLocation.toggle()
                }, label: {
                    Label("New location", systemImage: MySymbols.new)
                })
            })
        })
        .navigationTitle("Locations")
    }
}

#Preview {
    MDLocationsView()
}
