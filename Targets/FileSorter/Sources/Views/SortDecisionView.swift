import SwiftUI

// MARK: - SortDecisionView

struct SortDecisionView: View {
    
    @StateObject private var viewModel = SortDecisionViewModel()
    
    var body: some View {
        ZStack {
            // Global Background - Slightly darker gray as requested
            Color(white: 0.90)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // 1. Diagram Card
                diagramSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                
                // 2. Proposed Changes List Card
                proposedChangesList
                    .frame(height: 280) // Fixed height for consistency
                    .layoutPriority(0)
            }
            .padding(24)
        }
        .frame(minWidth: 900, minHeight: 700)
        // Auto-select first file on launch to show visual feedback immediately
        .onAppear {
            if let firstMove = viewModel.effectiveMoves.first {
                viewModel.selectMove(id: firstMove.id)
            }
        }
    }
    
    // MARK: - Diagram Section
    
    private var diagramSection: some View {
        ZStack(alignment: .topTrailing) {
            // The Graph with Drag Gesture
            SortDecisionDiagramView(
                nodes: viewModel.diagramNodes,
                edges: viewModel.diagramEdges,
                selectedMove: viewModel.selectedMove
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Floating Action Buttons
            HStack(spacing: 12) {
                Button("Accept") {
                    viewModel.acceptAll()
                }
                .buttonStyle(NiceButtonStyle(color: .blue))
                
                Button("Decline") {
                    viewModel.declineAll()
                }
                .buttonStyle(NiceButtonStyle(color: .gray))
            }
            .padding(20)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Proposed Changes List Section
    
    private var proposedChangesList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // List Header
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
                Text("User")
                    .font(.system(.headline, design: .default)) // Sans-serif
                    .foregroundStyle(.black) // Explicit Black
                Spacer()
            }
            .padding()
            .background(Color.white)
            
            Divider()
            
            // List Content
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.effectiveMoves.isEmpty {
                        Text("No pending moves")
                            .foregroundStyle(.gray)
                            .padding()
                    } else {
                        ForEach(viewModel.effectiveMoves) { move in
                            ProposedMoveRow(
                                move: move,
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

// MARK: - Subview: Proposed Move Row (Handles Hover & Text Color)

struct ProposedMoveRow: View {
    let move: ProposedFileMove
    let isSelected: Bool
    let onSelect: () -> Void
    let onDecline: () -> Void
    
    // State for hover effect on the decline button
    @State private var isHoveringDecline = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .foregroundStyle(.gray)
                .font(.title3)
            
            // Explicitly Black Text for visibility on White background
            Text(move.fileName)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("moved to: \(move.toParentName)")
                .font(.system(size: 14, design: .default))
                .foregroundStyle(Color(white: 0.4)) // Dark Gray
            
            // Decline Button with Hover Effect
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
        .background(isSelected ? Color.blue.opacity(0.1) : Color.white)
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
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - SortDecisionDiagramView

struct SortDecisionDiagramView: View {
    
    let nodes: [DiagramNode]
    let edges: [DiagramEdge]
    let selectedMove: ProposedFileMove?
    
    // State for Draggable Tree
    @State private var offset: CGSize = .zero
    @State private var lastDragPosition: CGSize = .zero
    
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
            // Apply the drag offset to the whole tree container
            .offset(x: offset.width, y: offset.height)
            .contentShape(Rectangle()) // Ensures the empty space is draggable
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = CGSize(
                            width: lastDragPosition.width + value.translation.width,
                            height: lastDragPosition.height + value.translation.height
                        )
                    }
                    .onEnded { value in
                        lastDragPosition = offset
                    }
            )
        }
        .padding(40)
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
        // Solid white background to hide lines behind nodes
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

// MARK: - Diagram Layout (Left-to-Right)

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
