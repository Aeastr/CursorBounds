//
//  CursorBounds.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//

import SwiftUI
import OSLog

public class CursorBounds {
    
    private let logger = Logger(subsystem: "com.aether.CursorBounds", category: "CursorOrigin")
    
    public var logLevel: LogLevel {
        get { CursorBoundsConfig.shared.logLevel }
        set { CursorBoundsConfig.shared.logLevel = newValue }
    }
    
    public init() {}
    
    
    public func getOrigin() -> Origin? {
        guard let focusedElement = getFocusedElement(),
              let cursorPositionResult = focusedElement.resolveCursorPosition() else {
            logger.fault("❌ [CursorBounds ERROR] No origin found or unsupported app, make sure accessibility permissions are enabled and app sandbox is disabled.")
            return nil
        }
        
        // Find which screen contains the caret’s origin
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(cursorPositionResult.bounds.origin) }) else {
            logger.warning("⚠️ [CursorBounds WARNING] No screen found containing bounds.")
            return nil
        }
        
        // We can work with either the full screen’s frame or just its visibleFrame.
        // visibleFrame excludes the Dock and Menu Bar areas, whereas frame does not, we need to consider the whole screen for our case (I've tested this and this works best, although feedback is welcome)
        let currentScreenMaxY = screen.frame.maxY
        return Origin(type: cursorPositionResult.type, NSPoint: NSPoint(x: cursorPositionResult.bounds.minX, y: currentScreenMaxY - cursorPositionResult.bounds.minY))
    }
    
    internal func log(_ message: String, osLogLevel: OSLogLevel) {
        guard logLevel.allows(osLogLevel: osLogLevel) else { return }
        
        switch osLogLevel {
        case .log, .trace, .debug:
            logger.debug("🔍 \(message, privacy: .public)")
        case .info:
            logger.info("ℹ️ \(message, privacy: .public)")
        case .notice:
            logger.notice("🗒️ \(message, privacy: .public)")
        case .warning:
            logger.warning("⚠️ \(message, privacy: .public)")
        case .error:
            logger.error("🚨 \(message, privacy: .public)")
        case .critical:
            logger.critical("🚫 \(message, privacy: .public)")
        case .fault:
            logger.fault("❗ \(message, privacy: .public)")
        }
    }
}

public class CursorBoundsConfig {
    public static var shared = CursorBoundsConfig()
    public var logLevel: LogLevel = .info
    
    private init() {} // Prevent external instantiation
}
