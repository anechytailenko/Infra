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
    /// Includes directories as children and files as FileItems.
    func toFolderNode() -> FolderNode {
        let childFolders = children
            .filter { $0.isDirectory }
            .map { $0.toFolderNode() }
        
        let childFiles = directChildFiles()
        
        // #region agent log
        let logData: [String: Any] = ["sessionId": "debug-session", "runId": "run1", "hypothesisId": "A", "location": "FileSystemAPIModels.swift:toFolderNode", "message": "Converting FSNodeResponse to FolderNode", "data": ["name": name, "path": path, "childFoldersCount": childFolders.count, "childFilesCount": childFiles.count], "timestamp": Date().timeIntervalSince1970 * 1000]
        if let jsonData = try? JSONSerialization.data(withJSONObject: logData), let jsonString = String(data: jsonData, encoding: .utf8) {
            let logPath = "/Users/hermanhavva/Documents/Personal/projects/FileSorterApp/.cursor/debug.log"
            if let handle = FileHandle(forWritingAtPath: logPath) {
                handle.seekToEndOfFile()
                handle.write((jsonString + "\n").data(using: .utf8)!)
                handle.closeFile()
            } else {
                FileManager.default.createFile(atPath: logPath, contents: (jsonString + "\n").data(using: .utf8))
            }
        }
        // #endregion
        
        return FolderNode(name: name, path: path, children: childFolders, files: childFiles)
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
