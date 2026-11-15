//
//  MDProductPictureFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 08.03.21.
//

import PhotosUI
import SwiftUI

struct MDProductPictureFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @State private var showCamera = false
    #if os(iOS)
        @State private var capturedImage: UIImage?
    #endif

    var existingProduct: MDProduct?

    @Binding var pictureFileName: String?

    @State private var isProcessing: Bool = false

    @State private var productImageFilename: String?
    @State private var productImageItem: PhotosPickerItem?
    @State private var productImageData: Data?
    @State private var productImage: Image?

    private func deletePicture(savedPictureFileNameData: Data) async {
        isProcessing = true
        do {
            try await grocyVM.deleteFile(groupName: "productpictures", fileName: savedPictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)))
            GrocyLogger.info("Picture successfully deleted.")
            await changeProductPicture(newPictureFileName: nil)
        } catch {
            GrocyLogger.error("Picture deletion failed. \(error)")
            isProcessing = false
        }
    }

    private func uploadPicture() async {
        if let productImageData = productImageData, let productImageFilename = productImageFilename {
            #if os(iOS)
                let imagePicture = UIImage(data: productImageData)
            #elseif os(macOS)
                let imagePicture = NSImage(data: productImageData)
            #endif
            if let pictureFileNameData = productImageFilename.data(using: .utf8) {
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
                    try await grocyVM.uploadFileData(fileData: jpegData, groupName: "productpictures", fileName: base64Encoded)
                    GrocyLogger.info("Picture successfully uploaded.")
                    await changeProductPicture(newPictureFileName: productImageFilename)
                } catch {
                    GrocyLogger.error("Picture upload failed. \(error)")
                    isProcessing = false
                }
            }
        }
    }

    private func changeProductPicture(newPictureFileName: String?) async {
        if let product = existingProduct {
            let updatedProduct = product
            updatedProduct.pictureFileName = newPictureFileName
            do {
                try await grocyVM.putMDObjectWithID(object: .products, id: product.id, content: updatedProduct)
                GrocyLogger.info("Picture successfully changed in product.")
                await grocyVM.requestData(objects: [.products])
                pictureFileName = newPictureFileName
                productImageFilename = nil
                productImage = nil
                productImageItem = nil
                productImageData = nil
            } catch {
                GrocyLogger.error("Adding picture to product failed. \(error)")
            }
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            if let pictureFileName = pictureFileName, !pictureFileName.isEmpty {
                Section("Existing product picture") {
                    PictureView(pictureFileName: pictureFileName, pictureType: .productPictures)
                        .clipShape(.rect(cornerRadius: 5.0))
                        .frame(maxWidth: Sizes.picturePreview, maxHeight: Sizes.picturePreview)
                    Text(pictureFileName)
                        .font(.caption)
                    if let pictureFileNameData = pictureFileName.data(using: .utf8) {
                        Button(
                            action: {
                                Task {
                                    await deletePicture(savedPictureFileNameData: pictureFileNameData)
                                }
                            },
                            label: {
                                Label("Delete product picture", systemImage: MySymbols.delete)
                                    .foregroundStyle(.red)
                            }
                        )
                        .disabled(isProcessing)
                    }
                }
            }
            Section {
                PhotosPicker(
                    selection: $productImageItem,
                    matching: .images,
                    label: {
                        Label("Select product picture from gallery", systemImage: MySymbols.gallery)
                    }
                )
                #if os(iOS)
                    Button(
                        action: {
                            showCamera.toggle()
                        },
                        label: {
                            Label("Add product picture from camera", systemImage: MySymbols.camera)
                        }
                    )
                    .fullScreenCover(isPresented: $showCamera) {
                        CameraPicker(sourceType: .camera) { image in
                            capturedImage = image
                        }
                    }
                #endif
                if let productImage {
                    productImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: Sizes.picturePreview, height: Sizes.picturePreview)
                    if let productImageFilename = productImageFilename {
                        Text(productImageFilename)
                            .font(.caption)
                        Button(
                            action: {
                                Task {
                                    await uploadPicture()
                                }
                            },
                            label: {
                                Label("Upload product picture", systemImage: MySymbols.upload)
                            }
                        )
                        .disabled(isProcessing)
                    }
                }
            }
        }
        .navigationTitle("Product picture")
        #if os(iOS)
            .onChange(of: capturedImage) {
                Task {
                    if let uiImage = capturedImage {
                        // Convert UIImage to JPEG data
                        if let data = uiImage.jpegData(compressionQuality: 0.8) {
                            if let product = existingProduct {
                                productImageFilename = "\(UUID())_\(product.name.cleanedFileName).jpg"
                            } else {
                                productImageFilename = "\(UUID()).jpg"
                            }
                            productImageData = data

                            #if os(iOS)
                                productImage = Image(uiImage: uiImage)
                            #elseif os(macOS)
                                if let nsImage = NSImage(data: data) {
                                    productImage = Image(nsImage: nsImage)
                                }
                            #endif
                        }
                    }
                }
            }
        #endif
        .onChange(of: productImageItem) {
            Task {
                if let data = try? await productImageItem?.loadTransferable(type: Data.self) {
                    if let product = existingProduct {
                        productImageFilename = "\(UUID())_\(product.name.cleanedFileName).jpg"
                    } else {
                        productImageFilename = "\(UUID()).jpg"
                    }
                    productImageData = data
                    #if os(iOS)
                        if let uiImage = UIImage(data: data) {
                            productImage = Image(uiImage: uiImage)
                            return
                        }
                    #elseif os(macOS)
                        if let nsImage = NSImage(data: data) {
                            productImage = Image(nsImage: nsImage)
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
        MDProductPictureFormView(
            pictureFileName: $pictureFileName
        )
    }
}
