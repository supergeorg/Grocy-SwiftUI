//
//  UserManagementView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI

struct UserRowView: View {
    var user: GrocyUser

        var body: some View {
            VStack(alignment: .leading){
                Text(user.displayName).font(.title)
                Group {
                    Text("Username: ")
                        +
                        Text(user.username)
                        +
                        Text(", ID: ")
                        +
                        Text(user.id)
                }.font(.caption)
            }
        }
}

struct UserManagementView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var body: some View {
        List{
            if grocyVM.users.isEmpty {
                Text("Keine Nutzer gefunden.").padding()
            }
            ForEach(grocyVM.users, id:\.id) {user in
//                Text(user.username)
                UserRowView(user: user)
            }
        }
        .onAppear(perform: grocyVM.getUsers)
    }
}

struct UserManagementView_Previews: PreviewProvider {
    static var previews: some View {
        UserManagementView()
    }
}
