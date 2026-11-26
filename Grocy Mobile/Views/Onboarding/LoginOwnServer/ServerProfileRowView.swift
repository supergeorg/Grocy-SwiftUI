//
//  ServerProfileRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.25.
//

import SwiftUI

struct ServerProfileRowView: View {
    @AppStorage("selectedServerProfileID") private var selectedServerProfileID: UUID?

    let profile: ServerProfile

    var isActive: Bool {
        return profile.id == selectedServerProfileID
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(profile.name.isEmpty ? profile.grocyServerURL : profile.name)
                        .font(profile.name.isEmpty ? .title2 : .largeTitle)
                    if profile.useHassIngress {
                        Image(systemName: MySymbols.homeAssistant)
                            .foregroundStyle(.tint)
                    }
                }
                if !profile.userName.isEmpty || !profile.displayName.isEmpty || profile.profilePicture != nil {
                    HStack(alignment: .center) {
                        if let profilePicture = profile.profilePicture {
                            #if os(iOS)
                                if let image = UIImage(data: profilePicture) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: Sizes.avatar, height: Sizes.avatar)
                                        .clipShape(.circle)
                                }
                            #elseif os(macOS)
                                if let image = NSImage(data: profilePicture) {
                                    Image(nsImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: Sizes.avatar, height: Sizes.avatar)
                                        .clipShape(.circle)
                                }
                            #endif
                        }
                        Text(profile.displayName)
                            .font(.subheadline)
                        Text(profile.userName)
                            .font(.caption)
                            .italic()
                    }
                }
                if !profile.name.isEmpty {
                    Text(profile.grocyServerURL)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: isActive ? MySymbols.active : MySymbols.inactive)
                .foregroundStyle(isActive ? .green : .primary)
        }
    }
}

#Preview {
    let selectedProfile = ServerProfile(name: "My profile", grocyServerURL: "http://homeserver.local:8123", userName: "username", displayName: "Display Name")
    let defaults = UserDefaults(suiteName: "Preview")!
    defaults.set(selectedProfile.id.uuidString, forKey: "selectedServerProfileID")

    return Form {
        ServerProfileRowView(profile: ServerProfile(name: "", grocyServerURL: "http://homeserver.local:8123"))
        ServerProfileRowView(profile: ServerProfile(name: "Demo profile", grocyServerURL: "http://homeserver.local:8123"))
        ServerProfileRowView(profile: ServerProfile(name: "Home Assistant", grocyServerURL: "http://homeassistant.local:8123", useHassIngress: true))
        ServerProfileRowView(profile: selectedProfile)
    }
    .defaultAppStorage(defaults)
}
