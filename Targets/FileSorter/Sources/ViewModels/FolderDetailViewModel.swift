import Foundation
import Combine

// MARK: - FolderDetailViewModel
// View model for FolderDetailView. Manages file list, history, filters, and AI sort operations.
// Calls POST /api/ai/suggest when AI Sort is triggered.

@MainActor
final class FolderDetailViewModel: ObservableObject {
    
    /// Folder selected from HomeView; used to derive the root directory path.
    let folder: FolderNode?
    
    /// The root directory path for API calls (derived from folder or filesystem response).
    var rootDirectoryPath: String = ""
    
    @Published var files: [FileItem] = []
    @Published var history: [HistoryItem] = []
    @Published var filterOption: FilterOption = .all
    @Published var sortOption: SortOption = .name
    @Published var showFiles: Bool = true
    @Published var showFolders: Bool = true
    
    // MARK: - AI Sort State
    
    /// True while the AI sort request is in progress (loading overlay visible).
    @Published var isSortingInProgress: Bool = false
    /// Set to true when loading completes successfully; drives programmatic navigation to SortDecisionView.
    @Published var shouldNavigateToSortDecision: Bool = false
    /// The AI suggestions response (passed to SortDecisionView).
    @Published var aiSuggestionsResponse: AISuggestResponse?
    /// Cancellable task for the AI sort operation.
    private var sortTask: Task<Void, Never>?
    
    // MARK: - Error State
    
    /// Error message to display (nil if no error)
    @Published var errorMessage: String?
    /// Whether to show an alert for critical errors
    @Published var showErrorAlert: Bool = false
    
    // MARK: - Dependencies
    
    private let httpClient: HTTPClient
    
    /// Folder tree for GraphView (derived from the selected folder).
    @Published var folderGraphRoot: FolderNode
    
    init(folder: FolderNode? = nil, httpClient: HTTPClient = URLSessionHTTPClient.shared) {
        self.folder = folder
        self.httpClient = httpClient
        // Use the folder itself as the graph root, or an empty placeholder
        self.folderGraphRoot = folder ?? FolderNode(name: "No folder selected", children: [])
        // Populate files from the folder
        self.files = folder?.files ?? []
        // Set root directory path for API calls
        self.rootDirectoryPath = folder?.path ?? ""
        
        // #region agent log
        let logData: [String: Any] = ["sessionId": "debug-session", "runId": "run1", "hypothesisId": "E", "location": "FolderDetailViewModel.swift:init", "message": "FolderDetailViewModel initialized", "data": ["folderName": folder?.name ?? "nil", "folderPath": folder?.path ?? "nil", "filesCount": self.files.count, "childrenCount": folder?.children.count ?? 0], "timestamp": Date().timeIntervalSince1970 * 1000]
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
    }
    
    /// Initialize with a specific root directory path (for when coming from HomeView with API data)
    convenience init(folder: FolderNode?, rootDirectoryPath: String, httpClient: HTTPClient = URLSessionHTTPClient.shared) {
        self.init(folder: folder, httpClient: httpClient)
        self.rootDirectoryPath = rootDirectoryPath
    }
    
    /// Filtered and sorted file list (in-memory filter by showFiles/kind, then sort).
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
    
    /// Child folders (subfolders) of the current folder, filtered by showFolders toggle.
    var filteredChildFolders: [FolderNode] {
        guard showFolders else { return [] }
        let children = folder?.children ?? []
        switch sortOption {
        case .name: return children.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .date, .size: return children // Folders don't have date/size, keep original order
        }
    }
    
    /// True if the folder items list is empty (no files and no folders to display)
    var isFolderItemsEmpty: Bool {
        filteredAndSortedFiles.isEmpty && filteredChildFolders.isEmpty
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
    
    /// Revert the most recent history entry (first item in the list).
    func revertLast() {
        guard !history.isEmpty else { return }
        history = Array(history.dropFirst())
    }
    
    /// Clears the current error state
    func dismissError() {
        errorMessage = nil
        showErrorAlert = false
    }
    
    // MARK: - AI Sort Actions
    
    /// Start the AI sort operation. Calls POST /api/ai/suggest and navigates to SortDecisionView on success.
    func startAISort() {
        guard !isSortingInProgress else { return }
        isSortingInProgress = true
        shouldNavigateToSortDecision = false
        errorMessage = nil
        
        sortTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let request = AISuggestRequest(rootDirectory: self.rootDirectoryPath)
                let response: AISuggestResponse = try await self.httpClient.post(
                    endpoint: APIConfiguration.Endpoints.aiSuggest,
                    body: request
                )
                
                guard !Task.isCancelled else { return }
                
                self.aiSuggestionsResponse = response
                self.isSortingInProgress = false
                self.shouldNavigateToSortDecision = true
                
                // Add to history on successful sort
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "'Today at' HH:mm"
                let historyItem = HistoryItem(
                    status: "sorted",
                    date: dateFormatter.string(from: Date()),
                    isSuccess: response.isSuccess
                )
                self.history.insert(historyItem, at: 0)
                
            } catch let error as APIError {
                guard !Task.isCancelled else { return }
                
                self.isSortingInProgress = false
                self.errorMessage = error.errorDescription
                self.showErrorAlert = error.isCritical
                
            } catch {
                guard !Task.isCancelled else { return }
                
                self.isSortingInProgress = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }
    
    /// Cancel the AI sort operation. Hides the loading overlay and stays on FolderDetailView.
    func cancelAISort() {
        sortTask?.cancel()
        sortTask = nil
        isSortingInProgress = false
        shouldNavigateToSortDecision = false
    }
}
