import Foundation

// MARK: - HTTP Client Protocol
// Protocol-based HTTP client for making network requests.
// Follows Dependency Inversion Principle (DIP) - high-level modules depend on abstractions.

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
// Follows Single Responsibility Principle (SRP) - handles HTTP communication only.
// Follows Open/Closed Principle (OCP) - open for extension via Logger injection.

final class URLSessionHTTPClient: HTTPClient {
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger: Logger
    
    init(session: URLSession = .shared, logger: Logger = ConsoleLogger.shared) {
        self.session = session
        self.logger = logger
        
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
        
        logger.info("URLSessionHTTPClient initialized with base URL: \(APIConfiguration.baseURL)")
    }
    
    func get<T: Decodable>(endpoint: String, queryParams: [String: String] = [:]) async throws -> T {
        let url = try buildURL(endpoint: endpoint, queryParams: queryParams)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = APIConfiguration.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        logger.info("GET \(url.absoluteString) [timeout: \(APIConfiguration.timeoutInterval)s]")
        if !queryParams.isEmpty {
            logger.debug("Query params: \(queryParams)")
        }
        
        return try await performRequest(request, endpoint: endpoint)
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
            logger.info("POST \(url.absoluteString) [timeout: \(APIConfiguration.timeoutInterval)s, body: \(request.httpBody?.count ?? 0) bytes]")
        } catch {
            logger.error("Failed to encode request body: \(error.localizedDescription)")
            throw APIError.decodingError(error)
        }
        
        return try await performRequest(request, endpoint: endpoint)
    }
    
    // MARK: - Private Helpers
    
    private func buildURL(endpoint: String, queryParams: [String: String]) throws -> URL {
        guard var components = URLComponents(string: APIConfiguration.baseURL + endpoint) else {
            logger.error("Invalid URL: \(APIConfiguration.baseURL + endpoint)")
            throw APIError.invalidURL
        }
        
        if !queryParams.isEmpty {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else {
            logger.error("Failed to construct URL from components: \(components)")
            throw APIError.invalidURL
        }
        
        return url
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest, endpoint: String) async throws -> T {
        let startTime = Date()
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            let duration = Date().timeIntervalSince(startTime)
            
            switch urlError.code {
            case .timedOut:
                logger.error("Request TIMEOUT after \(String(format: "%.2f", duration))s - \(request.httpMethod ?? "?") \(endpoint)")
            case .notConnectedToInternet:
                logger.error("No internet connection - \(request.httpMethod ?? "?") \(endpoint)")
            case .networkConnectionLost:
                logger.error("Network connection lost - \(request.httpMethod ?? "?") \(endpoint)")
            case .cannotFindHost:
                logger.error("Cannot find host - \(request.httpMethod ?? "?") \(endpoint)")
            case .cannotConnectToHost:
                logger.error("Cannot connect to host - \(request.httpMethod ?? "?") \(endpoint)")
            default:
                logger.error("Network error (\(urlError.code.rawValue)): \(urlError.localizedDescription) - \(request.httpMethod ?? "?") \(endpoint)")
            }
            
            throw APIError.networkError(urlError)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Request failed after \(String(format: "%.2f", duration))s: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type (not HTTPURLResponse)")
            throw APIError.unknown
        }
        
        let statusCode = httpResponse.statusCode
        let responseSize = data.count
        
        // Log response with status code
        if (200...299).contains(statusCode) {
            logger.info("Response \(statusCode) OK - \(request.httpMethod ?? "?") \(endpoint) [\(String(format: "%.2f", duration))s, \(responseSize) bytes]")
        } else if (400...499).contains(statusCode) {
            logger.warning("Response \(statusCode) Client Error - \(request.httpMethod ?? "?") \(endpoint) [\(String(format: "%.2f", duration))s]")
        } else if (500...599).contains(statusCode) {
            logger.error("Response \(statusCode) Server Error - \(request.httpMethod ?? "?") \(endpoint) [\(String(format: "%.2f", duration))s]")
        } else {
            logger.warning("Response \(statusCode) - \(request.httpMethod ?? "?") \(endpoint) [\(String(format: "%.2f", duration))s]")
        }
        
        // Check for server errors
        guard (200...299).contains(statusCode) else {
            let message = String(data: data, encoding: .utf8)
            if let message = message {
                logger.debug("Error response body: \(message.prefix(500))")
            }
            throw APIError.serverError(statusCode: statusCode, message: message)
        }
        
        // Decode the response
        do {
            let decoded = try decoder.decode(T.self, from: data)
            logger.debug("Successfully decoded response to \(T.self)")
            return decoded
        } catch {
            logger.error("Failed to decode response: \(error.localizedDescription)")
            if let jsonString = String(data: data.prefix(500), encoding: .utf8) {
                logger.debug("Response body preview: \(jsonString)")
            }
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - Shared Instance

extension URLSessionHTTPClient {
    /// Shared instance for convenience. Use dependency injection for testing.
    static let shared = URLSessionHTTPClient()
}
