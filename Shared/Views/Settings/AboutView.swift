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
                Text(caption).font(.title3)
                Text(content).font(.body)
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        Form(){
            Text("Ich möchte mich bei Bernd Bestel für die Entwicklung von Grocy bedanken. Ohne ihm wäre diese App nicht möglich.")
            AboutLineView(iconName: "info.circle", caption: "Version", content: "0.1")
            AboutLineView(iconName: "person.circle", caption: "Entwickler", content: "Georg Meißner")
        }
        .navigationTitle("Über diese App")
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView() {
            AboutView()
        }
    }
}
