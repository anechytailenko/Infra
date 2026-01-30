import Foundation

// MARK: - AI Suggest API Models
// DTOs for POST /api/ai/suggest endpoint.

/// Request payload for AI suggestions endpoint.
struct AISuggestRequest: Encodable {
    let rootDirectory: String
}

/// Response payload from AI suggestions endpoint.
struct AISuggestResponse: Decodable {
    let status: String
    let proposedActions: [ProposedAction]
    
    /// Whether the request was successful
    var isSuccess: Bool {
        status == "success"
    }
}

/// A single proposed file move action from the AI.
struct ProposedAction: Decodable, Identifiable {
    let originalPath: String
    let suggestedFolder: String
    let suggestedPath: String
    let confidenceScore: Double
    
    /// Unique identifier for UI purposes
    var id: String { originalPath }
    
    /// Normalizes path separators (handles both Unix `/` and Windows `\` paths)
    private static func normalizePath(_ path: String) -> String {
        path.replacingOccurrences(of: "\\", with: "/")
    }
    
    /// Extracts only the filename from the original path (no directory components)
    /// Handles both Unix and Windows path separators
    var fileName: String {
        let normalized = Self.normalizePath(originalPath)
        return (normalized as NSString).lastPathComponent
    }
    
    /// Extracts the parent folder name from the original path
    /// Handles both Unix and Windows path separators
    var fromFolderName: String {
        let normalized = Self.normalizePath(originalPath)
        let parent = (normalized as NSString).deletingLastPathComponent
        return (parent as NSString).lastPathComponent
    }
    
    /// Extracts only the folder name from suggestedFolder (in case it's a path)
    /// Handles both Unix and Windows path separators
    var suggestedFolderName: String {
        let normalized = Self.normalizePath(suggestedFolder)
        return (normalized as NSString).lastPathComponent
    }
    
    /// Confidence as a percentage string (e.g., "92%")
    var confidencePercentage: String {
        String(format: "%.0f%%", confidenceScore * 100)
    }
}

// MARK: - Mapping to Domain Models

extension ProposedAction {
    
    /// Converts to ProposedFileMove for use in SortDecisionView.
    /// Requires parent folder IDs to be provided (from the folder tree).
    func toProposedFileMove(fromParentId: UUID, toParentId: UUID) -> ProposedFileMove {
        ProposedFileMove(
            fileName: fileName,
            fromParentId: fromParentId,
            fromParentName: fromFolderName,
            toParentId: toParentId,
            toParentName: suggestedFolder
        )
    }
}

// MARK: - Mapping Helpers

extension Array where Element == ProposedAction {
    
    /// Extracts unique folder names that the AI suggests creating (names only, no paths).
    var uniqueSuggestedFolders: Set<String> {
        Set(map { $0.suggestedFolderName })
    }
    
    /// Groups proposed actions by their suggested folder.
    var groupedBySuggestedFolder: [String: [ProposedAction]] {
        Dictionary(grouping: self) { $0.suggestedFolder }
    }
}
