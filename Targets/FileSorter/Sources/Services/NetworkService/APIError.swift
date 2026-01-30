import Foundation

// MARK: - API Error Types
// Network error types for handling various failure scenarios.

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case noData
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please check the server configuration."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to process server response: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            if let message = message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server error with status code \(statusCode)"
        case .noData:
            return "No data received from server."
        case .unknown:
            return "An unknown error occurred."
        }
    }
    
    /// Indicates whether the error is recoverable (user can retry).
    /// Used for determining inline vs alert presentation.
    var isRecoverable: Bool {
        switch self {
        case .networkError:
            return true
        case .serverError(let statusCode, _):
            // 4xx errors are often recoverable (e.g., bad request can be fixed)
            // 5xx errors may be transient
            return statusCode >= 400 && statusCode < 600
        case .noData:
            return true
        case .invalidURL, .decodingError, .unknown:
            return false
        }
    }
    
    /// Indicates whether this is a critical error that should show an alert.
    var isCritical: Bool {
        switch self {
        case .decodingError, .invalidURL:
            return true
        case .serverError(let statusCode, _):
            return statusCode >= 500
        case .networkError:
            return true
        default:
            return false
        }
    }
}
