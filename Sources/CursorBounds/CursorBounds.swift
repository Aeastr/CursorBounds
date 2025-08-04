//
//  CursorBounds.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//

import Foundation
import AppKit
import ApplicationServices

/// A Swift-native API for retrieving cursor position and bounds information in macOS applications
///
/// ## Requirements
///
/// **Accessibility Permissions:** Always required. The system will prompt users to grant these permissions.
/// Use ``isAccessibilityEnabled()`` to check and ``requestAccessibilityPermissions()`` to prompt.
///
/// **App Sandbox:** Only needs to be disabled if you want to track cursors in *other* applications.
/// - ✅ **Tracking cursors within your own app:** App Sandbox can remain enabled
/// - ❌ **Tracking cursors in external apps:** App Sandbox must be disabled
///
/// Use cases (like showing popups relative to text fields in your own app) work fine with App Sandbox enabled.
public class CursorBounds {
    static let shared = CursorBounds.init()
    public init() {}
    
    // MARK: - Primary Methods
    
    /// Gets the current cursor position and bounds information
    ///
    /// This method is lightweight and focused solely on cursor positioning. For app and website context
    /// information, use CursorContext.
    ///
    /// The Accessibility API returns coordinates in macOS native coordinate system (origin at bottom-left),
    /// but you may need coordinates in a "flipped" system (origin at top-left) depending on your use case.
    ///
    /// - Parameters:
    ///   - correctionMode: How to handle coordinate system differences. Use `.adjustForYAxis` (default)
    ///     for flipped coordinates compatible with iOS-style views, or `.none` for raw macOS coordinates.
    ///   - corner: Which corner of the cursor's bounding rectangle to use for positioning.
    ///     Defaults to `.topLeft` for most intuitive behavior.
    /// - Returns: Complete cursor position information including the final calculated point
    /// - Throws: `CursorBoundsError` if cursor position cannot be determined
    public func cursorPosition(
        correctionMode: ScreenCorrectionMode = .adjustForYAxis,
        corner: BoundsCorner = .topLeft
    ) throws -> CursorPosition {
        // Check accessibility permissions first
        guard Self.isAccessibilityEnabled() else {
            throw CursorBoundsError.accessibilityPermissionDenied
        }
        
        // Get focused element and resolve cursor position
        let focusedElement = getFocusedElement()
        
        var cursorPositionResult: CursorPositionResult
        if let focusedElement,
           let resolved = focusedElement.resolveCursorPosition() {
            cursorPositionResult = resolved
        } else {
            // Use mouse fallback
            let mouseRect = CGRect(origin: NSEvent.mouseLocation, size: .zero)
            cursorPositionResult = CursorPositionResult(type: .mouseCursor, bounds: mouseRect)
        }
        
        // Find which screen contains the cursor
        let searchPoint = cursorPositionResult.bounds.origin
        let screen = NSScreen.screens.first(where: { $0.frame.insetBy(dx: -1, dy: -1).contains(searchPoint) })
        guard let screen else {
            print("[CursorBounds] Screen not found for point \(cursorPositionResult.bounds.origin)")
            throw CursorBoundsError.screenNotFound
        }
        
        // Get coordinates based on the specified corner
        let xCoordinate: CGFloat
        switch corner.x {
        case .minX:
            xCoordinate = cursorPositionResult.bounds.minX
        case .maxX:
            xCoordinate = cursorPositionResult.bounds.maxX
        }
        
        let yCoordinate: CGFloat
        switch corner.y {
        case .minY:
            yCoordinate = cursorPositionResult.bounds.minY
        case .maxY:
            yCoordinate = cursorPositionResult.bounds.maxY
        }
        
        // Apply Y-axis correction if necessary
        // macOS uses bottom-left origin, but many UI frameworks expect top-left origin
        let correctedY: CGFloat
        switch correctionMode {
        case .none:
            correctedY = yCoordinate
        case .adjustForYAxis:
            // Convert from macOS coordinates (bottom-left origin) to flipped coordinates (top-left origin)
            // Formula: flippedY = screenHeight - macOSY
            correctedY = screen.frame.maxY - yCoordinate
        }
        
        // Convert OriginType to CursorType
        let cursorType: CursorType
        switch cursorPositionResult.type {
        case .caret:
            cursorType = .textCaret
        case .rect:
            cursorType = .textField
        case .mouseCursor:
            cursorType = .mouseFallback
        }
        
        let point = NSPoint(x: xCoordinate, y: correctedY)
        
        return CursorPosition(point: point, type: cursorType, bounds: cursorPositionResult.bounds, screen: screen)
    }
    
