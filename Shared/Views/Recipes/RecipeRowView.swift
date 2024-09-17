//
//  RecipeRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 02.12.22.
//

import SwiftUI

struct RecipeRowView: View {
    var recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if let pictureFileName = recipe.pictureFileName {
                    PictureView(pictureFileName: pictureFileName, pictureType: .recipePictures, maxWidth: 200.0, maxHeight: 200.0)
                } else {
                    ProgressView()
                        .frame(width: 200.0, height: 200.0)
                }
            }
            Group {
                Text(recipe.name)
                    .font(.headline)
                HStack(alignment: .center) {
                    VStack(alignment: .center) {
                        Text(String(recipe.dueScore))
                            .font(.title3)
                        Text("Due score")
                            .font(.caption)
                    }
                    Spacer()
                    Text("TEST")
                }
            }
            .padding(8.0)
        }
        .background(.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 25.0))
        .shadow(radius: 8.0)
    }
}

//struct RecipeRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecipeRowView(recipe: Recipe())
//    }
//}
