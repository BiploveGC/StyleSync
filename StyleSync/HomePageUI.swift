//
//  SwiftUIView.swift
//  StyleSync
//
//  Created by csuftitan on 2/4/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var activeButton: String? // Track which button was clicked
    
    var body: some View {
        ZStack {
            // Background Image
            Image("ocean_background") // Replace with your image asset
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top Bar
                HStack {
                    Spacer()
                    Text("StyleSync")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.teal.opacity(0.7))
                        .cornerRadius(15)
                    Spacer()
                }
                .padding(.horizontal)
                
                Spacer()
                
                // User Name Badge
                HStack {
                    Text("Rabih Zeineddine")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .padding(.leading, 20)
                        .offset(y: -30) // Adjust position
                    Spacer()
                }
                
                // Silhouette Placeholder
                Image("silhouette") // Replace with a transparent silhouette asset
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .opacity(0.5)
                
                Spacer()
                
                // Bottom Bar - 4 Buttons to Open Image Picker
                HStack {
                    ImageSelectionButton(title: "Top", activeButton: $activeButton, showImagePicker: $showImagePicker)
                        .frame(width: 80) // Explicit width
                    ImageSelectionButton(title: "Bottom", activeButton: $activeButton, showImagePicker: $showImagePicker)
                        .frame(width: 95)
                    ImageSelectionButton(title: "Footwear", activeButton: $activeButton, showImagePicker: $showImagePicker)
                        .frame(width: 95)
                    ImageSelectionButton(title: "Accessory", activeButton: $activeButton, showImagePicker: $showImagePicker)
                        .frame(width: 95)
                }
                .frame(height: 55)
                .padding(.horizontal, 10)
                .background(Color.teal)
                .cornerRadius(15)
            }
            .padding()
        }
        // Camera/Gallery Selection Dialog
        .confirmationDialog("Choose an option for \(activeButton ?? "Item")", isPresented: $showImagePicker, titleVisibility: .visible) {
            Button("Camera") {
                sourceType = .camera
                showImagePicker = true
            }
            Button("Photo Library") {
                sourceType = .photoLibrary
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        // Show Image Picker When Selected
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: sourceType)
        }
    }
}

// MARK: - Button View for Image Selection
struct ImageSelectionButton: View {
    var title: String
    @Binding var activeButton: String?
    @Binding var showImagePicker: Bool
    
    var body: some View {
        Button(action: {
            activeButton = title
            showImagePicker = true
        }) {
            VStack {
                Image(systemName: "photo")
                Text(title)
            }
        }
    }
}

// MARK: - Image Picker Helper for Camera & Photo Library
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
