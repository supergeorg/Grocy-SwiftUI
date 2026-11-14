//
//  ServerSelectionView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.25.
//

import SwiftData
import SwiftUI

struct ServerSelectionView: View {
    @Environment(\.profileModelContext) private var profileModelContext
    @State private var showAddServer: Bool = false
    @State private var serverProfiles: [ServerProfile] = []

    @AppStorage("selectedServerProfileID") private var selectedServerProfileID: UUID?
    @AppStorage("localizationKey") var localizationKey: String = "en"

    private func fetchServerProfiles() {
        guard let modelContext = profileModelContext else { return }
        let descriptor = FetchDescriptor<ServerProfile>(sortBy: [SortDescriptor(\.id, order: .forward)])
        serverProfiles = (try? modelContext.fetch(descriptor)) ?? []
    }

    var selectedServerProfile: ServerProfile? {
        guard let selectedServerProfileID = selectedServerProfileID else { return nil }
        return serverProfiles.first(where: { $0.id == selectedServerProfileID })
    }

    var body: some View {
        List {
            ForEach(serverProfiles, id: \.id) { serverProfile in
                Button(
                    action: {
                        selectedServerProfileID = serverProfile.id
                    },
                    label: {
                        ServerProfileRowView(profile: serverProfile)
                    }
                )
                .foregroundStyle(.primary)
                .contextMenu(menuItems: {
                    contextMenuContent(for: serverProfile)
                })
            }
            .onDelete(perform: deleteProfiles)
        }
        .navigationTitle("Own server")
        .onAppear {
            fetchServerProfiles()
            if serverProfiles.isEmpty {
                showAddServer.toggle()
            }
        }
        .toolbar(content: {
            ToolbarItem(
                placement: .primaryAction,
                content: {
                    Button(
                        action: {
                            showAddServer.toggle()
                        },
                        label: {
                            Image(systemName: MySymbols.new)
                        }
                    )
                }
            )
        })
        .safeAreaBar(
            edge: .bottom,
            content: {
                if selectedServerProfile != nil {
                    NavigationLink(
                        value: LoginDestination(type: .ownServer),
                        label: {
                            Label("Login", systemImage: MySymbols.login)
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                        }
                    )
                    // System glass style: handles pressed and disabled states and keeps the label legible.
                    .buttonStyle(.glassProminent)
                    .tint(Color(.GrocyColors.grocyGreen))
                    .controlSize(.large)
                    // Keep the system side margin; the full-width label would otherwise touch the screen edges.
                    .padding(.horizontal)
                }
            }
        )
        #if os(iOS)
            .sheet(
                isPresented: $showAddServer,
                onDismiss: {
                    fetchServerProfiles()
                },
                content: {
                    NavigationStack {
                        ServerProfileFormView()
                    }
                    .environment(\.profileModelContext, profileModelContext)
                }
            )
        #else
            .sheet(
                isPresented: $showAddServer,
                onDismiss: {
                    fetchServerProfiles()
                },
                content: {
                    ServerProfileFormView()
                        .environment(\.profileModelContext, profileModelContext)
                }
            )
        #endif
    }

    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            profileModelContext?.delete(serverProfiles[index])
        }
    }

    @ViewBuilder
    private func contextMenuContent(for profile: ServerProfile) -> some View {
        NavigationLink(
            value: profile,
            label: {
                Label("Edit", systemImage: MySymbols.edit)
            }
        )
        Button(
            action: {
                duplicateProfile(profile)
            },
            label: {
                Label("Copy", systemImage: MySymbols.duplicate)
            }
        )
    }

    private func duplicateProfile(_ profile: ServerProfile) {
        var resource = LocalizedStringResource("Copy of \(profile.name)")
        resource.locale = Locale(identifier: localizationKey)
        let newServerProfile = ServerProfile(
            name: String(localized: resource),
            grocyServerURL: profile.grocyServerURL,
            grocyAPIKey: profile.grocyAPIKey,
            useHassIngress: profile.useHassIngress,
            hassToken: profile.hassToken,
            customHeaders: profile.customHeaders ?? [],
        )
        profileModelContext?.insert(newServerProfile)
        _ = try? profileModelContext?.save()
        fetchServerProfiles()
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        ServerSelectionView()
    }
}
