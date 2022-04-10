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
    
    private func deletePicture(savedPictureFileNameData: Data) {
        isProcessing = true
        grocyVM.deleteFile(groupName: "productpictures", fileName: savedPictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)), completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog("Picture successfully deleted. \(message)", type: .info)
                changeProductPicture(newPictureFilename: nil)
            case let .failure(error):
                grocyVM.postLog("Picture deletion failed. \(error)", type: .error)
                isProcessing = false
            }
        })
    }
    
    #if os(iOS)
    private func uploadPicture(imagepicture: UIImage, newPictureFilename: String) {
        if let pictureFileNameData = newPictureFilename.data(using: .utf8), let jpegpicture = imagepicture.jpegData(compressionQuality: 0.8) {
            let base64Encoded = pictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            
            isProcessing = true
            grocyVM.uploadFileData(fileData: jpegpicture, groupName: "productpictures", fileName: base64Encoded, completion: { result in
                switch result {
                case let .success(response):
                    grocyVM.postLog("Picture successfully uploaded. \(response)", type: .info)
                    changeProductPicture(newPictureFilename: newPictureFilename)
                case let .failure(error):
                    grocyVM.postLog("Picture upload failed. \(error)", type: .error)
                    isProcessing = false
                }
            })
        }
    }
    #elseif os(macOS)
    private func uploadPicture(imagepicture: NSImage, newPictureFilename: String) {
//        if let pictureFileNameData = newPictureFilename.data(using: .utf8), let jpegpicture = imagepicture.jpegData(compressionQuality: 0.8) {
//            let base64Encoded = pictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
//
//            isProcessing = true
//            grocyVM.uploadFileData(fileData: jpegpicture, groupName: "productpictures", fileName: base64Encoded, completion: { result in
//                switch result {
//                case let .success(response):
//                    grocyVM.postLog("Picture successfully uploaded. \(response)", type: .info)
//                    changeProductPicture(newPictureFilename: newPictureFilename)
//                case let .failure(error):
//                    grocyVM.postLog("Picture upload failed. \(error)", type: .error)
//                    isProcessing = false
//                }
//            })
//        }
    }
    #endif
    
    private func changeProductPicture(newPictureFilename: String?){
        if let product = product {
            var productPOST = product
            productPOST.pictureFileName = newPictureFilename
            grocyVM.putMDObjectWithID(object: .products, id: product.id, content: productPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog("Picture successfully changed in product. \(message)", type: .info)
                    grocyVM.requestData(objects: [.products])
                    pictureFilename = selectedPictureFileName
                    picture = nil
                    selectedPictureFileName = nil
                case let .failure(error):
                    grocyVM.postLog("Adding picture to product failed. \(error)", type: .error)
                }
                isProcessing = false
            })
        }
    }
    
    var body: some View {
        Form {
            Section {
                if let pictureFilename = pictureFilename, !pictureFilename.isEmpty {
                    if let base64Encoded = pictureFilename.data(using: .utf8)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)), let pictureURL = grocyVM.getPictureURL(groupName: "productpictures", fileName: base64Encoded), let url = URL(string: pictureURL) {
                        AsyncImage(url: url, content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .background(Color.white)
                        }, placeholder: {
                            ProgressView()
                        })
                        .frame(maxHeight: 100)
                    }
                    Text(pictureFilename)
                        .font(.caption)
                    if let pictureFilenameData = pictureFilename.data(using: .utf8) {
                        Button(action: {
                            deletePicture(savedPictureFileNameData: pictureFilenameData)
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
                            selectedPictureFileName = openPanel.url?.lastPathComponent
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
                        selectedPictureFileName = "\(UUID())_\(product.name).jpg"
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
                        selectedPictureFileName = "\(UUID())_\(product.name).jpg"
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
                            uploadPicture(imagepicture: picture, newPictureFilename: selectedPictureFileName)
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
            //            MDProductPictureFormView(product: MDProduct(id: "1", name: "Product name", mdProductDescription: "Product description", productGroupID: "1", active: "1", locationID: "1", shoppingLocationID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: "cookies.jpg", enableTareWeightHandling: "0", tareWeight: "0", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "TS", hideOnStockOverview: nil, userfields: nil), selectedPictureURL: Binding.constant(nil), selectedPictureFileName: Binding.constant(nil))
        }
    }
}
