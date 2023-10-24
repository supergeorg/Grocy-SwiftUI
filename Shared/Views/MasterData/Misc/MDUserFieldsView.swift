//
//  MDUserFieldsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 11.12.20.
//

import SwiftUI

struct MDUserFieldRowView: View {
    var userField: MDUserField
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(userField.caption)
                .font(.title)
            Text("Name: \(userField.name)")
            Text("Entity: \(userField.entity)")
            Text("Type: \("")")
            +
            Text(LocalizedStringKey(UserFieldType(rawValue: userField.type)?.getDescription() ?? userField.type))
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDUserFieldsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var searchString: String = ""
    @State private var showAddUserField: Bool = false
    
    @State private var shownEditPopover: MDUserField? = nil
    
    @State private var userFieldToDelete: MDUserField? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.userfields]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredUserFields: MDUserFields {
        grocyVM.mdUserFields
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDUserField) {
        userFieldToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    private func deleteUserField(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .userfields, id: toDelID)
            grocyVM.postLog("Deleting userfield was successful.", type: .info)
            await updateData()
        } catch {
            grocyVM.postLog("Deleting userfield failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
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
                .navigationTitle("Userfields")
        }
    }
    
    var bodyContent: some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
#if os(macOS)
                    RefreshButton(updateData: { Task { await updateData() } })
#endif
                    Button(action: {
                        showAddUserField.toggle()
                    }, label: {Image(systemName: MySymbols.new)})
                }
            }
            .navigationTitle("Userfields")
#if os(iOS)
            .sheet(isPresented: self.$showAddUserField, content: {
                NavigationView {
                    MDUserFieldFormView(isNewUserField: true, showAddUserField: $showAddUserField)
                } })
#endif
    }
    
    var content: some View {
        List{
            if grocyVM.mdUserFields.isEmpty {
                Text("No userfields found.")
            } else if filteredUserFields.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(filteredUserFields, id:\.id) { userField in
                NavigationLink(destination: MDUserFieldFormView(isNewUserField: false, userField: userField, showAddUserField: Binding.constant(false))) {
                    MDUserFieldRowView(userField: userField)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: userField) },
                           label: { Label("Delete", systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .task {
            Task {
                await updateData()
            }
        }
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredUserFields.count)
        .alert("Do you really want to delete this userfield?", isPresented: $showDeleteConfirmation, actions: {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let toDelID = userFieldToDelete?.id {
                    Task {
                        await deleteUserField(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(userFieldToDelete?.name ?? "Name not found") })
    }
}

#Preview {
    MDUserFieldsView()
}
