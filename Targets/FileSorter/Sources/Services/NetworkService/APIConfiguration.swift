import Foundation

// MARK: - API Configuration
// Hardcoded base URL and endpoint paths for the backend API.
// Follows Single Responsibility Principle (SRP) - centralizes all API configuration.

enum APIConfiguration {
    static let baseURL = "http://192.168.10.24:8000"
    
    enum Endpoints {
        static let filesystem = "/api/fs"
        static let aiSuggest = "/api/sort"
        static let execute = "/api/apply"
        static let prompt = "/api/prompt"
    }
    
    /// Default timeout interval for requests (in seconds)
    static let timeoutInterval: TimeInterval = 30.0
    
    /// Default filesystem path to scan on app launch.
    /// This is the starting directory for the folder tree.
    static let defaultFilesystemPath = "C:/_GitHub/KSE-smart-file-triage/home"
}
