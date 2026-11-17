//
//  RecipeThumbnailView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// A recipe's picture filling the space it's given (cropped), or a placeholder when the recipe has none.
/// Give it a frame or an aspect ratio; it clips itself.
struct RecipeThumbnailView: View {
    var pictureFileName: String?

    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                if let pictureFileName, !pictureFileName.isEmpty {
                    PictureView(pictureFileName: pictureFileName, pictureType: .recipePictures)
                        .scaledToFill()
                } else {
                    Image(systemName: MySymbols.picturePlaceholder)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .clipped()
            // Decorative: the recipe's name is always shown next to it.
            .accessibilityHidden(true)
    }
}

#Preview(traits: .previewData) {
    RecipeThumbnailView(pictureFileName: nil)
        .frame(width: Sizes.recipeThumbnail, height: Sizes.recipeThumbnail)
}
