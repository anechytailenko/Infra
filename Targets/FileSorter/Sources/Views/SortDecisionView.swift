import SwiftUI

// MARK: - SortDecisionView

struct SortDecisionView: View {
    
    @StateObject private var viewModel = SortDecisionViewModel()
    
    var body: some View {
        ZStack {
            SortDecisionStyle.mainBackgroundGray
                .ignoresSafeArea()
            
            VStack(spacing: SortDecisionStyle.stackSpacing) {
                topControlBar
                diagramSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                proposedChangesList
                    .frame(height: SortDecisionStyle.proposedListHeight)
                    .layoutPriority(0)
            }
            .padding(SortDecisionStyle.mainPadding)
        }
        .frame(minWidth: SortDecisionStyle.minWidth, minHeight: SortDecisionStyle.minHeight)
        .onAppear {
            if let firstMove = viewModel.effectiveMoves.first {
                viewModel.selectMove(id: firstMove.id)
            }
        }
    }
    
    // MARK: - Top Control Bar
    
    private var topControlBar: some View {
        HStack {
            Spacer()
            // Buttons are now separate from the diagram card
            Button("Accept") {
                viewModel.acceptAll()
            }
            .buttonStyle(NiceButtonStyle(color: SortDecisionStyle.acceptButtonColor))
            
            Button("Decline") {
                viewModel.declineAll()
            }
            .buttonStyle(NiceButtonStyle(color: SortDecisionStyle.declineButtonColor))
        }
    }
    
    // MARK: - Diagram Section
    
    // State for Gestures
    @State private var offset: CGSize = .zero
    @State private var lastDragPosition: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    private var diagramSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // The Graph
                SortDecisionDiagramView(
                    nodes: viewModel.diagramNodes,
                    edges: viewModel.diagramEdges,
                    selectedMove: viewModel.selectedMove
                )
                .scaleEffect(scale)
                .offset(x: offset.width, y: offset.height)
                // Gestures: Drag (Pan) and Magnification (Zoom)
                .gesture(
                    SimultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastDragPosition.width + value.translation.width,
                                    height: lastDragPosition.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastDragPosition = offset
                            },
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastScale * value
                                // Limit zoom levels
                                scale = max(SortDecisionStyle.zoomMin, min(SortDecisionStyle.zoomMax, newScale))
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SortDecisionStyle.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: SortDecisionStyle.cardCornerRadius))
            .shadow(color: SortDecisionStyle.cardShadowColor, radius: SortDecisionStyle.cardShadowRadius, x: SortDecisionStyle.cardShadowX, y: SortDecisionStyle.cardShadowY)
        }
    }
    
    // MARK: - Proposed Changes List Section
    
    private var proposedChangesList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: SortDecisionStyle.listHeaderHStackSpacing) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(SortDecisionStyle.folderIconColor)
                    .font(SortDecisionStyle.listHeaderIconFont)
                Text("User")
                    .font(SortDecisionStyle.listHeaderFont)
                    .foregroundStyle(SortDecisionStyle.textPrimary)
                Spacer()
            }
            .padding()
            .background(SortDecisionStyle.cardBackground)
            .zIndex(1)
            
            Divider()
                .overlay(Color.black.opacity(SortDecisionStyle.listDividerOverlayOpacity))
            
            // List Content
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.effectiveMoves.isEmpty {
                        Text("No pending moves")
                            .foregroundStyle(SortDecisionStyle.emptyListPlaceholderColor)
                            .padding()
                    } else {
                        // Enumerated to calculate Zebra stripes
                        ForEach(Array(viewModel.effectiveMoves.enumerated()), id: \.element.id) { index, move in
                            ProposedMoveRow(
                                move: move,
                                index: index,
                                isSelected: viewModel.selectedMoveId == move.id,
                                onSelect: { viewModel.selectMove(id: move.id) },
                                onDecline: { viewModel.declineFile(id: move.id) }
                            )
                            Divider()
                        }
                    }
                }
            }
        }
        .background(SortDecisionStyle.cardBackground)
        .cornerRadius(SortDecisionStyle.cardCornerRadius)
        .shadow(color: SortDecisionStyle.cardShadowColor, radius: SortDecisionStyle.cardShadowRadius, x: SortDecisionStyle.cardShadowX, y: SortDecisionStyle.cardShadowY)
    }
}

