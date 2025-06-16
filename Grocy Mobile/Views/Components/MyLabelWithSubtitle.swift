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
        HStack{
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.primary)
            }
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundStyle(isProblem ? Color.red : Color.primary)
                if !hideSubtitle {
                    if let subTitle = subTitle {
                        Text(subTitle)
                            .font(.caption)
                            .foregroundStyle(isSubtitleProblem ? Color.red : Color.primary)
                    }
                }
            }
        }
    }
}

struct MyLabelWithSubtitle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MyLabelWithSubtitle(title: "Title", subTitle: "subtitle", systemImage: "tag")
            MyLabelWithSubtitle(title: "Title", subTitle: "subtitle", systemImage: "tag", isProblem: true)
            MyLabelWithSubtitle(title: "Title", subTitle: "subtitle", systemImage: "tag", isSubtitleProblem: true)
        }
    }
}
