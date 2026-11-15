//
//  MyLabelWithSubtitle.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 02.03.21.
//

import SwiftUI

struct MyLabelWithSubtitle: View {
    var title: LocalizedStringKey
    var subTitle: LocalizedStringKey? = nil
    var systemImage: String? = nil
    var isProblem: Bool = false
    var isSubtitleProblem: Bool = false
    var hideSubtitle: Bool = false

    var body: some View {
        LabeledContent(
            content: {},
            label: {
                if let systemImage = systemImage {
                    Label {
                        Text(title)
                            .foregroundStyle(isProblem ? Color(.GrocyColors.grocyRed) : Color.primary)
                    } icon: {
                        Image(systemName: systemImage)
                            .foregroundStyle(.primary)
                    }
                } else {
                    Text(title)
                        .foregroundStyle(isProblem ? Color(.GrocyColors.grocyRed) : Color.primary)
                }
                if !hideSubtitle, let subTitle = subTitle {
                    Text(subTitle)
                        .foregroundStyle(isSubtitleProblem ? Color(.GrocyColors.grocyRed) : Color.secondary)
                }
            }
        )
    }
}

#Preview {
    Form {
        MyLabelWithSubtitle(title: "Title", subTitle: "subtitle", systemImage: MySymbols.name)
        MyLabelWithSubtitle(title: "Title", subTitle: "subtitle", systemImage: MySymbols.name, isProblem: true)
        MyLabelWithSubtitle(title: "Title", subTitle: "subtitle", systemImage: MySymbols.name, isSubtitleProblem: true)
    }
}
