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
    
    /// Extracts the filename from the original path
    var fileName: String {
        (originalPath as NSString).lastPathComponent
    }
    
    /// Extracts the parent folder name from the original path
    var fromFolderName: String {
        let parent = (originalPath as NSString).deletingLastPathComponent
        return (parent as NSString).lastPathComponent
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
    
    /// Extracts unique folder names that the AI suggests creating.
    var uniqueSuggestedFolders: Set<String> {
        Set(map { $0.suggestedFolder })
    }
    
    /// Groups proposed actions by their suggested folder.
    var groupedBySuggestedFolder: [String: [ProposedAction]] {
        Dictionary(grouping: self) { $0.suggestedFolder }
    }
}
