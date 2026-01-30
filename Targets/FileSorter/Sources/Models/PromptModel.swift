import Foundation

struct PromptFile: Identifiable, Hashable {
    let id: UUID
    let fullPath: String // Kept for reference/logic, but not displayed
    let name: String     // Display name (extracted from path)
    let size: String
    var isSelected: Bool
    var isMatched: Bool
    
    init(path: String, size: String = "Unknown", isSelected: Bool = false, isMatched: Bool = false) {
        self.id = UUID()
        self.fullPath = path
        // Logic: Extract "report.pdf" from "/documents/report.pdf"
        self.name = URL(fileURLWithPath: path).lastPathComponent
        self.size = size
        self.isSelected = isSelected
        self.isMatched = isMatched
    }
}
