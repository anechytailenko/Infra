import Foundation

// MARK: - Prompt API Models
// DTOs for GET /api/prompt endpoint.

/// Response model for prompt matching endpoint.
/// Server returns: { "status": "success", "matched_files": ["/path/...", ...] }
/// HTTPClient uses keyDecodingStrategy = .convertFromSnakeCase, so matched_files → matchedFiles.
struct PromptMatchResponse: Codable {
    let status: String?
    let matchedFiles: [String]
}
