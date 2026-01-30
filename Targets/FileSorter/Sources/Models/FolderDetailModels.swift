import Foundation

// MARK: - HistoryItem
// Represents a single history entry in FolderDetailView (e.g. "sorted" at a given date).

struct HistoryItem: Identifiable {
    let id = UUID()
    let status: String
    let date: String
    let isSuccess: Bool
}

// MARK: - SimpleNode
// Legacy tree node; folder-detail graph now uses FolderNode. Kept for any non-graph use.

struct SimpleNode: Identifiable {
    let id = UUID()
    let name: String
    var children: [SimpleNode] = []
}

// MARK: - FilterOption
// Filter for file list by kind.

enum FilterOption: String, CaseIterable {
    case all = "All"
    case images = "Images"
    case documents = "Documents"
    case archives = "Archives"
}

// MARK: - SortOption
// Sort order for file list.

enum SortOption: String, CaseIterable {
    case name = "Name"
    case date = "Date"
    case size = "Size"
}
