import SwiftUI

// MARK: - Layout Configuration
struct GraphLayoutConfig {
    let totalAvailableWidth: CGFloat
    let zoomScale: CGFloat
    let visibleColumns: Int = 5
    
    var columnStride: CGFloat { totalAvailableWidth / CGFloat(visibleColumns) }
    var nodeWidth: CGFloat { max(columnStride * 0.85, 100.0) }
    var spacing: CGFloat { columnStride - nodeWidth }
    func centerX(for depth: Int) -> CGFloat { (columnStride * CGFloat(depth)) + (columnStride / 2) }
    var verticalSpacing: CGFloat { 20.0 }
}

// MARK: - Graph Diagram Types
struct GraphNodeData: Identifiable {
    let id: UUID; let label: String; let iconName: String; let color: Color; let isGhost: Bool
}
protocol GraphDiagramLayout {
    func position(for nodeId: UUID) -> CGPoint?
    func fileOriginalPosition(move: ProposedFileMove) -> CGPoint?
    func fileProposedPosition(move: ProposedFileMove) -> CGPoint?
}

// MARK: - Graph Node View (Common)
struct GraphNodeView: View {
    let icon: String; let text: String; let baseColor: Color; var isGhost: Bool = false; var width: CGFloat = 140.0
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12))
            Text(text).font(.system(size: 12, weight: .medium))
                .lineLimit(1).minimumScaleFactor(0.6).foregroundColor(.black)
        }
        .padding(6).frame(width: width)
        .background(ZStack { Color.white; if !isGhost { baseColor.opacity(0.1) } })
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isGhost ? baseColor.opacity(0.3) : baseColor.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: isGhost ? [5, 5] : [])))
        .shadow(color: baseColor.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Main Graph View
struct GraphView: View {
    enum Mode {
        case folder(FolderNode)
        case diagram(nodes: [GraphNodeData], edges: [DiagramEdge], selectedMove: ProposedFileMove?, layout: any GraphDiagramLayout, size: CGSize)
    }
    private let mode: Mode
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var isDraggingFile: Bool = false
    
    private var startDepth: Int = 0
    private var selectedFile: FileRowDisplay?
    private var rootNode: FolderNode?
    
    var onAccept: (() -> Void)?
    var onDecline: (() -> Void)?
    var onManualMove: ((UUID, String) -> Void)?

    init(root: FolderNode, startDepth: Int = 0, selectedFile: FileRowDisplay? = nil, onAccept: (() -> Void)? = nil, onDecline: (() -> Void)? = nil, onManualMove: ((UUID, String) -> Void)? = nil) {
        mode = .folder(root)
        self.rootNode = root
        self.startDepth = startDepth
        self.selectedFile = selectedFile
        self.onAccept = onAccept
        self.onDecline = onDecline
        self.onManualMove = onManualMove
    }

    // Legacy diagram init
    init(nodes: [GraphNodeData], edges: [DiagramEdge], selectedMove: ProposedFileMove?, layout: any GraphDiagramLayout, size: CGSize) {
        mode = .diagram(nodes: nodes, edges: edges, selectedMove: selectedMove, layout: layout, size: size)
    }

    var body: some View {
        switch mode {
        case .folder(let root): folderBody(root: root)
        case .diagram(let nodes, let edges, let selectedMove, let layout, let size): diagramBody(nodes: nodes, edges: edges, selectedMove: selectedMove, layout: layout, size: size)
        }
    }

    private func folderBody(root: FolderNode) -> some View {
        GeometryReader { geo in
            let config = GraphLayoutConfig(totalAvailableWidth: geo.size.width, zoomScale: zoomScale)
            
            ZStack(alignment: .topLeading) {
                ScrollView([.vertical, .horizontal], showsIndicators: false) {
                    VStack(spacing: 0) {
                        ZStack(alignment: .leading) {
                            // 1. Grid
                            GridLinesView(config: config)
                            
                            // 2. Main Graph Layout
                            FolderGraphLayout(root: root, config: config, selectedFile: selectedFile, isDragging: isDraggingFile)
                                .padding(.vertical, 20)
                                .padding(.leading, (config.columnStride - config.nodeWidth) / 2)
                                
                                // 3. Drag Interaction Layer
                                .backgroundPreferenceValue(NodeBoundsKey.self) { preferences in
                                    GeometryReader { innerGeo in
                                        let positions = resolvePositions(from: preferences, in: innerGeo)
                                        if let file = selectedFile {
                                            FileDragLayer(
                                                file: file,
                                                rootNode: root, // Pass root to find names later
                                                config: config,
                                                nodePositions: positions,
                                                isDragging: $isDraggingFile,
                                                onDrop: { newFolderID in handleDrop(fileId: file.id, folderId: newFolderID) }
                                            )
                                            .padding(.vertical, 20)
                                            .padding(.leading, (config.columnStride - config.nodeWidth) / 2)
                                        }
                                    }
                                }
                        }
                        .contentShape(Rectangle())
                        .frame(width: max(geo.size.width, geo.size.width * zoomScale), height: max(geo.size.height - 80, 400) * zoomScale, alignment: .topLeading)
                        
                        // Footer
                        HStack(spacing: 0) {
                            ForEach(0..<config.visibleColumns, id: \.self) { i in
                                ZStack {
                                    Text("Depth \(i + startDepth)")
                                        .font(.caption).bold().foregroundColor(.black.opacity(0.6))
                                        .padding(6).frame(width: config.nodeWidth).background(Color.white).cornerRadius(6)
                                }.frame(width: config.columnStride)
                            }
                        }
                        .padding(.top, 20).padding(.bottom, 40)
                        .scaleEffect(zoomScale, anchor: .topLeading).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scaleEffect(zoomScale, anchor: .topLeading)
                    .gesture(MagnificationGesture().onChanged { val in
                        let delta = val / lastZoomScale
                        lastZoomScale = val
                        zoomScale = min(max(zoomScale * delta, 1.0), 3.0)
                    }.onEnded { _ in lastZoomScale = 1.0 })
                }
                
                // HUD
                HStack(spacing: 12) {
                    Button(action: { onAccept?() }) { Label("Accept", systemImage: "checkmark").padding(10).background(Color.green).foregroundColor(.white).cornerRadius(8) }.buttonStyle(.plain)
                    Button(action: { onDecline?() }) { Label("Decline", systemImage: "xmark").padding(10).background(Color.red).foregroundColor(.white).cornerRadius(8) }.buttonStyle(.plain)
                }
                .padding([.top, .trailing], 24).frame(maxWidth: .infinity, alignment: .topTrailing)
            }
        }
    }
    
    private func handleDrop(fileId: UUID, folderId: UUID) {
        if let targetFolder = findNode(id: folderId, in: rootNode!) {
            onManualMove?(fileId, targetFolder.name)
        }
    }
    
    private func resolvePositions(from preferences: [UUID: Anchor<CGRect>], in geometry: GeometryProxy) -> [UUID: CGRect] {
        var dict: [UUID: CGRect] = [:]
        for (id, anchor) in preferences { dict[id] = geometry[anchor] }
        return dict
    }
    
    private func findNode(id: UUID, in node: FolderNode) -> FolderNode? {
        if node.id == id { return node }
        for child in node.children { if let found = findNode(id: id, in: child) { return found } }
        return nil
    }
    
    private func diagramBody(nodes: [GraphNodeData], edges: [DiagramEdge], selectedMove: ProposedFileMove?, layout: any GraphDiagramLayout, size: CGSize) -> some View { EmptyView() }
}

// MARK: - Drag Layer
struct FileDragLayer: View {
    let file: FileRowDisplay
    let rootNode: FolderNode
    let config: GraphLayoutConfig
    let nodePositions: [UUID: CGRect]
    @Binding var isDragging: Bool
    var onDrop: (UUID) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var currentDragLocation: CGPoint = .zero
    @State private var potentialTargetID: UUID? = nil
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            // 1. Invisible Touch Target
            if let staticRect = nodePositions[file.id], !isDragging {
                Color.white.opacity(0.001)
                    .frame(width: staticRect.width, height: staticRect.height)
                    .position(x: staticRect.midX, y: staticRect.midY)
                    .gesture(
                        DragGesture(coordinateSpace: .local)
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    currentDragLocation = CGPoint(x: staticRect.midX, y: staticRect.midY)
                                }
                                dragOffset = value.translation
                                potentialTargetID = findNearestFolder(at: currentDragLocation, offset: dragOffset)
                            }
                            .onEnded { _ in endDrag() }
                    )
            }
            
            // 2. Dragging Elements
            if isDragging {
                let currentPoint = CGPoint(x: currentDragLocation.x + dragOffset.width, y: currentDragLocation.y + dragOffset.height)
                
                // A. Draw Connection to Nearest Folder (if found)
                if let targetID = potentialTargetID, let targetRect = nodePositions[targetID] {
                    Path { path in
                        // Start: Right Center of Target Folder
                        let startPoint = CGPoint(x: targetRect.maxX, y: targetRect.midY)
                        // End: Left Center of Dragging File
                        let endPoint = CGPoint(x: currentPoint.x - (config.nodeWidth / 2), y: currentPoint.y)
                        
                        path.move(to: startPoint)
                        let deltaX = endPoint.x - startPoint.x
                        let control1 = CGPoint(x: startPoint.x + deltaX * 0.5, y: startPoint.y)
                        let control2 = CGPoint(x: endPoint.x - deltaX * 0.5, y: endPoint.y)
                        path.addCurve(to: endPoint, control1: control1, control2: control2)
                    }
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                
                // B. The File Node Avatar
                FileNodeView(name: file.fileName, width: config.nodeWidth)
                    .position(x: currentPoint.x, y: currentPoint.y)
                    .shadow(radius: 8)
            }
        }
        .if(isDragging) { view in
            view.gesture(
                DragGesture(coordinateSpace: .local)
                    .onChanged { value in
                        dragOffset = value.translation
                        potentialTargetID = findNearestFolder(at: currentDragLocation, offset: dragOffset)
                    }
                    .onEnded { _ in endDrag() }
            )
        }
    }
    
    // Logic: Find nearest folder on the *previous* vertical line
    func findNearestFolder(at initialPoint: CGPoint, offset: CGSize) -> UUID? {
        let currentX = initialPoint.x + offset.width
        let currentY = initialPoint.y + offset.height
        
        // 1. Determine current section index (column)
        // Adding half width to center the detection logic
        let currentColumnIndex = Int(currentX / config.columnStride)
        
        // 2. Identify Target Column (Previous one)
        // If we are at column 1, we look at column 0. If at 0, we stick to 0.
        let targetColumnIndex = max(0, currentColumnIndex - 1)
        
        var bestDist = CGFloat.greatestFiniteMagnitude
        var bestID: UUID? = nil
        
        for (id, rect) in nodePositions {
            if id == file.id { continue } // Skip self
            
            // 3. Filter: Is this node in the target column?
            // We verify if the node's center X falls within the target column's bounds
            let nodeColumnIndex = Int(rect.midX / config.columnStride)
            
            if nodeColumnIndex == targetColumnIndex {
                // 4. Measure distance (Euclidean)
                let dist = hypot(rect.midX - currentX, rect.midY - currentY)
                if dist < bestDist {
                    bestDist = dist
                    bestID = id
                }
            }
        }
        
        // Fallback: If no node found in previous column (e.g., dragged too far left),
        // snap to Root if available and we are in the first column
        if bestID == nil && targetColumnIndex == 0 {
             if let rootRect = nodePositions[rootNode.id] {
                 return rootNode.id
             }
        }
        
        return bestID
    }
    
    func endDrag() {
        if let target = potentialTargetID {
            onDrop(target)
        }
        isDragging = false
        dragOffset = .zero
        potentialTargetID = nil
    }
}

