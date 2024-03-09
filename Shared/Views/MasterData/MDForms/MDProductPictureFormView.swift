//
//  MDProductPictureFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 08.03.21.
//

import SwiftUI

struct MDProductPictureFormView: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
    
    var product: MDProduct?
    
    @State private var selectedPictureFileName: String?
    @Binding var pictureFileName: String?
    
    @State private var isProcessing: Bool = false
    
#if os(iOS)
    @State private var showImagePicker: Bool = false
    @State private var showCamera: Bool = false
    @State private var picture: UIImage? = nil
#elseif os(macOS)
    @State private var picture: NSImage? = nil
#endif
    
    let groupName = "productpictures"
    
    private func deletePicture(savedPictureFileNameData: Data) async {
        isProcessing = true
        do {
            try await grocyVM.deleteFile(groupName: "productpictures", fileName: savedPictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)))
            grocyVM.postLog("Picture successfully deleted.", type: .info)
            await changeProductPicture(newPictureFileName: nil)
        } catch {
            grocyVM.postLog("Picture deletion failed. \(error)", type: .error)
            isProcessing = false
        }
    }
    
#if os(iOS)
    private func uploadPicture(imagePicture: UIImage, newPictureFileName: String) async {
        if let pictureFileNameData = newPictureFileName.data(using: .utf8), let jpegData = imagePicture.jpegData(compressionQuality: 0.8) {
            let base64Encoded = pictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            isProcessing = true
            do {
                try await grocyVM.uploadFileData(fileData: jpegData, groupName: "productpictures", fileName: base64Encoded)
                grocyVM.postLog("Picture successfully uploaded.", type: .info)
                await changeProductPicture(newPictureFileName: newPictureFileName)
            } catch {
                grocyVM.postLog("Picture upload failed. \(error)", type: .error)
                isProcessing = false
            }
        }
    }
#elseif os(macOS)
    private func uploadPicture(imagePicture: NSImage, newPictureFileName: String) async {
        if let pictureFileNameData = newPictureFileName.data(using: .utf8), let cgImage = imagePicture.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            let base64Encoded = pictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            if let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:]) {
                isProcessing = true
                do {
                    try await grocyVM.uploadFileData(fileData: jpegData, groupName: "productpictures", fileName: base64Encoded)
                    grocyVM.postLog("Picture successfully uploaded.", type: .info)
                    await changeProductPicture(newPictureFileName: newPictureFileName)
                } catch {
                    grocyVM.postLog("Picture upload failed. \(error)", type: .error)
                    isProcessing = false
                }
            }
        }
    }
#endif
    
    private func changeProductPicture(newPictureFileName: String?) async {
        if let product = product {
            var productPOST = product
            productPOST.pictureFileName = newPictureFileName
            do {
                try await grocyVM.putMDObjectWithID(object: .products, id: product.id, content: productPOST)
                grocyVM.postLog("Picture successfully changed in product.", type: .info)
                await grocyVM.requestData(objects: [.products])
                pictureFileName = selectedPictureFileName
                selectedPictureFileName = nil
            } catch {
                grocyVM.postLog("Adding picture to product failed. \(error)", type: .error)
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        Form {
            Section {
                if let pictureFileName = pictureFileName, !pictureFileName.isEmpty {
                    PictureView(pictureFileName: pictureFileName, pictureType: .productPictures, maxWidth: 100.0, maxHeight: 100.0)
                    Text(pictureFileName)
                        .font(.caption)
                    if let pictureFileNameData = pictureFileName.data(using: .utf8) {
                        Button(action: {
                            Task {
                                await deletePicture(savedPictureFileNameData: pictureFileNameData)
                            }
                        }, label: {
                            Label(LocalizedStringKey("str.md.product.picture.delete"), systemImage: MySymbols.delete)
                                .foregroundColor(.red)
                        })
                        .disabled(isProcessing)
                    }
                }
            }
            Section {
#if os(macOS)
                Button(LocalizedStringKey("str.md.product.picture.add.file")) {
                    let openPanel = NSOpenPanel()
                    openPanel.prompt = "Select File"
                    openPanel.allowsMultipleSelection = false
                    openPanel.canChooseDirectories = false
                    openPanel.canCreateDirectories = false
                    openPanel.canChooseFiles = true
                    openPanel.allowedContentTypes = [.image]
                    openPanel.begin { (result) -> Void in
                        if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                            do {
                                let imageData = try Data(contentsOf: openPanel.url!)
                                picture = NSImage(data: imageData)
                                selectedPictureFileName = openPanel.url?.lastPathComponent
                            } catch {
                                print("Error loading image : \(error)")
                            }
                        }
                    }
                }
#elseif os(iOS)
                Button(action: {
                    showImagePicker.toggle()
                }, label: {
                    Label(LocalizedStringKey("str.md.product.picture.add.gallery"), systemImage: MySymbols.gallery)
                })
                .sheet(isPresented: $showImagePicker, onDismiss: {
                    if let product = product {
                        selectedPictureFileName = "\(UUID())_\(product.name.cleanedFileName).jpg"
                    } else {
                        selectedPictureFileName = "\(UUID())_.jpg"
                    }
                }, content: {
                    ImageLibraryPicker(image: $picture, selectedPictureFileName: $selectedPictureFileName, productName: product?.name)
                })
                Button(action: {
                    showCamera.toggle()
                }, label: {
                    Label(LocalizedStringKey("str.md.product.picture.add.camera"), systemImage: MySymbols.camera)
                })
                .sheet(isPresented: $showCamera, onDismiss: {
                    if let product = product {
                        selectedPictureFileName = "\(UUID())_\(product.name.cleanedFileName).jpg"
                    } else {
                        selectedPictureFileName = "\(UUID())_.jpg"
                    }
                }, content: {
                    CameraPicker(image: $picture, selectedPictureFileName: $selectedPictureFileName, productName: product?.name, showCamera: $showCamera)
                })
#endif
                if let picture = picture {
#if os(iOS)
                    Image(uiImage: picture)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 150)
#elseif os(macOS)
                    Image(nsImage: picture)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 150)
#endif
                    if let selectedPictureFileName = selectedPictureFileName {
                        Text(selectedPictureFileName)
                            .font(.caption)
                        Button(action: {
                            Task {
                                await uploadPicture(imagePicture: picture, newPictureFileName: selectedPictureFileName)
                            }
                        }, label: {
                            Label(LocalizedStringKey("str.md.product.picture.upload"), systemImage: MySymbols.upload)
                        })
                        .disabled(isProcessing)
                    }
                }
            }
        }
#if os(iOS)
        .navigationTitle(LocalizedStringKey("str.md.product.picture"))
#endif
    }
}

struct MDProductPictureFormView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            //            MDProductPictureFormView(product: MDProduct(id: "1", name: "Product name", mdProductDescription: "Product description", productGroupID: "1", active: "1", locationID: "1", storeID: "1", quIDPurchase: "1", quIDStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: "cookies.jpg", enableTareWeightHandling: "0", tareWeight: "0", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "TS", hideOnStockOverview: nil, userfields: nil), selectedPictureURL: Binding.constant(nil), selectedPictureFileName: Binding.constant(nil))
        }
    }
}
