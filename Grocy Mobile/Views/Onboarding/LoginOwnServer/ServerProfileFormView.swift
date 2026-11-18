//
//  ServerProfileFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.25.
//

import AVFoundation
import SwiftData
import SwiftUI
import Vision

struct ListElementRow: View {
    @Bindable var header: LoginCustomHeader

    var body: some View {
        HStack {
            TextField("Name", text: $header.headerName)
                .autocorrectionDisabled(true)
            Text(":")
            TextField("Value", text: $header.headerValue)
                .autocorrectionDisabled(true)
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                #endif
        }
    }
}

struct ServerProfileFormView: View {
    @Environment(\.profileModelContext) private var profileModelContext
    @Environment(\.dismiss) private var dismiss

    @State private var serverProfile: ServerProfile
    @AppStorage("selectedServerProfileID") private var selectedServerProfileID: UUID?
    var isEditing: Bool = false

    init(serverProfile: ServerProfile? = nil) {
        if serverProfile != nil {
            isEditing = true
        }
        self.serverProfile = serverProfile ?? ServerProfile()
    }

    var selectedServerProfile: ServerProfile? {
        guard let selectedServerProfileID = selectedServerProfileID else { return nil }
        let descriptor = FetchDescriptor<ServerProfile>(predicate: #Predicate<ServerProfile> { $0.id == selectedServerProfileID })
        return (try? profileModelContext?.fetch(descriptor))?.first
    }

    #if os(iOS)
        @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
        @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

        @State private var isShowingGrocyScanner: Bool = false
        func handleGrocyScan(result: CodeResult) {
            self.isShowingGrocyScanner = false
            let grocyServerData = result.value.components(separatedBy: "|")
            guard grocyServerData.count == 2 else { return }

            let serverURL = grocyServerData[0]
            let apiKey = grocyServerData[1]

            if apiKey.count == 50 {
                serverProfile.grocyServerURL = serverURL
                serverProfile.grocyAPIKey = apiKey
            }
        }
        @State private var isShowingTokenScanner: Bool = false
        func handleHassTokenScan(result: CodeResult) {
            self.isShowingTokenScanner = false
            serverProfile.hassToken = result.value
        }
    #endif

    var body: some View {
        Form {
            Section("Server") {
                MyTextField(
                    textToEdit: $serverProfile.name,
                    description: "Name",
                    isCorrect: Binding.constant(true),
                    leadingIcon: MySymbols.name
                )
                MyTextField(
                    textToEdit: $serverProfile.grocyServerURL,
                    description: "Server URL",
                    isCorrect: Binding.constant(true),
                    leadingIcon: "network",
                    helpText: "Server-URL of your Grocy Instance (if you use Home Assistant Ingress, this can be accessed via right click on REST API Browser in the web interface)"
                )
                .textContentType(.URL)
                #if os(iOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled(true)

                MyTextField(
                    textToEdit: $serverProfile.grocyAPIKey,
                    description: "Valid API key",
                    isCorrect: Binding.constant(true),
                    leadingIcon: "key",
                    helpText: "API key for the user which is shown in the Manage API keys webview. If none exist, you need to create a new one."
                )
                .autocorrectionDisabled(true)
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                #endif
                if !serverProfile.grocyServerURL.isEmpty, let manageKeysURL = URL(string: "\(serverProfile.grocyServerURL)/manageapikeys") {
                    Link(
                        destination: manageKeysURL,
                        label: {
                            Label("Create API key", systemImage: MySymbols.apiKey)
                        }
                    )
                }
                #if os(iOS)
                    Button(
                        action: {
                            isShowingGrocyScanner.toggle()
                        },
                        label: {
                            Label("QR-Scan", systemImage: MySymbols.qrScan)
                        }
                    )
                    .sheet(
                        isPresented: $isShowingGrocyScanner,
                        content: {
                            CodeScannerSheetView(title: "QR-Scan", symbologies: [.qr], onCodeFound: self.handleGrocyScan)
                        }
                    )
                #endif
            }
            Section("Home Assistant Ingress") {
                MyToggle(isOn: $serverProfile.useHassIngress, description: "Use Home Assistant Ingress", icon: MySymbols.homeAssistant)
                if serverProfile.useHassIngress {
                    // The field gets the whole row, so the form can place its label above it when the label is long.
                    // The QR scan is its own row, like the Grocy QR scan above.
                    MyTextField(
                        textToEdit: $serverProfile.hassToken,
                        description: "Long-lived access token",
                        isCorrect: Binding.constant(true),
                        leadingIcon: MySymbols.apiKey,
                        helpText:
                            "This token has to be generated out of your Home Assistant Web interface. To do this, open your Home Assistant Profile page, scroll down to Long-Lived Access Tokens and create one. Name it and copy the resulting Token in the App or create a QR Code and scan it (iOS)."
                    )
                    .autocorrectionDisabled(true)
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                    #endif
                    #if os(iOS)
                        Button(
                            action: {
                                isShowingTokenScanner.toggle()
                            },
                            label: {
                                Label("Scan token QR code", systemImage: MySymbols.qrScan)
                            }
                        )
                        .sheet(
                            isPresented: $isShowingTokenScanner,
                            content: {
                                CodeScannerSheetView(title: "QR-Scan", symbologies: [.qr], onCodeFound: self.handleHassTokenScan)
                            }
                        )
                    #endif
                }
                Link(
                    destination: URL(string: "https://github.com/supergeorg/Grocy-SwiftUI/blob/main/Guides/Home%20Assistant%20Ingress/HomeAssistantIngressGuide.md")!,
                    label: {
                        Label("Guide (English)", systemImage: MySymbols.guide)
                    }
                )
            }
            Section(
                content: {
                    ForEach(serverProfile.customHeaders ?? []) { customHeader in
                        ListElementRow(header: customHeader)
                    }
                    .onDelete(perform: deleteHeader)
                },
                header: {
                    HStack {
                        Text("Custom Headers")
                        Spacer()
                        Button(
                            action: {
                                serverProfile.customHeaders?.append(LoginCustomHeader(headerName: "", headerValue: ""))
                            },
                            label: {
                                Label("Add", systemImage: MySymbols.new)
                            }
                        )
                    }
                }
            )
        }
        .navigationTitle("Own server")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        role: .cancel,
                        action: {
                            dismiss()
                        }
                    )
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        if isEditing {
                            if serverProfile.hasChanges {
                                serverProfile.userName = ""
                                serverProfile.displayName = ""
                                serverProfile.profilePicture = nil
                            }
                            try? serverProfile.modelContext?.save()
                        } else {
                            if selectedServerProfile == nil {
                                selectedServerProfileID = serverProfile.id
                            }
                            profileModelContext?.insert(serverProfile)
                            try? profileModelContext?.save()
                        }
                        dismiss()
                    }
                )
                .disabled(serverProfile.grocyServerURL.isEmpty || serverProfile.grocyAPIKey.isEmpty)
            }
        }
    }

    private func deleteHeader(at offsets: IndexSet) {
        serverProfile.customHeaders?.remove(atOffsets: offsets)
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        ServerProfileFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        ServerProfileFormView(
            serverProfile: ServerProfile(
                name: "My Server",
                grocyServerURL: "http://homeserver.local",
                grocyAPIKey: "API_KEY",
                useHassIngress: true,
                hassToken: "HASS_TOKEN",
                customHeaders: [LoginCustomHeader(headerName: "MY_HEADER", headerValue: "Header_VAL")]
            )
        )
    }
}
