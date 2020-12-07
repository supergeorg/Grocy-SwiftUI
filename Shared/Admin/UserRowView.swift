//
//  UserRowView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct UserRowActionsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var user: GrocyUser
    var isCurrentUser: Bool
    
    let paddingValue: CGFloat = 7
    let cornerRadiusValue: CGFloat = 3
    
    @State private var showDeleteAction: Bool = false
    
    var body: some View {
        HStack(spacing: 2){
            RowInteractionButton(title: nil, image: "square.and.pencil", backgroundColor: Color.grocyTurquoise, helpString: LocalizedStringKey("str.admin.user.tooltip.edit"))
                .onTapGesture {
                    print("edit user")
                }
            RowInteractionButton(image: "lock.fill", backgroundColor: Color.grocyTurquoise, helpString: LocalizedStringKey("str.admin.user.tooltip.permissions"))
                .onTapGesture {
                    print("edit userpermissions")
                }
            RowInteractionButton(image: "trash.fill", backgroundColor: isCurrentUser ? Color.grocyDeleteLocked : Color.grocyDelete, helpString: LocalizedStringKey("str.admin.user.tooltip.delete"))
                .onTapGesture {
                    showDeleteAction.toggle()
                }
                .alert(isPresented:$showDeleteAction) {
                    Alert(title: Text("str.admin.user.delete.question".localized), message: Text(""), primaryButton: .destructive(Text("str.delete")) {
                        grocyVM.deleteUser(id: user.id)
                        grocyVM.getUsers()
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

struct UserRowView_Previews: PreviewProvider {
    static var previews: some View {
        UserRowView(user: GrocyUser(id: "0", username: "username", firstName: "First name", lastName: "Last name", rowCreatedTimestamp: "ts", displayName: "Display Name"), isCurrentUser: false)
    }
}
