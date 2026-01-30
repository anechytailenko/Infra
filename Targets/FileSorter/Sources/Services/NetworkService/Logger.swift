import Foundation

// MARK: - Log Level

/// Severity levels for logging messages.
enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    var prefix: String {
        switch self {
        case .debug: return "[DEBUG]"
        case .info: return "[INFO]"
        case .warning: return "[WARNING]"
        case .error: return "[ERROR]"
        }
    }
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Logger Protocol
// Follows Interface Segregation Principle (ISP) - clients depend only on methods they use.

protocol Logger {
    /// The minimum log level to output. Messages below this level are ignored.
    var minimumLevel: LogLevel { get }
    
    /// Logs a message at the specified level.
    /// - Parameters:
    ///   - level: The severity level of the message
    ///   - message: The message to log
    ///   - file: The source file (auto-populated)
    ///   - function: The function name (auto-populated)
    ///   - line: The line number (auto-populated)
    func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String,
        function: String,
        line: Int
    )
}

// MARK: - Logger Protocol Extensions
// Convenience methods for different log levels.

extension Logger {
    
    func debug(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message(), file: file, function: function, line: line)
    }
    
    func info(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message(), file: file, function: function, line: line)
    }
    
    func warning(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message(), file: file, function: function, line: line)
    }
    
    func error(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message(), file: file, function: function, line: line)
    }
}

// MARK: - Console Logger Implementation
// Concrete implementation that outputs to the console (stdout).

final class ConsoleLogger: Logger {
    
    let minimumLevel: LogLevel
    private let dateFormatter: DateFormatter
    private let subsystem: String
    
    init(minimumLevel: LogLevel = .debug, subsystem: String = "HTTPClient") {
        self.minimumLevel = minimumLevel
        self.subsystem = subsystem
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= minimumLevel else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logMessage = message()
        
        print("\(timestamp) \(level.prefix) [\(subsystem)] \(fileName):\(line) \(function) - \(logMessage)")
    }
}

// MARK: - Silent Logger Implementation
// No-op logger for when logging should be disabled (e.g., in tests).

final class SilentLogger: Logger {
    
    let minimumLevel: LogLevel = .error
    
    func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String,
        function: String,
        line: Int
    ) {
        // No-op: silently discard all log messages
    }
}

// MARK: - Shared Instance

extension ConsoleLogger {
    /// Shared console logger instance for convenience.
    static let shared = ConsoleLogger(minimumLevel: .debug)
}
