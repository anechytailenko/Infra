import Foundation

struct PromptFile: Identifiable, Hashable {
    let id: UUID
    let fullPath: String
    let name: String
    let size: String
    var isSelected: Bool
    var isMatched: Bool
    
    init(path: String, size: String = "Unknown", isSelected: Bool = false, isMatched: Bool = false) {
        self.id = UUID()
        self.fullPath = path
        self.name = URL(fileURLWithPath: path).lastPathComponent
        self.size = size
        self.isSelected = isSelected
        self.isMatched = isMatched
    }
}
