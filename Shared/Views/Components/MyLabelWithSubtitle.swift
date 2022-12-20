//
//  MyLabelWithSubtitle.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 02.03.21.
//

import SwiftUI

struct MyLabelWithSubtitle: View {
    var title: String
    var subTitle: String? = nil
    var systemImage: String? = nil
    var isProblem: Bool = false
    var isSubtitleProblem: Bool = false
    var hideSubtitle: Bool = false
    
    var body: some View {
        HStack{
            if let systemImage = systemImage {
                Image(systemName: systemImage)
            }
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(title))
//                    .font(.headline)
                    .foregroundColor(isProblem ? Color.red : Color.primary)
                if !hideSubtitle {
                    if let subTitle = subTitle {
                        Text(LocalizedStringKey(subTitle))
                            .font(.caption)
                            .foregroundColor(isSubtitleProblem ? Color.red : Color.primary)
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
