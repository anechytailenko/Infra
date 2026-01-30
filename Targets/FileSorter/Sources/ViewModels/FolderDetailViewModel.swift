import Foundation
import Combine

// MARK: - FolderDetailViewModel (Stub)
// Stub: replace with real folder detail loading. init(folder:) will drive loading of file contents for that folder.
// Filter and sort are in-memory stubs over the stub files array.

final class FolderDetailViewModel: ObservableObject {
    
    /// Folder selected from HomeView; later used to load file contents.
    let folder: FolderNode?
    
    @Published var files: [FileItem] = []
    @Published var history: [HistoryItem] = []
    @Published var filterOption: FilterOption = .all
    @Published var sortOption: SortOption = .name
    @Published var showFiles: Bool = true
    @Published var showFolders: Bool = true
    
    /// Stub tree for GraphView (same structure as legacy User/Desktop/Downloads/Files).
    let folderGraphRoot: FolderNode
    
    init(folder: FolderNode? = nil) {
        self.folder = folder
        self.folderGraphRoot = Self.makeStubGraphTree()
        self.files = Self.makeStubFiles()
        self.history = Self.makeStubHistory()
    }
    
    private static func makeStubGraphTree() -> FolderNode {
        FolderNode(name: "User", children: [
            FolderNode(name: "Desktop"),
            FolderNode(name: "Downloads"),
            FolderNode(name: "Files")
        ])
    }
    
    private static func makeStubFiles() -> [FileItem] {
        [
            FileItem(path: "/User/Desktop", name: "IMG_8032.heic", date: Date(), size: 1400000),
            FileItem(path: "/User/Downloads", name: "IMG_8031.heic", date: Date().addingTimeInterval(-300), size: 1300000),
            FileItem(path: "/User/Docs", name: "Gemini_Generated.png", date: Date().addingTimeInterval(-1200), size: 1900000)
        ]
    }
    
    private static func makeStubHistory() -> [HistoryItem] {
        [
            HistoryItem(status: "sorted", date: "Today at 19:05", isSuccess: true),
            HistoryItem(status: "sorted", date: "Today at 18:59", isSuccess: true),
            HistoryItem(status: "sorted", date: "Today at 18:37", isSuccess: true)
        ]
    }
    
    /// Filtered and sorted file list (stub: in-memory filter by showFiles/kind, then sort).
    var filteredAndSortedFiles: [FileItem] {
        var list: [FileItem] = []
        if showFiles {
            switch filterOption {
            case .all: list = files
            case .images: list = files.filter { $0.kind == .image }
            case .documents: list = files.filter { $0.kind == .document }
            case .archives: list = files.filter { $0.kind == .archive }
            }
        }
        switch sortOption {
        case .name: return list.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .date: return list.sorted { $0.date > $1.date }
        case .size: return list.sorted { $0.size < $1.size }
        }
    }
    
    func setFilter(_ option: FilterOption) {
        filterOption = option
    }
    
    func setSort(_ option: SortOption) {
        sortOption = option
    }
    
    func toggleShowFiles() {
        showFiles.toggle()
    }
    
    func toggleShowFolders() {
        showFolders.toggle()
    }
    
    /// Revert the last history entry (stub: remove last item if any).
    func revertLast() {
        guard !history.isEmpty else { return }
        history = Array(history.dropLast())
    }
}
