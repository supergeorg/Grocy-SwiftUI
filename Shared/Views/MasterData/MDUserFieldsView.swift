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
                .font(.largeTitle)
            Text(LocalizedStringKey("str.md.userFields.rowName \(userField.name)"))
            Text(LocalizedStringKey("str.md.userFields.rowEntity \(userField.entity)"))
            Text(LocalizedStringKey("str.md.userFields.rowType \(UserFieldType(rawValue: userField.type)?.getDescription().localized ?? userField.type)"))
        }
        .padding(10)
        .multilineTextAlignment(.leading)
    }
}

struct MDUserFieldsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isSearching: Bool = false
    @State private var searchString: String = ""
    @State private var showAddUserField: Bool = false
    
    @State private var shownEditPopover: MDUserField? = nil
    
    @State private var reloadRotationDeg: Double = 0
    
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
    
    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            userFieldToDelete = filteredUserFields[offset]
            showDeleteAlert.toggle()
        }
    }
    private func deleteUserField(toDelID: Int) {
        grocyVM.deleteMDObject(object: .userfields, id: toDelID, completion: { result in
            switch result {
            case let .success(message):
                print(message)
                updateData()
            case let .failure(error):
                print("\(error)")
                toastType = .failDelete
            }
        })
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
            bodyContent
        } else {
            ServerOfflineView()
                .navigationTitle(LocalizedStringKey("str.md.userFields"))
        }
    }
    
    #if os(macOS)
    var bodyContent: some View {
        NavigationView{
            content
                .toolbar(content: {
                    ToolbarItem(placement: .primaryAction, content: {
                        HStack{
                            Button(action: {
                                withAnimation {
                                    self.reloadRotationDeg += 360
                                }
                                updateData()
                            }, label: {
                                Image(systemName: MySymbols.reload)
                                    .rotationEffect(Angle.degrees(reloadRotationDeg))
                            })
                            Button(action: {
                                showAddUserField.toggle()
                            }, label: {Image(systemName: MySymbols.new)})
                        }
                    })
                    ToolbarItem(placement: .automatic, content: {
                        ToolbarSearchField(searchTerm: $searchString)
                    })
                })
                .frame(minWidth: Constants.macOSNavWidth)
        }
        .navigationTitle(LocalizedStringKey("str.md.userFields"))
    }
    #elseif os(iOS)
    var bodyContent: some View {
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack{
                        Button(action: {
                            isSearching.toggle()
                        }, label: {Image(systemName: MySymbols.search)})
                        Button(action: {
                            updateData()
                        }, label: {
                            Image(systemName: MySymbols.reload)
                        })
                        Button(action: {
                            showAddUserField.toggle()
                        }, label: {Image(systemName: MySymbols.new)})
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("str.md.userFields"))
            .sheet(isPresented: self.$showAddUserField, content: {
                    NavigationView {
                        MDUserFieldFormView(isNewUserField: true, showAddUserField: $showAddUserField, toastType: $toastType)
                    } })
    }
    #endif
    
    var content: some View {
        List(){
            #if os(iOS)
            if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search") }
            #endif
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
            }
            .onDelete(perform: delete)
        }
        .onAppear(perform: {
            grocyVM.requestData(objects: dataToUpdate, ignoreCached: false)
        })
        .animation(.default)
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit), content: { item in
            switch item {
            case .successAdd:
                Label(LocalizedStringKey("str.md.new.success"), systemImage: MySymbols.success)
            case .failAdd:
                Label(LocalizedStringKey("str.md.new.fail"), systemImage: MySymbols.failure)
            case .successEdit:
                Label(LocalizedStringKey("str.md.edit.success"), systemImage: MySymbols.success)
            case .failEdit:
                Label(LocalizedStringKey("str.md.edit.fail"), systemImage: MySymbols.failure)
            case .failDelete:
                Label(LocalizedStringKey("str.md.delete.fail"), systemImage: MySymbols.failure)
            }
        })
        .alert(isPresented: $showDeleteAlert) {
            Alert(title: Text(LocalizedStringKey("str.md.userField.delete.confirm")), message: Text(userFieldToDelete?.name ?? "error"), primaryButton: .destructive(Text(LocalizedStringKey("str.delete"))) {
                if let toDelID = userFieldToDelete?.id {
                    deleteUserField(toDelID: toDelID)
                }
            }, secondaryButton: .cancel())
        }
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
