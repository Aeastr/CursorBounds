//
//  Origin.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//

import SwiftUI

public enum OriginType: String{
    case caret = "Caret"
    case rect = "Text Rect"
    case mouseCursor = "Mouse Cursor"
}

public struct Origin: Hashable {
    public private(set) var id: UUID
    public var type: OriginType
    public var NSPoint: NSPoint

    public init(id: UUID = UUID(), type: OriginType, NSPoint: NSPoint) {
        self.id = id
        self.type = type
        self.NSPoint = NSPoint
    }
}

public struct CursorPositionResult {
    var type: OriginType
    var bounds: CGRect
}
