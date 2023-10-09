//
//  MDLocationsView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 13.10.20.
//

import SwiftUI
import SwiftData

struct MDLocationRowView: View {
    var location: MDLocation
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack{
                Text(location.name)
                    .font(.title)
                    .foregroundStyle(location.active ? .primary : .secondary)
                if location.isFreezer {
                    Image(systemName: "thermometer.snowflake")
                        .font(.title)
                }
            }
            if let description = location.mdLocationDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDLocationsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.modelContext) private var context
    
    @State private var searchString: String = ""
    
    @State private var showAddLocation: Bool = false
    @State private var locationToDelete: MDLocation? = nil
    @State private var showDeleteAlert: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
        //        for loc in grocyVM.mdLocations {
        //            context.insert(loc)
        //        }
    }
    
    //    @Query(sort: \MDLocation.name, order: .forward) var mdLocations: [MDLocation]
    
    private var filteredLocations: MDLocations {
        grocyVM.mdLocations
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDLocation) {
        locationToDelete = itemToDelete
        showDeleteAlert.toggle()
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
        if grocyVM.failedToLoadObjects.filter( {dataToUpdate.contains($0) }).count == 0 {
#if os(macOS)
            NavigationView{
                content
                    .frame(minWidth: Constants.macOSNavWidth)
            }
#else
            content
#endif
        } else {
            ServerProblemView()
                .navigationTitle("Locations")
        }
    }
    
    var content: some View {
        List {
            if grocyVM.mdLocations.isEmpty {
                ContentUnavailableView("No locations", systemImage: MySymbols.location)
            } else if filteredLocations.isEmpty {
                ContentUnavailableView.search
            }
#if os(macOS)
            if showAddLocation {
                NavigationLink(destination: MDLocationFormView(showAddLocation: $showAddLocation), isActive: $showAddLocation, label: {
                    NewMDRowLabel(title: "Create location")
                })
                .frame(height: showAddLocation ? 50 : 0)
            }
#endif
            ForEach(filteredLocations, id:\.id) { location in
                NavigationLink(
                    value: location,
                    label: { MDLocationRowView(location: location) }
                )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                        Button(role: .destructive,
                               action: { deleteItem(itemToDelete: location) },
                               label: { Label(LocalizedStringKey("Delete"), systemImage: MySymbols.delete) }
                        )
                    })
            }
        }
        .navigationDestination(for: MDLocation.self, destination: { location in
            MDLocationFormView(location: location, showAddLocation: Binding.constant(false))
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
        .animation(.default,
                   value: filteredLocations.count
        )
        .alert(LocalizedStringKey("Do you really want to delete this location?"), isPresented: $showDeleteAlert, actions: {
            Button("Cancel", role: .cancel) { }
            Button(LocalizedStringKey("Delete"), role: .destructive) {
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
                    showAddLocation = true
                }, label: {
                    Image(systemName: MySymbols.new)
                })
            })
        })
        .navigationTitle("Locations")
#if os(iOS)
        .sheet(isPresented: self.$showAddLocation, content: {
            NavigationView {
                MDLocationFormView(showAddLocation: $showAddLocation)
            }
        })
#endif
    }
}

//struct MDLocationsView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            MDLocationRowView(location: MDLocation(id: 0, name: "Location", active: true, mdLocationDescription: "Location description", isFreezer: true, rowCreatedTimestamp: ""))
//#if os(macOS)
//            MDLocationsView()
//#else
//            NavigationView() {
//                MDLocationsView()
//            }
//#endif
//        }
//    }
//}
