import SwiftUI
import ARKit
import RealityKit
import UIKit

struct ReadyPlayerMeView: UIViewRepresentable {
    @Binding var heightScale: Float
    @Binding var weightScale: Float
    @Binding var skinColor: UIColor
    @Binding var hairColor: UIColor
    @Binding var activeClothingItem: String?
    @Binding var selectedClothingImage: UIImage?
    @Binding var clothingOffset: SIMD3<Float>
    @Binding var clothingScale: Float
    @Binding var clothingTilt: Float
    @Binding var clothingPitch: Float
    @Binding var resetTrigger: Bool
    var avatarName: String  // NEW

    class Coordinator: NSObject {
        var modelEntity: ModelEntity?
        var clothingEntity: ModelEntity?
        var clothingOffsetBinding: Binding<SIMD3<Float>>?
        var currentZPosition: Float = -11.0
        var currentScale: Float = 1.0
        var lastBodyScale: SIMD3<Float> = SIMD3(0, 0, 0)
        var lastBodyPosition: SIMD3<Float> = SIMD3(0, 0, 0)

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? ARView,
                  let entity = modelEntity else { return }
            let translation = gesture.translation(in: view)
            let rotationAmount = Float(translation.x) * 0.005

            // Safely remove any duplicate from the scene
            view.scene.anchors.forEach { anchor in
                anchor.children.removeAll { $0.name == entity.name && $0 != entity }
            }

            entity.transform.rotation *= simd_quatf(angle: rotationAmount, axis: [0, 1, 0])
            gesture.setTranslation(.zero, in: view)
        }

