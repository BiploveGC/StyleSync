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

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero) // ✅ Initialize ARView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        guard let localURL = Bundle.main.url(forResource: "Girl_in_a_bikini", withExtension: "usdz") else {
            print("❌ Failed to find Girl_in_a_bikini.usdz in the app bundle.")
            return
        }

        Task {
            do {
                let modelEntity = try await ModelEntity(contentsOf: localURL)

                // ✅ Shrink model to proper size
                modelEntity.scale = SIMD3<Float>(self.weightScale * 0.03, self.heightScale * 0.03, self.weightScale * 0.03)

                // ✅ Move model up and back so full body is visible
                modelEntity.position = SIMD3<Float>(0, -2.0, -2.5)

                // ✅ Ensure lighting works for visibility
                modelEntity.components[ModelComponent.self]?.materials = [SimpleMaterial(color: .white, isMetallic: false)]

                // ✅ Attach to RealityKit scene
                let anchor = AnchorEntity(world: [0, -0.8, -2.5])
                anchor.addChild(modelEntity)
                uiView.scene.anchors.removeAll()
                uiView.scene.anchors.append(anchor)

                print("✅ Model loaded successfully and repositioned!")

            } catch {
                print("❌ Failed to load Girl_in_a_bikini.usdz: \(error.localizedDescription)")
            }
        }
    }
    // MARK: - Adjust Skin & Hair Colors
    func applyColorChanges(to model: ModelEntity) {
        for child in model.children {
            if let modelComponent = child as? ModelEntity {
                if let material = modelComponent.model?.materials.first {
                    
                    if child.name.lowercased().contains("skin") {
                        if var simpleMaterial = material as? SimpleMaterial {
                            simpleMaterial.color = .init(tint: skinColor)
                            modelComponent.model?.materials = [simpleMaterial]
                        } else if var pbrMaterial = material as? PhysicallyBasedMaterial {
                            pbrMaterial.baseColor = .init(tint: skinColor)
                            modelComponent.model?.materials = [pbrMaterial]
                        }
                    }
                    
                    if child.name.lowercased().contains("hair") {
                        if var simpleMaterial = material as? SimpleMaterial {
                            simpleMaterial.color = .init(tint: hairColor)
                            modelComponent.model?.materials = [simpleMaterial]
                        } else if var pbrMaterial = material as? PhysicallyBasedMaterial {
                            pbrMaterial.baseColor = .init(tint: hairColor)
                            modelComponent.model?.materials = [pbrMaterial]
                        }
                    }
                }
            }
        }
    }

    // MARK: - Apply Clothing Selection
    func applyClothing(to model: ModelEntity) {
        guard let activeClothingItem = activeClothingItem else { return }

        let clothingFile: String
        switch activeClothingItem {
        case "Top": clothingFile = "top.usdz"
        case "Bottom": clothingFile = "pants.usdz"
        case "Footwear": clothingFile = "shoes.usdz"
        case "Accessory": clothingFile = "hat.usdz"
        default: return
        }

        Task {
            do {
                let clothingEntity = try await ModelEntity(contentsOf: URL(string: clothingFile)!)
                clothingEntity.position = SIMD3(0, 1.0, 0) // ✅ Adjust position
                model.addChild(clothingEntity)
            } catch {
                print("Failed to load clothing: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Main SwiftUI View
struct ContentView: View {
    @State private var heightScale: Float = 1.0  // Default scale (1x)
    @State private var weightScale: Float = 1.0  // Default weight (1x)
    @State private var skinColor: UIColor = .systemBrown // Default skin color
    @State private var hairColor: UIColor = .black // Default hair color
    @State private var activeClothingItem: String? = nil
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

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
                // Top Bar
                ZStack {
                    Text("StyleSync")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.teal.opacity(0.7))
                        .cornerRadius(15)
                        .frame(maxWidth: .infinity)

                    HStack {
                        Spacer()
                        Menu {
                            Button("Height", action: { print("Height selected") })
                            Button("Weight", action: { print("Weight selected") })
                            Button("Skin Color", action: { print("Skin Color selected") })
                            Button("Hair Color", action: { print("Hair Color selected") })
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 50, weight: .bold))
                                .frame(width: 50, height: 50)
                                .foregroundColor(.black)
                                .frame(width: 40)
                                .padding(.trailing, 50)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding(.horizontal, 20)

                Spacer()

                // RealityKit Avatar in the Middle
                ReadyPlayerMeView(heightScale: $heightScale, weightScale: $weightScale, skinColor: $skinColor, hairColor: $hairColor, activeClothingItem: $activeClothingItem)
                    .frame(height: 500)

                Spacer()

                // Bottom Bar with 4 Buttons
                HStack {
                    ForEach(["Top", "Bottom", "Footwear", "Accessory"], id: \.self) { title in
                        Button(action: {
                            activeClothingItem = title
                            showImagePicker = true
                        }) {
                            VStack {
                                iconImage(for: title)
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
        .actionSheet(isPresented: $showImagePicker) {
            ActionSheet(title: Text("Choose Image Source"), buttons: [
                .default(Text("Take a Photo")) {
                    sourceType = .camera
                    showImagePicker = true
                },
                .default(Text("Choose from Library")) {
                    sourceType = .photoLibrary
                    showImagePicker = true
                },
                .cancel()
            ])
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
        }
    }
    
    // MARK: - Icon Selector
    func iconImage(for title: String) -> Image {
        switch title {
        case "Top":
            return Image(systemName: "tshirt")
        case "Bottom":
            return Image("Pants") // Uses the custom asset from your Assets catalog
        case "Footwear":
            return Image(systemName: "shoe")
        case "Accessory":
            return Image(systemName: "sunglasses")
        default:
            return Image(systemName: "photo")
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
