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
    
    @Binding var toastType: MDToastType?
    
    let paddingValue: CGFloat = 7
    let cornerRadiusValue: CGFloat = 3
    
    @State private var showDeleteAction: Bool = false
    
    private func deleteUser() {
        grocyVM.deleteUser(id: user.id, completion: { result in
            switch result {
            case let .success(message):
                print(message)
//                toastType = .successAdd
                grocyVM.requestData(additionalObjects: [.users])
            case let .failure(error):
                print("\(error)")
                toastType = .failDelete
            }
        })
    }
    
    var body: some View {
        HStack(spacing: 2){
            RowInteractionButton(title: nil, image: "square.and.pencil", backgroundColor: Color.grocyTurquoise, helpString: LocalizedStringKey("str.admin.user.tooltip.edit"))
                .onTapGesture {
                    grocyVM.postLog(message: "Edit user not implemented", type: .info)
                }
                .disabled(true)
            RowInteractionButton(image: "lock.fill", backgroundColor: Color.grocyTurquoise, helpString: LocalizedStringKey("str.admin.user.tooltip.permissions"))
                .onTapGesture {
                    grocyVM.postLog(message: "Edit permissions not implemented", type: .info)
                }
                .disabled(true)
            RowInteractionButton(image: "trash.fill", backgroundColor: isCurrentUser ? Color.grocyDeleteLocked : Color.grocyDelete, helpString: LocalizedStringKey("str.admin.user.tooltip.delete"))
                .onTapGesture {
                    showDeleteAction.toggle()
                }
                .alert(isPresented:$showDeleteAction) {
                    Alert(title: Text(LocalizedStringKey("str.admin.user.delete.question")), message: Text(""), primaryButton: .destructive(Text(LocalizedStringKey("str.delete"))) {
                        deleteUser()
                    }, secondaryButton: .cancel())
                }
                .disabled(isCurrentUser)
        }
    }
}

struct UserRowView: View {
    var user: GrocyUser
    
    var isCurrentUser: Bool
    
    @Binding var toastType: MDToastType?
    
    var body: some View {
        HStack{
            UserRowActionsView(user: user, isCurrentUser: isCurrentUser, toastType: $toastType)
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
        UserRowView(user: GrocyUser(id: "0", username: "username", firstName: "First name", lastName: "Last name", rowCreatedTimestamp: "ts", displayName: "Display Name", pictureFileName: nil), isCurrentUser: false, toastType: Binding.constant(nil))
    }
}
