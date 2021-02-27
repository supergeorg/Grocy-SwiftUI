//
//  AppCommands.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct AppCommands: Commands {
    @CommandsBuilder var body: some Commands {
        CommandMenu(LocalizedStringKey("str.nav.stockOverview")) {
            Button(action: {}, label: {
                Label(LocalizedStringKey("str.nav.stockOverview"), systemImage: MySymbols.stockOverview)
                    .labelStyle(TextIconLabelStyle())
            })
            .keyboardShortcut("o")
            
            Button(action: {}, label: {
                Label(LocalizedStringKey("str.stock.journal"), systemImage: MySymbols.stockJournal)
                    .labelStyle(TextIconLabelStyle())
            })
            .keyboardShortcut("j")
        }
    }
}