        @objc func handleClothingDrag(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? ARView,
                  let binding = clothingOffsetBinding else { return }
            let translation = gesture.translation(in: view)
            if gesture.state == .changed {
                let dx = Float(translation.x) * 0.01
                let dy = Float(-translation.y) * 0.01
                let dz = Float(-translation.y) * 0.01
                if abs(translation.y) > abs(translation.x) {
                    binding.wrappedValue.z += dz
                } else {
                    binding.wrappedValue.x += dx
                    binding.wrappedValue.y += dy
                }
                gesture.setTranslation(.zero, in: view)
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let view = gesture.view as? ARView,
                  let entity = modelEntity else { return }
            if gesture.state == .changed {
                let scaleFactor = Float(gesture.scale)
                let newScale = simd_clamp(currentScale * scaleFactor, 0.1, 50.0)
                let relativeScale = newScale / currentScale
                currentScale = newScale
                entity.scale *= SIMD3<Float>(repeating: relativeScale)
                let newZ = simd_clamp(currentZPosition - (relativeScale - 1) * 5.0, -20.0, -5.0)
                entity.position.z = newZ
                currentZPosition = newZ
                let yAdjustment = (currentScale - 1.0) * 1.8
                entity.position.y = -4.4 + yAdjustment
                gesture.scale = 1.0
            }
            if gesture.state == .ended {
                centerModel(entity)
            }
        }

        private func centerModel(_ entity: ModelEntity) {
            entity.position.x = 0
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let view = gesture.view as? ARView,
                  let entity = modelEntity else { return }
            if gesture.state == .changed {
                let rotation = Float(gesture.rotation)
                entity.transform.rotation *= simd_quatf(angle: rotation, axis: [0, 0, 1])
                gesture.rotation = 0
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.clear)

        let config = ARWorldTrackingConfiguration()
        config.isLightEstimationEnabled = false
        arView.session.run(config, options: [])

        arView.addGestureRecognizer(UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:))))
        let dragGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClothingDrag(_:)))
        dragGesture.minimumNumberOfTouches = 2
        arView.addGestureRecognizer(dragGesture)
        arView.addGestureRecognizer(UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:))))
        arView.addGestureRecognizer(UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:))))

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        let newScale = SIMD3(weightScale * 0.030, heightScale * 0.030, weightScale * 0.030)
        // Default Y/Z for newPosition, will adjust below
        var newPosition = SIMD3(0, -4.4, context.coordinator.currentZPosition)

        // Always reload avatar when resetTrigger is true, or model is nil, or avatarName changed
        if resetTrigger || context.coordinator.modelEntity == nil || context.coordinator.modelEntity?.name != avatarName {
            context.coordinator.currentScale = 1.0
            context.coordinator.currentZPosition = -11.0
            context.coordinator.modelEntity = nil
            context.coordinator.clothingEntity = nil
            context.coordinator.lastBodyScale = .zero
            context.coordinator.lastBodyPosition = .zero

            uiView.scene.anchors.removeAll()

            Task {
                do {
                    guard let url = Bundle.main.url(forResource: avatarName, withExtension: "usdz") else {
                        print("❌ Avatar file not found: \(avatarName).usdz")
                        return
                    }
                    let modelEntity = try await ModelEntity(contentsOf: url)
                    modelEntity.name = avatarName
                    // Per-avatar scale adjustment
                    switch avatarName {
                    case "avatar1", "avatar2", "avatar3", "avatar4":
                        modelEntity.scale = [5.0, 5.0, 5.0] // Make these avatars huge for visibility
                    case "Girl_in_a_bikini":
                        modelEntity.scale = [0.03, 0.03, 0.03]
                    default:
                        modelEntity.scale = [0.03, 0.03, 0.03]
                    }
                    // Per-avatar position adjustment
                    switch avatarName {
                    case "avatar1":
                        modelEntity.position = [0, -4.4, -11.0]
                    case "avatar2":
                        modelEntity.position = [0, -4.4, -11.0]
                    case "avatar3":
                        modelEntity.position = [0, -4.4, -11.0]
                    case "avatar4":
                        modelEntity.position = [0, -4.4, -11.0]
                    case "Girl_in_a_bikini":
                        modelEntity.position = [0, -4.4, -11.0]
                    default:
                        modelEntity.position = [0, -4.4, -11.0]
                    }

                    let anchor = AnchorEntity(.camera)
                    anchor.addChild(modelEntity)
                    uiView.scene.anchors.append(anchor)

                    context.coordinator.modelEntity = modelEntity
                    context.coordinator.clothingOffsetBinding = $clothingOffset
                    // Per-avatar scale for lastBodyScale
                    let lastBodyScale: SIMD3<Float>
                    switch avatarName {
                    case "avatar1", "avatar2", "avatar3", "avatar4":
                        lastBodyScale = [1.5, 1.5, 1.5]
                    default:
                        lastBodyScale = SIMD3(weightScale * 0.030, heightScale * 0.030, weightScale * 0.030)
                    }
                    context.coordinator.lastBodyScale = lastBodyScale
                    // Match the per-avatar position for lastBodyPosition as well:
                    let lastBodyY: Float
                    let lastBodyZ: Float
                    switch avatarName {
                    case "avatar1":
                        lastBodyY = -4.4; lastBodyZ = -11.0
                    case "avatar2":
                        lastBodyY = -4.4; lastBodyZ = -11.0
                    case "avatar3":
                        lastBodyY = -4.4; lastBodyZ = -11.0
                    case "avatar4":
                        lastBodyY = -4.4; lastBodyZ = -11.0
                    case "Girl_in_a_bikini":
                        lastBodyY = -4.4; lastBodyZ = -11.0
                    default:
                        lastBodyY = -4.4; lastBodyZ = -11.0
                    }
                    context.coordinator.lastBodyPosition = SIMD3(0, lastBodyY, lastBodyZ)

                    if activeClothingItem != nil {
                        applyClothing(to: modelEntity, context: context)
                    }

                    print("✅ Loaded avatar: \(avatarName)")
                } catch {
                    print("❌ Failed to load avatar model: \(error.localizedDescription)")
                }
            }

            DispatchQueue.main.async {
                resetTrigger = false
            }

            return
        }

        if let model = context.coordinator.modelEntity {
            if context.coordinator.lastBodyScale != newScale {
                model.scale = newScale
                context.coordinator.lastBodyScale = newScale
            }

            // Per-avatar position adjustment for update (not just initial load)
            switch avatarName {
            case "avatar1":
                newPosition.y = -4.4; newPosition.z = -11.0
            case "avatar2":
                newPosition.y = -4.4; newPosition.z = -11.0
            case "avatar3":
                newPosition.y = -4.4; newPosition.z = -11.0
            case "avatar4":
                newPosition.y = -4.4; newPosition.z = -11.0
            case "Girl_in_a_bikini":
                newPosition.y = -4.4; newPosition.z = -11.0
            default:
                newPosition.y = -4.4; newPosition.z = -11.0
            }

            if context.coordinator.lastBodyPosition != newPosition {
                model.position = newPosition
                context.coordinator.lastBodyPosition = newPosition
            }

            if activeClothingItem == nil {
                if let clothing = context.coordinator.clothingEntity {
                    clothing.removeFromParent()
                    context.coordinator.clothingEntity = nil
                }
            } else {
                if context.coordinator.clothingEntity == nil {
                    applyClothing(to: model, context: context)
                } else if let clothing = context.coordinator.clothingEntity {
                    clothing.scale = [clothingScale, clothingScale, clothingScale]
                    clothing.position = clothingOffset

                    let diagonalAxis = simd_normalize(SIMD3<Float>(1, 0, 1))
                    let tiltRotation = simd_quatf(angle: clothingTilt, axis: diagonalAxis)
                    let pitchRotation = simd_quatf(angle: clothingPitch, axis: SIMD3<Float>(1, 0, 0))
                    clothing.transform.rotation = tiltRotation * pitchRotation
                }
            }
        }
    }

    func applyClothing(to model: ModelEntity, context: Context) {
        guard let activeClothingItem = activeClothingItem else { return }
        Task {
            do {
                guard let url = Bundle.main.url(forResource: activeClothingItem, withExtension: "usdz") else { return }
                let clothingEntity = try await ModelEntity(contentsOf: url)

                if let cgImage = selectedClothingImage?.cgImage {
                    let texture = try await TextureResource(image: cgImage, withName: "ClothingTexture", options: .init(semantic: .color))
                    var material = UnlitMaterial()
                    material.baseColor = .texture(texture)
                    clothingEntity.model?.materials = [material]
                }

                clothingEntity.scale = [clothingScale, clothingScale, clothingScale]
                clothingEntity.position = clothingOffset
                let diagonalAxis = simd_normalize(SIMD3<Float>(1, 0, 1))
                clothingEntity.transform.rotation = simd_quatf(angle: clothingTilt, axis: diagonalAxis)
                clothingEntity.transform.rotation *= simd_quatf(angle: clothingPitch, axis: SIMD3<Float>(1, 0, 0))

                model.addChild(clothingEntity)
                context.coordinator.clothingEntity = clothingEntity
            } catch {
                print("❌ Failed to apply clothing texture: \(error.localizedDescription)")
            }
        }
    }
}




