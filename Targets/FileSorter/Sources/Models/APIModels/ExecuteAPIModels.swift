import Foundation

// MARK: - Execute API Models
// DTOs for POST /api/fs/execute endpoint.

/// Request payload for executing file move actions.
struct ExecuteRequest: Encodable {
    let acceptedActions: [AcceptedAction]
}

/// A single accepted file move action to execute.
struct AcceptedAction: Encodable {
    let originalPath: String
    let newPath: String
}

/// Response payload from execute endpoint.
struct ExecuteResponse: Decodable {
    let status: String
    
    /// Whether the execution was successful
    var isSuccess: Bool {
        status == "success"
    }
}

// MARK: - Conversion Helpers

extension ProposedAction {
    
    /// Converts a ProposedAction to an AcceptedAction for execution.
    func toAcceptedAction() -> AcceptedAction {
        AcceptedAction(
            originalPath: originalPath,
            newPath: suggestedPath
        )
    }
}

extension Array where Element == ProposedAction {
    
    /// Converts an array of ProposedActions to AcceptedActions for execution.
    func toAcceptedActions() -> [AcceptedAction] {
        map { $0.toAcceptedAction() }
    }
    
    /// Creates an ExecuteRequest from the array of proposed actions.
    func toExecuteRequest() -> ExecuteRequest {
        ExecuteRequest(acceptedActions: toAcceptedActions())
    }
}
