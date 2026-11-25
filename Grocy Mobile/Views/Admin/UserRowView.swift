//
//  UserRowView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

/// A user in the user management: picture, display name and username, marked when it's the logged-in user.
struct UserRowView: View {
    var user: GrocyUser

    var isCurrentUser: Bool

    var body: some View {
        HStack(spacing: Spacing.medium) {
            UserAvatarView(pictureFileName: user.pictureFileName)
            VStack(alignment: .leading) {
                HStack(spacing: Spacing.xSmall) {
                    Text(user.displayName.isEmpty ? user.username : user.displayName)
                        .font(.headline)
                    if isCurrentUser {
                        Text("You")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(user.username)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .previewData) {
    List {
        UserRowView(
            user: GrocyUser(id: 1, username: "username", firstName: "First name", lastName: "Last name", displayName: "Display Name"),
            isCurrentUser: false
        )
        UserRowView(user: GrocyUser(id: 2, username: "me", displayName: "Current user"), isCurrentUser: true)
    }
}
