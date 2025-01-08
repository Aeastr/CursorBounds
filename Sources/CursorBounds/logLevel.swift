import SwiftUI
import OSLog


//      .debug: For detailed information during successful operations.
//      .info: For steps where an alternative approach is attempted.
//      .warning: For intermediate failures that are non-critical.
//      .error: For complete failures after all attempts.


/// User-defined logging levels
public enum LogLevel {
    case debug   // Includes all logs
    case info    // Includes info, notice, warning, error, critical, fault
    case warning // Includes warning, error, critical, fault
    case error   // Includes error, critical, fault
    case none    // No logs at all
    
    /// Check if a specific OSLog level is allowed based on the current user-defined log level
    func allows(osLogLevel: OSLogLevel) -> Bool {
        return osLogLevel.rawValue >= self.minimumOSLogLevel().rawValue
    }
    
    /// Maps the user-defined log level to the minimum OSLog level it allows
    private func minimumOSLogLevel() -> OSLogLevel {
        switch self {
        case .debug: return .trace
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .none: return .fault // None means no logs
        }
    }
}

/// OSLog levels mapped to user-defined categories
public enum OSLogLevel: Int, Comparable {
    case log = 0
    case trace = 1
    case debug = 2
    case info = 3
    case notice = 4
    case warning = 5
    case error = 6
    case critical = 7
    case fault = 8
    
    public static func < (lhs: OSLogLevel, rhs: OSLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