    /// Gets just the cursor point (convenience method)
    /// - Parameter correctionMode: How to handle screen coordinate correction
    /// - Returns: The cursor position as an NSPoint
    /// - Throws: `CursorBoundsError` if cursor position cannot be determined
    public func cursorPoint(
        correctionMode: ScreenCorrectionMode = .adjustForYAxis
    ) throws -> NSPoint {
        let position = try cursorPosition(correctionMode: correctionMode)
        return position.point
    }
    
    /// Gets the cursor type without full position data
    /// - Returns: The method used to detect the cursor
    /// - Throws: `CursorBoundsError` if cursor position cannot be determined
    public func cursorType() throws -> CursorType {
        let position = try cursorPosition()
        return position.type
    }
    
    /// Calculates an intelligent position for a popup or UI element relative to the cursor
    ///
    /// This method handles screen boundary detection, smart positioning with fallbacks,
    /// and ensures the popup stays within visible screen bounds.
    ///
    /// - Parameters:
    ///   - size: The size of the popup/element to be positioned
    ///   - preferredPosition: Where to position relative to cursor. `.auto` chooses best option
    ///   - margin: Distance between cursor and popup edge (default: 12 points)
    ///   - correctionMode: Screen coordinate correction mode
    ///   - corner: Which corner of cursor bounds to use as reference
    /// - Returns: The calculated origin point for the popup
    /// - Throws: `CursorBoundsError` if cursor position cannot be determined
    public func smartPosition(
        for size: CGSize,
        preferredPosition: PopupPosition = .auto,
        margin: CGFloat = 12,
        correctionMode: ScreenCorrectionMode = .adjustForYAxis,
        corner: BoundsCorner = .topLeft
    ) throws -> NSPoint {
        // Get the cursor position
        let cursorPos = try cursorPosition(correctionMode: correctionMode, corner: corner)
        
        // Use the screen that was already found in cursorPosition()
        let screen = cursorPos.screen
        
        let visible = screen.visibleFrame
        
        // Calculate Y position based on preferred position and available space
        let belowY = cursorPos.point.y + margin
        let aboveY = cursorPos.point.y - size.height - margin
        
        var originY: CGFloat
        
        switch preferredPosition {
        case .below:
            // Try below first, fallback to above if no space
            if belowY + size.height <= visible.maxY {
                originY = belowY
            } else if aboveY >= visible.minY {
                originY = aboveY
            } else {
                // Constrain within screen bounds
                originY = max(min(belowY, visible.maxY - size.height), visible.minY)
            }
            
        case .above:
            // Try above first, fallback to below if no space
            if aboveY >= visible.minY {
                originY = aboveY
            } else if belowY + size.height <= visible.maxY {
                originY = belowY
            } else {
                // Constrain within screen bounds
                originY = max(min(aboveY, visible.maxY - size.height), visible.minY)
            }
            
        case .auto:
            // Choose the position with more available space
            let spaceBelow = visible.maxY - belowY
            let spaceAbove = aboveY - visible.minY
            
            if spaceBelow >= size.height {
                // Enough space below
                originY = belowY
            } else if spaceAbove >= size.height {
                // Enough space above
                originY = aboveY
            } else if spaceBelow >= spaceAbove {
                // More space below, even if not enough
                originY = belowY
            } else {
                // More space above
                originY = aboveY
            }
            
            // Ensure we stay within bounds
            originY = max(min(originY, visible.maxY - size.height), visible.minY)
        }
        
        // Calculate X position, keeping popup on screen
        var originX = cursorPos.point.x
        
        // Adjust X to keep popup within screen bounds
        if originX + size.width > visible.maxX {
            originX = visible.maxX - size.width - 8  // Small margin from edge
        }
        if originX < visible.minX {
            originX = visible.minX + 8  // Small margin from edge
        }
        
        return NSPoint(x: originX, y: originY)
    }
    
    // MARK: - Utility Methods
    
    /// Checks if accessibility permissions are granted
    /// - Returns: `true` if accessibility permissions are available, `false` otherwise
    public static func isAccessibilityEnabled() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// Requests accessibility permissions by opening System Preferences
    /// This will prompt the user to grant accessibility permissions if not already granted
    public static func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}

// MARK: - Helper Functions

/// Safely casts a `CFTypeRef` to a desired type.
public func castCF<T, U>(_ value: T, to type: U.Type = U.self) -> U? {
    return value as? U
}
