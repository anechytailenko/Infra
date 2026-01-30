import SwiftUI

// MARK: - Layout Configuration

struct GraphLayoutConfig {
    let totalAvailableWidth: CGFloat
    let zoomScale: CGFloat
    let visibleColumns: Int = GraphViewStyle.visibleColumns

    var columnStride: CGFloat { totalAvailableWidth / CGFloat(visibleColumns) }
    var nodeWidth: CGFloat { max(columnStride * GraphViewStyle.nodeWidthMultiplier, GraphViewStyle.minNodeWidth) }
    var spacing: CGFloat { columnStride - nodeWidth }
    func centerX(for depth: Int) -> CGFloat { (columnStride * CGFloat(depth)) + (columnStride / 2) }
    var verticalSpacing: CGFloat { GraphViewStyle.verticalSpacing }
}

// MARK: - Graph Diagram Types (shared for diagram mode)

struct GraphNodeData: Identifiable {
    let id: UUID
    let label: String
    let iconName: String
    let color: Color
    let isGhost: Bool
}

protocol GraphDiagramLayout {
    func position(for nodeId: UUID) -> CGPoint?
    func fileOriginalPosition(move: ProposedFileMove) -> CGPoint?
    func fileProposedPosition(move: ProposedFileMove) -> CGPoint?
}

// MARK: - Graph Node View (shared for diagram mode)

struct GraphNodeView: View {
    let icon: String
    let text: String
    let baseColor: Color
    var isGhost: Bool = false

    var body: some View {
        HStack(spacing: SortDecisionStyle.nodeHStackSpacing) {
            Image(systemName: icon)
                .font(SortDecisionStyle.nodeIconFont)
            Text(text)
                .font(SortDecisionStyle.nodeTextFont)
        }
        .padding(.horizontal, SortDecisionStyle.nodePaddingHorizontal)
        .padding(.vertical, SortDecisionStyle.nodePaddingVertical)
        .background(
            ZStack {
                SortDecisionStyle.cardBackground
                if !isGhost {
                    baseColor.opacity(SortDecisionStyle.nodeFillOpacity)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: SortDecisionStyle.nodeCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: SortDecisionStyle.nodeCornerRadius)
                .strokeBorder(isGhost ? baseColor.opacity(SortDecisionStyle.nodeGhostBorderOpacity) : baseColor.opacity(SortDecisionStyle.nodeBorderOpacity), style: StrokeStyle(lineWidth: SortDecisionStyle.nodeBorderLineWidth, dash: isGhost ? SortDecisionStyle.nodeGhostDash : []))
        )
        .foregroundStyle(baseColor)
        .shadow(color: baseColor.opacity(isGhost ? SortDecisionStyle.nodeGhostShadowOpacity : SortDecisionStyle.nodeShadowOpacity), radius: SortDecisionStyle.nodeShadowRadius, x: 0, y: SortDecisionStyle.nodeShadowY)
    }
}

// MARK: - Main Graph View

struct GraphView: View {
    enum Mode {
        case folder(FolderNode)
        case diagram(nodes: [GraphNodeData], edges: [DiagramEdge], selectedMove: ProposedFileMove?, layout: any GraphDiagramLayout, size: CGSize, onFileDrop: ((UUID, UUID, String) -> Void)?)
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
    var onFolderSelected: ((FolderNode) -> Void)?

    // Folder mode initializer with all UI_03 features
    init(
        root: FolderNode,
        startDepth: Int = 0,
        selectedFile: FileRowDisplay? = nil,
        onAccept: (() -> Void)? = nil,
        onDecline: (() -> Void)? = nil,
        onManualMove: ((UUID, String) -> Void)? = nil,
        onFolderSelected: ((FolderNode) -> Void)? = nil
    ) {
        mode = .folder(root)
        self.rootNode = root
        self.startDepth = startDepth
        self.selectedFile = selectedFile
        self.onAccept = onAccept
        self.onDecline = onDecline
        self.onManualMove = onManualMove
        self.onFolderSelected = onFolderSelected
    }

