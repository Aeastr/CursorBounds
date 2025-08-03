//
//  CursorPosition.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//

import Foundation
import AppKit

/// Represents the position and metadata of a cursor
public struct CursorPosition: Identifiable, Hashable {
    public let id = UUID()
    
    /// The screen coordinates of the cursor
    public let point: NSPoint
    
    /// The type of cursor detection method used
    public let type: CursorType
    
    /// The bounding rectangle of the cursor or text element
    public let bounds: CGRect
    
    /// Convenience property for X coordinate
    public var x: CGFloat { point.x }
    
    /// Convenience property for Y coordinate  
    public var y: CGFloat { point.y }
    
    public init(point: NSPoint, type: CursorType, bounds: CGRect) {
        self.point = point
        self.type = type
        self.bounds = bounds
    }

    public static func == (lhs: CursorPosition, rhs: CursorPosition) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// The method used to detect the cursor position
public enum CursorType: String, CaseIterable {
    case textCaret = "Text Caret"
    case textField = "Text Field"
    case mouseFallback = "Mouse Fallback"
    
    /// A user-friendly description of the cursor type
    public var description: String {
        switch self {
        case .textCaret:
            return "Precise text cursor position"
        case .textField:
            return "Text field bounding area"
        case .mouseFallback:
            return "Mouse cursor position (fallback)"
        }
    }
}

/// Specifies which corner of the bounding rectangle to use for positioning
public enum BoundsCorner {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    
    /// The X coordinate component of this corner
    var x: BoundsCornerX {
        switch self {
        case .topLeft, .bottomLeft: return .minX
        case .topRight, .bottomRight: return .maxX
        }
    }
    
    /// The Y coordinate component of this corner
    var y: BoundsCornerY {
        switch self {
        case .topLeft, .topRight: return .minY
        case .bottomLeft, .bottomRight: return .maxY
        }
    }
}
