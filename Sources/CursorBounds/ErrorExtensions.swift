//
//  ErrorExtensions.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//

import SwiftUI

// MARK: - AXError Description Extension

extension AXError: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .success:
            return "Success"
        case .failure:
            return "Failure"
        case .illegalArgument:
            return "Illegal Argument"
        case .invalidUIElement:
            return "Invalid UI Element"
        case .notImplemented:
            return "Not Implemented"
        case .actionUnsupported:
            return "Action Unsupported"
        case .notificationUnsupported:
            return "Notification Unsupported"
        case .notificationNotRegistered:
            return "Notification Not Registered"
        case .parameterizedAttributeUnsupported:
            return "Parameterized Attribute Unsupported"
        case .apiDisabled:
            return "API Disabled"
        case .cannotComplete:
            return "Cannot Complete Operation"
        case .attributeUnsupported:
            return "Attribute Unsupported"
        case .invalidUIElementObserver:
            return "Invalid UI Element Observer"
        case .noValue:
            return "No Value Available"
        case .notificationAlreadyRegistered:
            return "Notification Already Registered"
        case .notEnoughPrecision:
            return "Not Enough Precision"
        default:
            return "Unknown Error"
        }
    }
}