struct ContentView: View {
    @State private var heightScale: Float = 1.0
    @State private var weightScale: Float = 1.0
    @State private var skinColor: UIColor = .systemBrown
    @State private var hairColor: UIColor = .black
    @State private var activeClothingItem: String? = nil
    @State private var selectedImage: UIImage?
    @State private var showClosetView = false
    @State private var clothingOffset: SIMD3<Float> = SIMD3(0, 0, 0)
    @State private var clothingScale: Float = 1.0
    @State private var clothingTilt: Float = 0.0
    @State private var clothingPitch: Float = 0.0
    @State private var resetTrigger: Bool = false

    // 👤 Avatar switching
    @State private var currentAvatarIndex = 0
    let avatarNames = ["avatar1", "avatar2", "avatar3", "avatar4", "Girl_in_a_bikini"]

    private func resetAvatarState() {
        activeClothingItem = nil
        selectedImage = nil
        clothingOffset = SIMD3<Float>(0, 0, 0)
        clothingScale = 1.0
        clothingTilt = 0.0
        clothingPitch = 0.0
        heightScale = 1.0
        weightScale = 1.0
    }

    @ViewBuilder
    func sliderWithLabel(_ label: String, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(label): \(value.wrappedValue, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.black)
            Slider(value: value, in: range)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("Background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // App Title
                    VStack {
                        Text("StyleSync")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(8)
                            .background(Color.teal.opacity(0.7))
                            .cornerRadius(15)
                    }

                    // Avatar Switch Buttons
                    HStack {
                        Button(action: {
                            if currentAvatarIndex > 0 {
                                currentAvatarIndex -= 1
                                resetTrigger = true
                            }
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }

                        Text("Avatar \(currentAvatarIndex + 1)")
                            .font(.subheadline)
                            .padding(.horizontal)

                        Button(action: {
                            if currentAvatarIndex < avatarNames.count - 1 {
                                currentAvatarIndex += 1
                                resetTrigger = true
                            }
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 5)

                    Spacer()

                    // Avatar View
                    ReadyPlayerMeView(
                        heightScale: $heightScale,
                        weightScale: $weightScale,
                        skinColor: $skinColor,
                        hairColor: $hairColor,
                        activeClothingItem: $activeClothingItem,
                        selectedClothingImage: $selectedImage,
                        clothingOffset: $clothingOffset,
                        clothingScale: $clothingScale,
                        clothingTilt: $clothingTilt,
                        clothingPitch: $clothingPitch,
                        resetTrigger: $resetTrigger,
                        avatarName: avatarNames[currentAvatarIndex]
                    )
                    .frame(height: geometry.size.height * 0.46)

                    // Clothing Sliders
                    VStack {
                        Text("Adjust Clothing Position & Scale")
                            .font(.headline)
                            .foregroundColor(.black)

                        ScrollView {
                            sliderWithLabel("Y Offset", value: $clothingOffset.y, range: -100...300)
                            sliderWithLabel("X Offset", value: $clothingOffset.x, range: -100...200)
                            sliderWithLabel("Z Offset", value: $clothingOffset.z, range: -200...200)
                            sliderWithLabel("Tilt", value: $clothingTilt, range: -0.8000...0.8000)
                            sliderWithLabel("Tilt Forward/Back", value: $clothingPitch, range: -0.9000...9.8000)
                            sliderWithLabel("Scale", value: $clothingScale, range: 0.1...200.0)
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .frame(maxWidth: 380)
                        .frame(maxHeight: 180)
                    }

                    Spacer()

                    // Outfit Picker Button
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
                }

                // Reset Button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            resetAvatarState()
                            resetTrigger = true
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
            .fullScreenCover(isPresented: $showClosetView) {
                ClosetView(activeClothingItem: $activeClothingItem)
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

