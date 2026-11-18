//
//  OnboardingView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.01.21.
//

import SwiftUI

/// The first screen after installing: what Grocy and the app do, before choosing a server.
struct OnboardingView: View {
    @AppStorage("onboardingNeeded") var onboardingNeeded: Bool = true
    @AppStorage(WhatsNew.storageKey) private var whatsNewLastVersion: String = ""

    @ScaledMetric(relativeTo: .largeTitle) private var logoHeight: CGFloat = Sizes.introductionLogoHeight

    static let features: [IntroductionFeature] = [
        IntroductionFeature(
            symbol: MySymbols.stockOverview,
            tint: Color(.GrocyColors.grocyGreen),
            title: "Know what's at home",
            text: "See your stock, what's due soon and what's running low, and scan barcodes to purchase or consume."
        ),
        IntroductionFeature(
            symbol: MySymbols.shoppingList,
            tint: Color(.GrocyColors.grocyBlue),
            title: "Shop with your lists",
            text: "Shopping lists stay in sync with your household, and can be mirrored to Reminders."
        ),
        IntroductionFeature(
            symbol: MySymbols.recipe,
            tint: .orange,
            title: "Cook from your recipes",
            text: "Check what you can cook with your stock, and import recipes from websites."
        ),
        IntroductionFeature(
            symbol: MySymbols.householdManagement,
            tint: Color(.GrocyColors.grocyTurquoise),
            title: "Run the household",
            text: "Chores, tasks, batteries and equipment in one place, with widgets for your Home Screen."
        ),
        IntroductionFeature(
            symbol: MySymbols.serverConnection,
            tint: Color(.GrocyColors.grocyGray),
            title: "Your data on your server",
            text: "Grocy Mobile connects to your self-hosted Grocy server. You can try a demo server first."
        ),
    ]

    var body: some View {
        IntroductionLayout(
            title: "Welcome to Grocy Mobile",
            subtitle: "The native app for Grocy, the self-hosted groceries and household management solution.",
            features: Self.features
        ) {
            Image("grocy-logo")
                .resizable()
                .scaledToFit()
                .frame(height: logoHeight)
                .accessibilityLabel("Grocy")
        } actions: {
            Button {
                // A new user has nothing to compare with, so What's New only appears after the next update.
                whatsNewLastVersion = WhatsNew.appVersion
                withAnimation {
                    onboardingNeeded = false
                }
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .introductionButton(tint: Color(.GrocyColors.grocyGreen))
            .keyboardShortcut(.defaultAction)
        }
    }
}

#Preview(traits: .previewData) {
    OnboardingView()
}
