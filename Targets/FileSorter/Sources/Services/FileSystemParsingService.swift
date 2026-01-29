import Foundation

// 1. The Protocol (The Contract)
protocol FileSystemParsingService {
    func loadData() -> FileSystemNode?
}

// 2. The Implementation (The CSV Parser)
// Note: We removed 'static' so this can be instantiated.
class MockCSVParser: FileSystemParsingService {
    
    // We inject the AI service here, so the Parser doesn't create it internally.
    private let aiService: ContentGeneratorService
    
    init(aiService: ContentGeneratorService = MockAIContentGenerator()) {
        self.aiService = aiService
    }
    
    func loadData() -> FileSystemNode? {
        guard let url = Bundle.main.url(forResource: "mock_filesystem", withExtension: "txt") else { return nil }
        
        do {
            let content = try String(contentsOf: url)
            let lines = content.components(separatedBy: .newlines)
            // Call the private helper
            return parse(lines: lines)
        } catch {
            return nil
        }
    }
    
    // Logic remains exactly the same, just removed 'static'
    private func parse(lines: [String]) -> FileSystemNode? {
        var nodeMap: [String: FileSystemNode] = [:]
        var folderMap: [String: FolderItem] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for line in lines where !line.isEmpty {
            let parts = line.components(separatedBy: ",")
            if parts.count < 5 { continue }
            
            let path = parts[0].trimmingCharacters(in: .whitespaces)
            let typeStr = parts[1].trimmingCharacters(in: .whitespaces)
            let name = parts[2].trimmingCharacters(in: .whitespaces)
            let size = Int64(parts[3]) ?? 0
            let date = dateFormatter.date(from: parts[4]) ?? Date()
            
            if typeStr == "folder" {
                let folder = FolderItem(path: path, name: name, date: date, children: [])
                folderMap[path] = folder
                nodeMap[path] = .folder(folder)
            } else {
                let generatedContent = aiService.generateDescription(for: name)
                let file = FileItem(path: path, name: name, date: date, size: size, content: generatedContent)
                nodeMap[path] = .file(file)
            }
        }
        
        var root: FileSystemNode?
        let allPaths = Array(nodeMap.keys)
        
        for path in allPaths {
            guard let currentNode = nodeMap[path] else { continue }
            if path == "/Root" { root = currentNode; continue }
            
            let parentPath = (path as NSString).deletingLastPathComponent
            if var parentFolder = folderMap[parentPath] {
                parentFolder.children.append(currentNode)
                folderMap[parentPath] = parentFolder
                nodeMap[parentPath] = .folder(parentFolder)
            }
        }
        return nodeMap["/Root"]
    }
}
