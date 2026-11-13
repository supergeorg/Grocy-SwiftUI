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
        // Real buttons (not tap gestures), labeled for VoiceOver; the icon-only style keeps the row compact.
        HStack {
            Button {
                GrocyLogger.info("Edit user not implemented")
            } label: {
                Label("Edit this item", systemImage: MySymbols.edit)
            }
            .help("Edit this item")
            .disabled(true)
            Button {
                GrocyLogger.info("Edit permissions not implemented")
            } label: {
                Label("Configure user permissions", systemImage: MySymbols.permissions)
            }
            .help("Configure user permissions")
            .disabled(true)
            Button(role: .destructive) {
                showDeleteAction.toggle()
            } label: {
                Label("Delete this item", systemImage: MySymbols.delete)
            }
            .help("Delete this item")
            .disabled(isCurrentUser)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .alert(
            "Are you sure you want to delete user \"\(user.displayName)\"?",
            isPresented: $showDeleteAction,
            actions: {
                Button("Cancel", role: .cancel) {}
                // No destructive role: the person chose to delete, this button carries out their intent (HIG).
                Button("Delete") {
                    Task {
                        await deleteUser()
                    }
                }
            },
            message: {
                Text("This can't be undone.")
            }
        )
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
