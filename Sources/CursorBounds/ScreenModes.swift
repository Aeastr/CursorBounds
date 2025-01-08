//
//  ScreenCorrectionMode.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//


import Foundation
import AppKit

public enum ScreenCorrectionMode {
    case none              // No correction applied
    case adjustForYAxis    // Apply Y-axis correction
}

public enum BoundsCornerX {
    case minX
    case maxX
}

public enum BoundsCornerY {
    case minY
    case maxY
}