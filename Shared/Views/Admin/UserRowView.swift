//
//  UserRowView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct UserRowActionsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    var user: GrocyUser
    var isCurrentUser: Bool
    
    
    
    let paddingValue: CGFloat = 7
    let cornerRadiusValue: CGFloat = 3
    
    @State private var showDeleteAction: Bool = false
    
    private func deleteUser() async {
        do {
            try await grocyVM.deleteUser(id: user.id)
            grocyVM.postLog("Delete user successful.", type: .info)
            await grocyVM.requestData(additionalObjects: [.users])
        } catch {
            grocyVM.postLog("Delete user failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        HStack(spacing: 2){
            RowInteractionButton(title: nil, image: "square.and.pencil", backgroundColor: Color(.GrocyColors.grocyTurquoise), helpString: LocalizedStringKey("str.admin.user.tooltip.edit"))
                .onTapGesture {
                    grocyVM.postLog("Edit user not implemented", type: .info)
                }
                .disabled(true)
            RowInteractionButton(image: "lock.fill", backgroundColor: Color(.GrocyColors.grocyTurquoise), helpString: LocalizedStringKey("str.admin.user.tooltip.permissions"))
                .onTapGesture {
                    grocyVM.postLog("Edit permissions not implemented", type: .info)
                }
                .disabled(true)
            RowInteractionButton(image: "trash.fill", backgroundColor: isCurrentUser ? Color(.GrocyColors.grocyDeleteLocked) : Color(.GrocyColors.grocyDelete), helpString: LocalizedStringKey("str.admin.user.tooltip.delete"))
                .onTapGesture {
                    showDeleteAction.toggle()
                }
                .alert(isPresented:$showDeleteAction) {
                    Alert(title: Text(LocalizedStringKey("str.admin.user.delete.question")), message: Text(""), primaryButton: .destructive(Text(LocalizedStringKey("str.delete"))) {
                        Task {
                            await deleteUser()
                        }
                    }, secondaryButton: .cancel())
                }
                .disabled(isCurrentUser)
        }
    }
}

struct UserRowView: View {
    var user: GrocyUser
    
    var isCurrentUser: Bool
    
    
    
    var body: some View {
        HStack{
            UserRowActionsView(user: user, isCurrentUser: isCurrentUser)
            Divider()
            VStack(alignment: .leading){
                Text(user.username)
                    .font(.title)
                Text(user.displayName)
                    .font(.caption)
            }
        }
    }
}

//struct UserRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        UserRowView(user: GrocyUser(id: "0", username: "username", firstName: "First name", lastName: "Last name", rowCreatedTimestamp: "ts", displayName: "Display Name", pictureFileName: nil), isCurrentUser: false)
//    }
//}
