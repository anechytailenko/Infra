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
            let layoutSize = CGSize(
                width: max(geo.size.width, SortDecisionStyle.diagramMinLayoutWidth),
                height: max(geo.size.height, SortDecisionStyle.diagramMinLayoutHeight)
            )
            let graphNodes = viewModel.diagramNodes.map { node in
                GraphNodeData(
                    id: node.id,
                    label: node.name,
                    iconName: "folder.fill",
                    color: node.isAICreated ? .green : .blue,
                    isGhost: false
                )
            }
            let layout = DiagramLayout(size: layoutSize, nodes: viewModel.diagramNodes, selectedMove: viewModel.selectedMove)
            ZStack(alignment: .topLeading) {
                GraphView(
                    nodes: graphNodes,
                    edges: viewModel.diagramEdges,
                    selectedMove: viewModel.selectedMove,
                    layout: layout,
                    size: layoutSize
                )
                .scaleEffect(scale)
                .offset(x: offset.width, y: offset.height)
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

// MARK: - Diagram Layout (conforms to GraphDiagramLayout for use with GraphView)

struct DiagramLayout: GraphDiagramLayout {
    
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
        let marginH = SortDecisionStyle.diagramHorizontalMargin
        
        if nodeId == root.id {
            let x = max(marginH, size.width * SortDecisionStyle.diagramRootXFactor)
            return CGPoint(x: x, y: size.height * SortDecisionStyle.diagramRootYFactor)
        }
        
        let folders = folderNodes
        guard let index = folders.firstIndex(where: { $0.id == nodeId }) else { return nil }
        
        let folderColumnX = min(size.width - marginH, size.width * SortDecisionStyle.diagramFolderColumnXFactor)
        let marginV = SortDecisionStyle.diagramVerticalMargin
        let availableHeight = max(0, size.height - 2 * marginV)
        let count = CGFloat(folders.count)
        let spacingY = count > 1
            ? min(SortDecisionStyle.diagramFolderSpacingY, availableHeight / (count - 1))
            : 0
        let totalHeight = (count - 1) * spacingY
        let startY = marginV + max(0, (availableHeight - totalHeight) / 2)
        let y = startY + CGFloat(index) * spacingY
        return CGPoint(x: folderColumnX, y: y)
    }
    
    func fileOriginalPosition(move: ProposedFileMove) -> CGPoint? {
        guard let rootPos = position(for: move.fromParentId) else { return nil }
        let marginH = SortDecisionStyle.diagramHorizontalMargin
        let folderColumnX = min(size.width - marginH, size.width * SortDecisionStyle.diagramFolderColumnXFactor)
        let maxOffsetX = max(0, folderColumnX - rootPos.x - marginH)
        let offsetX = min(SortDecisionStyle.diagramFileOriginalOffsetX, maxOffsetX * 0.5)
        let maxOffsetY = max(0, size.height - rootPos.y - SortDecisionStyle.diagramVerticalMargin)
        let offsetY = min(SortDecisionStyle.diagramFileOriginalOffsetY, maxOffsetY * 0.6)
        return CGPoint(x: rootPos.x + offsetX, y: rootPos.y + offsetY)
    }
    
    func fileProposedPosition(move: ProposedFileMove) -> CGPoint? {
        guard let folderPos = position(for: move.toParentId) else { return nil }
        let marginH = SortDecisionStyle.diagramHorizontalMargin
        let maxOffsetX = max(0, size.width - folderPos.x - marginH)
        let offsetX = min(SortDecisionStyle.diagramFileProposedOffsetX, maxOffsetX * 0.8)
        return CGPoint(x: folderPos.x + offsetX, y: folderPos.y + SortDecisionStyle.diagramFileProposedOffsetY)
    }
}

#Preview {
    SortDecisionView()
}
