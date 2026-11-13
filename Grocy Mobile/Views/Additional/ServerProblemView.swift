//
//  ServerProblemView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 02.03.21.
//

import SwiftUI

struct ServerProblemView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @AppStorage("devMode") private var devMode: Bool = false

    @State private var isLoading: Bool = false

    var isCompact: Bool = false

    private enum ServerErrorState: Identifiable {
        case connection, api, other, none

        var id: Int {
            self.hashValue
        }
    }
    private var serverErrorState: ServerErrorState {
        if grocyVM.failedToLoadErrors.isEmpty {
            return .none
        }
        for error in grocyVM.failedToLoadErrors {
            switch error {
            case APIError.decodingError:
                return .api
            case APIError.serverError:
                return .connection
            default:
                break
            }
        }
        return .other
    }

    private var serverErrorInfo: (String, LocalizedStringKey) {
        switch serverErrorState {
        case .connection:
            return (MySymbols.offline, "No connection to server.")
        case .api:
            return (MySymbols.api, "API error detected.")
        case .other:
            return (MySymbols.unknown, "Unknown error occured.")
        case .none:
            return (MySymbols.success, "")
        }
    }

    func reload() {
        isLoading = true
        Task {
            await grocyVM.retryFailedRequests()
        }
        isLoading = false
    }

    var body: some View {
        if !isCompact {
            normalView
        } else {
            compactView
        }
    }

    var normalView: some View {
        VStack(alignment: .center, spacing: 20) {
            Image(systemName: serverErrorInfo.0)
                .font(.system(size: 100))
            if serverErrorState != .none {
                VStack(alignment: .center) {
                    Text(serverErrorInfo.1)
                    Text("Please check the log to determine the problem.")
                        .font(.caption)
                }
            }
            Button(
                action: {
                    reload()
                },
                label: {
                    Label("Try again", systemImage: MySymbols.reload)
                        .symbolEffect(.rotate, isActive: isLoading)
                        .frame(maxWidth: .infinity)
                }
            )
            // System glass style: handles pressed and disabled states and keeps the label legible.
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            if devMode {
                List {
                    ForEach(grocyVM.failedToLoadObjects.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { object in
                        Text(object.rawValue)
                    }
                    ForEach(grocyVM.failedToLoadAdditionalObjects.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { additionalObject in
                        Text(additionalObject.rawValue)
                    }
                }
            }
        }
    }

    var compactView: some View {
        HStack(alignment: .center) {
            Image(systemName: serverErrorInfo.0)
            VStack(alignment: .leading) {
                Text(serverErrorInfo.1)
                Text("Please check the log to determine the problem.")
                    .font(.caption)
            }
            Spacer()
            Button(
                action: {
                    reload()
                },
                label: {
                    Label("Try again", systemImage: MySymbols.reload)
                        .symbolEffect(.rotate, isActive: isLoading)
                }
            )
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.horizontal)
        .background(Color.red)
        .cornerRadius(5)
    }
}

#Preview {
    ServerProblemView()
}

#Preview {
    ServerProblemView(isCompact: true)
}
