//
//  MyToggle.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MyToggle: View {
    @Binding var isOn: Bool
    var description: String
    var descriptionInfo: String?
    var icon: String?
    
    @State private var showInfo: Bool = false
    
    var body: some View {
        HStack{
            if icon != nil {
                Image(systemName: icon!)
            }
            Toggle(LocalizedStringKey(description), isOn: $isOn)
            if let descriptionInfoU = descriptionInfo {
                #if os(macOS)
                Image(systemName: "questionmark.circle.fill")
                    .help(LocalizedStringKey(descriptionInfoU))
                #elseif os(iOS)
                Image(systemName: "questionmark.circle.fill")
                    .onTapGesture {
                        showInfo.toggle()
                    }
                    .help(LocalizedStringKey(descriptionInfoU))
                    .popover(isPresented: $showInfo, content: {
                        Text(LocalizedStringKey(descriptionInfo!))
                            .padding()
                    })
                #endif
            }
        }
    }
}

struct MyToggle_Previews: PreviewProvider {
    static var previews: some View {
        MyToggle(isOn: Binding.constant(true), description: "Description", descriptionInfo: "Descriptioninfo", icon: "tag")
    }
}
