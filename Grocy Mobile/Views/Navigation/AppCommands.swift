//
//  AppCommands.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct AppCommands: Commands {
    @CommandsBuilder var body: some Commands {
        CommandMenu("Stock overview") {
            Button(
                action: {},
                label: {
                    Label("Stock overview", systemImage: MySymbols.stockOverview)
                        .labelStyle(.titleAndIcon)
                }
            )
            .keyboardShortcut("o")

            Button(
                action: {},
                label: {
                    Label("Stock journal", systemImage: MySymbols.stockJournal)
                        .labelStyle(.titleAndIcon)
                }
            )
            .keyboardShortcut("j")
        }
    }
}
