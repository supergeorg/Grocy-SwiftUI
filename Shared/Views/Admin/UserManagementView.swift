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
    
    @State private var toastType: ToastType?
    
    private let additionalDataToUpdate: [AdditionalEntities] = [.users, .system_config]
    
    private func updateData() {
        grocyVM.requestData(additionalObjects: additionalDataToUpdate)
    }
    
    var filteredUsers: GrocyUsers {
        grocyVM.users
            .filter {
                !searchString.isEmpty ? ($0.username.localizedCaseInsensitiveContains(searchString) && $0.displayName.localizedCaseInsensitiveContains(searchString)) : true
            }
    }
    
    var body: some View {
        if grocyVM.failedToLoadAdditionalObjects.filter({additionalDataToUpdate.contains($0)}).count == 0 {
            bodyContent
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.admin.user"))
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
                        updateData()
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
                            Text(LocalizedStringKey("str.admin.user.new"))
                            Image(systemName: MySymbols.new)
                        }
                    })
                    .popover(isPresented: $showAddUser, content: {
                        UserFormView(isNewUser: true, toastType: $toastType)
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
    }
#endif
    
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
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit),
            isShown: [.successAdd, .successEdit, .failDelete].contains(toastType),
            text: { item in
                switch item {
                case .successAdd:
                    return LocalizedStringKey("str.md.new.success")
                case .successEdit:
                    return LocalizedStringKey("str.md.edit.success")
                case .failDelete:
                    return LocalizedStringKey("str.md.delete.fail")
                default:
                    return LocalizedStringKey("")
                }
            })
    }
}

struct UserManagementView_Previews: PreviewProvider {
    static var previews: some View {
        UserManagementView()
    }
}
