import SwiftUI

// MARK: - SortDecisionView

struct SortDecisionView: View {
    
    @StateObject private var viewModel = SortDecisionViewModel()
    
    var body: some View {
        ZStack {
            // Global Background (Darker Gray as requested)
            Color(white: 0.90)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                
                // 1. Top Control Bar (Buttons outside the tree view)
                topControlBar
                
                // 2. Diagram Card (Zoomable & Draggable)
                diagramSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                
                // 3. Proposed Changes List Card
                proposedChangesList
                    .frame(height: 280)
                    .layoutPriority(0)
            }
            .padding(24)
        }
        .frame(minWidth: 900, minHeight: 750)
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
            .buttonStyle(NiceButtonStyle(color: .blue))
            
            Button("Decline") {
                viewModel.declineAll()
            }
            .buttonStyle(NiceButtonStyle(color: .gray))
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
                                scale = max(0.5, min(3.0, newScale))
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white) // Card Background
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Proposed Changes List Section
    
    private var proposedChangesList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
                Text("User")
                    .font(.system(.headline, design: .default))
                    .foregroundStyle(.black)
                Spacer()
            }
            .padding()
            .background(Color.white)
            .zIndex(1) // Ensure header sits on top of scrolling content
            
            // Distinct Separator Line
            Divider()
                .overlay(Color.black.opacity(0.1))
            
            // List Content
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.effectiveMoves.isEmpty {
                        Text("No pending moves")
                            .foregroundStyle(.gray)
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
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
                Color.blue.opacity(0.1)
            } else {
                index % 2 == 0 ? Color.white : Color(white: 0.97)
            }
            
            // Content
            HStack(spacing: 12) {
                // Left: Icon + Filename
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.gray)
                        .font(.title3)
                    
                    Text(move.fileName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black)
                }
                
                Spacer()
                
                // Right: Decline Button
                Button {
                    withAnimation { onDecline() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(isHoveringDecline ? Color.red : Color.gray.opacity(0.5))
                        .scaleEffect(isHoveringDecline ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isHoveringDecline)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringDecline = hovering
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Center Layer: "Moved To" property
            // We use a ZStack layer to ensure it is perfectly centered in the row
            Text("moved to: \(move.toParentName)")
                .font(.system(size: 14))
                .foregroundStyle(Color.gray)
                .allowsHitTesting(false) // Let clicks pass through to the row
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
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
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 24) // Slightly wider buttons
            .padding(.vertical, 10)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
        // Increase padding inside the scalable area so nodes aren't cut off easily
        .padding(100)
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
                let control1 = CGPoint(x: start.x + deltaX * 0.5, y: start.y)
                let control2 = CGPoint(x: end.x - deltaX * 0.5, y: end.y)
                
                path.addCurve(to: end, control1: control1, control2: control2)
                
                switch edge.style {
                case .normal:
                    context.stroke(path, with: .color(.blue.opacity(0.4)), lineWidth: 2)
                case .originalFile:
                    context.stroke(
                        path,
                        with: .color(.red.opacity(0.6)),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 5])
                    )
                case .proposedFile:
                    context.stroke(path, with: .color(.green), lineWidth: 2)
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
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            ZStack {
                Color.white
                if !isGhost {
                    baseColor.opacity(0.15)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isGhost ? baseColor.opacity(0.5) : baseColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: isGhost ? [4, 4] : []))
        )
        .foregroundStyle(baseColor)
        .shadow(color: baseColor.opacity(isGhost ? 0.0 : 0.15), radius: 6, x: 0, y: 3)
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
            return CGPoint(x: size.width * 0.2, y: size.height * 0.5)
        }
        
        let folders = folderNodes
        guard let index = folders.firstIndex(where: { $0.id == nodeId }) else { return nil }
        
        let folderColumnX = size.width * 0.6
        let spacingY: CGFloat = 100
        let totalHeight = CGFloat(folders.count - 1) * spacingY
        let startY = (size.height - totalHeight) / 2
        
        let y = startY + CGFloat(index) * spacingY
        return CGPoint(x: folderColumnX, y: y)
    }
    
    func fileOriginalPosition(move: ProposedFileMove) -> CGPoint? {
        guard let rootPos = position(for: move.fromParentId) else { return nil }
        return CGPoint(x: rootPos.x + 40, y: rootPos.y + 70)
    }
    
    func fileProposedPosition(move: ProposedFileMove) -> CGPoint? {
        guard let folderPos = position(for: move.toParentId) else { return nil }
        return CGPoint(x: folderPos.x + 160, y: folderPos.y)
    }
}

#Preview {
    SortDecisionView()
}
