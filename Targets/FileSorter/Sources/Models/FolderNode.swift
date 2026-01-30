import Foundation

/// Tree node for the folder graph. Used by HomeViewModel, PromptViewModel, and GraphView.
struct FolderNode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    var children: [FolderNode] = []
    var files: [FileItem] = []
    var isMatched: Bool = false
    
    init(name: String, path: String = "", children: [FolderNode] = [], files: [FileItem] = [], isMatched: Bool = false) {
        self.name = name
        self.path = path
        self.children = children
        self.files = files
        self.isMatched = isMatched
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FolderNode, rhs: FolderNode) -> Bool {
        lhs.id == rhs.id
    }
}
