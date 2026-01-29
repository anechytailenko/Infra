import Foundation

// MARK: - Classification Enum

enum FileKind: String, Codable, Hashable {
    case document
    case image
    case archive
}

// MARK: - The Node Wrapper
// This is the "Container" that allows arrays to hold both Files and Folders.

enum FileSystemNode: Identifiable, Hashable {
    case file(FileItem)
    case folder(FolderItem)
    
    var id: UUID {
        switch self {
        case .file(let item): return item.id
        case .folder(let item): return item.id
        }
    }
    
    var name: String {
        switch self {
        case .file(let item): return item.name
        case .folder(let item): return item.name
        }
    }
}
