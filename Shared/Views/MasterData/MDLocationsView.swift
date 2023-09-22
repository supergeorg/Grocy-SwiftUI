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
                    .foregroundColor(location.active ? .primary : .gray)
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
    @State private var toastType: ToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
        for loc in grocyVM.mdLocations {
            context.insert(loc)
        }
    }
    
    @Query(sort: \MDLocation.name, order: .forward) var mdLocations: [MDLocation]
    
    private var filteredLocations: MDLocations {
        mdLocations
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
            toastType = .failDelete
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter( {dataToUpdate.contains($0) }).count == 0 {
#if os(macOS)
            NavigationView{
                bodyContent
                    .frame(minWidth: Constants.macOSNavWidth)
            }
#else
            bodyContent
#endif
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.md.locations"))
        }
    }
    
    var bodyContent: some View {
        content
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
            .navigationTitle(LocalizedStringKey("str.md.locations"))
#if os(iOS)
            .sheet(isPresented: self.$showAddLocation, content: {
                NavigationView {
                    MDLocationFormView(showAddLocation: $showAddLocation)
                } })
#endif
    }
    
    
    var content: some View {
        List {
            if filteredLocations.isEmpty {
                ContentUnavailableView("str.md.locations.empty", systemImage: MySymbols.location)
            } else if filteredLocations.isEmpty {
                ContentUnavailableView.search
            }
#if os(macOS)
            if showAddLocation {
                NavigationLink(destination: MDLocationFormView(showAddLocation: $showAddLocation), isActive: $showAddLocation, label: {
                    NewMDRowLabel(title: "str.md.location.new")
                })
                    .frame(height: showAddLocation ? 50 : 0)
            }
#endif
            ForEach(filteredLocations, id:\.id) {location in
                NavigationLink(destination: MDLocationFormView(location: location, showAddLocation: Binding.constant(false))) {
                    MDLocationRowView(location: location)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: location) },
                           label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .task {
            Task {
                await updateData()
            }
        }
        .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
        .refreshable {
            await updateData()
        }
        .animation(.default,
                   value: filteredLocations.count)
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit),
            isShown: [.successAdd, .failAdd, .successEdit, .failEdit, .failDelete].contains(toastType),
            text: { item in
            switch item {
            case .successAdd:
                return LocalizedStringKey("str.md.new.success")
            case .failAdd:
                return LocalizedStringKey("str.md.new.fail")
            case .successEdit:
                return LocalizedStringKey("str.md.edit.success")
            case .failEdit:
                return LocalizedStringKey("str.md.edit.fail")
            case .failDelete:
                return LocalizedStringKey("str.md.delete.fail")
            default:
                return LocalizedStringKey("str.error")
            }
        })
        .alert(LocalizedStringKey("str.md.location.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = locationToDelete?.id {
                    Task {
                        await deleteLocation(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(locationToDelete?.name ?? "Name not found") })
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
