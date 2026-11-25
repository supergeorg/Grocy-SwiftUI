//
//  GrocyInfoView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 12.10.20.
//

import SwiftUI

struct GrocyInfoView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var systemInfo: SystemInfo? = nil

    @AppStorage("localizationKey") var localizationKey: String = "en"
    @AppStorage("isDemoModus") var isDemoModus: Bool = false
    @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue

    var isSupportedServer: Bool {
        if let systemInfo {
            return GrocyAPP.supportedVersions.contains(systemInfo.grocyVersion.version)
        } else {
            return false
        }
    }
    var releaseDate: String {
        if let systemInfo {
            return formatDateOutput(systemInfo.grocyVersion.releaseDate) ?? formatTimestampOutput(
                systemInfo.grocyVersion.releaseDate,
                localizationKey: localizationKey
            ) ?? ""
        } else {
            return ""
        }
    }

    var body: some View {
        Form {
            if isDemoModus {
                LabeledContent(
                    content: {
                        Link(
                            destination: URL(string: demoServerURL)!,
                            label: {
                                Text(demoServerURL)
                            }
                        )
                    },
                    label: {
                        Label("Grocy Server Demo URL", systemImage: MySymbols.serverURL)
                            .foregroundStyle(.primary)
                    }
                )
            } else if let grocyServerURL = grocyVM.selectedServerProfile?.grocyServerURL {
                LabeledContent(
                    content: {
                        Link(
                            destination: URL(string: grocyServerURL)!,
                            label: {
                                Text(grocyServerURL)
                            }
                        )
                    },
                    label: {
                        Label("Grocy Server URL", systemImage: MySymbols.serverURL)
                            .foregroundStyle(.primary)
                    }
                )
            }
            if let systemInfo {
                LabeledContent(
                    content: {
                        Text(systemInfo.grocyVersion.version)
                    },
                    label: {
                        Label(
                            isSupportedServer ? "Supported server version" : "Unsupported server version",
                            systemImage: isSupportedServer ? MySymbols.success : MySymbols.failure
                        )
                    }
                )
                .foregroundStyle(isSupportedServer ? .green : .red)
                LabeledContent(
                    content: {
                        Text(releaseDate)
                    },
                    label: {
                        Label("Release date", systemImage: MySymbols.date)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text(systemInfo.phpVersion)
                    },
                    label: {
                        Label("PHP version", systemImage: MySymbols.phpVersion)
                            .foregroundStyle(.primary)
                    }
                )
                LabeledContent(
                    content: {
                        Text(systemInfo.sqliteVersion)
                    },
                    label: {
                        Label("SQLite version", systemImage: MySymbols.database)
                            .foregroundStyle(.primary)
                    }
                )
                if let os = systemInfo.os {
                    LabeledContent(
                        content: {
                            Text(os)
                        },
                        label: {
                            Label("OS", systemImage: MySymbols.serverOS)
                                .foregroundStyle(.primary)
                        }
                    )
                }
                if let client = systemInfo.client {
                    LabeledContent(
                        content: {
                            Text(client)
                        },
                        label: {
                            Label("Client information", systemImage: MySymbols.clientDevices)
                                .foregroundStyle(.primary)
                        }
                    )
                }
            }
            if !isDemoModus, let profile = grocyVM.selectedServerProfile, let fingerprint = profile.trustedCertificateFingerprint {
                Section {
                    LabeledContent("SHA-256 fingerprint") {
                        Text(fingerprint)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                    Button("Don't trust this certificate", role: .destructive) {
                        profile.trustedCertificateFingerprint = nil
                        // Applies at once, not only at the next login.
                        grocyVM.grocyApi.setTrustedCertificate(fingerprint: nil)
                    }
                } header: {
                    Text("Trusted certificate")
                } footer: {
                    Text("The server's certificate isn't trusted by this device, but you trusted it for this server.")
                }
            }
        }
        .navigationTitle("Information about Grocy Server")
        .formStyle(.grouped)
    }
}

#Preview(traits: .previewData) {
    GrocyInfoView(
        systemInfo: SystemInfo(
            grocyVersion: SystemInfo.GrocyVersion(version: "version", releaseDate: "date"),
            phpVersion: "php",
            sqliteVersion: "sqlite",
            os: "iOS",
            client: "Grocy Mobile"
        )
    )
}
