//
//  MDUserEntitiesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 14.12.20.
//

import SwiftUI

struct MDUserEntityRowView: View {
    var userEntity: MDUserEntity
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(userEntity.caption)
                .font(.largeTitle)
            Text(userEntity.name)
        }
        .padding(10)
        .multilineTextAlignment(.leading)
    }
}

struct MDUserEntitiesView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isSearching: Bool = false
    @State private var searchString: String = ""
    @State private var showAddUserEntity: Bool = false
    
    @State private var shownEditPopover: MDUserEntity? = nil
    
    @State private var reloadRotationDeg: Double = 0
    
    @State private var userEntityToDelete: MDUserEntity? = nil
    @State private var showDeleteAlert: Bool = false
    
    @State private var toastType: MDToastType?
    
    private var filteredUserEntities: MDUserEntities {
        grocyVM.mdUserEntities
            .filter {
                searchString.isEmpty ? true : ($0.name.localizedCaseInsensitiveContains(searchString) || $0.caption.localizedCaseInsensitiveContains(searchString))
            }
            .sorted {
                $0.name < $1.name
            }
    }
    
    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            userEntityToDelete = filteredUserEntities[offset]
            showDeleteAlert.toggle()
        }
    }
    
    private func deleteUserEntity(toDelID: String) {
        grocyVM.deleteMDObject(object: .userentities, id: toDelID, completion: { result in
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
    
    private func updateData() {
        grocyVM.requestData(objects: [.userentities])
    }
    
    var body: some View {
        #if os(macOS)
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
                                showAddUserEntity.toggle()
                            }, label: {Image(systemName: MySymbols.new)})
                            .popover(isPresented: self.$showAddUserEntity, content: {
                                MDUserEntityFormView(isNewUserEntity: true, toastType: $toastType)
                            })
                        }
                    })
                    ToolbarItem(placement: .automatic, content: {
                        ToolbarSearchField(searchTerm: $searchString)
                    })
                })
                .frame(minWidth: Constants.macOSNavWidth)
        }
        .navigationTitle(LocalizedStringKey("str.md.userEntities"))
        #elseif os(iOS)
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
                            showAddUserEntity.toggle()
                        }, label: {Image(systemName: MySymbols.new)})
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("str.md.userEntities"))
            .sheet(isPresented: self.$showAddUserEntity, content: {
                    NavigationView {
                        MDUserEntityFormView(isNewUserEntity: true, toastType: $toastType)
                    } })
        #endif
    }
    
    var content: some View {
        List(){
            #if os(iOS)
            if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search") }
            #endif
            if grocyVM.mdUserEntities.isEmpty {
                Text(LocalizedStringKey("str.md.userEntities.empty"))
            } else if filteredUserEntities.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult"))
            }
            ForEach(filteredUserEntities, id:\.id) { userEntity in
                NavigationLink(destination: MDUserEntityFormView(isNewUserEntity: false, userEntity: userEntity, toastType: $toastType)) {
                    MDUserEntityRowView(userEntity: userEntity)
                }
            }
            .onDelete(perform: delete)
        }
        .onAppear(perform: {
            grocyVM.requestData(objects: [.userentities], ignoreCached: false)
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
            Alert(title: Text(LocalizedStringKey("str.md.userEntity.delete.confirm")), message: Text(userEntityToDelete?.name ?? "error"), primaryButton: .destructive(Text(LocalizedStringKey("str.delete"))) {
                deleteUserEntity(toDelID: userEntityToDelete?.id ?? "")
            }, secondaryButton: .cancel())
        }
    }
}

struct MDUserEntitiesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            #if os(macOS)
            MDUserEntitiesView()
            #else
            NavigationView() {
                MDUserEntitiesView()
            }
            #endif
        }
    }
}
