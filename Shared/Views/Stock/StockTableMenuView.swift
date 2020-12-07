//
//  StockTableMenuView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

import SwiftUI

struct StockTableMenuView: View {
    var body: some View {
        VStack{
            Button(action: {
                print("add")
            }, label: {
                Label(LocalizedStringKey("str.stock.tbl.menu.addToShL"), systemImage: "cart")
            })
            Divider()
            Group{
                Button(action: {
                    print("buy")
                }, label: {
                    Label(LocalizedStringKey("str.stock.buy"), systemImage: "cart")
                })
                Button(action: {
                    print("verbr")
                }, label: {
                    Label(LocalizedStringKey("str.stock.consume"), systemImage: "tuningfork")
                })
                Button(action: {
                    print("uml")
                }, label: {
                    Label(LocalizedStringKey("str.stock.transfer"), systemImage: "arrow.left.arrow.right")
                })
                Button(action: {
                    print("inv")
                }, label: {
                    Label(LocalizedStringKey("str.stock.inventory"), systemImage: "list.bullet")
                })
            }
            Divider()
            Group{
                Button(LocalizedStringKey("str.stock.tbl.menu.consumeAsSpoiled \("fe")")){}
                Button(LocalizedStringKey("str.stock.tbl.menu.searchRecipes")){}
            }
            Group{
                Button(LocalizedStringKey("str.details.title")) {}
                Button(LocalizedStringKey("str.details.stockEntries")) {}
                Button(LocalizedStringKey("str.details.stockJournal")) {}
//                Button(LocalizedStringKey("str.details.title")) {}
                Button(LocalizedStringKey("str.details.edit")) {}
            }
        }
    }
}

struct StockTableMenuView_Previews: PreviewProvider {
    static var previews: some View {
        StockTableMenuView()
    }
}
