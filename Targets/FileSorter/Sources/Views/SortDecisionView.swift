import SwiftUI

// MARK: - SortDecisionView

struct SortDecisionView: View {

    @StateObject private var viewModel = SortDecisionViewModel()

    var body: some View {
        VStack(spacing: 0) {
            topBar
            SortDecisionDiagramView(
                nodes: viewModel.diagramNodes,
                edges: viewModel.diagramEdges,
                selectedMove: viewModel.selectedMove
            )
            .frame(minHeight: 220)
            .padding()

            proposedChangesList
        }
        .frame(minWidth: 500, minHeight: 500)
    }

    // MARK: - Top Bar (Accept / Decline)

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Accept") {
                viewModel.acceptAll()
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            Button("Decline") {
                viewModel.declineAll()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Proposed Changes List

    private var proposedChangesList: some View {
        VStack(alignment: .leading, spacing: 0) {
            listHeader
            List {
                ForEach(viewModel.effectiveMoves) { move in
                    proposedMoveRow(move: move)
                }
            }
            .listStyle(.plain)
        }
    }

    private var listHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
            Text("User")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
    }

    private func proposedMoveRow(move: ProposedFileMove) -> some View {
        let isSelected = viewModel.selectedMoveId == move.id
        return HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .foregroundStyle(.secondary)
            Text(move.fileName)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("moved to: \(move.toParentName)")
                .foregroundStyle(.secondary)
            Button {
                viewModel.declineFile(id: move.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .onTapGesture {
            viewModel.selectMove(id: move.id)
        }
    }
}

// MARK: - SortDecisionDiagramView

struct SortDecisionDiagramView: View {

    let nodes: [DiagramNode]
    let edges: [DiagramEdge]
    let selectedMove: ProposedFileMove?

    var body: some View {
        GeometryReader { geo in
            let layout = DiagramLayout(size: geo.size, nodes: nodes, selectedMove: selectedMove)
            ZStack(alignment: .topLeading) {
                edgesLayer(layout: layout, size: geo.size)
                nodesLayer(layout: layout)
                if let move = selectedMove {
                    fileNodesLayer(layout: layout, move: move)
                }
            }
        }
    }

    private func edgesLayer(layout: DiagramLayout, size: CGSize) -> some View {
        Canvas { context, _ in
            for edge in edges {
                let from = layout.position(for: edge.fromId)
                let to: CGPoint? = {
                    switch edge.style {
                    case .normal:
                        return layout.position(for: edge.toId)
                    case .originalFile:
                        return selectedMove.flatMap { layout.fileOriginalPosition(move: $0) }
                    case .proposedFile:
                        return selectedMove.flatMap { layout.fileProposedPosition(move: $0) }
                    }
                }()
                guard let from = from, let to = to else { continue }
                var path = Path()
                path.move(to: from)
                path.addLine(to: to)
                switch edge.style {
                case .normal:
                    context.stroke(path, with: .color(.blue), lineWidth: 2)
                case .originalFile:
                    context.stroke(
                        path,
                        with: .color(.red),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
                case .proposedFile:
                    context.stroke(path, with: .color(.green), lineWidth: 2)
                }
            }
        }
    }

    private func nodesLayer(layout: DiagramLayout) -> some View {
        ForEach(nodes) { node in
            let pos = layout.position(for: node.id) ?? .zero
            diagramNodeView(node: node)
                .position(pos)
        }
    }

    private func fileNodesLayer(layout: DiagramLayout, move: ProposedFileMove) -> some View {
        Group {
            if let fromPos = layout.fileOriginalPosition(move: move) {
                fileNodeView(fileName: move.fileName, color: .red)
                    .position(fromPos)
            }
            if let toPos = layout.fileProposedPosition(move: move) {
                fileNodeView(fileName: move.fileName, color: .green)
                    .position(toPos)
            }
        }
    }

    private func diagramNodeView(node: DiagramNode) -> some View {
        let color: Color = node.isAICreated ? .green : .blue
        return HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .font(.title3)
            Text(node.name)
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.2))
        .foregroundStyle(color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func fileNodeView(fileName: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.fill")
                .font(.title3)
            Text(fileName)
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.2))
        .foregroundStyle(color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Diagram Layout (mock positions)

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
            return CGPoint(x: size.width / 2, y: 40)
        }
        let folders = folderNodes
        guard let index = folders.firstIndex(where: { $0.id == nodeId }) else { return nil }
        let count = max(folders.count, 1)
        let step = size.width / CGFloat(count + 1)
        let x = step * CGFloat(index + 1)
        return CGPoint(x: x, y: 100)
    }

    func fileOriginalPosition(move: ProposedFileMove) -> CGPoint? {
        guard let from = position(for: move.fromParentId) else { return nil }
        return CGPoint(x: from.x, y: from.y + 70)
    }

    func fileProposedPosition(move: ProposedFileMove) -> CGPoint? {
        guard let to = position(for: move.toParentId) else { return nil }
        return CGPoint(x: to.x, y: to.y + 70)
    }
}

// MARK: - Preview

#Preview {
    SortDecisionView()
        .frame(width: 600, height: 600)
}
