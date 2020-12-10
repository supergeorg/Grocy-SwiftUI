//
//  RowInteractionButton.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

import SwiftUI

struct RowInteractionButton: View {
    var title: String?
    var image: String
    
    var backgroundColor: Color
    
    let paddingValue: CGFloat = 7
    let cornerRadiusValue: CGFloat = 3
    let fontSizeValue: CGFloat = 15
    
    var foregroundColor: Color?
    
    var helpString: LocalizedStringKey?
    
    var body: some View {
        HStack(alignment: .center, spacing: 2){
            Image(systemName: image)
                .font(Font.system(size: fontSizeValue, weight: .bold))
            if title != nil {
                Text(title!)
                    .font(Font.system(size: fontSizeValue, weight: .regular))
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .frame(height: fontSizeValue)
        .padding(paddingValue)
        .background(backgroundColor)
        .foregroundColor(foregroundColor != nil ? foregroundColor! : Color.white)
        .cornerRadius(cornerRadiusValue)
        .help(helpString != nil ? helpString! : "")
    }
}

struct RowInteractionButton_Previews: PreviewProvider {
    static var previews: some View {
        RowInteractionButton(title: "test", image: "trash", backgroundColor: Color.blue)
    }
}
