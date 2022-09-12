//
//  PhotoPicker.swift
//  Netty
//
//  Created by Danny on 9/12/22.
//

import SwiftUI
import PhotosUI
import CloudKit

struct ImagePicker: UIViewControllerRepresentable {
    
    let uploadImage: (_ image: UIImage) -> ()
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(imagePicker: self, uploadImage: uploadImage)
    }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        let imagePicker: ImagePicker
        let uploadImage: (_ image: UIImage) -> ()
        
        init(imagePicker: ImagePicker, uploadImage: @escaping (_: UIImage) -> Void) {
            self.imagePicker = imagePicker
            self.uploadImage = uploadImage
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage {
                uploadImage(image)
            }
            picker.dismiss(animated: true)
        }
    }
}
