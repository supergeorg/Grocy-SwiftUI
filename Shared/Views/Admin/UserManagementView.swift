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
    
    var filteredUsers: GrocyUsers {
        grocyVM.users
            .filter {
                !searchString.isEmpty ? ($0.username.localizedCaseInsensitiveContains(searchString) && $0.displayName.localizedCaseInsensitiveContains(searchString)) : true
            }
    }
    
    private func updateData() {
        grocyVM.getUsers()
        grocyVM.getSystemConfig()
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
                        UserFormView(isNewUser: true)
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
                            UserFormView(isNewUser: true)
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
                UserRowView(user: user, isCurrentUser: (grocyVM.systemConfig?.userUsername == user.username))
            }
        }
        .navigationTitle(LocalizedStringKey("str.admin.user"))
        .onAppear(perform: updateData)
        .animation(.default)
    }
}

struct UserManagementView_Previews: PreviewProvider {
    static var previews: some View {
        UserManagementView()
    }
}
