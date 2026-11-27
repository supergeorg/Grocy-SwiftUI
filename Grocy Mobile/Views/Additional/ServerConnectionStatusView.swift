//
//  ServerConnectionStatusView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 27.11.26.
//

import SwiftUI

/// Tells that the server can't be reached and the app shows the data saved on the device, like Mail's offline status.
///
/// Unobtrusive but always there while the problem lasts: in the tab view's bottom accessory, or at the bottom of the sidebar.
/// Never an alert: there's nothing to decide, and the saved data stays usable. Tapping it tries the server again;
/// the app also tries again by itself (every 30 seconds, when the network comes back, and back in the foreground).
struct ServerConnectionStatusView: View {
    enum Style {
        /// In `tabViewBottomAccessory`, which brings its own glass.
        case tabAccessory
        /// At the bottom of the sidebar, which is glass already, so no glass of its own.
        case sidebar
        /// Floating above the content (iPhone with the sidebar navigation, on the pushed screens).
        case floating
    }

    var style: Style

    @Environment(GrocyViewModel.self) private var grocyVM
    #if os(iOS)
        @Environment(\.tabViewBottomAccessoryPlacement) private var accessoryPlacement
    #endif

    private var connection: ServerConnection { grocyVM.serverConnection }

    /// Next to the minimized tab bar, there's only room for one line.
    private var isInline: Bool {
        #if os(iOS)
            style == .tabAccessory && accessoryPlacement == .inline
        #else
            false
        #endif
    }

    var body: some View {
        if let problem = connection.problem {
            switch style {
            case .tabAccessory:
                button(for: problem)
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.large)
            case .sidebar:
                button(for: problem)
                    .buttonStyle(.plain)
                    .padding(Spacing.medium)
                    .background(Color(.GrocyColors.grocyRedBackground), in: .rect(cornerRadius: Spacing.medium))
                    .padding(Spacing.small)
            case .floating:
                button(for: problem)
                    .buttonStyle(.glass)
                    .padding(.horizontal, Spacing.large)
                    .padding(.bottom, Spacing.small)
            }
        }
    }

    private func button(for problem: ServerConnection.Problem) -> some View {
        Button {
            Task { await grocyVM.checkServerConnection() }
        } label: {
            HStack(spacing: Spacing.medium) {
                Image(systemName: symbol(for: problem))
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title(for: problem))
                        .font(.subheadline.weight(.semibold))
                    if !isInline {
                        detail(for: problem)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .lineLimit(1)
                Spacer(minLength: 0)
                if connection.isChecking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: MySymbols.reload)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: isInline ? nil : Sizes.minimumHitTarget)
            .contentShape(.rect)
        }
        .disabled(connection.isChecking)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Tries to reach the server again.")
    }

    private func symbol(for problem: ServerConnection.Problem) -> String {
        switch problem {
        case .noNetwork: MySymbols.offline
        case .unreachable: MySymbols.serverUnreachable
        case .serverError: MySymbols.warning
        }
    }

    private func title(for problem: ServerConnection.Problem) -> LocalizedStringKey {
        switch problem {
        case .noNetwork: "No internet connection"
        case .unreachable: "Server not reachable"
        case .serverError: "Server problem"
        }
    }

    @ViewBuilder
    private func detail(for problem: ServerConnection.Problem) -> some View {
        if case .serverError(let message) = problem {
            Text(message)
        } else if let lastContact = connection.lastContact {
            // Refreshed every minute, so "1 minute ago" doesn't stay.
            TimelineView(.everyMinute) { _ in
                Text("Last updated \(lastContact.formatted(.relative(presentation: .named)))")
            }
        } else {
            Text("Showing the data saved on this device")
        }
    }
}

extension View {
    /// The server status in the tab view's bottom accessory, only while there's a problem.
    func serverConnectionAccessory(_ connection: ServerConnection) -> some View {
        #if os(iOS)
            tabViewBottomAccessory(isEnabled: connection.problem != nil) {
                ServerConnectionStatusView(style: .tabAccessory)
            }
        #else
            self
        #endif
    }
}

#Preview(traits: .previewData) {
    VStack {
        ServerConnectionStatusView(style: .sidebar)
        ServerConnectionStatusView(style: .floating)
    }
}
