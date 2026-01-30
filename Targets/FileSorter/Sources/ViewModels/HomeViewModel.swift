import Foundation
import Combine

// MARK: - HomeViewModel
// View model for HomeView. Owns folder tree, search state, and navigation intent (folder detail / search results).
// Fetches filesystem from backend API via HTTPClient.

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published state

    /// Root of the folder tree shown in the graph.
    @Published var rootNode: FolderNode
    
    /// The current filesystem path being displayed
    @Published var currentPath: String = ""
    
    /// Raw API response for the filesystem (used by detail views)
    @Published var filesystemResponse: FSNodeResponse?

    /// Search bar text; two-way binding from HomeView.
    @Published var searchQuery: String = ""

    /// Selected folder in the graph; non-nil drives navigation to FolderDetailView.
    @Published var selectedFolder: FolderNode?

    /// Non-nil when user has submitted search and we should push the search-results screen.
    @Published var searchResultsQuery: String?
    
    // MARK: - Loading & Error State
    
    /// True while loading filesystem from API
    @Published var isLoading: Bool = false
    
    /// Error message to display (nil if no error)
    @Published var errorMessage: String?
    
    /// Whether to show an alert for critical errors
    @Published var showErrorAlert: Bool = false
    
    // MARK: - Dependencies
    
    private let httpClient: HTTPClient
    
    // MARK: - Initialization

    init(httpClient: HTTPClient = URLSessionHTTPClient.shared) {
        self.httpClient = httpClient
        self.rootNode = FolderNode(name: "Loading...", children: [])
    }
    
    // MARK: - API Actions
    
    /// Fetches the filesystem tree from the backend.
    /// - Parameter path: The absolute path on the host to scan (e.g., "/Users/jdoe/Downloads")
    func fetchFilesystem(path: String) async {
        isLoading = true
        errorMessage = nil
        currentPath = path
        
        do {
            let response: FSNodeResponse = try await httpClient.get(
                endpoint: APIConfiguration.Endpoints.filesystem,
                queryParams: ["path": path]
            )
            
            filesystemResponse = response
            rootNode = response.toFolderNode()
            isLoading = false
            
        } catch let error as APIError {
            isLoading = false
            errorMessage = error.errorDescription
            showErrorAlert = error.isCritical
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    /// Retry fetching with the last used path
    func retryFetch() async {
        guard !currentPath.isEmpty else { return }
        await fetchFilesystem(path: currentPath)
    }
    
    /// Refresh filesystem from backend. Uses last path if available, otherwise default.
    /// Call when HomeView appears so the backend is polled every time the user opens home.
    func refreshOnAppear() async {
        let path = currentPath.isEmpty ? APIConfiguration.defaultFilesystemPath : currentPath
        await fetchFilesystem(path: path)
    }
    
    /// Clears the current error state
    func dismissError() {
        errorMessage = nil
        showErrorAlert = false
    }
    
    // MARK: - Data Availability
    
    /// True when filesystem data has been successfully loaded from the API.
    /// Folders are only clickable when this is true.
    var isDataAvailable: Bool {
        filesystemResponse != nil
    }

    // MARK: - Navigation Actions

    /// Called when the user taps a folder in the graph. Sets selectedFolder to drive navigation.
    func selectFolder(_ node: FolderNode?) {
        selectedFolder = node
    }

    /// Called when the user submits the search bar. Pushes search-results screen (stub for now).
    func submitSearch() {
        searchResultsQuery = searchQuery
    }

    /// Called when folder detail is dismissed. Clears selection so we pop.
    func clearFolderSelection() {
        selectedFolder = nil
    }

    /// Called when search results screen is dismissed.
    func clearSearchResults() {
        searchResultsQuery = nil
    }
}
