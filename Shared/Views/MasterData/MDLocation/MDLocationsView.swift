//
//  MDLocationsView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 13.10.20.
//

import SwiftData
import SwiftUI

struct MDLocationsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchString: String = ""
    @State private var showAddLocation: Bool = false
    @State private var locationToDelete: MDLocation? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    // Fetch the data with a dynamic predicate
    var mdLocations: MDLocations {
        let sortDescriptor = SortDescriptor<MDLocation>(\.name)
        let predicate = searchString.isEmpty ? nil :
        #Predicate<MDLocation> { location in
            searchString == "" ? true : location.name.localizedStandardContains(searchString)
        }
        
        let descriptor = FetchDescriptor<MDLocation>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // Get the unfiltered count without fetching any data
    var mdLocationsCount: Int {
        var descriptor = FetchDescriptor<MDLocation>(
            sortBy: []
        )
        descriptor.fetchLimit = 0
        
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    private let dataToUpdate: [ObjectEntities] = [.locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
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
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if mdLocationsCount == 0 {
                ContentUnavailableView("No location defined. Please create one.", systemImage: MySymbols.location)
            } else if mdLocations.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(mdLocations, id: \.id) { location in
                NavigationLink(value: location) {
                    MDLocationRowView(location: location)
                }
                .swipeActions(
                    edge: .trailing, allowsFullSwipe: true,
                    content: {
                        Button(
                            role: .destructive,
                            action: { deleteItem(itemToDelete: location) },
                            label: { Label("Delete", systemImage: MySymbols.delete) }
                        )
                    })
            }
        }
        .navigationDestination(
            isPresented: $showAddLocation,
            destination: {
                MDLocationFormView()
            }
        )
        .navigationDestination(
            for: MDLocation.self,
            destination: { location in
                MDLocationFormView(existingLocation: location)
            }
        )
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
            value: mdLocations.count
        )
        .confirmationDialog(
            "Do you really want to delete this location?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let toDelID = locationToDelete?.id {
                        Task {
                            await deleteLocation(toDelID: toDelID)
                        }
                    }
                }
            },
            message: {
                Text(locationToDelete?.name ?? "")
            }
        )
        .toolbar(content: {
            ToolbarItemGroup(
                placement: .primaryAction,
                content: {
#if os(macOS)
                    RefreshButton(updateData: { Task { await updateData() } })
#endif
                    Button(
                        action: {
                            showAddLocation.toggle()
                        },
                        label: {
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