    /// Diagram mode initializer with optional file drop handler for drag-and-drop support.
    init(
        nodes: [GraphNodeData],
        edges: [DiagramEdge],
        selectedMove: ProposedFileMove?,
        layout: any GraphDiagramLayout,
        size: CGSize,
        onFileDrop: ((UUID, UUID, String) -> Void)? = nil
    ) {
        mode = .diagram(nodes: nodes, edges: edges, selectedMove: selectedMove, layout: layout, size: size, onFileDrop: onFileDrop)
    }

    var body: some View {
        switch mode {
        case .folder(let root):
            folderBody(root: root)
        case .diagram(let nodes, let edges, let selectedMove, let layout, let size, let onFileDrop):
            diagramBody(nodes: nodes, edges: edges, selectedMove: selectedMove, layout: layout, size: size, onFileDrop: onFileDrop)
        }
    }

    // MARK: - Folder Mode Body

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
                            FolderGraphLayout(
                                root: root,
                                config: config,
                                selectedFile: selectedFile,
                                isDragging: isDraggingFile,
                                onFolderSelected: onFolderSelected
                            )
                            .padding(.vertical, 20)
                            .padding(.leading, (config.columnStride - config.nodeWidth) / 2)

                            // 3. Drag Interaction Layer
                            .overlayPreferenceValue(NodeBoundsKey.self) { preferences in
                                GeometryReader { innerGeo in
                                    let positions = resolvePositions(from: preferences, in: innerGeo)

                                    if let file = selectedFile {
                                        FileDragLayer(
                                            file: file,
                                            rootNode: root,
                                            config: config,
                                            nodePositions: positions,
                                            isDragging: $isDraggingFile,
                                            onDrop: { newFolderID in handleDrop(fileId: file.id, folderId: newFolderID) }
                                        )
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                                        .font(GraphViewStyle.depthPillFont)
                                        .fontWeight(GraphViewStyle.depthPillFontWeight)
                                        .foregroundColor(.black.opacity(GraphViewStyle.depthPillTextOpacity))
                                        .padding(.horizontal, GraphViewStyle.depthPillPaddingHorizontal)
                                        .padding(.vertical, GraphViewStyle.depthPillPaddingVertical)
                                        .frame(width: config.nodeWidth)
                                        .background(Color.white)
                                        .cornerRadius(GraphViewStyle.depthPillCornerRadius)
                                }.frame(width: config.columnStride)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, GraphViewStyle.footerBottomPadding)
                        .scaleEffect(zoomScale, anchor: .topLeading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scaleEffect(zoomScale, anchor: .topLeading)
                    .gesture(MagnificationGesture()
                        .onChanged { val in
                            let delta = val / lastZoomScale
                            lastZoomScale = val
                            zoomScale = min(max(zoomScale * delta, GraphViewStyle.zoomMin), GraphViewStyle.zoomMax)
                        }
                        .onEnded { _ in lastZoomScale = 1.0 }
                    )
                }

                // HUD (only show if handlers are provided)
                if onAccept != nil || onDecline != nil {
                    HStack(spacing: GraphViewStyle.hudButtonSpacing) {
                        if let acceptAction = onAccept {
                            Button(action: { acceptAction() }) {
                                Label("Accept", systemImage: "checkmark")
                                    .padding(GraphViewStyle.hudButtonPadding)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(GraphViewStyle.hudButtonCornerRadius)
                            }
                            .buttonStyle(.plain)
                        }
                        if let declineAction = onDecline {
                            Button(action: { declineAction() }) {
                                Label("Decline", systemImage: "xmark")
                                    .padding(GraphViewStyle.hudButtonPadding)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(GraphViewStyle.hudButtonCornerRadius)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding([.top, .trailing], GraphViewStyle.hudPadding)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                }
            }
        }
    }

    private func handleDrop(fileId: UUID, folderId: UUID) {
        if let rootNode = rootNode, let targetFolder = findNode(id: folderId, in: rootNode) {
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

    // MARK: - Diagram Mode Body

    private func diagramBody(nodes: [GraphNodeData], edges: [DiagramEdge], selectedMove: ProposedFileMove?, layout: any GraphDiagramLayout, size: CGSize, onFileDrop: ((UUID, UUID, String) -> Void)?) -> some View {
        let layoutSize = size
        let padding = SortDecisionStyle.diagramInnerPadding
        return ZStack(alignment: .topLeading) {
            diagramEdgesLayer(edges: edges, selectedMove: selectedMove, layout: layout)
            diagramNodesLayer(nodes: nodes, layout: layout, onFileDrop: onFileDrop)
            if let move = selectedMove {
                diagramFileNodesLayer(move: move, layout: layout)
            }
        }
        .frame(width: layoutSize.width, height: layoutSize.height)
        .padding(padding)
    }

    private func diagramEdgesLayer(edges: [DiagramEdge], selectedMove: ProposedFileMove?, layout: any GraphDiagramLayout) -> some View {
        Canvas { context, _ in
            for edge in edges {
                let fromCenter = layout.position(for: edge.fromId)
                let toCenter: CGPoint? = {
                    switch edge.style {
                    case .normal: return layout.position(for: edge.toId)
                    case .originalFile: return selectedMove.flatMap { layout.fileOriginalPosition(move: $0) }
                    case .proposedFile: return selectedMove.flatMap { layout.fileProposedPosition(move: $0) }
                    }
                }()
                guard let startCenter = fromCenter, let endCenter = toCenter else { continue }

                let start = CGPoint(
                    x: startCenter.x + SortDecisionStyle.folderNodeHalfWidth,
                    y: startCenter.y
                )

                let endOffset: CGFloat = {
                    switch edge.style {
                    case .normal: return SortDecisionStyle.folderNodeHalfWidth
                    case .originalFile, .proposedFile: return 0
                    }
                }()
                let end = CGPoint(
                    x: endCenter.x - endOffset,
                    y: endCenter.y
                )

                var path = Path()
                path.move(to: start)
                let deltaX = end.x - start.x
                let control1 = CGPoint(x: start.x + deltaX * SortDecisionStyle.edgeCurveControlFactor, y: start.y)
                let control2 = CGPoint(x: end.x - deltaX * SortDecisionStyle.edgeCurveControlFactor, y: end.y)
                path.addCurve(to: end, control1: control1, control2: control2)
                switch edge.style {
                case .normal:
                    context.stroke(path, with: .color(SortDecisionStyle.edgeNormalColor), lineWidth: SortDecisionStyle.edgeNormalLineWidth)
                case .originalFile:
                    context.stroke(path, with: .color(SortDecisionStyle.edgeOriginalFileColor), style: StrokeStyle(lineWidth: SortDecisionStyle.edgeOriginalFileLineWidth, dash: SortDecisionStyle.edgeOriginalFileDash))
                case .proposedFile:
                    context.stroke(path, with: .color(SortDecisionStyle.edgeProposedFileColor), lineWidth: SortDecisionStyle.edgeProposedFileLineWidth)
                }
            }
        }
    }

    private func diagramNodesLayer(nodes: [GraphNodeData], layout: any GraphDiagramLayout, onFileDrop: ((UUID, UUID, String) -> Void)?) -> some View {
        ForEach(nodes) { node in
            if let pos = layout.position(for: node.id) {
                DroppableFolderNode(
                    node: node,
                    position: pos,
                    onFileDrop: onFileDrop
                )
            }
        }
    }

    private func diagramFileNodesLayer(move: ProposedFileMove, layout: any GraphDiagramLayout) -> some View {
        Group {
            if let fromPos = layout.fileOriginalPosition(move: move) {
                GraphNodeView(icon: "doc.fill", text: move.fileName, baseColor: .red, isGhost: true)
                    .fixedSize()
                    .anchorAtLeading(at: fromPos)
            }
            if let toPos = layout.fileProposedPosition(move: move) {
                GraphNodeView(icon: "doc.fill", text: move.fileName, baseColor: .green, isGhost: false)
                    .fixedSize()
                    .anchorAtLeading(at: toPos)
            }
        }
    }
}

// MARK: - Droppable Folder Node (diagram mode drag-and-drop)

private struct DroppableFolderNode: View {
    let node: GraphNodeData
    let position: CGPoint
    let onFileDrop: ((UUID, UUID, String) -> Void)?

    @State private var isTargeted = false

    var body: some View {
        GraphNodeView(icon: node.iconName, text: node.label, baseColor: node.color, isGhost: node.isGhost)
            .scaleEffect(isTargeted ? 1.1 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: SortDecisionStyle.nodeCornerRadius)
                    .stroke(Color.blue, lineWidth: isTargeted ? 3 : 0)
            )
            .shadow(color: isTargeted ? Color.blue.opacity(0.5) : Color.clear, radius: 8)
            .animation(.easeInOut(duration: 0.15), value: isTargeted)
            .position(position)
            .dropDestination(for: String.self) { items, _ in
                guard let fileIdString = items.first,
                      let fileId = UUID(uuidString: fileIdString) else { return false }
                onFileDrop?(fileId, node.id, node.label)
                return true
            } isTargeted: { targeted in
                isTargeted = targeted
            }
    }
}

// MARK: - View Extension for Leading-Edge Anchored Positioning

extension View {
    func anchorAtLeading(at point: CGPoint) -> some View {
        self.modifier(LeadingAnchorModifier(targetPoint: point))
    }
}

private struct LeadingAnchorModifier: ViewModifier {
    let targetPoint: CGPoint
    @State private var viewSize: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { geo in
                Color.clear
                    .onAppear { viewSize = geo.size }
                    .onChange(of: geo.size) { newSize in viewSize = newSize }
            })
            .position(x: targetPoint.x + viewSize.width / 2, y: targetPoint.y)
    }
}

// MARK: - File Drag Layer (folder mode)

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

