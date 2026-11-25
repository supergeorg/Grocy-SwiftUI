//
//  UserAvatarView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 25.11.26.
//

import SwiftUI

/// A user's picture in a circle, or a person symbol when the user has none (or it can't be loaded).
struct UserAvatarView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var pictureFileName: String?
    var size: CGFloat = Sizes.avatar

    @State private var pictureData: Data?

    var body: some View {
        Group {
            if let pictureData, let image = Image(data: pictureData) {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: MySymbols.user)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quaternary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .accessibilityHidden(true)
        .task(id: pictureFileName) {
            await loadPicture()
        }
    }

    private func loadPicture() async {
        guard let pictureFileName, !pictureFileName.isEmpty else {
            pictureData = nil
            return
        }
        do {
            // One size for all avatars (the view model caches a picture by its name), twice the largest for Retina screens.
            pictureData = try await grocyVM.getUserPicture(
                fileName: Data(pictureFileName.utf8).base64EncodedString(),
                bestFitWidth: Int(Sizes.userPicture) * 2
            )
        } catch {
            if !isCancellation(error) {
                GrocyLogger.warning("Loading the picture of a user failed. \(error)")
            }
        }
    }
}

#Preview(traits: .previewData) {
    HStack {
        UserAvatarView(pictureFileName: nil)
        UserAvatarView(pictureFileName: nil, size: Sizes.userPicture)
    }
}
