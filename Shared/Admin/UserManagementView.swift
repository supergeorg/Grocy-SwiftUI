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
    }
    
    var body: some View {
        #if os(macOS)
        content
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic, content: {
                    SearchBar(text: $searchString, placeholder: "str.search".localized)
                    Button(action: {
                        withAnimation {
                            self.reloadRotationDeg += 360
                        }
                        updateData()
                    }, label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(Angle.degrees(reloadRotationDeg))
                    })
                    Button(action: {
                        showAddUser.toggle()
                    }, label: {
                        HStack{
                            Text("str.admin.user.new".localized)
                            Image(systemName: "plus")
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
        #endif
    }
    
    var content: some View {
        List{
            if grocyVM.users.isEmpty {
                Text("Keine Nutzer gefunden.").padding()
            }
            ForEach(filteredUsers, id:\.id) {user in
                UserRowView(user: user)
            }
        }
        .navigationTitle("str.admin.user".localized)
        .onAppear(perform: updateData)
        .animation(.default)
    }
}

struct UserManagementView_Previews: PreviewProvider {
    static var previews: some View {
        UserManagementView()
    }
}