// MARK: - Subview: Proposed Move Row

struct ProposedMoveRow: View {
    let move: ProposedFileMove
    let index: Int
    let isSelected: Bool
    let onSelect: () -> Void
    let onDecline: () -> Void
    
    @State private var isHoveringDecline = false
    
    var body: some View {
        ZStack {
            // Zebra Styling Background
            // If selected: Blue tint.
            // If not selected: Alternate between White and Very Light Gray (0.97)
            if isSelected {
                Color.blue.opacity(SortDecisionStyle.listSelectedRowTintOpacity)
            } else {
                index % 2 == 0 ? SortDecisionStyle.listRowEven : SortDecisionStyle.listZebraGray
            }
            
            HStack(spacing: SortDecisionStyle.listRowHStackSpacing) {
                HStack(spacing: SortDecisionStyle.listRowHStackSpacing) {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(SortDecisionStyle.listRowIconColor)
                        .font(SortDecisionStyle.rowIconFont)
                    
                    Text(move.fileName)
                        .font(SortDecisionStyle.rowFileNameFont)
                        .foregroundStyle(SortDecisionStyle.textPrimary)
                }
                
                Spacer()
                
                Button {
                    withAnimation { onDecline() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(SortDecisionStyle.rowIconFont)
                        .foregroundStyle(isHoveringDecline ? SortDecisionStyle.declineButtonRed : SortDecisionStyle.declineButtonGray)
                        .scaleEffect(isHoveringDecline ? SortDecisionStyle.rowDeclineHoverScale : 1.0)
                        .animation(.easeInOut(duration: SortDecisionStyle.rowDeclineHoverDuration), value: isHoveringDecline)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringDecline = hovering
                }
            }
            .padding(.horizontal, SortDecisionStyle.listRowPaddingHorizontal)
            .padding(.vertical, SortDecisionStyle.listRowPaddingVertical)
            
            Text("moved to: \(move.toParentName)")
                .font(SortDecisionStyle.rowMovedToFont)
                .foregroundStyle(SortDecisionStyle.textSecondary)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: SortDecisionStyle.rowSelectSpringResponse, dampingFraction: SortDecisionStyle.rowSelectSpringDamping)) {
                onSelect()
            }
        }
    }
}

// MARK: - Custom Button Style

struct NiceButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SortDecisionStyle.buttonFont)
            .padding(.horizontal, SortDecisionStyle.buttonPaddingHorizontal)
            .padding(.vertical, SortDecisionStyle.buttonPaddingVertical)
            .background(color)
            .foregroundStyle(SortDecisionStyle.buttonForeground)
            .clipShape(Capsule())
            .shadow(color: color.opacity(SortDecisionStyle.buttonShadowOpacity), radius: SortDecisionStyle.buttonShadowRadius, x: 0, y: SortDecisionStyle.buttonShadowY)
            .scaleEffect(configuration.isPressed ? SortDecisionStyle.buttonPressScale : 1.0)
            .animation(.easeInOut(duration: SortDecisionStyle.buttonPressAnimationDuration), value: configuration.isPressed)
    }
}

// MARK: - SortDecisionDiagramView (Internal)

struct SortDecisionDiagramView: View {
    
    let nodes: [DiagramNode]
    let edges: [DiagramEdge]
    let selectedMove: ProposedFileMove?
    
