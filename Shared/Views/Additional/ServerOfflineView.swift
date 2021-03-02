//
//  ServerOfflineView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 02.03.21.
//

import SwiftUI

struct ServerOfflineView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    var body: some View {
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
}

struct ServerOfflineView_Previews: PreviewProvider {
    static var previews: some View {
        ServerOfflineView()
    }
}
