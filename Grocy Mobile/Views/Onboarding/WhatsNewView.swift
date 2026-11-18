//
//  WhatsNewView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftUI

/// The highlights of the installed release, shown in a sheet on the first launch after an update and from About this app.
struct WhatsNewView: View {
    var version: String = WhatsNew.appVersion

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        IntroductionLayout(
            title: "What's New in Grocy Mobile",
            subtitle: "Version \(version)",
            features: WhatsNew.features(for: version)
        ) {
            Image(systemName: MySymbols.whatsNew)
                .font(.largeTitle)
                .imageScale(.large)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(.GrocyColors.grocyGreen))
                .accessibilityHidden(true)
        } actions: {
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .introductionButton(tint: Color(.GrocyColors.grocyGreen))
            .keyboardShortcut(.defaultAction)
        }
    }
}

extension View {
    /// Shows What's New once after an update, then remembers the version.
    func whatsNewSheet() -> some View {
        modifier(WhatsNewSheetModifier())
    }
}

private struct WhatsNewSheetModifier: ViewModifier {
    @AppStorage(WhatsNew.storageKey) private var whatsNewLastVersion: String = ""
    @State private var isPresented: Bool = false

    func body(content: Content) -> some View {
        content
            .task {
                #if DEBUG
                    // UI tests start logged in and would otherwise find the sheet in front of every screen.
                    if UITestConfiguration.isActive { return }
                #endif
                isPresented = WhatsNew.shouldShow(lastShownVersion: whatsNewLastVersion, appVersion: WhatsNew.appVersion)
            }
            .sheet(
                isPresented: $isPresented,
                onDismiss: {
                    whatsNewLastVersion = WhatsNew.appVersion
                },
                content: {
                    WhatsNewView()
                }
            )
    }
}

#Preview(traits: .previewData) {
    WhatsNewView(version: "3.4.0")
}
