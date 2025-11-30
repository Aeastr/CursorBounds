//
//  CursorBoundsError.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//

import Foundation

/// Errors that can occur when retrieving cursor position information
public enum CursorBoundsError: Error, LocalizedError {
    case accessibilityPermissionDenied
    case noFocusedElement
    case cursorPositionUnavailable
    case screenNotFound
    case noSourceAvailable(tried: [CursorType])

    public var errorDescription: String? {
        switch self {
        case .accessibilityPermissionDenied:
            return "Accessibility permissions are required but not granted"
        case .noFocusedElement:
            return "No focused UI element found"
        case .cursorPositionUnavailable:
            return "Unable to determine cursor position using any available method"
        case .screenNotFound:
            return "No screen found containing the cursor bounds"
        case .noSourceAvailable:
            return "No cursor source was able to provide a position"
        }
    }

    public var failureReason: String? {
        switch self {
        case .accessibilityPermissionDenied:
            return "The application does not have accessibility permissions"
        case .noFocusedElement:
            return "No text input field or UI element is currently focused"
        case .cursorPositionUnavailable:
            return "All cursor detection methods (caret, text field, mouse fallback) failed"
        case .screenNotFound:
            return "The cursor position is outside the bounds of all available screens"
        case .noSourceAvailable(let tried):
            let triedNames = tried.map { $0.rawValue }.joined(separator: ", ")
            return "Tried sources [\(triedNames)] but none succeeded"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .accessibilityPermissionDenied:
            return "Grant accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility"
        case .noFocusedElement:
            return "Click on a text field or text area to focus it"
        case .cursorPositionUnavailable:
            return "Ensure a text field is focused and accessibility permissions are granted"
        case .screenNotFound:
            return "Ensure the cursor is within the visible screen area"
        case .noSourceAvailable:
            return "Focus a text field for caret detection, or include mouseFallback in sourcePriority"
        }
    }
}
