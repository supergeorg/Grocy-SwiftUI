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
    
    @Binding var selectedPictureURL: URL?
    @Binding var selectedPictureFileName: String?
    @State private var newPictureURL: URL? = nil
    @State private var newPictureFileName: String?
    @State private var showNewPicture: Bool = false
    
    @State private var isProcessing: Bool = false
    
#if os(iOS)
    @State private var showImagePicker: Bool = false
    @State private var showCamera: Bool = false
#endif
    
    let groupName = "productpictures"
    
    private func deletePicture(savedPictureFileNameData: Data) {
        isProcessing = true
        grocyVM.deleteFile(groupName: "productpictures", fileName: savedPictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)), completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog("Picture successfully deleted. \(message)", type: .info)
                changeProductPicture(pictureFileName: nil)
            case let .failure(error):
                grocyVM.postLog("Picture deletion failed. \(error)", type: .error)
                isProcessing = false
            }
        })
    }
    
    private func uploadPicture(pictureFileName: String, selectedImageURL: URL) {
        if let pictureFileNameData = pictureFileName.data(using: .utf8) {
            let base64Encoded = pictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            isProcessing = true
            grocyVM.uploadFile(fileURL: selectedImageURL, groupName: "productpictures", fileName: base64Encoded, completion: {result in
                switch result {
                case let .success(response):
                    grocyVM.postLog("Picture successfully uploaded. \(response)", type: .info)
                    changeProductPicture(pictureFileName: pictureFileName)
                case let .failure(error):
                    grocyVM.postLog("Picture upload failed. \(error)", type: .error)
                    isProcessing = false
                }
            })
        }
    }
    
    private func changeProductPicture(pictureFileName: String?){
        if let product = product {
            var productPOST = product
            productPOST.pictureFileName = pictureFileName
            grocyVM.putMDObjectWithID(object: .products, id: product.id, content: productPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog("Picture successfully changed in product. \(message)", type: .info)
                    grocyVM.requestData(objects: [.products])
                    newPictureURL = selectedPictureURL
                    newPictureFileName = selectedPictureFileName
                    showNewPicture = true
                    selectedPictureURL = nil
                    selectedPictureFileName = nil
                case let .failure(error):
                    grocyVM.postLog("Adding picture to product failed. \(error)", type: .error)
                }
                isProcessing = false
            })
        }
    }
    
    var body: some View {
        VStack{
            if showNewPicture {
                if let newPictureURL = newPictureURL, let newPictureFileName = newPictureFileName {
                    AsyncImage(url: newPictureURL, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(Color.white)
                    }, placeholder: {
                        ProgressView()
                    })
                        .frame(maxHeight: 100)
                    Text(newPictureFileName)
                        .font(.caption)
                }
            } else {
                if let pictureFileName = product?.pictureFileName, !pictureFileName.isEmpty {
                    if let base64Encoded = pictureFileName.data(using: .utf8)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)), let pictureURL = URL(string: grocyVM.getPictureURL(groupName: groupName, fileName: base64Encoded) ?? "") {
                        AsyncImage(url: pictureURL, content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .background(Color.white)
                        }, placeholder: {
                            ProgressView()
                        })
                            .frame(maxHeight: 100)
                    }
                    Text(pictureFileName)
                        .font(.caption)
                }
            }
            Form{
                Section{
                    if showNewPicture {
                        if let newPictureFileName = newPictureFileName, newPictureURL != nil, let newPictureFileNameData = newPictureFileName.data(using: .utf8) {
                            Button(action: {
                                deletePicture(savedPictureFileNameData: newPictureFileNameData)
                            }, label: {
                                Label(LocalizedStringKey("str.md.product.picture.delete"), systemImage: MySymbols.delete)
                                    .foregroundColor(.red)
                            })
                                .disabled(isProcessing)
                        }
                    } else {
                        if let savedPictureFileName = product?.pictureFileName, !savedPictureFileName.isEmpty, let savedPictureFileNameData = savedPictureFileName.data(using: .utf8) {
                            Button(action: {
                                deletePicture(savedPictureFileNameData: savedPictureFileNameData)
                            }, label: {
                                Label(LocalizedStringKey("str.md.product.picture.delete"), systemImage: MySymbols.delete)
                                    .foregroundColor(.red)
                            })
                                .disabled(isProcessing)
                        }
                    }
                }
                Section{
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
                                selectedPictureURL = openPanel.url
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
                        .sheet(isPresented: $showImagePicker, content: {
                            ImagePicker(sourceType: .photoLibrary, completionHandler: { imageURL in
                                if let imageURL = imageURL {
                                    selectedPictureURL = imageURL
                                    if let product = product {
                                        selectedPictureFileName = "\(UUID())_\(product.name).\(imageURL.pathExtension)"
                                    } else {
                                        selectedPictureFileName = "\(UUID())_\(imageURL.lastPathComponent)"
                                    }
                                    showImagePicker = false
                                }
                            })
                        })
                    Button(action: {
                        showCamera.toggle()
                    }, label: {
                        Label(LocalizedStringKey("str.md.product.picture.add.camera"), systemImage: MySymbols.camera)
                    })
                        .sheet(isPresented: $showCamera, content: {
                            ImagePicker(sourceType: .camera, completionHandler: { imageURL in
                                if let imageURL = imageURL {
                                    selectedPictureURL = imageURL
                                    if let product = product {
                                        selectedPictureFileName = "\(UUID())_\(product.name).\(imageURL.pathExtension)"
                                    } else {
                                        selectedPictureFileName = "\(UUID())_\(imageURL.lastPathComponent)"
                                    }
                                    showCamera = false
                                }
                            })
                        })
#endif
                    if let selectedPictureURL = selectedPictureURL, let selectedPictureFileName = selectedPictureFileName {
                        VStack(alignment: .center){
                            AsyncImage(url: selectedPictureURL, content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .background(Color.white)
                            }, placeholder: {
                                ProgressView()
                            })
                                .frame(maxWidth: 100)
                            Text(selectedPictureFileName)
                                .font(.caption)
                        }
                    }
                    if let selectedPictureFileName = selectedPictureFileName, let selectedPictureURL = selectedPictureURL{
                        Button(action: {
                            uploadPicture(pictureFileName: selectedPictureFileName, selectedImageURL: selectedPictureURL)
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
