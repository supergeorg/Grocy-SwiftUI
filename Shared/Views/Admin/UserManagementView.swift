//
//  UserManagementView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI

struct UserManagementView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var searchString: String = ""
    
    @State private var reloadRotationDeg: Double = 0.0
    
    @State private var showAddUser: Bool = false
    
    @State private var toastType: MDToastType?
    
    var filteredUsers: GrocyUsers {
        grocyVM.users
            .filter {
                !searchString.isEmpty ? ($0.username.localizedCaseInsensitiveContains(searchString) && $0.displayName.localizedCaseInsensitiveContains(searchString)) : true
            }
    }
    
    private func updateData() {
        grocyVM.requestData(additionalObjects: [.users, .system_config])
    }
    
    var body: some View {
        #if os(macOS)
        content
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic, content: {
                    SearchBarSwiftUI(text: $searchString, placeholder: "str.search")
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
                        showAddUser.toggle()
                    }, label: {
                        HStack{
                            Text(LocalizedStringKey("str.admin.user.new"))
                            Image(systemName: MySymbols.new)
                        }
                    })
                    .popover(isPresented: $showAddUser, content: {
                        UserFormView(isNewUser: true, toastType: $toastType)
                            .padding()
                    })
                })
            })
        #elseif os(iOS)
        content
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic, content: {
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
                        showAddUser.toggle()
                    }, label: {
                        HStack{
                            Text(LocalizedStringKey("str.admin.user.new"))
                            Image(systemName: MySymbols.new)
                        }
                    })
                    .sheet(isPresented: $showAddUser, content: {
                        NavigationView{
                            UserFormView(isNewUser: true, toastType: $toastType)
                        }
                    })
                })
            })
        #endif
    }
    
    var content: some View {
        List{
            if grocyVM.users.isEmpty {
                Text(LocalizedStringKey("str.admin.user.empty")).padding()
            }
            ForEach(filteredUsers, id:\.id) {user in
                UserRowView(user: user, isCurrentUser: (grocyVM.systemConfig?.userUsername == user.username), toastType: $toastType)
            }
        }
        .navigationTitle(LocalizedStringKey("str.admin.user"))
        .onAppear(perform: updateData)
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit), content: { item in
            switch item {
            case .successAdd:
                Label(LocalizedStringKey("str.md.new.success"), systemImage: MySymbols.success)
            case .successEdit:
                Label(LocalizedStringKey("str.md.edit.success"), systemImage: MySymbols.success)
            case .failDelete:
                Label(LocalizedStringKey("str.md.delete.fail"), systemImage: MySymbols.failure)
            default:
                EmptyView()
            }
        })
        .animation(.default)
    }
}

struct UserManagementView_Previews: PreviewProvider {
    static var previews: some View {
        UserManagementView()
    }
}
