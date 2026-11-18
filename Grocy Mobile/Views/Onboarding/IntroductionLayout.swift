//
//  IntroductionLayout.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftUI

/// One feature of an introduction screen: a symbol, a short title and one or two sentences.
struct IntroductionFeature: Identifiable {
    /// Unique within one screen's list.
    let id: String
    let symbol: String
    let tint: Color
    let title: LocalizedStringKey
    let text: LocalizedStringKey

    init(symbol: String, tint: Color, title: LocalizedStringKey, text: LocalizedStringKey) {
        self.id = symbol
        self.symbol = symbol
        self.tint = tint
        self.title = title
        self.text = text
    }
}

struct IntroductionFeatureRow: View {
    let feature: IntroductionFeature

    @ScaledMetric(relativeTo: .title) private var iconWidth: CGFloat = Sizes.introductionIconWidth

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.large) {
            Image(systemName: feature.symbol)
                .font(.title)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(feature.tint)
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // VoiceOver reads the title and the text as one element.
        .accessibilityElement(children: .combine)
    }
}

/// The layout shared by the onboarding, the login start and What's New, in the style of the system's welcome screens:
/// a header, a large title, a list of features, and the actions in a bar at the bottom,
/// so they stay reachable however long the list is or however large the text.
struct IntroductionLayout<Header: View, Actions: View>: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey? = nil
    let features: [IntroductionFeature]
    @ViewBuilder var header: Header
    @ViewBuilder var actions: Actions

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xLarge) {
                VStack(spacing: Spacing.medium) {
                    header
                        .padding(.bottom, Spacing.small)
                    Text(title)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.bottom, Spacing.large)

                VStack(alignment: .leading, spacing: Spacing.xLarge) {
                    ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                        IntroductionFeatureRow(feature: feature)
                            // The rows appear one after another; with Reduce Motion they only fade in.
                            .opacity(isShown ? 1 : 0)
                            .offset(y: isShown || reduceMotion ? 0 : Spacing.large)
                            .animation(.smooth.delay(Double(index) * 0.08), value: isShown)
                    }
                }
            }
            .frame(maxWidth: Sizes.introductionReadableWidth)
            .padding(.horizontal, Spacing.xLarge)
            .padding(.vertical, Spacing.xLarge)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaBar(edge: .bottom) {
            VStack(spacing: Spacing.medium) {
                actions
            }
            .frame(maxWidth: Sizes.introductionReadableWidth)
            .padding(.horizontal, Spacing.xLarge)
            .padding(.vertical, Spacing.medium)
            .frame(maxWidth: .infinity)
        }
        .background {
            // A light brand tint behind the header that fades into the system background,
            // so the feature texts keep the system contrast in light and dark mode.
            LinearGradient(
                colors: [Color(.GrocyColors.grocyBlueBackground).opacity(0.6), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .background(.background)
            .ignoresSafeArea()
        }
        #if os(macOS)
            .frame(minWidth: Constants.macOSMinWindowWidth, minHeight: Constants.macOSIntroductionMinHeight)
        #endif
        .onAppear {
            isShown = true
        }
    }
}

extension View {
    /// A full-width action of an introduction screen. The prominent style is for the one main action of a screen.
    func introductionButton(tint: Color, isProminent: Bool = true) -> some View {
        Group {
            if isProminent {
                self.buttonStyle(.glassProminent)
            } else {
                self.buttonStyle(.glass)
            }
        }
        .tint(tint)
        .controlSize(.large)
    }
}

#Preview(traits: .previewData) {
    IntroductionLayout(
        title: "Welcome to Grocy Mobile",
        subtitle: "The native app for Grocy, the self-hosted groceries and household management solution.",
        features: OnboardingView.features
    ) {
        Image("grocy-logo")
            .resizable()
            .scaledToFit()
            .frame(height: Sizes.introductionLogoHeight)
    } actions: {
        Button {
        } label: {
            Text("Continue")
                .frame(maxWidth: .infinity)
        }
        .introductionButton(tint: Color(.GrocyColors.grocyGreen))
    }
}
