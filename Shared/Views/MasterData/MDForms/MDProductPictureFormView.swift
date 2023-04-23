//
//  MDProductPictureFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 08.03.21.
//

import SwiftUI

struct MDProductPictureFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var product: MDProduct?
    
    @State private var selectedPictureFileName: String?
    @Binding var pictureFilename: String?
    
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
            await changeProductPicture(newPictureFilename: nil)
        } catch {
            grocyVM.postLog("Picture deletion failed. \(error)", type: .error)
            isProcessing = false
        }
    }
    
#if os(iOS)
    private func uploadPicture(imagePicture: UIImage, newPictureFilename: String) async {
        if let pictureFileNameData = newPictureFilename.data(using: .utf8), let jpegData = imagePicture.jpegData(compressionQuality: 0.8) {
            let base64Encoded = pictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            isProcessing = true
            do {
                try await grocyVM.uploadFileData(fileData: jpegData, groupName: "productpictures", fileName: base64Encoded)
                grocyVM.postLog("Picture successfully uploaded.", type: .info)
                await changeProductPicture(newPictureFilename: newPictureFilename)
            } catch {
                grocyVM.postLog("Picture upload failed. \(error)", type: .error)
                isProcessing = false
            }
        }
    }
#elseif os(macOS)
    private func uploadPicture(imagePicture: NSImage, newPictureFilename: String) async {
        if let pictureFileNameData = newPictureFilename.data(using: .utf8), let cgImage = imagePicture.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            let base64Encoded = pictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            if let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:]) {
                isProcessing = true
                do {
                    try await grocyVM.uploadFileData(fileData: jpegData, groupName: "productpictures", fileName: base64Encoded)
                    grocyVM.postLog("Picture successfully uploaded.", type: .info)
                    await changeProductPicture(newPictureFilename: newPictureFilename)
                } catch {
                    grocyVM.postLog("Picture upload failed. \(error)", type: .error)
                    isProcessing = false
                }
            }
        }
    }
#endif
    
    private func changeProductPicture(newPictureFilename: String?) async {
        if let product = product {
            var productPOST = product
            productPOST.pictureFileName = newPictureFilename
            do {
                try await grocyVM.putMDObjectWithID(object: .products, id: product.id, content: productPOST)
                grocyVM.postLog("Picture successfully changed in product.", type: .info)
                await grocyVM.requestData(objects: [.products])
                pictureFilename = selectedPictureFileName
                picture = nil
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
                if let pictureFilename = pictureFilename, !pictureFilename.isEmpty {
                    //                    if
                    //                        let base64Encoded = pictureFilename.data(using: .utf8)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)),
                    //                        let pictureURL = grocyVM.getPictureURL(groupName: "productpictures", fileName: base64Encoded), let url = URL(string: pictureURL) {
                    //                        AsyncImage(url: url, content: { image in
                    //                            image
                    //                                .resizable()
                    //                                .aspectRatio(contentMode: .fit)
                    //                                .background(Color.white)
                    //                        }, placeholder: {
                    //                            ProgressView()
                    //                        })
                    //                        .frame(maxHeight: 100)
                    //                    }
                    Text(pictureFilename)
                        .font(.caption)
                    if let pictureFilenameData = pictureFilename.data(using: .utf8) {
                        Button(action: {
                            Task {
                                await deletePicture(savedPictureFileNameData: pictureFilenameData)
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
                                await uploadPicture(imagePicture: picture, newPictureFilename: selectedPictureFileName)
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
            //            MDProductPictureFormView(product: MDProduct(id: "1", name: "Product name", mdProductDescription: "Product description", productGroupID: "1", active: "1", locationID: "1", storeID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: "cookies.jpg", enableTareWeightHandling: "0", tareWeight: "0", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "TS", hideOnStockOverview: nil, userfields: nil), selectedPictureURL: Binding.constant(nil), selectedPictureFileName: Binding.constant(nil))
        }
    }
}
