import Foundation
import Combine

// MARK: - SortDecisionViewModel
// View model for SortDecisionView. Manages proposed file moves and executes accepted actions via API.

@MainActor
final class SortDecisionViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var proposedMoves: [ProposedFileMove]
    @Published var selectedMoveId: UUID?
    @Published private(set) var diagramNodes: [DiagramNode]
    @Published private(set) var diagramEdges: [DiagramEdge]
    
    // MARK: - Execution State
    
    /// True while executing file moves
    @Published var isExecuting: Bool = false
    /// True when execution completes successfully
    @Published var executionComplete: Bool = false
    
    // MARK: - Error State
    
    /// Error message to display (nil if no error)
    @Published var errorMessage: String?
    /// Whether to show an alert for critical errors
    @Published var showErrorAlert: Bool = false
    
    // MARK: - API Data
    
    /// Original proposed actions from the AI response (used for execute request)
    private var originalProposedActions: [ProposedAction] = []
    /// Mapping from ProposedFileMove ID to ProposedAction
    private var moveToActionMap: [UUID: ProposedAction] = [:]
    
    // MARK: - Dependencies
    
    private let httpClient: HTTPClient

    // MARK: - Initialization

    /// Default initializer with empty data.
    /// Use init(aiResponse:) when navigating from FolderDetailView with AI suggestions.
    init(httpClient: HTTPClient = URLSessionHTTPClient.shared) {
        self.httpClient = httpClient
        self.diagramNodes = []
        self.diagramEdges = []
        self.proposedMoves = []
        self.selectedMoveId = nil
    }
    
    /// Initialize with AI suggestions response from the API.
    /// This is the primary way to create this ViewModel when coming from FolderDetailView.
    init(aiResponse: AISuggestResponse, httpClient: HTTPClient = URLSessionHTTPClient.shared) {
        self.httpClient = httpClient
        self.originalProposedActions = aiResponse.proposedActions
        
        // Build diagram nodes from unique folders
        let rootId = UUID()
        var folderIds: [String: UUID] = [:]
        var nodes: [DiagramNode] = []
        
        // Add root node
        let rootNode = DiagramNode(id: rootId, name: "Root", isFolder: true, isAICreated: false)
        nodes.append(rootNode)
        
        // Add folder nodes for each unique suggested folder
        for folderName in aiResponse.proposedActions.uniqueSuggestedFolders {
            let folderId = UUID()
            folderIds[folderName] = folderId
            let isAICreated = true // AI-suggested folders
            let folderNode = DiagramNode(id: folderId, name: folderName, isFolder: true, isAICreated: isAICreated)
            nodes.append(folderNode)
        }
        
        self.diagramNodes = nodes
        
        // Convert ProposedActions to ProposedFileMoves
        var moves: [ProposedFileMove] = []
        var mapping: [UUID: ProposedAction] = [:]
        for action in aiResponse.proposedActions {
            let toParentId = folderIds[action.suggestedFolder] ?? rootId
            let move = ProposedFileMove(
                fileName: action.fileName,
                fromParentId: rootId,
                fromParentName: action.fromFolderName,
                toParentId: toParentId,
                toParentName: action.suggestedFolder
            )
            moves.append(move)
            mapping[move.id] = action
        }
        
        self.proposedMoves = moves
        self.moveToActionMap = mapping
        self.diagramEdges = []
        self.selectedMoveId = nil
        
        rebuildDiagramEdges()
    }

    // MARK: - Actions

    /// Execute all accepted (non-declined) file moves via POST /api/fs/execute
    func acceptAll() {
        guard !isExecuting else { return }
        
        // Get accepted actions
        let acceptedMoveIds = Set(effectiveMoves.map { $0.id })
        let acceptedActions = originalProposedActions.filter { action in
            // Find the move that corresponds to this action
            moveToActionMap.contains { $0.value.originalPath == action.originalPath && acceptedMoveIds.contains($0.key) }
        }
        
        // If no API actions (mock mode), just mark as complete
        guard !acceptedActions.isEmpty else {
            executionComplete = true
            return
        }
        
        isExecuting = true
        errorMessage = nil
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let request = acceptedActions.toExecuteRequest()
                let response: ExecuteResponse = try await self.httpClient.post(
                    endpoint: APIConfiguration.Endpoints.execute,
                    body: request
                )
                
                self.isExecuting = false
                
                if response.isSuccess {
                    self.executionComplete = true
                } else {
                    self.errorMessage = "Server returned unsuccessful status"
                    self.showErrorAlert = true
                }
                
            } catch let error as APIError {
                self.isExecuting = false
                self.errorMessage = error.errorDescription
                self.showErrorAlert = error.isCritical
                
            } catch {
                self.isExecuting = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }

    func declineAll() {
        proposedMoves = proposedMoves.map { move in
            var m = move
            m.isDeclined = true
            return m
        }
        selectedMoveId = nil
        rebuildDiagramEdges()
    }

    func declineFile(id: UUID) {
        proposedMoves = proposedMoves.map { move in
            guard move.id == id else { return move }
            var m = move
            m.isDeclined = true
            return m
        }
        if selectedMoveId == id {
            selectedMoveId = nil
        }
        rebuildDiagramEdges()
    }

    func selectMove(id: UUID?) {
        selectedMoveId = id
        rebuildDiagramEdges()
    }
    
    /// Clears the current error state
    func dismissError() {
        errorMessage = nil
        showErrorAlert = false
    }

    // MARK: - Helpers

    var selectedMove: ProposedFileMove? {
        guard let id = selectedMoveId else { return nil }
        return proposedMoves.first { $0.id == id && !$0.isDeclined }
    }

    var effectiveMoves: [ProposedFileMove] {
        proposedMoves.filter { !$0.isDeclined }
    }

    private func rebuildDiagramEdges() {
        let rootId = diagramNodes.first { $0.name == "Root" || $0.name == "User" }?.id ?? UUID()
        var edges: [DiagramEdge] = diagramNodes
            .filter { $0.id != rootId }
            .map { DiagramEdge(fromId: rootId, toId: $0.id, style: .normal) }

        if let move = selectedMove {
            edges.append(DiagramEdge(fromId: move.fromParentId, toId: move.id, style: .originalFile))
            edges.append(DiagramEdge(fromId: move.toParentId, toId: move.id, style: .proposedFile))
        }

        diagramEdges = edges
    }
}
