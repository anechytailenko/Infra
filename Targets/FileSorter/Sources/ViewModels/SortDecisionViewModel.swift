import Foundation
import Combine

// MARK: - SortDecisionViewModel (mocked)

final class SortDecisionViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var proposedMoves: [ProposedFileMove]
    @Published var selectedMoveId: UUID?
    @Published private(set) var diagramNodes: [DiagramNode]
    @Published private(set) var diagramEdges: [DiagramEdge]

    // MARK: - Init (mock data)

    init() {
        let rootId = UUID()
        let imgId = UUID()
        let desktopId = UUID()
        let filesId = UUID()

        let rootNode = DiagramNode(id: rootId, name: "User", isFolder: true, isAICreated: false)
        let imgNode = DiagramNode(id: imgId, name: "Img", isFolder: true, isAICreated: false)
        let desktopNode = DiagramNode(id: desktopId, name: "Desktop", isFolder: true, isAICreated: false)
        let filesNode = DiagramNode(id: filesId, name: "Files", isFolder: true, isAICreated: true)

        self.diagramNodes = [rootNode, imgNode, desktopNode, filesNode]

        let normalEdges = [
            DiagramEdge(fromId: rootId, toId: imgId, style: .normal),
            DiagramEdge(fromId: rootId, toId: desktopId, style: .normal),
            DiagramEdge(fromId: rootId, toId: filesId, style: .normal)
        ]

        self.diagramEdges = normalEdges

        self.proposedMoves = [
            ProposedFileMove(fileName: "file_01", fromParentId: rootId, fromParentName: "User", toParentId: imgId, toParentName: "Img"),
            ProposedFileMove(fileName: "file_02", fromParentId: rootId, fromParentName: "User", toParentId: desktopId, toParentName: "Desktop"),
            ProposedFileMove(fileName: "file_03", fromParentId: rootId, fromParentName: "User", toParentId: filesId, toParentName: "Files"),
            ProposedFileMove(fileName: "file_04", fromParentId: rootId, fromParentName: "User", toParentId: imgId, toParentName: "Img"),
            ProposedFileMove(fileName: "file_05", fromParentId: rootId, fromParentName: "User", toParentId: desktopId, toParentName: "Desktop"),
            ProposedFileMove(fileName: "file_06", fromParentId: rootId, fromParentName: "User", toParentId: filesId, toParentName: "Files")
        ]

        self.selectedMoveId = nil
        rebuildDiagramEdges()
    }

    // MARK: - Actions

    func acceptAll() {
        // Placeholder: in real flow would apply moves
    }

    func declineAll() {
        proposedMoves = proposedMoves.map { move in
            var m = move
            m.isDeclined = true
            return m
        }
        selectedMoveId = nil
        rebuildDiagramEdges()
    }

    func declineFile(id: UUID) {
        proposedMoves = proposedMoves.map { move in
            guard move.id == id else { return move }
            var m = move
            m.isDeclined = true
            return m
        }
        if selectedMoveId == id {
            selectedMoveId = nil
        }
        rebuildDiagramEdges()
    }

    func selectMove(id: UUID?) {
        selectedMoveId = id
        rebuildDiagramEdges()
    }

    // MARK: - Helpers

    var selectedMove: ProposedFileMove? {
        guard let id = selectedMoveId else { return nil }
        return proposedMoves.first { $0.id == id && !$0.isDeclined }
    }

    var effectiveMoves: [ProposedFileMove] {
        proposedMoves.filter { !$0.isDeclined }
    }

    private func rebuildDiagramEdges() {
        let rootId = diagramNodes.first { $0.name == "User" }?.id ?? UUID()
        var edges: [DiagramEdge] = diagramNodes
            .filter { $0.id != rootId }
            .map { DiagramEdge(fromId: rootId, toId: $0.id, style: .normal) }

        if let move = selectedMove {
            edges.append(DiagramEdge(fromId: move.fromParentId, toId: move.id, style: .originalFile))
            edges.append(DiagramEdge(fromId: move.toParentId, toId: move.id, style: .proposedFile))
        }

        diagramEdges = edges
    }
}