// MARK: - Recursive Layout
struct FolderGraphLayout: View {
    let root: FolderNode
    let config: GraphLayoutConfig
    let selectedFile: FileRowDisplay?
    let isDragging: Bool

    var body: some View {
        RecursiveNodeView(node: root, depth: 0, config: config, selectedFile: selectedFile, isDragging: isDragging)
            .backgroundPreferenceValue(NodeBoundsKey.self) { preferences in
                GeometryReader { geometry in
                    ZStack {
                        ForEach(Array(preferences.keys), id: \.self) { id in
                            if let node = findNode(id: id, in: root), !node.children.isEmpty {
                                drawCurve(from: id, to: node.children.map { $0.id }, preferences: preferences, geometry: geometry, color: AppStyle.edgeNormalColor, dash: [])
                            }
                        }
                        // Static connection line (hidden during drag)
                        if !isDragging, let file = selectedFile, let _ = preferences[file.id] {
                            Group {
                                let parentID = determineParentID(for: file, root: root)
                                if preferences[parentID] != nil {
                                    drawCurve(from: parentID, to: [file.id], preferences: preferences, geometry: geometry, color: .green, dash: [5, 5])
                                }
                            }
                        }
                    }
                }
            }
    }
    
    func determineParentID(for file: FileRowDisplay, root: FolderNode) -> UUID {
        if let dest = file.destination, let pNode = findNodeByName(name: dest, in: root) {
            return pNode.id
        }
        return root.id
    }
    
