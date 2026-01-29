import Foundation

struct FolderItem: Identifiable, Hashable {
    let id: UUID
    let path: String
    let name: String
    let date: Date
    
    // Hierarchy Logic
    var children: [FileSystemNode]
    
    init(
        id: UUID = UUID(),
        path: String,
        name: String,
        date: Date,
        children: [FileSystemNode] = []
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.date = date
        self.children = children
    }
}
