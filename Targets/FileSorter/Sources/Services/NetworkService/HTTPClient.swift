import Foundation

// MARK: - HTTP Client Protocol
// Protocol-based HTTP client for making network requests.

protocol HTTPClient {
    /// Performs a GET request to the specified endpoint.
    /// - Parameters:
    ///   - endpoint: The API endpoint path (e.g., "/api/fs")
    ///   - queryParams: Optional query parameters to append to the URL
    /// - Returns: Decoded response of type T
    func get<T: Decodable>(endpoint: String, queryParams: [String: String]) async throws -> T
    
    /// Performs a POST request to the specified endpoint.
    /// - Parameters:
    ///   - endpoint: The API endpoint path (e.g., "/api/ai/suggest")
    ///   - body: The request body to encode as JSON
    /// - Returns: Decoded response of type T
    func post<T: Decodable, U: Encodable>(endpoint: String, body: U) async throws -> T
}

// MARK: - URLSession HTTP Client Implementation

final class URLSessionHTTPClient: HTTPClient {
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(session: URLSession = .shared) {
        self.session = session
        
        // Configure JSON decoder
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Configure ISO8601 date decoding with fractional seconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try with fractional seconds first
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Fallback to standard ISO8601
            let standardFormatter = ISO8601DateFormatter()
            if let date = standardFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        
        // Configure JSON encoder
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    func get<T: Decodable>(endpoint: String, queryParams: [String: String] = [:]) async throws -> T {
        let url = try buildURL(endpoint: endpoint, queryParams: queryParams)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = APIConfiguration.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return try await performRequest(request)
    }
    
    func post<T: Decodable, U: Encodable>(endpoint: String, body: U) async throws -> T {
        let url = try buildURL(endpoint: endpoint, queryParams: [:])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = APIConfiguration.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.decodingError(error)
        }
        
        return try await performRequest(request)
    }
    
    // MARK: - Private Helpers
    
    private func buildURL(endpoint: String, queryParams: [String: String]) throws -> URL {
        guard var components = URLComponents(string: APIConfiguration.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        if !queryParams.isEmpty {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        return url
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        // Check for server errors
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
        
        // Decode the response
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - Shared Instance

extension URLSessionHTTPClient {
    /// Shared instance for convenience. Use dependency injection for testing.
    static let shared = URLSessionHTTPClient()
}
