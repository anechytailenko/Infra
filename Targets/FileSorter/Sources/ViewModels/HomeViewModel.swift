import Foundation
import Combine

// MARK: - Prompt Navigation Item
// Drives navigation to PromptView with query and matched file paths.

struct PromptNavigationItem: Identifiable, Hashable {
    let id = UUID()
    let query: String
    let matchedFiles: [String]
}

// MARK: - HomeViewModel
// View model for HomeView. Owns folder tree, search state, and navigation intent (folder detail / search results / prompt).
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
    
    /// Non-nil when prompt API succeeded; drives navigation to PromptView.
    @Published var promptNavigationItem: PromptNavigationItem?
    
    // MARK: - Loading & Error State
    
    /// True while loading filesystem from API
    @Published var isLoading: Bool = false
    
    /// Error message to display (nil if no error)
    @Published var errorMessage: String?
    
    /// Whether to show an alert for critical errors
    @Published var showErrorAlert: Bool = false
    
    /// True while prompt API is in progress.
    @Published var isPromptLoading: Bool = false
    
    /// Error message from prompt API (nil if none).
    @Published var promptErrorMessage: String?
    
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
            
            // Show stub data on error for development
            rootNode = Self.makeStubTree()
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showErrorAlert = true
            
            // Show stub data on error for development
            rootNode = Self.makeStubTree()
        }
    }
    
    /// Retry fetching with the last used path
    func retryFetch() async {
        guard !currentPath.isEmpty else { return }
        await fetchFilesystem(path: currentPath)
    }
    
    /// Fetches the filesystem when the home view appears. Uses the default path on first load, or the last path when returning.
    func refreshOnAppear() async {
        let path = currentPath.isEmpty ? APIConfiguration.defaultFilesystemPath : currentPath
        await fetchFilesystem(path: path)
    }
    
    /// Clears the current error state
    func dismissError() {
        errorMessage = nil
        showErrorAlert = false
    }

    // MARK: - Stub Data (fallback)
    
    private static func makeStubTree() -> FolderNode {
        FolderNode(name: "Root", children: [
            FolderNode(name: "Project_Docs", children: [
                FolderNode(name: "Client_Reports", children: [
                    FolderNode(name: "Client_Report_Q1"),
                    FolderNode(name: "Client_Report_Q2")
                ]),
                FolderNode(name: "Shared_Assets", children: [
                    FolderNode(name: "Eiomnal_Assets", children: [
                        FolderNode(name: "Source_Files")
                    ]),
                    FolderNode(name: "Logos"),
                    FolderNode(name: "Templates")
                ]),
                FolderNode(name: "Marketing_Materials"),
                FolderNode(name: "Internal_Docs")
            ])
        ])
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
    
    /// Called when the user submits a prompt from the search bar. Calls GET /api/prompt?text=... and navigates to PromptView on success.
    func submitPrompt() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        isPromptLoading = true
        promptErrorMessage = nil
        
        do {
            let response: PromptMatchResponse = try await httpClient.get(
                endpoint: APIConfiguration.Endpoints.prompt,
                queryParams: ["text": query]
            )
            promptNavigationItem = PromptNavigationItem(query: query, matchedFiles: response.matchedFiles)
            isPromptLoading = false
        } catch let error as APIError {
            isPromptLoading = false
            promptErrorMessage = error.errorDescription
        } catch {
            isPromptLoading = false
            promptErrorMessage = error.localizedDescription
        }
    }
    
    /// Clears prompt result so navigation pops PromptView.
    func clearPromptResult() {
        promptNavigationItem = nil
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
