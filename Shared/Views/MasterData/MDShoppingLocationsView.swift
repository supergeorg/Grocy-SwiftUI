//
//  MDShoppingLocationsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDShoppingLocationRowView: View {
    var shoppingLocation: MDShoppingLocation
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(shoppingLocation.name)
                .font(.title)
            if let description = shoppingLocation.mdShoppingLocationDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDShoppingLocationsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var searchString: String = ""
    
    @State private var showAddShoppingLocation: Bool = false
    @State private var shoppingLocationToDelete: MDShoppingLocation? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var toastType: ToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.shopping_locations]
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredShoppingLocations: MDShoppingLocations {
        grocyVM.mdShoppingLocations
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDShoppingLocation) {
        shoppingLocationToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteShoppingLocation(toDelID: Int) {
        grocyVM.deleteMDObject(object: .shopping_locations,
                               id: toDelID,
                               completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog("Deleting shopping location was successful. \(message)", type: .info)
                updateData()
            case let .failure(error):
                grocyVM.postLog("Deleting shopping location failed. \(error)", type: .error)
                toastType = .failDelete
            }
        })
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter( {dataToUpdate.contains($0) })
            .count == 0 {
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
                .navigationTitle(LocalizedStringKey("str.md.shoppingLocations"))
        }
    }
    
    var bodyContent: some View {
        content
            .toolbar(content: {
                ToolbarItemGroup(placement: .primaryAction, content: {
#if os(macOS)
                    RefreshButton(updateData: { updateData() })
#endif
                    Button(action: {
                        showAddShoppingLocation.toggle()
                    }, label: {
                        Image(systemName: MySymbols.new)
                    })
                })
            })
            .navigationTitle(LocalizedStringKey("str.md.shoppingLocations"))
#if os(iOS)
            .sheet(isPresented: self.$showAddShoppingLocation, content: {
                NavigationView {
                    MDShoppingLocationFormView(isNewShoppingLocation: true, showAddShoppingLocation: $showAddShoppingLocation, toastType: $toastType)
                }
            })
#endif
    }
    
    var content: some View {
        List{
            if grocyVM.mdShoppingLocations.isEmpty {
                Text(LocalizedStringKey("str.md.shoppingLocations.empty"))
            } else if filteredShoppingLocations.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult"))
            }
#if os(macOS)
            if showAddShoppingLocation {
                NavigationLink(destination: MDShoppingLocationFormView(isNewShoppingLocation: true, showAddShoppingLocation: $showAddShoppingLocation, toastType: $toastType), isActive: $showAddShoppingLocation, label: {
                    NewMDRowLabel(title: "str.md.shoppingLocation.new")
                })
            }
#endif
            ForEach(filteredShoppingLocations, id:\.id) { shoppingLocation in
                NavigationLink(destination: MDShoppingLocationFormView(isNewShoppingLocation: false, shoppingLocation: shoppingLocation, showAddShoppingLocation: Binding.constant(false), toastType: $toastType)) {
                    MDShoppingLocationRowView(shoppingLocation: shoppingLocation)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: shoppingLocation) },
                           label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .onAppear(perform: {
            grocyVM.requestData(objects: dataToUpdate)
        })
        .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
        .refreshable { updateData() }
        .animation(.default,
                   value: filteredShoppingLocations.count)
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
        .alert(LocalizedStringKey("str.md.shoppingLocation.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = shoppingLocationToDelete?.id {
                    deleteShoppingLocation(toDelID: toDelID)
                }
            }
        }, message: { Text(shoppingLocationToDelete?.name ?? "Name not found") })
    }
}

struct MDShoppingLocationsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            List {
                MDShoppingLocationRowView(shoppingLocation: MDShoppingLocation(id: 0, name: "Location", mdShoppingLocationDescription: "Description", rowCreatedTimestamp: ""))
            }
#if os(macOS)
            MDShoppingLocationsView()
#else
            NavigationView() {
                MDShoppingLocationsView()
            }
#endif
        }
    }
}
