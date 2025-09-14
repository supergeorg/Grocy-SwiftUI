//
//  PictureView.swift
//  Grocy Mobile (iOS)
//
//  Created by Georg Meissner on 28.08.23.
//

import SwiftUI

enum PictureType: String {
    case productPictures = "productpictures"
    case userPictures = "userpictures"
    case recipePictures = "recipepictures"
}

struct PictureView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var pictureFileName: String
    var pictureType: PictureType

    #if os(iOS)
        @State private var picture: UIImage? = nil
    #elseif os(macOS)
        @State private var picture: NSImage? = nil
    #endif

    var body: some View {
        if let picture = picture {
            #if os(iOS)
                Image(uiImage: picture)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color.white)
            #elseif os(macOS)
                Image(nsImage: picture)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color.white)
            #endif
        } else {
            ProgressView()
                .task {
                    do {
                        if let base64Encoded = pictureFileName.data(using: .utf8)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
                            var pictureData: Data? = nil
                            switch pictureType {
                            case .productPictures:
                                pictureData = try await grocyVM.getProductPicture(fileName: base64Encoded)
                            case .userPictures:
                                pictureData = try await grocyVM.getUserPicture(fileName: base64Encoded)
                            case .recipePictures:
                                pictureData = try await grocyVM.getRecipePicture(fileName: base64Encoded)
                            }
                            if let pictureData = pictureData {
                                #if os(iOS)
                                    self.picture = UIImage(data: pictureData)
                                #elseif os(macOS)
                                    self.picture = NSImage(data: pictureData)
                                #endif
                            }
                        }
                    } catch {
                        GrocyLogger.error("Getting product picture failed. \(error)")
                    }
                }
        }
    }
}

//struct PictureView_Previews: PreviewProvider {
//    static var previews: some View {
//        PictureView()
//    }
//}
