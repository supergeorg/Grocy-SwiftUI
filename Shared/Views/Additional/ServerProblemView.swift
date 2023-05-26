//
//  ServerProblemView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 02.03.21.
//

import SwiftUI

struct ServerProblemView: View {
    var isCompact: Bool = false
    
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("devMode") private var devMode: Bool = false
    
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
    
    private var serverErrorInfo: (String, String) {
        switch serverErrorState {
        case .connection:
            return (MySymbols.offline, "str.error.connection")
        case .api:
            return (MySymbols.api, "str.error.api")
        case .other:
            return (MySymbols.unknown, "str.error.other")
        case .none:
            return (MySymbols.success, "")
        }
    }
    
    
    var body: some View {
        if !isCompact {
            normalView
        } else {
#if os(macOS)
            compactView
#else
            compactView
#endif
        }
    }
    
    var normalView: some View {
        VStack(alignment: .center, spacing: 20){
            Image(systemName: serverErrorInfo.0)
                .font(.system(size: 100))
            if serverErrorState != .none {
                VStack(alignment: .center) {
                    Text(LocalizedStringKey(serverErrorInfo.1))
                    Text(LocalizedStringKey("str.error.logInfo"))
                        .font(.caption)
                }
            }
            Button(action: {
                Task {
                    await grocyVM.retryFailedRequests()
                }
            }, label: {
                Label(LocalizedStringKey("str.retry"), systemImage: MySymbols.reload)
            })
                .buttonStyle(FilledButtonStyle())
                .controlSize(.large)
            if devMode {
                List() {
                    ForEach(grocyVM.failedToLoadObjects.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { object in
                        Text(object.rawValue)
                    }
                }
                List() {
                    ForEach(grocyVM.failedToLoadAdditionalObjects.sorted(by:  { $0.rawValue < $1.rawValue }), id: \.self) { additionalObject in
                        Text(additionalObject.rawValue)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(14)
    }
    
    var compactView: some View {
        HStack(alignment: .center) {
            Image(systemName: serverErrorInfo.0)
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(serverErrorInfo.1))
                Text(LocalizedStringKey("str.error.logInfo"))
                    .font(.caption)
            }
            Spacer()
            Button(action: {
                Task {
                    await grocyVM.retryFailedRequests()
                }
            }, label: {
                Label(LocalizedStringKey("str.retry"), systemImage: MySymbols.reload)
            })
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .padding(.horizontal)
        .background(Color.red)
        .cornerRadius(5)
    }
}

struct ServerProblemView_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            ServerProblemView()
            ServerProblemView()
                .preferredColorScheme(.dark)
            ServerProblemView(isCompact: true)
        }
    }
}
