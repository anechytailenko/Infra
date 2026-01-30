import SwiftUI

// MARK: - Graph Diagram Types (shared diagram mode)

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

// MARK: - Graph View (folder tree or diagram mode)

struct GraphView: View {
    enum Mode {
        case folder(FolderNode, onFolderSelected: ((FolderNode) -> Void)?)
        case diagram(nodes: [GraphNodeData], edges: [DiagramEdge], selectedMove: ProposedFileMove?, layout: any GraphDiagramLayout, size: CGSize)
    }
    private let mode: Mode

    init(root: FolderNode, onFolderSelected: ((FolderNode) -> Void)? = nil) {
        mode = .folder(root, onFolderSelected: onFolderSelected)
    }

    init(nodes: [GraphNodeData], edges: [DiagramEdge], selectedMove: ProposedFileMove?, layout: any GraphDiagramLayout, size: CGSize) {
        mode = .diagram(nodes: nodes, edges: edges, selectedMove: selectedMove, layout: layout, size: size)
    }

    var body: some View {
        switch mode {
        case .folder(let root, let onFolderSelected):
            folderBody(root: root, onFolderSelected: onFolderSelected)
        case .diagram(let nodes, let edges, let selectedMove, let layout, let size):
            diagramBody(nodes: nodes, edges: edges, selectedMove: selectedMove, layout: layout, size: size)
        }
    }

    // MARK: - Folder Mode

    private func folderBody(root: FolderNode, onFolderSelected: ((FolderNode) -> Void)?) -> some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            FolderGraphLayout(root: root, onFolderSelected: onFolderSelected)
                .padding(GraphViewStyle.graphAreaPadding)
        }
    }

    // MARK: - Diagram Mode

    private func diagramBody(nodes: [GraphNodeData], edges: [DiagramEdge], selectedMove: ProposedFileMove?, layout: any GraphDiagramLayout, size: CGSize) -> some View {
        let layoutSize = size
        let padding = SortDecisionStyle.diagramInnerPadding
        return ZStack(alignment: .topLeading) {
            diagramEdgesLayer(edges: edges, selectedMove: selectedMove, layout: layout)
            diagramNodesLayer(nodes: nodes, layout: layout)
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
                let from = layout.position(for: edge.fromId)
                let to: CGPoint? = {
                    switch edge.style {
                    case .normal: return layout.position(for: edge.toId)
                    case .originalFile: return selectedMove.flatMap { layout.fileOriginalPosition(move: $0) }
                    case .proposedFile: return selectedMove.flatMap { layout.fileProposedPosition(move: $0) }
                    }
                }()
                guard let start = from, let end = to else { continue }
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

    private func diagramNodesLayer(nodes: [GraphNodeData], layout: any GraphDiagramLayout) -> some View {
        ForEach(nodes) { node in
            if let pos = layout.position(for: node.id) {
                GraphNodeView(icon: node.iconName, text: node.label, baseColor: node.color, isGhost: node.isGhost)
                    .position(pos)
            }
        }
    }

    private func diagramFileNodesLayer(move: ProposedFileMove, layout: any GraphDiagramLayout) -> some View {
        Group {
            if let fromPos = layout.fileOriginalPosition(move: move) {
                GraphNodeView(icon: "doc.fill", text: move.fileName, baseColor: .red, isGhost: true)
                    .position(fromPos)
            }
            if let toPos = layout.fileProposedPosition(move: move) {
                GraphNodeView(icon: "doc.fill", text: move.fileName, baseColor: .green, isGhost: false)
                    .position(toPos)
            }
        }
    }
}

// MARK: - Graph Layout & Recursion (folder mode)

struct FolderGraphLayout: View {
    let root: FolderNode
    var onFolderSelected: ((FolderNode) -> Void)? = nil

    var body: some View {
        RecursiveNodeView(node: root, depth: 0, onFolderSelected: onFolderSelected)
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
                            .stroke(AppStyle.edgeNormalColor, lineWidth: AppStyle.edgeNormalLineWidth)
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
    var onFolderSelected: ((FolderNode) -> Void)? = nil
    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .center, spacing: GraphViewStyle.folderGraphHStackSpacing) {
            nodeContent

            if !node.children.isEmpty {
                VStack(alignment: .leading, spacing: GraphViewStyle.folderGraphVStackSpacing) {
                    ForEach(node.children) { child in
                        RecursiveNodeView(node: child, depth: depth + 1, onFolderSelected: onFolderSelected)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var nodeContent: some View {
        let itemView = FolderItemView(name: node.name)
            .anchorPreference(key: NodeBoundsKey.self, value: .bounds) { [node.id: $0] }

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

// MARK: - Helper Components (folder mode)

struct FolderItemView: View {
    let name: String
    var body: some View {
        HStack(spacing: AppStyle.nodeHStackSpacing) {
            Image(systemName: "folder.fill")
                .font(AppStyle.nodeIconFont)
                .foregroundStyle(AppStyle.folderIconColor)
            Text(name)
                .font(AppStyle.nodeTextFont)
                .foregroundStyle(AppStyle.textPrimary.opacity(0.8))
        }
        .padding(.vertical, AppStyle.nodePaddingVertical)
        .padding(.horizontal, AppStyle.nodePaddingHorizontal)
        .background(AppStyle.folderIconColor.opacity(AppStyle.nodeFillOpacity))
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.nodeCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.nodeCornerRadius)
                .strokeBorder(AppStyle.folderIconColor.opacity(AppStyle.nodeBorderOpacity), lineWidth: AppStyle.nodeBorderLineWidth)
        )
    }
}

struct NodeBoundsKey: PreferenceKey {
    typealias Value = [UUID: Anchor<CGRect>]
    static var defaultValue: Value = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