    func drawCurve(from parentId: UUID, to childIds: [UUID], preferences: [UUID: Anchor<CGRect>], geometry: GeometryProxy, color: Color, dash: [CGFloat]) -> some View {
        ZStack {
            if let startAnchor = preferences[parentId] {
                let startRect = geometry[startAnchor]
                let startPoint = CGPoint(x: startRect.maxX, y: startRect.midY)
                
                ForEach(childIds, id: \.self) { childId in
                    if let childAnchor = preferences[childId] {
                        let endRect = geometry[childAnchor]
                        let endPoint = CGPoint(x: endRect.minX, y: endRect.midY)
                        
                        Path { path in
                            path.move(to: startPoint)
                            let deltaX = endPoint.x - startPoint.x
                            let control1 = CGPoint(x: startPoint.x + deltaX * 0.5, y: startPoint.y)
                            let control2 = CGPoint(x: endPoint.x - deltaX * 0.5, y: endPoint.y)
                            path.addCurve(to: endPoint, control1: control1, control2: control2)
                        }
                        .stroke(color, style: StrokeStyle(lineWidth: 2, dash: dash))
                    }
                }
            }
        }
    }
    
    func findNode(id: UUID, in node: FolderNode) -> FolderNode? {
        if node.id == id { return node }
        for child in node.children { if let found = findNode(id: id, in: child) { return found } }
        return nil
    }
    func findNodeByName(name: String, in node: FolderNode) -> FolderNode? {
        if node.name == name { return node }
        for child in node.children { if let found = findNodeByName(name: name, in: child) { return found } }
        return nil
    }
}

