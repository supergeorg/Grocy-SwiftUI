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
    /// The form for a new object zooms out of the create button.
    @Namespace private var addTransition
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
        .overlay {
            if serverProfiles.isEmpty {
                ContentUnavailableView {
                    Label("No servers", systemImage: MySymbols.ownServer)
                } description: {
                    Text("No server added yet. Please add one.")
                } actions: {
                    Button("Add server") {
                        showAddServer = true
                    }
                }
            }
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
                            Label("Add server", systemImage: MySymbols.new)
                        }
                    )
                }
            )
            #if os(iOS)
                .matchedTransitionSource(id: ZoomTransitionID.add, in: addTransition)
            #endif
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
                    .navigationTransition(.zoom(sourceID: ZoomTransitionID.add, in: addTransition))
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
            let profile = serverProfiles[index]
            if profile.id == selectedServerProfileID {
                selectedServerProfileID = nil
            }
            profileModelContext?.delete(profile)
        }
        do {
            try profileModelContext?.save()
        } catch {
            GrocyLogger.error("Deleting server profile failed. \(error)")
        }
        // Refresh, so the list (and its empty state after the last server) shows the deletion.
        fetchServerProfiles()
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
