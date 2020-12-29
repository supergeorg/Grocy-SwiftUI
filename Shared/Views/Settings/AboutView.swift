//
//  AboutView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 26.10.20.
//

import SwiftUI

struct AboutLineView: View {
    var iconName: String
    var caption: String
    var content: String
    var body: some View {
        HStack{
            Image(systemName: iconName).font(.title)
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(caption)).font(.title3)
                Text(content).font(.body)
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        Form(){
            Text(LocalizedStringKey("str.settings.about.thanks"))
            AboutLineView(iconName: "info.circle", caption: "str.settings.about.version", content: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Version number not found")
            AboutLineView(iconName: "person.circle", caption: "str.settings.about.developer", content: "Georg Meißner")
            AboutLineView(iconName: "barcode.viewfinder", caption: "CodeScanner", content: "Copyright (c) 2019 Paul Hudson")
        }
        .navigationTitle(LocalizedStringKey("str.settings.about"))
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView() {
            AboutView()
        }
    }
}
