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
public struct CursorBounds {
    
    public init() {}
    
    // MARK: - Primary Methods
    
    /// Gets the current cursor position and bounds information
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
        
        // Get focused element
        guard let focusedElement = getFocusedElement() else {
            throw CursorBoundsError.noFocusedElement
        }
        
        // Get cursor position result from the existing implementation
        guard let cursorPositionResult = focusedElement.resolveCursorPosition() else {
            throw CursorBoundsError.cursorPositionUnavailable
        }
        
        // Find which screen contains the cursor
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(cursorPositionResult.bounds.origin) }) else {
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
        return CursorPosition(point: point, type: cursorType, bounds: cursorPositionResult.bounds)
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
