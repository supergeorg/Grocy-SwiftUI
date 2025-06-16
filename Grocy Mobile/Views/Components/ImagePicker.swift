////
////  ImagePicker.swift
////  Grocy-SwiftUI
////
////  Created by Georg Meissner on 08.03.21.
////
//
//import PhotosUI
//import SwiftUI
//
//extension UIImage {
//    func resized(withPercentage percentage: CGFloat, isOpaque: Bool = true) -> UIImage? {
//        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
//        let format = imageRendererFormat
//        format.opaque = isOpaque
//        return UIGraphicsImageRenderer(size: canvas, format: format).image {
//            _ in draw(in: CGRect(origin: .zero, size: canvas))
//        }
//    }
//    func resized(toWidth width: CGFloat, isOpaque: Bool = true) -> UIImage? {
//        let canvas = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
//        let format = imageRendererFormat
//        format.opaque = isOpaque
//        return UIGraphicsImageRenderer(size: canvas, format: format).image {
//            _ in draw(in: CGRect(origin: .zero, size: canvas))
//        }
//    }
//}
//
//struct CameraPicker: UIViewControllerRepresentable {
//    @Binding var image: UIImage?
//    @Binding var selectedPictureFileName: String?
//    var productName: String?
//    @Binding var showCamera: Bool
//
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let viewController = UIImagePickerController()
//        viewController.delegate = context.coordinator
//#if targetEnvironment(simulator)
//        viewController.sourceType = .photoLibrary
//#else
//        viewController.sourceType = .camera
//#endif
//        return viewController
//    }
//    
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
//    
//    func makeCoordinator() -> Coordinator {
//        return Coordinator(self)
//    }
//    
//    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//        let parent: CameraPicker
//        
//        init(_ parent: CameraPicker) {
//            self.parent = parent
//        }
//        
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//            let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
//            let resizedImage = image.resized(toWidth: 300.0)
//            if let productName = self.parent.productName {
//                self.parent.selectedPictureFileName = "\(UUID())_\(productName.cleanedFileName).jpg"
//            } else {
//                self.parent.selectedPictureFileName = "\(UUID())_.jpg"
//            }
//            self.parent.image = resizedImage
//            self.parent.showCamera = false
//        }
//    }
//}
//
//struct ImageLibraryPicker: UIViewControllerRepresentable {
//    @Binding var image: UIImage?
//    @Binding var selectedPictureFileName: String?
//    var productName: String?
//    
//    func makeUIViewController(context: Context) -> PHPickerViewController {
//        var config = PHPickerConfiguration()
//        config.filter = .images
//        let picker = PHPickerViewController(configuration: config)
//        picker.delegate = context.coordinator
//        return picker
//    }
//    
//    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
//        
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    class Coordinator: NSObject, PHPickerViewControllerDelegate {
//        let parent: ImageLibraryPicker
//        
//        init(_ parent: ImageLibraryPicker) {
//            self.parent = parent
//        }
//        
//        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//            picker.dismiss(animated: true)
//            
//            guard let provider = results.first?.itemProvider else { return }
//            
//            if provider.canLoadObject(ofClass: UIImage.self) {
//                provider.loadObject(ofClass: UIImage.self) { image, _ in
//                    let resizedImage = (image as? UIImage)?.resized(toWidth: 300)
//                    if let productName = self.parent.productName {
//                        self.parent.selectedPictureFileName = "\(UUID())_\(productName.cleanedFileName).jpg"
//                    } else {
//                        self.parent.selectedPictureFileName = "\(UUID())_.jpg"
//                    }
//                    self.parent.image = resizedImage
//                }
//            }
//        }
//    }
//}
//
////struct ImagePicker_Previews: PreviewProvider {
////    static var previews: some View {
////        ImagePicker(sourceType: .photoLibrary, completionHandler: {imageURL in
////            print(imageURL?.absoluteURL ?? "error")
////        })
////    }
////}
