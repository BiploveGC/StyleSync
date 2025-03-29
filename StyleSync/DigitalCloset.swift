//DigitalCloset
import SwiftUI
import SceneKit

struct ClosetView: View {
    @Environment(\.presentationMode) var presentationMode // Allows navigation back
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @State private var selectedItem: ClothingItem? = nil
    @State private var clothes: [ClothingItem] = [
        .usdz(name: "Blue Shirt", filename: "blueshirt"),
        .usdz(name: "Denim Pants", filename: "pantsdenim"),
        .usdz(name: "Casual Shirt", filename: "shirt1"),
        .usdz(name: "Teal Shirt", filename: "tealshirt"),
        .usdz(name: "Tommy Hilfiger Jacket", filename: "Tommy_Hilfiger_Jacket")
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss() // Go back to HomePageUI
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    
                    Spacer()
                    
                    Text("StyleSync")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Spacer().frame(width: 40) // Keeps the title centered
                }
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(clothes, id: \.id) { item in
                            VStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 1)
                                        .frame(height: 100)
                                    
                                    item.view
                                }
                                .onTapGesture {
                                    withAnimation {
                                        selectedItem = item
                                    }
                                }
                                
                                Text(item.name)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation {
                                        clothes.removeAll { $0.id == item.id }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .fullScreenCover(item: $selectedItem) { item in
                FullScreenItemView(item: item)
            }
            .navigationBarBackButtonHidden(true) // Hides default back button
        }
    }
}

// MARK: - Clothing Item Enum
enum ClothingItem: Identifiable {
    case usdz(name: String, filename: String)
    
    var id: String {
        switch self {
        case .usdz(_, let filename): return filename
        }
    }
    
    var name: String {
        switch self {
        case .usdz(let name, _): return name
        }
    }
    
    @ViewBuilder var view: some View {
        switch self {
        case .usdz(_, let filename):
            SceneKitView(usdzFileName: filename)
                .frame(width: 80, height: 80)
        }
    }
}

// MARK: - Full-Screen View
struct FullScreenItemView: View {
    let item: ClothingItem
    var onTryOn: (String, UIImage?) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var offset = CGSize.zero
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack{
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(16)
                    }
                }
                Spacer()
                
                if case .usdz(_, let filename) = item {
                    ZoomableSceneKitView(usdzFileName: filename)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.8)
                        .offset(y: offset.height)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    if gesture.translation.height > 0 {
                                        offset = gesture.translation
                                    }
                                }
                                .onEnded { _ in
                                    if offset.height > 100 {
                                        dismiss()
                                    } else {
                                        offset = .zero
                                    }
                                }
                        )
                }
                
                Text(item.name)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                // Try on button
                
                Spacer()
            }
        }
    }
}

// MARK: - SceneKitView (Grid Preview)
struct SceneKitView: UIViewRepresentable {
    let usdzFileName: String

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.clear

        guard let url = Bundle.main.url(forResource: usdzFileName, withExtension: "usdz") else {
            print("❌ Error: Could not find \(usdzFileName).usdz in bundle.")
            return sceneView
        }

        do {
            let scene = try SCNScene(url: url)
            sceneView.scene = scene
        } catch {
            print("❌ Error loading 3D model: \(error.localizedDescription)")
        }

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}

// MARK: - ZoomableSceneKitView (Full Screen)
struct ZoomableSceneKitView: UIViewRepresentable {
    let usdzFileName: String

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.clear

        guard let url = Bundle.main.url(forResource: usdzFileName, withExtension: "usdz") else {
            print("❌ Error: Could not find \(usdzFileName).usdz in bundle.")
            return sceneView
        }

        do {
            let scene = try SCNScene(url: url)
            sceneView.scene = scene
        } catch {
            print("❌ Error loading 3D model: \(error.localizedDescription)")
        }

        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        
        sceneView.addGestureRecognizer(pinchGesture)
        sceneView.addGestureRecognizer(rotationGesture)

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator: NSObject {
        @objc func handlePinch(_ sender: UIPinchGestureRecognizer) {
            guard let sceneView = sender.view as? SCNView,
                  let node = sceneView.scene?.rootNode.childNodes.first else { return }

            if sender.state == .changed {
                let scale = Float(sender.scale)
                node.scale = SCNVector3(x: node.scale.x * scale, y: node.scale.y * scale, z: node.scale.z * scale)
                sender.scale = 1.0
            }
        }

        @objc func handleRotation(_ sender: UIRotationGestureRecognizer) {
            guard let sceneView = sender.view as? SCNView,
                  let node = sceneView.scene?.rootNode.childNodes.first else { return }

            if sender.state == .changed {
                node.eulerAngles.y -= Float(sender.rotation)
                sender.rotation = 0
            }
        }
    }
}

// MARK: - Preview
struct ClosetView_Previews: PreviewProvider {
    static var previews: some View {
        ClosetView()
    }
}


