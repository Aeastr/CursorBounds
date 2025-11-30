//
//  ChromeExtensionBridge.swift
//  CursorBounds
//
//  Reads cursor position from Chrome extension via native messaging host
//

import Foundation
import AppKit

/// Position data from Chrome extension
public struct ChromeCaretPosition: Codable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public let isSelection: Bool
    public let charOffset: Int?
    public let tabId: Int?
    public let url: String?
    public let timestamp: Int64

    /// Age of this position data in milliseconds
    public var ageMs: Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000) - timestamp
    }

    /// Whether this position data is fresh (less than 500ms old)
    public var isFresh: Bool {
        return ageMs < 500
    }

    /// Convert to CGRect
    public var bounds: CGRect {
        return CGRect(x: x, y: y, width: max(width, 1), height: max(height, 18))
    }

    /// Convert to NSPoint
    public var point: NSPoint {
        return NSPoint(x: x, y: y)
    }
}

/// Bridge to get cursor position from Chrome extension
public class ChromeExtensionBridge {

    public static let shared = ChromeExtensionBridge()

    /// Path where the native host writes position data
    private let positionFilePath = "/tmp/cursorbounds_position.json"

    /// Cache of last read position
    private var cachedPosition: ChromeCaretPosition?
    private var cacheTimestamp: Date?

    /// How long to cache the file read (milliseconds)
    public var cacheLifetimeMs: Int = 50

    public init() {}

    /// Check if the Chrome extension appears to be active
    /// (position file exists and is recent)
    public var isExtensionActive: Bool {
        guard let position = readPosition() else {
            return false
        }
        // Consider active if we have data less than 5 seconds old
        return position.ageMs < 5000
    }

    /// Read the latest cursor position from the extension
    /// Returns nil if no data available or data is stale
    public func readPosition() -> ChromeCaretPosition? {
        // Check cache first
        if let cached = cachedPosition,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) * 1000 < Double(cacheLifetimeMs) {
            return cached
        }

        // Read from file
        guard FileManager.default.fileExists(atPath: positionFilePath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: positionFilePath)),
              let position = try? JSONDecoder().decode(ChromeCaretPosition.self, from: data) else {
            return nil
        }

        // Update cache
        cachedPosition = position
        cacheTimestamp = Date()

        return position
    }

    /// Read position only if it's fresh (recent)
    public func readFreshPosition() -> ChromeCaretPosition? {
        guard let position = readPosition(), position.isFresh else {
            return nil
        }
        return position
    }

    /// Clear the cached position
    public func clearCache() {
        cachedPosition = nil
        cacheTimestamp = nil
    }

    /// Delete the position file (cleanup)
    public func cleanup() {
        try? FileManager.default.removeItem(atPath: positionFilePath)
        clearCache()
    }
}

// MARK: - CursorBounds Integration

public extension CursorBounds {

    /// Gets cursor position, preferring Chrome extension data for Chromium browsers
    ///
    /// This checks if the Chrome extension has fresh position data and uses that
    /// for more accurate caret positioning in Chromium browsers.
    ///
    /// - Parameters:
    ///   - correctionMode: How to handle coordinate system differences
    ///   - corner: Which corner of the cursor's bounding rectangle to use
    ///   - preferExtension: Whether to prefer extension data when available (default: true)
    /// - Returns: Complete cursor position information
    /// - Throws: `CursorBoundsError` if cursor position cannot be determined
    func cursorPositionWithExtension(
        correctionMode: ScreenCorrectionMode = .adjustForYAxis,
        corner: BoundsCorner = .topLeft,
        preferExtension: Bool = true
    ) throws -> CursorPosition {
        // Try Chrome extension first if preferred
        if preferExtension, let chromePosition = ChromeExtensionBridge.shared.readFreshPosition() {
            // Find which screen contains this position
            let searchPoint = CGPoint(x: chromePosition.x, y: chromePosition.y)
            if let screen = NSScreen.screens.first(where: { $0.frame.insetBy(dx: -1, dy: -1).contains(searchPoint) }) {

                // Apply Y-axis correction if needed
                let correctedY: CGFloat
                switch correctionMode {
                case .none:
                    correctedY = chromePosition.y
                case .adjustForYAxis:
                    correctedY = screen.frame.maxY - chromePosition.y
                }

                let point = NSPoint(x: chromePosition.x, y: correctedY)
                let cursorType: CursorType = chromePosition.isSelection ? .textField : .textCaret

                return CursorPosition(
                    point: point,
                    type: cursorType,
                    bounds: chromePosition.bounds,
                    screen: screen
                )
            }
        }

        // Fall back to standard method
        return try cursorPosition(correctionMode: correctionMode, corner: corner)
    }
}
