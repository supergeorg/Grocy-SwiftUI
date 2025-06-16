//
//  MyToggle.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MyToggle: View {
    @Binding var isOn: Bool
    var description: LocalizedStringKey
    var descriptionInfo: LocalizedStringKey?
    var icon: String?
    
    @State private var showInfo: Bool = false
    
    var body: some View {
        HStack{
            Toggle(isOn: $isOn, label: {
                if let icon = icon {
                    HStack {
                        Label(description, systemImage: icon)
                            .foregroundStyle(.primary)
#if os(macOS)
                        if let descriptionInfo = descriptionInfo {
                            FieldDescription(description: descriptionInfo)
                        }
#endif
                    }
                } else {
                    Text(description)
                }
            })
#if os(iOS)
            if let descriptionInfo = descriptionInfo {
                FieldDescription(description: descriptionInfo)
            }
#endif
        }
    }
}

#Preview {
    MyToggle(isOn: Binding.constant(true), description: "Description", descriptionInfo: "Descriptioninfo", icon: "tag")
}
