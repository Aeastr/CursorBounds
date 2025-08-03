//
//  Origin.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//

import Foundation

// MARK: - Internal Types for Implementation

/// Internal enum used by the existing implementation
internal enum OriginType: String {
    case caret = "Caret"
    case rect = "Text Rect"
    case mouseCursor = "Mouse Cursor"
}

/// Internal struct used by the existing implementation to pass cursor data
internal struct CursorPositionResult {
    var type: OriginType
    var bounds: CGRect
}
