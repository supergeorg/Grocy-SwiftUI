//
//  ServerStatusView.swift
//  Grocy Mobile
//

import SwiftUI

extension ConnectionProblem {
    var title: LocalizedStringKey {
        switch self {
        case .offline: "No internet connection"
        case .serverUnreachable: "Server not reachable"
        case .serverError: "Server error"
        }
    }

    var symbol: String {
        switch self {
        case .offline: MySymbols.offline
        case .serverUnreachable: MySymbols.serverUnreachable
        case .serverError: MySymbols.warning
        }
    }
}

/// Says that the server can't be used right now and how old the shown data is. Tapping it tries again.
///
/// Small and out of the way, but shown on every screen for as long as the problem lasts: in the tab bar's accessory
/// (`serverStatusAccessory()`) or below the content (`serverStatusBar()`).
struct ServerStatusView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @State private var isRetrying = false

    var body: some View {
        if let problem = grocyVM.connectionProblem {
            Button {
                Task {
                    isRetrying = true
                    await grocyVM.retryFailedRequests()
                    isRetrying = false
                }
            } label: {
                HStack(spacing: Spacing.small) {
                    Image(systemName: problem.symbol)
                        .foregroundStyle(Color(.GrocyColors.grocyRed))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(problem.title)
                            .font(.subheadline.weight(.semibold))
                        // Updates itself, so "2 minutes ago" doesn't stand still.
                        TimelineView(.everyMinute) { _ in
                            Group {
                                if let lastContact = grocyVM.lastServerContact {
                                    Text("Updated \(lastContact, format: .relative(presentation: .named))")
                                } else {
                                    Text("Showing saved data")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: isRetrying ? MySymbols.progress : MySymbols.reload)
                        .symbolEffect(.variableColor.iterative, isActive: isRetrying)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(isRetrying)
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text("Tries to reach the server again"))
        }
    }
}

extension View {
    #if os(iOS)
        /// Shows the server status in the tab bar's accessory while there's a connection problem, and nothing otherwise.
        func serverStatusAccessory(isShown: Bool) -> some View {
            tabViewBottomAccessory(isEnabled: isShown) {
                ServerStatusView()
                    .padding(.horizontal, Spacing.large)
            }
        }
    #endif

    /// Shows the server status in a glass capsule below the content while there's a connection problem,
    /// for the screens without a tab bar (the sidebar navigation on iPad, iPhone and Mac).
    func serverStatusBar(isShown: Bool) -> some View {
        safeAreaInset(edge: .bottom) {
            if isShown {
                ServerStatusView()
                    .padding(.horizontal, Spacing.large)
                    .padding(.vertical, Spacing.small)
                    .glassEffect(.regular, in: .capsule)
                    .padding(.horizontal, Spacing.large)
                    .padding(.bottom, Spacing.small)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.smooth, value: isShown)
    }
}

#Preview(traits: .previewData) {
    ServerStatusView()
        .padding()
}
