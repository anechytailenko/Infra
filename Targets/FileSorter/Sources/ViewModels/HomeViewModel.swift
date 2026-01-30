import Foundation
import Combine

// MARK: - HomeViewModel
// View model for HomeView. Owns folder tree, search state, and navigation intent (folder detail / search results).
// Stub implementation: replace with real folder loading and search when services are added.

final class HomeViewModel: ObservableObject {

    // MARK: - Published state

    /// Root of the folder tree shown in the graph.
    @Published var rootNode: FolderNode

    /// Search bar text; two-way binding from HomeView.
    @Published var searchQuery: String = ""

    /// Selected folder in the graph; non-nil drives navigation to FolderDetailView.
    @Published var selectedFolder: FolderNode?

    /// Non-nil when user has submitted search and we should push the search-results screen.
    @Published var searchResultsQuery: String?

    // MARK: - Initialization

    init() {
        self.rootNode = Self.makeStubTree()
    }

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

    // MARK: - Actions

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
