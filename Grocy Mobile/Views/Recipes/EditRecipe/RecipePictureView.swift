//
//  RecipePictureView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 05.02.26.
//

import PhotosUI
import SwiftUI

struct RecipePictureView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @State private var showCamera = false
    #if os(iOS)
        @State private var capturedImage: UIImage?
    #endif

    var existingRecipe: Recipe

    @Binding var pictureFileName: String?

    @State private var isProcessing: Bool = false

    @State private var recipeImageFilename: String?
    @State private var recipeImageItem: PhotosPickerItem?
    @State private var recipeImageData: Data?
    @State private var recipeImage: Image?

    private func deletePicture(savedPictureFileNameData: Data) async {
        isProcessing = true
        do {
            try await grocyVM.deleteFile(groupName: PictureType.recipePictures.rawValue, fileName: savedPictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)))
            GrocyLogger.info("Picture successfully deleted.")
            await changePicture(newPictureFileName: nil)
        } catch {
            GrocyLogger.error("Picture deletion failed. \(error)")
            isProcessing = false
        }
    }

    private func uploadPicture() async {
        if let recipeImageData, let recipeImageFilename {
            #if os(iOS)
                let imagePicture = UIImage(data: recipeImageData)
            #elseif os(macOS)
                let imagePicture = NSImage(data: recipeImageData)
            #endif
            if let pictureFileNameData = recipeImageFilename.data(using: .utf8) {
                #if os(iOS)
                    let jpegData = imagePicture?.jpegData(compressionQuality: 0.8)
                    guard let jpegData = jpegData else {
                        isProcessing = false
                        return
                    }
                #elseif os(macOS)
                    guard let cgImage = unsafe imagePicture?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                        isProcessing = false
                        return
                    }
                    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
                    let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
                    guard let jpegData = jpegData else {
                        isProcessing = false
                        return
                    }
                #endif
                let base64Encoded = pictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
                isProcessing = true
                do {
                    try await grocyVM.uploadFileData(fileData: jpegData, groupName: PictureType.recipePictures.rawValue, fileName: base64Encoded)
                    GrocyLogger.info("Picture successfully uploaded.")
                    await changePicture(newPictureFileName: recipeImageFilename)
                } catch {
                    GrocyLogger.error("Picture upload failed. \(error)")
                    isProcessing = false
                }
            }
        }
    }

    private func changePicture(newPictureFileName: String?) async {
        let updatedRecipe = existingRecipe
        updatedRecipe.pictureFileName = newPictureFileName
        do {
            try await grocyVM.putMDObjectWithID(object: .recipes, id: updatedRecipe.id, content: updatedRecipe)
            GrocyLogger.info("Picture successfully changed in recipe.")
            await grocyVM.requestData(objects: [.recipes])
            pictureFileName = newPictureFileName
            recipeImageFilename = nil
            recipeImage = nil
            recipeImageItem = nil
            recipeImageData = nil
        } catch {
            GrocyLogger.error("Adding picture to recipe failed. \(error)")
        }
        isProcessing = false
    }

    var body: some View {
        List {
            if let pictureFileName = pictureFileName, !pictureFileName.isEmpty {
                Section {
                    VStack(alignment: .leading) {
                        PictureView(pictureFileName: pictureFileName, pictureType: .recipePictures)
                            .clipShape(.rect(cornerRadius: 5.0))
                            .frame(maxWidth: Sizes.picturePreview, maxHeight: Sizes.picturePreview)
                        Text(pictureFileName)
                            .font(.caption)
                    }
                    if let pictureFileNameData = pictureFileName.data(using: .utf8) {
                        // The destructive role colors the button, instead of a hard-coded red label.
                        Button(
                            role: .destructive,
                            action: {
                                Task {
                                    await deletePicture(savedPictureFileNameData: pictureFileNameData)
                                }
                            },
                            label: {
                                Label("Delete", systemImage: MySymbols.delete)
                            }
                        )
                        .disabled(isProcessing)
                    }
                }
            }
            Section {
                PhotosPicker(
                    selection: $recipeImageItem,
                    matching: .images,
                    label: {
                        Label("Select picture from gallery", systemImage: MySymbols.gallery)
                    }
                )
                #if os(iOS)
                    Button(
                        action: {
                            showCamera.toggle()
                        },
                        label: {
                            Label("Add picture from camera", systemImage: MySymbols.camera)
                        }
                    )
                    .fullScreenCover(isPresented: $showCamera) {
                        CameraPicker(sourceType: .camera) { image in
                            capturedImage = image
                        }
                    }
                #endif
                if let recipeImage {
                    recipeImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: Sizes.picturePreview, height: Sizes.picturePreview)
                    if let recipeImageFilename {
                        Text(recipeImageFilename)
                            .font(.caption)
                        Button(
                            action: {
                                Task {
                                    await uploadPicture()
                                }
                            },
                            label: {
                                Label("Upload picture", systemImage: MySymbols.upload)
                            }
                        )
                        .disabled(isProcessing)
                    }
                }
            }
        }
        #if os(iOS)
            .onChange(of: capturedImage) {
                Task {
                    if let uiImage = capturedImage {
                        // Convert UIImage to JPEG data
                        if let data = uiImage.jpegData(compressionQuality: 0.8) {
                            recipeImageFilename = "\(UUID())_\(existingRecipe.name.cleanedFileName).jpg"
                            recipeImageData = data

                            #if os(iOS)
                                recipeImage = Image(uiImage: uiImage)
                            #elseif os(macOS)
                                if let nsImage = NSImage(data: data) {
                                    recipeImage = Image(nsImage: nsImage)
                                }
                            #endif
                        }
                    }
                }
            }
        #endif
        .onChange(of: recipeImageItem) {
            Task {
                if let data = try? await recipeImageItem?.loadTransferable(type: Data.self) {
                    recipeImageFilename = "\(UUID())_\(existingRecipe.name.cleanedFileName).jpg"
                    recipeImageData = data
                    #if os(iOS)
                        if let uiImage = UIImage(data: data) {
                            recipeImage = Image(uiImage: uiImage)
                            return
                        }
                    #elseif os(macOS)
                        if let nsImage = NSImage(data: data) {
                            recipeImage = Image(nsImage: nsImage)
                            return
                        }
                    #endif
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var pictureFileName: String? = nil
    NavigationStack {
        RecipePictureView(
            existingRecipe: Recipe(),
            pictureFileName: $pictureFileName
        )
    }
}
