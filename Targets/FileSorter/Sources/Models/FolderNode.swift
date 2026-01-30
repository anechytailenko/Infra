import Foundation

/// Tree node for the folder graph on the home screen. Used by HomeViewModel and GraphView.
struct FolderNode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    var children: [FolderNode] = []
    /// Files directly contained in this folder (not recursive)
    var files: [FileItem] = []
    /// Whether this folder is newly created (e.g., by AI suggestion) - shown with green highlight
    var isNew: Bool = false

    init(name: String, path: String = "", children: [FolderNode] = [], files: [FileItem] = [], isNew: Bool = false) {
        self.name = name
        self.path = path
        self.children = children
        self.files = files
        self.isNew = isNew
    }
    
    // Hashable conformance (required for navigationDestination)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FolderNode, rhs: FolderNode) -> Bool {
        lhs.id == rhs.id
    }
}
