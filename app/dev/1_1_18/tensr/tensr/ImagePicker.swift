//
//  ImagePicker.swift
//  tensr
//
//  Created by azim on 8/12/19.
//  Copyright © 2019 azim. All rights reserved.
//

import SwiftUI

// https://stackoverflow.com/questions/56515871/how-to-open-the-imagepicker-in-swiftui
struct ImagePicker: UIViewControllerRepresentable {

    @Binding var isShown: Bool
    @Binding var image: Image?
    @Binding var imagePicked: Bool
    @Binding var imageData: Data?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        @Binding var isShown: Bool
        @Binding var image: Image?
        @Binding var imagePicked: Bool
        @Binding var imageData: Data?

        init(isShown: Binding<Bool>, image: Binding<Image?>, imagePicked: Binding<Bool>, imageData: Binding<Data?>) {
            _isShown = isShown
            _image = image
            _imagePicked = imagePicked
            _imageData = imageData
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let uiImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            
            image = Image(uiImage: uiImage)
            imagePicked = true
            imageData = uiImage.pngData()
            isShown = false
            
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            isShown = false
        }

    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(isShown: $isShown, image: $image, imagePicked: $imagePicked, imageData: $imageData)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<ImagePicker>) {

    }
 
}
