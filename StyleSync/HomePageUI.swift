import SwiftUI
import UIKit

struct ContentView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var activeButton: String? // Track which button was clicked

    var body: some View {
        ZStack {
            // Background Image from URL
            AsyncImage(url: URL(string: "https://images.pexels.com/photos/1032650/pexels-photo-1032650.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2")) { image in
                image.resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            } placeholder: {
                ProgressView()
            }

            VStack {
                // Top Bar with Centered "StyleSync" & Properly Positioned Ellipsis Menu
                ZStack {
                    Text("StyleSync")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.teal.opacity(0.7))
                        .cornerRadius(15)
                        .frame(maxWidth: .infinity) // Ensures it stays centered

                    // Right-aligned three-dot menu
                    HStack {
                        Spacer() // Pushes ellipsis to the right
                        Menu {
                            Button("Height", action: { print("Height selected") })
                            Button("Weight", action: { print("Weight selected") })
                            Button("Skin Color", action: { print("Skin Color selected") })
                            Button("Hair Color", action: { print("Hair Color selected") })
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.black)
                                .frame(width: 40) // Fixed size
                                .padding(.trailing, 20) // Moves it inward properly
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding(.horizontal, 20)
    
                Spacer()

                // Silhouette Placeholder
                Image("silhouette")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .opacity(0.5)

                Spacer()

                // Bottom Bar - 4 Buttons to Open Image Picker
                HStack {
                    ForEach(["Top", "Bottom", "Footwear", "Accessory"], id: \.self) { title in
                        Button(action: {
                            activeButton = title
                            showImagePicker = true
                        }) {
                            VStack {
                                if UIImage(named: iconName(for: title)) != nil {
                                    Image(iconName(for: title)) // Use asset image if found
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.black)
                                } else {
                                    Image(systemName: iconName(for: title)) // Use SF Symbol if asset not found
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.black)
                                }
                                Text(title)
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(width: 95)
                    }
                }
                .frame(height: 55)
                .padding(.horizontal, 10)
                .background(Color.teal)
                .cornerRadius(15)
            }
            .padding()
        }
        .confirmationDialog(
            Text("Choose an option for " + (activeButton ?? "Item")),
            isPresented: $showImagePicker,
            titleVisibility: .visible
        ) {
            Button("Camera") {
                sourceType = .camera
                showImagePicker = false
            }
            Button("Photo Library") {
                sourceType = .photoLibrary
                showImagePicker = false
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: sourceType)
        }
    }

    func iconName(for title: String) -> String {
        switch title {
        case "Top": return "tshirt"
        case "Footwear": return "shoe"
        case "Bottom": return "Pants"
        case "Accessory": return "sunglasses"
        default: return "photo"
        }
    }
}

// Image Picker Code (Unchanged)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
