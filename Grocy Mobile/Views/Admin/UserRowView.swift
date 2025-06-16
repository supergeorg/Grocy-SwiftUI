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
            GrocyLogger.info("Delete user successful.")
            await grocyVM.requestData(additionalObjects: [.users])
        } catch {
            GrocyLogger.error("Delete user failed. \(error)")
        }
    }
    
    var body: some View {
        HStack(spacing: 2){
            RowInteractionButton(title: nil, image: "square.and.pencil", backgroundColor: Color(.GrocyColors.grocyTurquoise), helpString: "Edit this item")
                .onTapGesture {
                    GrocyLogger.info("Edit user not implemented")
                }
                .disabled(true)
            RowInteractionButton(image: "lock.fill", backgroundColor: Color(.GrocyColors.grocyTurquoise), helpString: "Configure user permissions")
                .onTapGesture {
                    GrocyLogger.info("Edit permissions not implemented")
                }
                .disabled(true)
            RowInteractionButton(image: "trash.fill", backgroundColor: isCurrentUser ? Color(.GrocyColors.grocyDeleteLocked) : Color(.GrocyColors.grocyDelete), helpString: "Delete this item")
                .onTapGesture {
                    showDeleteAction.toggle()
                }
                .alert(isPresented:$showDeleteAction) {
                    Alert(title: Text("Do you really want to delete this user?"), message: Text(""), primaryButton: .destructive(Text("Delete")) {
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
