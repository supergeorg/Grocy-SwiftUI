//
//  LoginDemoServerView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.25.
//

import SwiftUI

struct LoginDemoServerView: View {
    @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue

    var body: some View {
        Form {
            Picker(
                selection: $demoServerURL,
                label: Text("Demo server"),
                content: {
                    ForEach(
                        GrocyAPP.DemoServers.allCases,
                        content: { demoServer in
                            Text(demoServer.description).tag(demoServer.rawValue)
                        }
                    )
                }
            )
            .pickerStyle(.inline)
        }
        .navigationTitle("Demo server")
        .formStyle(.grouped)
        .safeAreaBar(
            edge: .bottom,
            content: {
                NavigationLink(
                    value: LoginDestination(type: .demoServer),
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
        )
    }
}

#Preview {
    @Previewable @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue
    
    NavigationStack {
        LoginDemoServerView(demoServerURL: demoServerURL)
    }
}
