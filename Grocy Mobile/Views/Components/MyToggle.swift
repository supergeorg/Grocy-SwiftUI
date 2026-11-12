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

    var body: some View {
        // The label belongs to the Toggle itself, so VoiceOver announces what is switched.
        Toggle(isOn: $isOn) {
            if let icon = icon {
                Label {
                    labelText
                } icon: {
                    Image(systemName: icon).foregroundStyle(.primary)
                }
            } else {
                labelText
            }
        }
    }

    private var labelText: some View {
        HStack {
            Text(description)
                .layoutPriority(1)
            if let descriptionInfo = descriptionInfo {
                FieldDescription(description: descriptionInfo)
                    .fixedSize()
            }
        }
    }
}

#Preview {
    @Previewable @State var isOn: Bool = true

    Form {
        MyToggle(isOn: $isOn, description: "Description", descriptionInfo: "Descriptioninfo", icon: "tag")
        MyToggle(isOn: $isOn, description: "Enable tare weight handling", descriptionInfo: "Descriptioninfo", icon: "tag")
        MyToggle(isOn: $isOn, description: "Without icon")
    }
}