                // A. Connection Line
                if let targetID = potentialTargetID, let targetRect = nodePositions[targetID] {
                    Path { path in
                        let startPoint = CGPoint(x: targetRect.maxX, y: targetRect.midY)
                        let endPoint = CGPoint(x: currentPoint.x - (config.nodeWidth / 2), y: currentPoint.y)

                        path.move(to: startPoint)
                        let deltaX = endPoint.x - startPoint.x
                        let control1 = CGPoint(x: startPoint.x + deltaX * 0.5, y: startPoint.y)
                        let control2 = CGPoint(x: endPoint.x - deltaX * 0.5, y: endPoint.y)
                        path.addCurve(to: endPoint, control1: control1, control2: control2)
                    }
                    .stroke(GraphViewStyle.dragConnectionColor, style: StrokeStyle(lineWidth: 2, dash: GraphViewStyle.dragLineDash))
                }

                // B. The Avatar
                FileNodeView(name: file.fileName, width: config.nodeWidth)
                    .position(x: currentPoint.x, y: currentPoint.y)
                    .shadow(radius: GraphViewStyle.dragShadowRadius)
                    .gesture(
                        DragGesture(coordinateSpace: .local)
                            .onChanged { value in
                                dragOffset = value.translation
                                potentialTargetID = findNearestFolder(at: currentDragLocation, offset: dragOffset)
                            }
                            .onEnded { _ in endDrag() }
                    )
            }
        }
    }

    func findNearestFolder(at initialPoint: CGPoint, offset: CGSize) -> UUID? {
        let currentX = initialPoint.x + offset.width
        let currentY = initialPoint.y + offset.height

        let currentColumnIndex = Int(currentX / config.columnStride)
        let targetColumnIndex = max(0, currentColumnIndex - 1)

        var bestDist = CGFloat.greatestFiniteMagnitude
        var bestID: UUID? = nil

        for (id, rect) in nodePositions {
            if id == file.id { continue }
            if !isIDFolder(id) { continue }

            let nodeColumnIndex = Int(rect.midX / config.columnStride)

            if nodeColumnIndex == targetColumnIndex {
                let dist = hypot(rect.midX - currentX, rect.midY - currentY)
                if dist < bestDist {
                    bestDist = dist
                    bestID = id
                }
            }
        }

        if bestID == nil && targetColumnIndex == 0 {
            if nodePositions[rootNode.id] != nil {
                return rootNode.id
            }
        }

        return bestID
    }

    func isIDFolder(_ uuid: UUID) -> Bool {
        func check(_ node: FolderNode) -> Bool {
            if node.id == uuid { return true }
            for child in node.children {
                if check(child) { return true }
            }
            return false
        }
        return check(rootNode)
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

// MARK: - Recursive Layout (folder mode)

struct FolderGraphLayout: View {
    let root: FolderNode
    let config: GraphLayoutConfig
    let selectedFile: FileRowDisplay?
    let isDragging: Bool
    var onFolderSelected: ((FolderNode) -> Void)?

    var body: some View {
        RecursiveNodeView(
            node: root,
            depth: 0,
            config: config,
            selectedFile: selectedFile,
            isDragging: isDragging,
            onFolderSelected: onFolderSelected
        )
        .backgroundPreferenceValue(NodeBoundsKey.self) { preferences in
            GeometryReader { geometry in
                ZStack {
                    // 1. Folder Connections
                    ForEach(Array(preferences.keys), id: \.self) { id in
                        if let node = findNode(id: id, in: root), !node.children.isEmpty {
                            drawCurve(from: id, to: node.children.map { $0.id }, preferences: preferences, geometry: geometry, color: AppStyle.edgeNormalColor, dash: [])
                        }
                    }

                    // 2. Selected File Connection (Static)
                    if !isDragging, let file = selectedFile, preferences[file.id] != nil {
                        Group {
                            let parentID = determineParentID(for: file, root: root)
                            if preferences[parentID] != nil {
                                drawCurve(from: parentID, to: [file.id], preferences: preferences, geometry: geometry, color: GraphViewStyle.fileNodeColor, dash: GraphViewStyle.dragLineDash)
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
                        .stroke(color, style: StrokeStyle(lineWidth: AppStyle.edgeNormalLineWidth, dash: dash))
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
    var onFolderSelected: ((FolderNode) -> Void)?

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .center, spacing: config.spacing) {
            nodeContent
                .anchorPreference(key: NodeBoundsKey.self, value: .bounds) { [node.id: $0] }

            let shouldInsertFile: Bool = {
                guard let file = selectedFile else { return false }
                if let dest = file.destination { return node.name == dest }
                else { return depth == 0 }
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
                        if childIndex < childrenCount && (!shouldInsertFile || i != middleIndex) {
                            RecursiveNodeView(
                                node: node.children[childIndex],
                                depth: depth + 1,
                                config: config,
                                selectedFile: selectedFile,
                                isDragging: isDragging,
                                onFolderSelected: onFolderSelected
                            )
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var nodeContent: some View {
        let itemView = FolderItemView(name: node.name, width: config.nodeWidth, isNew: node.isNew)

        if let onFolderSelected = onFolderSelected {
            Button { onFolderSelected(node) } label: {
                itemView
                    .scaleEffect(isHovering ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovering)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovering = $0 }
        } else if node.name == "Root" {
            NavigationLink(destination: FolderDetailView(folder: node)) { itemView }
                .buttonStyle(PlainButtonStyle())
        } else {
            itemView
        }
    }
}

// MARK: - Component Views

struct FileNodeView: View {
    let name: String
    let width: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.fill").font(.system(size: 12))
            Text(name)
                .font(.system(size: 12, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundColor(GraphViewStyle.fileNodeColor)
        }
        .padding(6)
        .frame(width: width)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(GraphViewStyle.fileNodeColor, lineWidth: GraphViewStyle.fileNodeBorderWidth))
        .shadow(color: GraphViewStyle.fileNodeColor.opacity(GraphViewStyle.fileNodeShadowOpacity), radius: GraphViewStyle.fileNodeShadowRadius)
    }
}

struct FolderItemView: View {
    let name: String
    let width: CGFloat
    var isNew: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder.fill")
                .foregroundColor(isNew ? GraphViewStyle.newFolderColor : AppStyle.folderIconColor)
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundColor(.black)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .frame(width: width)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isNew ? GraphViewStyle.newFolderColor.opacity(GraphViewStyle.newFolderBorderOpacity) : Color.blue.opacity(0.3), lineWidth: 1)
        )
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
                    path.move(to: CGPoint(x: centerX, y: 0))
                    path.addLine(to: CGPoint(x: centerX, y: geometry.size.height))
                }
            }
            .stroke(Color.gray.opacity(GraphViewStyle.gridLineOpacity), style: StrokeStyle(lineWidth: 1, dash: GraphViewStyle.gridLineDash))
        }
    }
}

// MARK: - Preference Keys

struct NodeBoundsKey: PreferenceKey {
    typealias Value = [UUID: Anchor<CGRect>]
    static var defaultValue: Value = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
