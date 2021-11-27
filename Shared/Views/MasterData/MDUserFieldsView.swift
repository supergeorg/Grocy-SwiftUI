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
            Text(LocalizedStringKey("str.md.userFields.rowName \(userField.name)"))
            Text(LocalizedStringKey("str.md.userFields.rowEntity \(userField.entity)"))
            Text(LocalizedStringKey("str.md.userFields.rowType \("")"))
            +
            Text(LocalizedStringKey(UserFieldType(rawValue: userField.type)?.getDescription() ?? userField.type))
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDUserFieldsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var searchString: String = ""
    @State private var showAddUserField: Bool = false
    
    @State private var shownEditPopover: MDUserField? = nil
    
    @State private var userFieldToDelete: MDUserField? = nil
    @State private var showDeleteAlert: Bool = false
    
    @State private var toastType: MDToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.userfields]
    
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredUserFields: MDUserFields {
        grocyVM.mdUserFields
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDUserField) {
        userFieldToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteUserField(toDelID: Int) {
        grocyVM.deleteMDObject(object: .userfields, id: toDelID, completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog(message: "Deleting userfield was successful. \(message)", type: .info)
                updateData()
            case let .failure(error):
                grocyVM.postLog(message: "Deleting userfield failed. \(error)", type: .error)
                toastType = .failDelete
            }
        })
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
                .navigationTitle(LocalizedStringKey("str.md.userFields"))
        }
    }
    
    var bodyContent: some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
#if os(macOS)
                    RefreshButton(updateData: { updateData() })
#endif
                    Button(action: {
                        showAddUserField.toggle()
                    }, label: {Image(systemName: MySymbols.new)})
                }
            }
            .navigationTitle(LocalizedStringKey("str.md.userFields"))
#if os(iOS)
            .sheet(isPresented: self.$showAddUserField, content: {
                NavigationView {
                    MDUserFieldFormView(isNewUserField: true, showAddUserField: $showAddUserField, toastType: $toastType)
                } })
#endif
    }
    
    var content: some View {
        List{
            if grocyVM.mdUserFields.isEmpty {
                Text(LocalizedStringKey("str.md.userFields.empty"))
            } else if filteredUserFields.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult"))
            }
#if os(macOS)
            if showAddUserField {
                NavigationLink(destination: MDUserFieldFormView(isNewUserField: true, showAddUserField: $showAddUserField, toastType: $toastType), isActive: $showAddUserField, label: {
                    NewMDRowLabel(title: "str.md.userField.new")
                })
            }
#endif
            ForEach(filteredUserFields, id:\.id) { userField in
                NavigationLink(destination: MDUserFieldFormView(isNewUserField: false, userField: userField, showAddUserField: Binding.constant(false), toastType: $toastType)) {
                    MDUserFieldRowView(userField: userField)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: userField) },
                           label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .onAppear(perform: {
            grocyVM.requestData(objects: dataToUpdate, ignoreCached: false)
        })
        .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
        .refreshable { updateData() }
        .animation(.default, value: filteredUserFields.count)
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit), text: { item in
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
            }
        })
        .alert(LocalizedStringKey("str.md.userField.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = userFieldToDelete?.id {
                    deleteUserField(toDelID: toDelID)
                }
            }
        }, message: { Text(userFieldToDelete?.name ?? "Name not found") })
    }
}

struct MDUserFieldsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDUserFieldRowView(userField: MDUserField(id: 1, name: "Test", entity: "locations", caption: "caption", type: "1", showAsColumnInTables: 0, config: nil, sortNumber: nil, rowCreatedTimestamp: "ts"))
#if os(macOS)
            MDUserFieldsView()
#else
            NavigationView() {
                MDUserFieldsView()
            }
#endif
        }
    }
}
