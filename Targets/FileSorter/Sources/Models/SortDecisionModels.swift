import Foundation

// MARK: - File Row Display (for FileMoveListView)

struct FileRowDisplay: Identifiable {
    let id: UUID
    let fileName: String
    let destination: String?
    
    init(id: UUID = UUID(), fileName: String, destination: String?) {
        self.id = id
        self.fileName = fileName
        self.destination = destination
    }
}

// MARK: - Proposed File Move (list row + diagram from/to)

struct ProposedFileMove: Identifiable, Hashable {
    let id: UUID
    let fileName: String
    let fromParentId: UUID
    let fromParentName: String
    let toParentId: UUID
    let toParentName: String
    var isDeclined: Bool

    init(
        id: UUID = UUID(),
        fileName: String,
        fromParentId: UUID,
        fromParentName: String,
        toParentId: UUID,
        toParentName: String,
        isDeclined: Bool = false
    ) {
        self.id = id
        self.fileName = fileName
        self.fromParentId = fromParentId
        self.fromParentName = fromParentName
        self.toParentId = toParentId
        self.toParentName = toParentName
        self.isDeclined = isDeclined
    }
    
    /// Converts to FileRowDisplay for use in FileMoveListView.
    /// Returns nil destination if the move is declined.
    func toFileRowDisplay() -> FileRowDisplay {
        FileRowDisplay(
            id: self.id,
            fileName: self.fileName,
            destination: self.isDeclined ? nil : self.toParentName
        )
    }
}

// MARK: - Diagram Node (root + folders; files shown only for selected move)

struct DiagramNode: Identifiable, Hashable {
    let id: UUID
    let name: String
    let isFolder: Bool
    let isAICreated: Bool

    init(id: UUID = UUID(), name: String, isFolder: Bool, isAICreated: Bool = false) {
        self.id = id
        self.name = name
        self.isFolder = isFolder
        self.isAICreated = isAICreated
    }
}

// MARK: - Diagram Edge (tree + selected file original/proposed)

enum DiagramEdgeStyle: Hashable {
    case normal           // blue solid
    case originalFile     // red dashed
    case proposedFile     // green solid
}

struct DiagramEdge: Identifiable, Hashable {
    let id: UUID
    let fromId: UUID
    let toId: UUID
    let style: DiagramEdgeStyle

    init(id: UUID = UUID(), fromId: UUID, toId: UUID, style: DiagramEdgeStyle) {
        self.id = id
        self.fromId = fromId
        self.toId = toId
        self.style = style
    }
}
