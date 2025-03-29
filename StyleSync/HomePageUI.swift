//HomePageUi
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
    
    class Coordinator: NSObject {
        var modelEntity: ModelEntity?

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? ARView,
                  let entity = modelEntity else { return }

            let translation = gesture.translation(in: view)
            let rotationAmount = Float(translation.x) * 0.005
            entity.transform.rotation *= simd_quatf(angle: rotationAmount, axis: [0, 1, 0])
            gesture.setTranslation(.zero, in: view)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.clear) // ✅ Transparent Background
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
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
                modelEntity.scale = SIMD3(weightScale * 0.030, heightScale * 0.030, weightScale * 0.030)
                modelEntity.position = SIMD3(0, -4.4, -11.0)

                let anchor = AnchorEntity(.camera)
                anchor.addChild(modelEntity)
                uiView.scene.anchors.removeAll()
                uiView.scene.anchors.append(anchor)
                
                context.coordinator.modelEntity = modelEntity

                if activeClothingItem != nil {
                    applyClothing(to: modelEntity)
                }

                print("✅ Model loaded successfully!")

            } catch {
                print("❌ Failed to load model: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Apply Clothing Selection
    func applyClothing(to model: ModelEntity) {
        guard let activeClothingItem = activeClothingItem else { return }
        
        Task {
            do {
                let clothingEntity = try await ModelEntity(contentsOf: Bundle.main.url(forResource: activeClothingItem, withExtension: "usdz")!)
                
                if let cgImage = selectedClothingImage?.cgImage {
                    let texture = try await TextureResource(image: cgImage, withName: "ClothingTexture", options: .init(semantic: .color))
                    var material = UnlitMaterial()
                    material.baseColor = .texture(texture)
                    clothingEntity.model?.materials = [material]
                }
                
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
    @State private var showClosetView = false

    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: "https://images.pexels.com/photos/1032650/pexels-photo-1032650.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2")) { image in
                image.resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            } placeholder: {
                ProgressView()
            }

            VStack {
                Text("StyleSync")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.teal.opacity(0.7))
                    .cornerRadius(15)
                    .frame(maxWidth: .infinity)

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

                Button(action: {
                    showClosetView = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "hanger")
                            .font(.title2)
                        Text("Pick an Outfit")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.teal, Color.blue]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(20)
                    .shadow(radius: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                .fullScreenCover(isPresented: $showClosetView) {
                    ClosetView()
                }
            }
        }
    }
}




// MARK: - SwiftUI Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
