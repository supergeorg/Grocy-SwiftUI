//
//  CardView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 18.02.21.
//

import SwiftUI

struct CardView<Content>: View where Content: View {
    let content: () -> Content
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        self.content()
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .light ? Color.white : Color.black)
                    .shadow(color: colorScheme == .light ? .black : .gray, radius: 2, x: 0, y: 0)
            )
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(content: {Text("test")})
    }
}
