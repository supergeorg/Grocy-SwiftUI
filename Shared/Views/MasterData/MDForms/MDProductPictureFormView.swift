//
//  MDProductPictureFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 08.03.21.
//

import SwiftUI
import URLImage

struct MDProductPictureFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var product: MDProduct?
    
    @Binding var selectedPictureURL: URL?
    @Binding var selectedPictureFileName: String?
    @State private var newPictureURL: URL?
    @State private var newPictureFileName: String?
    
    #if os(iOS)
    @State private var showImagePicker: Bool = false
    @State private var showCamera: Bool = false
    #endif
    
    let groupName = "productpictures"
    
    private func deletePicture(savedPictureFileNameData: Data) {
        grocyVM.deleteFile(groupName: "productpictures", fileName: savedPictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)), completion: { result in
            switch result {
            case let .success(message):
                grocyVM.postLog(message: "Picture successfully deleted. \(message)", type: .info)
                changeProductPicture(pictureFileName: nil)
            case let .failure(error):
                grocyVM.postLog(message: "Picture deletion failed. \(error)", type: .error)
            }
        })
    }
    
    private func uploadPicture(pictureFileName: String, selectedImageURL: URL) {
        if let pictureFileNameData = pictureFileName.data(using: .utf8) {
            let base64Encoded = pictureFileNameData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            grocyVM.uploadFile(fileURL: selectedImageURL, groupName: "productpictures", fileName: base64Encoded, completion: {result in
                switch result {
                case let .success(response):
                    grocyVM.postLog(message: "Picture successfully uploaded. \(response)", type: .info)
                    changeProductPicture(pictureFileName: pictureFileName)
                case let .failure(error):
                    grocyVM.postLog(message: "Picture upload failed. \(error)", type: .error)
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
                    grocyVM.postLog(message: "Picture successfully added to product. \(message)", type: .info)
                    grocyVM.requestData(objects: [.products])
                    selectedPictureURL = nil
                    selectedPictureFileName = nil
                case let .failure(error):
                    grocyVM.postLog(message: "Adding picture to product failed. \(error)", type: .error)
                }
            })
        }
    }
    
    var body: some View {
        VStack{
            if let pictureFileName = product?.pictureFileName {
                if !pictureFileName.isEmpty {
                    if let base64Encoded = pictureFileName.data(using: .utf8)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
                        if let pictureURL = URL(string: grocyVM.getPictureURL(groupName: groupName, fileName: base64Encoded) ?? "") {
                            URLImage(url: pictureURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .background(Color.white)
                            }
                            .frame(maxHeight: 100)
                        }
                    }
                    Text(pictureFileName)
                        .font(.caption)
                }
            }
            Form{
                Section{
                    if let savedPictureFileName = product?.pictureFileName {
                        if !savedPictureFileName.isEmpty{
                            if let savedPictureFileNameData = savedPictureFileName.data(using: .utf8) {
                                Button(action: {
                                    deletePicture(savedPictureFileNameData: savedPictureFileNameData)
                                }, label: {
                                    Label(LocalizedStringKey("str.md.product.picture.delete"), systemImage: MySymbols.delete)
                                        .foregroundColor(.red)
                                })
                            }
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
                        openPanel.allowedFileTypes = ["png","jpg","jpeg"]
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
                                showImagePicker = false
                            }
                        })
                    })
                    #endif
                    if let selectedPictureURL = selectedPictureURL {
                        if let selectedPictureFileName = selectedPictureFileName {
                            VStack(alignment: .center){
                                URLImage(url: selectedPictureURL, content: {image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .background(Color.white)
                                })
                                .frame(maxWidth: 100)
                                Text(selectedPictureFileName)
                                    .font(.caption)
                            }
                        }
                    }
                    Button(action: {
                        if let selectedPictureFileName = selectedPictureFileName{
                            if let selectedPictureURL = selectedPictureURL {
                                uploadPicture(pictureFileName: selectedPictureFileName, selectedImageURL: selectedPictureURL)
                            }
                        }
                    }, label: {
                        Label(LocalizedStringKey("str.md.product.picture.upload"), systemImage: MySymbols.upload)
                    })
                }
            }
        }
        .navigationTitle(LocalizedStringKey("str.md.product.picture"))
    }
}

struct MDProductPictureFormView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            MDProductPictureFormView(product: MDProduct(id: "1", name: "Product name", mdProductDescription: "Product description", productGroupID: "1", active: "1", locationID: "1", shoppingLocationID: "1", quIDPurchase: "1", quIDStock: "1", quFactorPurchaseToStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: "cookies.jpg", enableTareWeightHandling: "0", tareWeight: "0", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "TS", hideOnStockOverview: nil, userfields: nil), selectedPictureURL: Binding.constant(nil), selectedPictureFileName: Binding.constant(nil))
        }
    }
}
