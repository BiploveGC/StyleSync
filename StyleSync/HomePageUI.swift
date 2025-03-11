import SwiftUI
import RealityKit
import UIKit 

// MARK: - RealityKit Avatar View
struct ReadyPlayerMeView: UIViewRepresentable {
    @Binding var heightScale: Float
    @Binding var weightScale: Float
    @Binding var skinColor: UIColor
    @Binding var hairColor: UIColor
    @Binding var activeClothingItem: String?
    @Binding var selectedClothingImage: UIImage?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.clear) // ✅ Transparent Background
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        guard let localURL = Bundle.main.url(forResource: "Girl_in_a_bikini", withExtension: "usdz") else {
            print("❌ Model not found")
            return
        }

        Task {
            do {
                let modelEntity = try await ModelEntity(contentsOf: localURL)
                modelEntity.scale = SIMD3(weightScale * 0.035, heightScale * 0.035, weightScale * 0.035)
                modelEntity.position = SIMD3(0, -4.5, -4.5)

                let anchor = AnchorEntity(world: [0, -0.8, -2.5])
                anchor.addChild(modelEntity)
                uiView.scene.anchors.removeAll()
                uiView.scene.anchors.append(anchor)

                applyColorChanges(to: modelEntity)
                applyClothing(to: modelEntity)

                print("✅ Model loaded successfully!")

            } catch {
                print("❌ Failed to load model: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Apply Skin & Hair Colors
    func applyColorChanges(to model: ModelEntity) {
        for child in model.children {
            if let modelComponent = child as? ModelEntity {
                if let material = modelComponent.model?.materials.first {
                    let newColor = child.name.lowercased().contains("skin") ? skinColor : hairColor
                    if var simpleMaterial = material as? SimpleMaterial {
                        simpleMaterial.color = .init(tint: newColor)
                        modelComponent.model?.materials = [simpleMaterial]
                    } else if var pbrMaterial = material as? PhysicallyBasedMaterial {
                        pbrMaterial.baseColor = .init(tint: newColor)
                        modelComponent.model?.materials = [pbrMaterial]
                    }
                }
            }
        }
    }

    // MARK: - Apply Clothing Selection with Image
        func applyClothing(to model: ModelEntity) {
            guard let cgImage = selectedClothingImage?.cgImage else { return }

            guard let texture = try? TextureResource(image: cgImage, withName: "ClothingTexture", options: .init(semantic: .color)) else {
                print("❌ Failed to create texture")
                return
            }

            var material = UnlitMaterial()
            material.baseColor = .texture(texture)

            Task {
                do {
                    let clothingEntity = try await ModelEntity(contentsOf: Bundle.main.url(forResource: "basic_clothing", withExtension: "usdz")!)
                    clothingEntity.model?.materials = [material]
                    clothingEntity.position = SIMD3(0, 1.0, 0)
                    model.addChild(clothingEntity)
                    print("✅ Applied custom clothing texture!")
                } catch {
                    print("❌ Failed to apply clothing texture: \(error.localizedDescription)")
                }
            }
        }
    }

// MARK: - SwiftUI ContentView
struct ContentView: View {
    @State private var heightScale: Float = 1.0
    @State private var weightScale: Float = 1.0
    @State private var skinColor: UIColor = .systemBrown
    @State private var hairColor: UIColor = .black
    @State private var activeClothingItem: String?
    @State private var selectedImage: UIImage?
    @State private var showActionSheet = false
    @State private var showPickerSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        ZStack {
            // ✅ Background Image
            AsyncImage(url: URL(string: "https://images.pexels.com/photos/1032650/pexels-photo-1032650.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2")) { image in
                image.resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            } placeholder: {
                ProgressView()
            }

            VStack {
                // ✅ Header
                Text("StyleSync")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.teal.opacity(0.7))
                    .cornerRadius(15)
                    .frame(maxWidth: .infinity)
                
                HStack{
                    Spacer()
                    Menu{
                        Button("Height", action: { print("Height selected")})
                        Button("Weight", action: { print("Weight selected") })
                        Button("Skin Color", action: { print("Skin Color selected") })
                        Button("Hair Color", action: { print("Hair Color selected") })
                    }label: {
                        Image(systemName:"ellipsis")
                            .font(.system(size: 50, weight: .bold))
                            .frame(width: 50, height: 50)
                            .foregroundColor(.black)
                            .frame(width: 40)
                            .padding(.trailing, 50)
                    }
                }
                
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding(.horizontal, 20)

                
                
                

                // ✅ Avatar View
                ReadyPlayerMeView(
                    heightScale: $heightScale,
                    weightScale: $weightScale,
                    skinColor: $skinColor,
                    hairColor: $hairColor,
                    activeClothingItem: $activeClothingItem,
                    selectedClothingImage: $selectedImage
                )
                .frame(height: 500) 

                Spacer()

                // ✅ Clothing Selection Buttons
                HStack {
                                    ForEach(["Top", "Bottom", "Footwear", "Accessory"], id: \.self) { title in
                                        Button(action: {
                                            activeClothingItem = title
                                            showActionSheet = true // Trigger action sheet
                                        }) {
                                            VStack {
                                                Image(systemName: iconName(for: title))
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 30, height: 30)
                                                    .foregroundColor(.black)
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
                        .actionSheet(isPresented: $showActionSheet) {
                            ActionSheet(title: Text("Choose Image Source"), buttons: [
                                .default(Text("Take a Photo")) {
                                    sourceType = .camera
                                    showPickerSheet = true // Trigger Image Picker
                                },
                                .default(Text("Choose from Library")) {
                                    sourceType = .photoLibrary
                                    showPickerSheet = true // Trigger Image Picker
                                },
                                .cancel()
                            ])
                        }
                        .sheet(isPresented: $showPickerSheet) {
                            ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                        }
                    }

                    // MARK: - Icon Selector
                    func iconName(for title: String) -> String {
                        switch title {
                        case "Top": return "tshirt"
                        case "Bottom": return "pants"
                        case "Footwear": return "shoe"
                        case "Accessory": return "sunglasses"
                        default: return "photo"
                        }
                    }
                }

// MARK: - Image Picker for Camera and Library
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.parent.selectedImage = image
                }
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - SwiftUI Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
