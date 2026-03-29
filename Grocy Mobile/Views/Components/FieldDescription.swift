//
//  FieldDescription.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI

struct FieldDescription: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var description: LocalizedStringKey

    @State private var showDescription: Bool = false

    var body: some View {
        Image(systemName: MySymbols.hint)
            .help(description)
            #if os(iOS)
                .onTapGesture {
                    showDescription.toggle()
                }
                .popover(isPresented: $showDescription) {
                    if horizontalSizeClass == .compact {
                        ScrollView {
                            Text(description)
                            .padding()
                            .frame(minWidth: 200, maxWidth: 400)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 4)
                        }
                        .presentationCompactAdaptation(.popover)
                        .presentationSizing(.fitted)
                    } else {
                        Text(description)
                        .padding()
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            #endif
    }
}

#Preview {
    NavigationStack {
        FieldDescription(description: "Description")
    }
}
