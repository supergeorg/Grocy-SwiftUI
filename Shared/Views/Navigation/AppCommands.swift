//
//  AppCommands.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct AppCommands: Commands {
    
    func openQR() {
        
    }
    func anotherAction() {}
    
    @CommandsBuilder var body: some Commands {
        CommandMenu("DEBUG") {
            Button(action: {
                openQR()
            }) {
                Text("Open QR")
            }
            Button(action: {
                anotherAction()
            }) {
                Text("Another action")
            }
        }
    }
}
