import Foundation

// MARK: - API Configuration
// Hardcoded base URL and endpoint paths for the backend API.

enum APIConfiguration {
    static let baseURL = "http://localhost:8080"
    
    enum Endpoints {
        static let filesystem = "/api/fs"
        static let aiSuggest = "/api/ai/suggest"
        static let execute = "/api/fs/execute"
    }
    
    /// Default timeout interval for requests (in seconds)
    static let timeoutInterval: TimeInterval = 30.0
}
