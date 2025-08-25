//
//  OnboardingView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.01.21.
//

import SwiftUI

struct OnboardingDevicesView: View {
    var body: some View {
        HStack {
            #if os(macOS)
                Image(systemName: "macbook")
                Image(systemName: "macmini")
                Image(systemName: "desktopcomputer")
            #elseif os(iOS)
                Image(systemName: "iphone")
                Image(systemName: "iphone.homebutton")
                Image(systemName: "ipad")
                Image(systemName: "ipad.homebutton")
            #endif
        }
    }
}

public enum OnboardingCards: CaseIterable {
    case GROCY
    case ERP_BEYOND
    case IOS_MACOS

    public var title: LocalizedStringKey {
        switch self {
        case .GROCY:
            return "Grocy"
        case .ERP_BEYOND:
            return "grocy - ERP beyond your fridge"
        case .IOS_MACOS:
            return "Grocy for iOS/macOS"
        }
    }

    public var subtitle: LocalizedStringKey {
        switch self {
        case .GROCY:
            return ""
        case .ERP_BEYOND:
            return "grocy is a web-based self-hosted groceries & household management solution for your home."
        case .IOS_MACOS:
            return "An app in native design, allowing a comfortable use of Grocy at home and on the go."
        }
    }

    public var imageName: String {
        switch self {
        case .GROCY:
            return "grocy-logo"
        case .ERP_BEYOND:
            return "web-stock"
        case .IOS_MACOS:
            return "stock-screenshot"
        }
    }
}

struct OnboardingCardView: View {
    var card: OnboardingCards
    var body: some View {
        VStack {
            Image(card.imageName)
                .resizable()
                .scaledToFit()
            Spacer()
            Text(card.title).font(.largeTitle)
            if card.subtitle == "" {
                OnboardingDevicesView()
                    .font(.largeTitle)
            } else {
                Text(card.subtitle)
            }
            Spacer()
        }
        .padding()
    }
}

struct OnboardingView: View {
    @AppStorage("onboardingNeeded") var onboardingNeeded: Bool = true

    var body: some View {
        VStack {
            #if os(iOS)
                TabView {
                    ForEach(OnboardingCards.allCases, id: \.self) { card in
                        OnboardingCardView(card: card)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
            #else
                HStack {
                    ForEach(OnboardingCards.allCases, id: \.self) { card in
                        OnboardingCardView(card: card)
                    }
                }
            #endif
            Button(
                action: {
                    onboardingNeeded = false
                },
                label: {
                    Text("Let's get started!")
                        #if os(iOS)
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding()
                            .glassEffect(.regular.tint(.GrocyColors.grocyGreen).interactive())
                        #endif
                }
            )
        }
        .background(Color(.GrocyColors.grocyBlueBackground))
    }
}

#Preview {
    OnboardingView()
        .colorScheme(.light)
}

#Preview("Dark Mode") {
    OnboardingView()
        .colorScheme(.dark)
}
