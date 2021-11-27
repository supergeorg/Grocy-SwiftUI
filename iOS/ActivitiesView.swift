//
//  ActivitiesView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 22.01.21.
//

import SwiftUI

struct ActivitiesView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var body: some View {
        List(){
            NavigationLink(destination: PurchaseProductView()) {
                Label(LocalizedStringKey("str.md.products"), systemImage: "archivebox")
            }
            
            ForEach(grocyVM.mdUserEntities, id:\.id) {userEntity in
                NavigationLink(destination: UserEntityView(userEntity: userEntity)) {
                    Label(LocalizedStringKey(userEntity.caption), systemImage: getSFSymbolForFA(faName: userEntity.iconCSSClass ?? ""))
                }
            }
        }
        .navigationTitle(LocalizedStringKey("str.nav.activities"))
        .onAppear(perform: {
            grocyVM.requestData(objects: [.userentities], ignoreCached: false)
        })
    }
}

struct ActivitiesView_Previews: PreviewProvider {
    static var previews: some View {
        ActivitiesView()
    }
}