struct RecursiveNodeView: View {
    let node: FolderNode
    let depth: Int
    let config: GraphLayoutConfig
    let selectedFile: FileRowDisplay?
    let isDragging: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: config.spacing) {
            
            FolderItemView(name: node.name, width: config.nodeWidth, isNew: node.isNew)
                .anchorPreference(key: NodeBoundsKey.self, value: .bounds) { [node.id: $0] }
            
            let shouldInsertFile: Bool = {
                guard let file = selectedFile else { return false }
                if let dest = file.destination { return node.name == dest }
                else { return depth == 0 } // Insert in root if unmoved (Depth 0)
            }()
            
            if !node.children.isEmpty || shouldInsertFile {
                VStack(alignment: .leading, spacing: config.verticalSpacing) {
                    
                    let childrenCount = node.children.count
                    let middleIndex = childrenCount / 2
                    let totalItems = childrenCount + (shouldInsertFile ? 1 : 0)
                    
                    ForEach(0..<totalItems, id: \.self) { i in
                        if shouldInsertFile && i == middleIndex {
                            if let file = selectedFile {
                                FileNodeView(name: file.fileName, width: config.nodeWidth)
                                    .opacity(isDragging ? 0 : 1)
                                    .anchorPreference(key: NodeBoundsKey.self, value: .bounds) { [file.id: $0] }
                            }
                        }
                        
                        let childIndex = (shouldInsertFile && i > middleIndex) ? i - 1 : i
                        if childIndex < childrenCount && ( !shouldInsertFile || i != middleIndex ) {
                            RecursiveNodeView(node: node.children[childIndex], depth: depth + 1, config: config, selectedFile: selectedFile, isDragging: isDragging)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Components & Helpers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

struct FileNodeView: View {
    let name: String; let width: CGFloat
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.fill").font(.system(size: 12))
            Text(name).font(.system(size: 12, weight: .bold)).lineLimit(1).minimumScaleFactor(0.6).foregroundColor(.green)
        }
        .padding(6).frame(width: width).background(Color.white).cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 2))
        .shadow(color: .green.opacity(0.2), radius: 4)
    }
}

struct FolderItemView: View {
    let name: String; let width: CGFloat; var isNew: Bool = false
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder.fill").foregroundColor(isNew ? .green : AppStyle.folderIconColor)
            Text(name).font(.system(size: 14, weight: .medium)).lineLimit(1).minimumScaleFactor(0.6).foregroundColor(.black)
        }
        .padding(.vertical, 8).padding(.horizontal, 6).frame(width: width)
        .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isNew ? Color.green.opacity(0.5) : Color.blue.opacity(0.3), lineWidth: 1))
    }
}

struct GridLinesView: View {
    let config: GraphLayoutConfig
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let totalLines = config.visibleColumns + 2
                for depth in 0..<totalLines {
                    let centerX = config.centerX(for: depth)
                    path.move(to: CGPoint(x: centerX, y: 0)); path.addLine(to: CGPoint(x: centerX, y: geometry.size.height))
                }
            }
            .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
    }
}

struct NodeBoundsKey: PreferenceKey {
    typealias Value = [UUID: Anchor<CGRect>]
    static var defaultValue: Value = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) { value.merge(nextValue(), uniquingKeysWith: { $1 }) }
}

struct FolderNode: Identifiable {
    let id = UUID(); let name: String; var isNew: Bool = false; var children: [FolderNode] = []
}
