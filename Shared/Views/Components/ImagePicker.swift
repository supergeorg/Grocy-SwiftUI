//
//  ImagePicker.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 08.03.21.
//

import SwiftUI

extension UIImage {
    func resized(withPercentage percentage: CGFloat, isOpaque: Bool = true) -> UIImage? {
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        let format = imageRendererFormat
        format.opaque = isOpaque
        return UIGraphicsImageRenderer(size: canvas, format: format).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
    func resized(toWidth width: CGFloat, isOpaque: Bool = true) -> UIImage? {
        let canvas = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        let format = imageRendererFormat
        format.opaque = isOpaque
        return UIGraphicsImageRenderer(size: canvas, format: format).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIImagePickerController
    typealias SourceType = UIImagePickerController.SourceType
    
    let sourceType: SourceType
    let completionHandler: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let viewController = UIImagePickerController()
        viewController.delegate = context.coordinator
        #if targetEnvironment(simulator)
        viewController.sourceType = (sourceType == .camera) ? SourceType.photoLibrary : sourceType
        #else
        viewController.sourceType = sourceType
        #endif
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(completionHandler: completionHandler)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completionHandler: (URL?) -> Void
        
        init(completionHandler: @escaping (URL?) -> Void) {
            self.completionHandler = completionHandler
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let imgUrl = info[UIImagePickerController.InfoKey.imageURL] as? URL{
                let imgName = imgUrl.lastPathComponent
                let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
                let localPath = documentDirectory?.appending(imgName)
                
                let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
                let resizedImage = image.resized(toWidth: 300.0)!
                let data = resizedImage.jpegData(compressionQuality: 0.8)! as NSData
                data.write(toFile: localPath!, atomically: true)
                let photoURL = URL.init(fileURLWithPath: localPath!)
                completionHandler(photoURL)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completionHandler(nil)
        }
    }
}

struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        ImagePicker(sourceType: .photoLibrary, completionHandler: {imageURL in
            print(imageURL?.absoluteURL ?? "error")
        })
    }
}
