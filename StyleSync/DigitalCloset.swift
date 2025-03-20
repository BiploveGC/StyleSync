import SwiftUI
import SceneKit

struct ClosetView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @State private var selectedItem: ClothingItem? = nil
    
    let clothes: [ClothingItem] = [
        .emoji("👗"), .emoji("👕"), .emoji("👖"),
        .emoji("🧥"), .emoji("👚"), .emoji("👔"),
        .emoji("👞"), .emoji("👠"), .usdz("Tommy_Hilfiger_Jacket")
    ]
    
    var body: some View {
        VStack {
            Text("StyleSync")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(clothes, id: \.id) { item in
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 1)
                                .frame(height: 100)
                            
                            item.view
                                .font(.largeTitle)
                        }
                        .onTapGesture {
                            selectedItem = item
                        }
                    }
                }
                .padding()
            }
        }
        .fullScreenCover(item: $selectedItem) { item in
            FullScreenItemView(item: item)
        }
    }
}

// Enum to Handle Different Clothing Types
enum ClothingItem: Identifiable {
    case emoji(String)
    case usdz(String)
    
    var id: String {
        switch self {
        case .emoji(let emoji): return emoji
        case .usdz(let filename): return filename
        }
    }
    
    @ViewBuilder var view: some View {
        switch self {
        case .emoji(let emoji):
            Text(emoji)
        case .usdz(_):
            SceneKitView(usdzFileName: "Tommy_Hilfiger_Jacket")
                .frame(width: 80, height: 80)
        }
    }
}

// Full-Screen View with Swipe-Down Dismiss
struct FullScreenItemView: View {
    let item: ClothingItem
    @Environment(\.dismiss) var dismiss
    @State private var offset = CGSize.zero
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                item.view
                    .font(.system(size: 200)) // Large size for emoji
                    .frame(width: 300, height: 300)
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
                
                Spacer()
            }
        }
    }
}

// SceneKit View for 3D Model
struct SceneKitView: UIViewRepresentable {
    let usdzFileName: String

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true

        if let scene = try? SCNScene(url: Bundle.main.url(forResource: usdzFileName, withExtension: "usdz")!) {
            sceneView.scene = scene
        }

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}

struct ClosetView_Previews: PreviewProvider {
    static var previews: some View {
        ClosetView()
    }
}

