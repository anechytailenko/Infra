import SwiftUI

// MARK: - View Model (Stub)
class FolderStructureViewModel: ObservableObject {
    @Published var rootNode: FolderNode
    
    init() {
        self.rootNode = FolderNode(name: "Root", children: [
            FolderNode(name: "Project_Docs", children: [
                FolderNode(name: "Client_Reports", children: [
                    FolderNode(name: "Client_Report_Q1"),
                    FolderNode(name: "Client_Report_Q2")
                ]),
                FolderNode(name: "Shared_Assets", children: [
                    FolderNode(name: "Eiomnal_Assets", children: [
                        FolderNode(name: "Source_Files")
                    ]),
                    FolderNode(name: "Logos"),
                    FolderNode(name: "Templates")
                ]),
                FolderNode(name: "Marketing_Materials"),
                FolderNode(name: "Internal_Docs")
            ])
        ])
    }
}

// MARK: - Main View
struct GraphView: View {
    @StateObject private var viewModel = FolderStructureViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.96, blue: 0.97)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            TextField("Smart search", text: $searchText).textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(10).background(Color.white).cornerRadius(12).frame(width: 300)
                        
                        Button(action: {}) {
                            Text("Sort").fontWeight(.medium).foregroundColor(.black.opacity(0.8))
                                .padding(.horizontal, 20).padding(.vertical, 8).background(Color.white).cornerRadius(12)
                        }.buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Graph Area
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        FolderGraphLayout(root: viewModel.rootNode)
                            .padding(50)
                    }
                    
                    // Footer
                    HStack(spacing: 60) {
                        ForEach(["Depth 0", "Depth 1", "Depth 2", "Depth 3", "Depth 4"], id: \.self) { depth in
                            Text(depth).font(.caption).fontWeight(.semibold).foregroundColor(.black.opacity(0.7))
                                .padding(.horizontal, 16).padding(.vertical, 8).background(Color.white).cornerRadius(10)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

// MARK: - Graph Layout & Recursion
struct FolderGraphLayout: View {
    let root: FolderNode
    
    var body: some View {
        RecursiveNodeView(node: root, depth: 0)
            .backgroundPreferenceValue(NodeBoundsKey.self) { preferences in
                GeometryReader { geometry in
                    self.drawConnections(preferences: preferences, in: geometry)
                }
            }
    }
    
    func drawConnections(preferences: [UUID: Anchor<CGRect>], in geometry: GeometryProxy) -> some View {
        ZStack {
            ForEach(Array(preferences.keys), id: \.self) { id in
                if let node = findNode(id: id, in: root), !node.children.isEmpty {
                    let startRect = geometry[preferences[id]!]
                    let startPoint = CGPoint(x: startRect.maxX, y: startRect.midY)
                    
                    ForEach(node.children) { child in
                        if let childAnchor = preferences[child.id] {
                            let endRect = geometry[childAnchor]
                            let endPoint = CGPoint(x: endRect.minX, y: endRect.midY)
                            
                            Path { path in
                                path.move(to: startPoint)
                                path.addCurve(
                                    to: endPoint,
                                    control1: CGPoint(x: (startPoint.x + endPoint.x) / 2, y: startPoint.y),
                                    control2: CGPoint(x: (startPoint.x + endPoint.x) / 2, y: endPoint.y)
                                )
                            }
                            .stroke(Color.blue.opacity(0.4), lineWidth: 2)
                        }
                    }
                }
            }
        }
    }
    
    func findNode(id: UUID, in node: FolderNode) -> FolderNode? {
        if node.id == id { return node }
        for child in node.children {
            if let found = findNode(id: id, in: child) { return found }
        }
        return nil
    }
}

struct RecursiveNodeView: View {
    let node: FolderNode
    let depth: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 80) {
            // NAVIGATION LOGIC: Only "Root" is clickable to go to next screen
            if node.name == "Root" {
                NavigationLink(destination: FolderDetailView()) {
                    FolderItemView(name: node.name)
                        .anchorPreference(key: NodeBoundsKey.self, value: .bounds) { [node.id: $0] }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                FolderItemView(name: node.name)
                    .anchorPreference(key: NodeBoundsKey.self, value: .bounds) { [node.id: $0] }
            }
            
            if !node.children.isEmpty {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(node.children) { child in
                        RecursiveNodeView(node: child, depth: depth + 1)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Components
struct FolderItemView: View {
    let name: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill").foregroundColor(.blue.opacity(0.6))
            Text(name).font(.system(size: 13, weight: .regular)).foregroundColor(.black.opacity(0.8))
        }
        .padding(.vertical, 8).padding(.horizontal, 12).background(Color.blue.opacity(0.1)).cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.3), lineWidth: 1))
    }
}

struct NodeBoundsKey: PreferenceKey {
    typealias Value = [UUID: Anchor<CGRect>]
    static var defaultValue: Value = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct FolderNode: Identifiable {
    let id = UUID()
    let name: String
    var children: [FolderNode] = []
}
