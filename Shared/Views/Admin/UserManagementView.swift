//
//  UserManagementView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI

struct UserManagementView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @State private var searchString: String = ""
    
    @State private var reloadRotationDeg: Double = 0.0
    
    @State private var showAddUser: Bool = false
    
    private let additionalDataToUpdate: [AdditionalEntities] = [.users, .system_config]
    
    private func updateData() async {
        await grocyVM.requestData(additionalObjects: additionalDataToUpdate)
    }
    
//    var filteredUsers: GrocyUsers {
//        grocyVM.users
//            .filter {
//                !searchString.isEmpty ? ($0.username.localizedCaseInsensitiveContains(searchString) && $0.displayName.localizedCaseInsensitiveContains(searchString)) : true
//            }
//    }
    
    var body: some View {
        if grocyVM.failedToLoadAdditionalObjects.filter({additionalDataToUpdate.contains($0)}).count == 0 {
            bodyContent
        } else {
            ServerProblemView()
                .navigationTitle("User management")
        }
    }
    
#if os(macOS)
    var bodyContent: some View {
        content
            .toolbar(content: {
                ToolbarItem(placement: .automatic, content: {
                    Button(action: {
                        withAnimation {
                            self.reloadRotationDeg += 360
                        }
                        Task {
                            await updateData()
                        }
                    }, label: {
                        Image(systemName: MySymbols.reload)
                            .rotationEffect(Angle.degrees(reloadRotationDeg))
                    })
                })
                
                ToolbarItem(placement: .automatic, content: {
                    Button(action: {
                        showAddUser.toggle()
                    }, label: {
                        HStack{
                            Text("New user")
                            Image(systemName: MySymbols.new)
                        }
                    })
                    .popover(isPresented: $showAddUser, content: {
                        UserFormView(isNewUser: true)
                            .padding()
                            .frame(width: 500, height: 500)
                    })
                })
            })
    }
#elseif os(iOS)
    var bodyContent: some View {
        content
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic, content: {
                    Button(action: {
                        showAddUser.toggle()
                    }, label: {
                        HStack{
                            Text("New user")
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
    }
#endif
    
    var content: some View {
        List{
//            if grocyVM.users.isEmpty {
//                Text("No users found").padding()
//            }
//            ForEach(filteredUsers, id:\.id) {user in
//                UserRowView(user: user, isCurrentUser: (grocyVM.systemConfig?.userUsername == user.username))
//            }
        }
        .navigationTitle("User management")
        .task {
            Task {
                await updateData()
            }
        }
        .refreshable {
            await updateData()
        }
    }
}

struct UserManagementView_Previews: PreviewProvider {
    static var previews: some View {
        UserManagementView()
    }
}
