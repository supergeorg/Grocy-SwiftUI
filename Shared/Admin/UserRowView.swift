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
    
    let paddingValue: CGFloat = 7
    let cornerRadiusValue: CGFloat = 3
    
    @State private var showDeleteAction: Bool = false
    
    var body: some View {
        HStack(spacing: 2){
            Image(systemName: "square.and.pencil")
                .font(Font.system(size: 15, weight: .bold))
                .padding(paddingValue)
                .background(Color.grocyTurquoise)
                .foregroundColor(.white)
                .cornerRadius(cornerRadiusValue)
                .help("str.admin.user.tooltip.edit".localized)
                .onTapGesture {
                    print("edit user")
                }
            Image(systemName: "lock.fill")
                .font(Font.system(size: 15, weight: .bold))
                .padding(paddingValue)
                .background(Color.grocyTurquoise)
                .foregroundColor(.white)
                .cornerRadius(cornerRadiusValue)
                .help("str.admin.user.tooltip.permissions".localized)
                .onTapGesture {
                    print("edit userpermissions")
                }
            Image(systemName: "trash.fill")
                .font(Font.system(size: 15, weight: .bold))
                .padding(paddingValue)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(cornerRadiusValue)
                .help("str.admin.user.tooltip.delete".localized)
                .onTapGesture {
                    showDeleteAction.toggle()
                }
                .alert(isPresented:$showDeleteAction) {
                    Alert(title: Text("str.admin.user.delete.question".localized), message: Text(""), primaryButton: .destructive(Text("str.delete")) {
                        grocyVM.deleteUser(id: user.id)
                        grocyVM.getUsers()
                    }, secondaryButton: .cancel())
                }
        }
    }
}

struct UserRowView: View {
    var user: GrocyUser
    
    var body: some View {
        HStack{
            UserRowActionsView(user: user)
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
        UserRowView(user: GrocyUser(id: "0", username: "username", firstName: "First name", lastName: "Last name", rowCreatedTimestamp: "ts", displayName: "Display Name"))
    }
}
