import Foundation

struct FileItem: Identifiable, Hashable {
    let id: UUID
    let path: String
    let name: String
    let date: Date
    let size: Int64
    
    // Added: The content used for AI processing
    var content: String?
    
    // Domain Logic
    let typeExtension: String
    let kind: FileKind
    
    init(
        id: UUID = UUID(),
        path: String,
        name: String,
        date: Date,
        size: Int64,
        content: String? = nil // Optional, defaults to empty/nil
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.date = date
        self.size = size
        self.content = content
        
        // 1. Extract Extension
        if let extensionRange = name.range(of: ".", options: .backwards) {
            self.typeExtension = String(name[extensionRange.upperBound...]).lowercased()
        } else {
            self.typeExtension = ""
        }
        
        // 2. Detect Kind
        self.kind = FileItem.detectKind(from: self.typeExtension)
    }
    
    // Static helper for classification
    static func detectKind(from extensionString: String) -> FileKind {
        let images = ["png", "jpg", "jpeg", "svg", "gif", "bmp", "heic"]
        let archives = ["zip", "rar", "tar", "gz", "7z"]
        
        if images.contains(extensionString) { return .image }
        if archives.contains(extensionString) { return .archive }
        return .document
    }
}
