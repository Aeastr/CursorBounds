//
//  ScreenCorrectionMode.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//

import Foundation
import AppKit

/// Specifies how to handle coordinate system differences between macOS and other platforms
///
/// macOS uses a coordinate system where (0,0) is at the bottom-left of the screen, with Y increasing upward.
/// However, iOS uses a "flipped" coordinate system where (0,0) is at the top-left, with Y increasing downward.
/// Some NSViews have an `isFlipped` property that adopts this iOS-style coordinate system.
///
/// The Accessibility API returns coordinates in the macOS native system, but you may need to convert
/// these coordinates depending on how you plan to use them in your application.
public enum ScreenCorrectionMode {
    /// Use raw coordinates as returned by the Accessibility API
    ///
    /// Choose this when:
    /// - Working directly with macOS native coordinate systems
    /// - Interfacing with AppKit views that are not flipped
    /// - You want to handle coordinate conversion yourself
    case none
    
    /// Apply Y-axis correction to convert from macOS coordinates to "flipped" coordinates
    ///
    /// Choose this when:
    /// - Working with flipped coordinate systems (iOS-style)
    /// - Interfacing with NSViews where `isFlipped = true`
    /// - You want coordinates where (0,0) is at the top-left of the screen
    ///
    /// This performs the conversion: `correctedY = screen.frame.maxY - originalY`
    case adjustForYAxis
}

/// Specifies which corner of the bounding rectangle to use for X-coordinate positioning
public enum BoundsCornerX {
    /// Use the left edge of the bounding rectangle
    case minX
    /// Use the right edge of the bounding rectangle
    case maxX
}

public enum BoundsCornerY {
    case minY
    case maxY
}