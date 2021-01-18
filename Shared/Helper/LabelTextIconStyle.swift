//
//  LabelTextIconStyle.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 18.01.21.
//

import SwiftUI

struct TextIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}
