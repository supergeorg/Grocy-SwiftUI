//
//  FieldDescription.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI

struct FieldDescription: View {
    var description: String
    
    @State private var showDescription: Bool = false
    
    var body: some View {
        #if os(macOS)
        Image(systemName: "questionmark.circle.fill")
            .help(LocalizedStringKey(description))
        #elseif os(iOS)
        Image(systemName: "questionmark.circle.fill")
            .onTapGesture {
                showDescription.toggle()
            }
            .help(LocalizedStringKey(description))
            .popover(isPresented: $showDescription, content: {
                Text(LocalizedStringKey(description))
                    .padding()
            })
        #endif
    }
}

struct FieldDescription_Previews: PreviewProvider {
    static var previews: some View {
        FieldDescription(description: "Description")
    }
}
