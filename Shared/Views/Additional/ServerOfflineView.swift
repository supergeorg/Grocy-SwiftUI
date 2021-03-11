//
//  ServerOfflineView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 02.03.21.
//

import SwiftUI

struct ServerOfflineView: View {
    var isCompact: Bool = false
    
    @StateObject var grocyVM: GrocyViewModel = .shared
    var body: some View {
        if !isCompact {
            normalView
        } else {
            #if os(macOS)
            CardView{
                compactView
            }
            #else
            compactView
            #endif
        }
    }
    
    var normalView: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                CardView{
                    VStack(alignment: .center, spacing: 20){
                        Image(systemName: MySymbols.offline)
                            .font(.system(size: 100))
                        Text(LocalizedStringKey("str.connection.failed"))
                        Button(action: {
                            grocyVM.retryFailedRequests()
                        }, label: {
                            Label(LocalizedStringKey("str.retry"), systemImage: MySymbols.reload)
                        })
                        .buttonStyle(FilledButtonStyle())
                    }
                }
                Spacer()
            }
            Spacer()
        }
    }
    
    var compactView: some View {
        HStack(alignment: .center){
            Label(LocalizedStringKey("str.connection.failed"), systemImage: MySymbols.offline)
                .foregroundColor(.red)
            Spacer()
            Button(action: {
                grocyVM.retryFailedRequests()
            }, label: {
                Label(LocalizedStringKey("str.retry"), systemImage: MySymbols.reload)
            })
            .buttonStyle(FilledButtonStyle())
        }
    }
}

struct ServerOfflineView_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            ServerOfflineView()
            ServerOfflineView(isCompact: true)
        }
    }
}
