import Foundation

// MARK: - File System API Models
// DTOs for GET /api/fs endpoint.

/// Response model for filesystem discovery endpoint.
/// Maps the recursive JSON structure from the backend.
struct FSNodeResponse: Codable {
    let path: String
    let name: String
    let type: String              // "file" or "directory"
    let createdAt: Date
    let sizeBytes: Int64
    let `extension`: String
    let children: [FSNodeResponse]
    
    /// Whether this node represents a directory
    var isDirectory: Bool {
        type == "directory"
    }
    
    /// Whether this node represents a file
    var isFile: Bool {
        type == "file"
    }
}

// MARK: - Mapping to Domain Models

extension FSNodeResponse {
    
    /// Converts the API response to a FolderNode tree for the graph view.
    /// Includes path and direct child files for each folder.
    func toFolderNode() -> FolderNode {
        let childFolders = children
            .filter { $0.isDirectory }
            .map { $0.toFolderNode() }
        
        let directFiles = directChildFiles()
        
        return FolderNode(name: name, path: path, children: childFolders, files: directFiles)
    }
    
    /// Converts a file node to a FileItem domain model.
    /// Returns nil if this node is a directory.
    func toFileItem() -> FileItem? {
        guard isFile else { return nil }
        
        return FileItem(
            path: path,
            name: name,
            date: createdAt,
            size: sizeBytes
        )
    }
    
    /// Extracts all files from this node and its descendants.
    func allFiles() -> [FileItem] {
        var files: [FileItem] = []
        
        if let fileItem = toFileItem() {
            files.append(fileItem)
        }
        
        for child in children {
            files.append(contentsOf: child.allFiles())
        }
        
        return files
    }
    
    /// Extracts only direct child files (not recursive).
    func directChildFiles() -> [FileItem] {
        children.compactMap { $0.toFileItem() }
    }
}
