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
            Toggle(description.localized, isOn: $isOn)
            if descriptionInfo != nil {
                Image(systemName: "questionmark.circle.fill")
                    .onTapGesture {
                        showInfo.toggle()
                    }
                    .popover(isPresented: $showInfo, content: {
                        Text(descriptionInfo!.localized)
                            .padding()
                    })
            }
        }
    }
}

struct MyToggle_Previews: PreviewProvider {
    static var previews: some View {
        MyToggle(isOn: Binding.constant(true), description: "Description", descriptionInfo: "Descriptioninfo", icon: "tag")
    }
}
