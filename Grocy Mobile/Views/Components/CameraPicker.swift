//
//  CameraPicker.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 04.12.25.
//

#if os(iOS)

    import SwiftUI
    import PhotosUI

    struct CameraPicker: UIViewControllerRepresentable {
        var sourceType: UIImagePickerController.SourceType = .camera
        let onImagePicked: (UIImage) -> Void

        @Environment(\.presentationMode) private var presentationMode

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = context.coordinator
            return picker
        }

        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: CameraPicker

            init(_ parent: CameraPicker) {
                self.parent = parent
            }

            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.onImagePicked(image)
                }
                parent.presentationMode.wrappedValue.dismiss()
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }

#endif
