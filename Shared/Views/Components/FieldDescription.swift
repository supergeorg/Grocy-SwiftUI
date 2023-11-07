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
        Image(systemName: MySymbols.hint)
            .help(description)
#if os(iOS)
            .onTapGesture {
                showDescription.toggle()
            }
            .popover(isPresented: $showDescription, content: {
                Text(description)
                    .padding()
                    .fixedSize(horizontal: false, vertical: true)
            })
#endif
    }
}

struct FieldDescription_Previews: PreviewProvider {
    static var previews: some View {
        FieldDescription(description: "Description")
    }
}