    var body: some View {
        GeometryReader { geo in
            let layout = DiagramLayout(size: geo.size, nodes: nodes, selectedMove: selectedMove)
            
            ZStack(alignment: .topLeading) {
                // 1. Edges
                edgesLayer(layout: layout)
                
                // 2. Nodes
                nodesLayer(layout: layout)
                
                // 3. File Stubs
                if let move = selectedMove {
                    fileNodesLayer(layout: layout, move: move)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(SortDecisionStyle.diagramInnerPadding)
    }
    
    // MARK: - Layers
    
    private func edgesLayer(layout: DiagramLayout) -> some View {
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
                    context.stroke(
                        path,
                        with: .color(SortDecisionStyle.edgeOriginalFileColor),
                        style: StrokeStyle(lineWidth: SortDecisionStyle.edgeOriginalFileLineWidth, dash: SortDecisionStyle.edgeOriginalFileDash)
                    )
                case .proposedFile:
                    context.stroke(path, with: .color(SortDecisionStyle.edgeProposedFileColor), lineWidth: SortDecisionStyle.edgeProposedFileLineWidth)
                }
            }
        }
    }
    
    private func nodesLayer(layout: DiagramLayout) -> some View {
        ForEach(nodes) { node in
            if let pos = layout.position(for: node.id) {
                DiagramNodeView(
                    icon: "folder.fill",
                    text: node.name,
                    baseColor: node.isAICreated ? .green : .blue,
                    isGlassy: true
                )
                .position(pos)
            }
        }
    }
    
    private func fileNodesLayer(layout: DiagramLayout, move: ProposedFileMove) -> some View {
        Group {
            if let fromPos = layout.fileOriginalPosition(move: move) {
                DiagramNodeView(
                    icon: "doc.fill",
                    text: move.fileName,
                    baseColor: .red,
                    isGhost: true
                )
                .position(fromPos)
            }
            if let toPos = layout.fileProposedPosition(move: move) {
                DiagramNodeView(
                    icon: "doc.fill",
                    text: move.fileName,
                    baseColor: .green,
                    isGhost: false
                )
                .position(toPos)
            }
        }
    }
}

// MARK: - Diagram Node View Component

struct DiagramNodeView: View {
    let icon: String
    let text: String
    let baseColor: Color
    var isGlassy: Bool = false
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

// MARK: - Diagram Layout Logic

private struct DiagramLayout {
    
    let size: CGSize
    let nodes: [DiagramNode]
    let selectedMove: ProposedFileMove?
    
    private var rootNode: DiagramNode? {
        nodes.first { $0.name == "User" }
    }
    
    private var folderNodes: [DiagramNode] {
        nodes.filter { $0.id != rootNode?.id }
    }
    
    func position(for nodeId: UUID) -> CGPoint? {
        guard let root = rootNode else { return nil }
        
        if nodeId == root.id {
            return CGPoint(x: size.width * SortDecisionStyle.diagramRootXFactor, y: size.height * SortDecisionStyle.diagramRootYFactor)
        }
        
        let folders = folderNodes
        guard let index = folders.firstIndex(where: { $0.id == nodeId }) else { return nil }
        
        let folderColumnX = size.width * SortDecisionStyle.diagramFolderColumnXFactor
        let spacingY = SortDecisionStyle.diagramFolderSpacingY
        let totalHeight = CGFloat(folders.count - 1) * spacingY
        let startY = (size.height - totalHeight) / 2
        
        let y = startY + CGFloat(index) * spacingY
        return CGPoint(x: folderColumnX, y: y)
    }
    
    func fileOriginalPosition(move: ProposedFileMove) -> CGPoint? {
        guard let rootPos = position(for: move.fromParentId) else { return nil }
        return CGPoint(x: rootPos.x + SortDecisionStyle.diagramFileOriginalOffsetX, y: rootPos.y + SortDecisionStyle.diagramFileOriginalOffsetY)
    }
    
    func fileProposedPosition(move: ProposedFileMove) -> CGPoint? {
        guard let folderPos = position(for: move.toParentId) else { return nil }
        return CGPoint(x: folderPos.x + SortDecisionStyle.diagramFileProposedOffsetX, y: folderPos.y + SortDecisionStyle.diagramFileProposedOffsetY)
    }
}

#Preview {
    SortDecisionView()
}
