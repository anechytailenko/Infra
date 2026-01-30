import Foundation

/// Tree node for the folder graph on the home screen. Used by HomeViewModel and GraphView.
struct FolderNode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    var isNew: Bool = false
    var children: [FolderNode] = []
    /// Files directly contained in this folder (not recursive)
    var files: [FileItem] = []
    
    init(name: String, path: String = "", isNew: Bool = false, children: [FolderNode] = [], files: [FileItem] = []) {
        self.name = name
        self.path = path
        self.isNew = isNew
        self.children = children
        self.files = files
    }
    
    // Hashable conformance (required for navigationDestination)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FolderNode, rhs: FolderNode) -> Bool {
        lhs.id == rhs.id
    }
}
