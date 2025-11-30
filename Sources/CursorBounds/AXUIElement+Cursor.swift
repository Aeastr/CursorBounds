//
//  AXUIElement+Cursor.swift
//
//  Created by Aether on 02/01/2025.
//

import Cocoa
import AppKit
import ApplicationServices
import Accessibility

// MARK: - AXUIElement Extension

internal extension AXUIElement {
    /// Attempts to return the bounding rect of the insertion point (cursor) in the current text area.
    /// Tries sources in the specified priority order, or uses default order if not specified.
    /// - Parameter priority: Optional array of cursor types to try in order. If nil, uses default order.
    /// - Returns: `cursorPositionResult` representing the bounding rectangle and type
    ///
    func resolveCursorPosition(priority: [CursorType]? = nil) -> CursorPositionResult? {
        let order = priority ?? [.textCaret, .textField, .mouseFallback]

        for sourceType in order {
            if let result = trySource(sourceType) {
                return result
            }
        }

        return nil
    }

    /// Attempts to get cursor position from a specific source type
    private func trySource(_ type: CursorType) -> CursorPositionResult? {
        switch type {
        case .textCaret:
            if let caretBounds = getCaretBounds(), caretBounds.width > 0 || caretBounds.height > 0 {
                return CursorPositionResult(type: .caret, bounds: caretBounds)
            }
        case .textField:
            if let caretRect = getCaretRect() {
                return CursorPositionResult(type: .rect, bounds: caretRect)
            }
        case .mouseFallback:
            if let mouseRect = getMouseCursorRect() {
                return CursorPositionResult(type: .mouseCursor, bounds: mouseRect)
            }
        }
        return nil
    }
    
    // MARK: - Primary Method: Caret Bounds
    
    /// Primary method to retrieve the bounding rect of the caret using `AXSelectedTextRange` and `AXBoundsForRange`.
    /// - Returns: The `CGRect` representing the caret's bounding rectangle, or `nil` if unavailable.
    private func getCaretBounds() -> CGRect? {
        
        // Obtain the cursor position
        guard let cursorPosition = getCursorPosition() else {
            return nil
        }
        
        
        // Create a CFRange for the cursor position
        var cfRange = CFRange(location: cursorPosition, length: 1)
        guard let axValueRange = AXValueCreate(.cfRange, &cfRange) else {
            return nil
        }
        
        // Retrieve the bounding rectangle for the range
        var rawBounds: CFTypeRef?
        let error = AXUIElementCopyParameterizedAttributeValue(
            self,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            axValueRange,
            &rawBounds
        )
        
        
        guard error == .success,
              let boundsCF = castCF(rawBounds, to: AXValue.self) else {
            return nil
        }
        
        // Extract CGRect from AXValue
        var rect = CGRect.zero
        if AXValueGetValue(boundsCF, .cgRect, &rect) {
            return rect
        } else {
        }
        
        return nil
    }
    
    // MARK: - Secondary Method: Caret Rect
    
    /// Secondary method to retrieve the caret's rect, especially useful when the caret is at the end of the text (caret has issues being accessed - will address later).
    /// Ensures that the bounds belong to a text-related element before returning (otherwise regular cursor fallback will never be triggered).
    /// - Returns: The `CGRect` representing the caret's rect, or `nil` if unavailable or invalid.
    private func getCaretRect() -> CGRect? {
        
        // Retrieve the AXRole attribute to verify the element type
        guard let role = getAttributeString(attribute: kAXRoleAttribute) else {
            return nil
        }
        
        
        // Define expected roles that are text-related
        let expectedRoles: Set<String> = ["AXTextField", "AXTextArea", "AXSearchField", "AXComboBox"]
        
        // Verify that the element's role is one of the expected text-related roles
        guard expectedRoles.contains(role) else {
            return nil
        }
        
        // Attempt to retrieve the AXFrame attribute
        let kAXFrameAttribute = "AXFrame"
        let kAXPositionAttribute = "AXPosition"
        
        let kAXFrameAttributeStr = kAXFrameAttribute as String
        var frameValue: CFTypeRef?
        let frameError = AXUIElementCopyAttributeValue(self, kAXFrameAttributeStr as CFString, &frameValue)
        
        if frameError == .success, let axFrame = castCF(frameValue, to: AXValue.self) {
            var frame = CGRect.zero
            if AXValueGetValue(axFrame, .cgRect, &frame) {
                return frame
            } else {
            }
        } else {
        }
        
        // Attempt to retrieve the AXPosition attribute as a fallback
        let kAXPositionAttributeStr = kAXPositionAttribute as String
        var positionValue: CFTypeRef?
        let positionError = AXUIElementCopyAttributeValue(self, kAXPositionAttributeStr as CFString, &positionValue)
        
        if positionError == .success, let axPosition = castCF(positionValue, to: AXValue.self) {
            var position = CGPoint.zero
            if AXValueGetValue(axPosition, .cgPoint, &position) {
                // Returning a CGRect with zero size at the caret's position
                return CGRect(origin: position, size: CGSize(width: 0, height: 0))
            } else {
            }
        } else {
        }
        
        return nil
    }
    
    // MARK: - Helper Method: Retrieve String Attributes
    
    /// Retrieves a string attribute from the AXUIElement.
    /// - Parameter attribute: The AX attribute to retrieve (e.g., kAXRoleAttribute).
    /// - Returns: The string value of the attribute, or `nil` if unavailable.
    internal func getAttributeString(attribute: String) -> String? {
        
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, attribute as CFString, &value)
        
        guard error == .success else {
            return nil
        }
        
        // Check if the value is actually a string before trying to cast it
        guard let unwrappedValue = value else {
            return nil
        }
        
        // Check the type first to avoid crashes
        let typeID = CFGetTypeID(unwrappedValue)
        let stringTypeID = CFStringGetTypeID()
        
        if typeID == stringTypeID {
            // Safe to cast to CFString
            if let cfString = castCF(unwrappedValue, to: CFString.self) {
                let string = cfString as String
                return string
            }
        }
        
        // If it's not a string type, return nil instead of crashing
        return nil
    }
    
    
    
    // MARK: - Fallback Method: Mouse Cursor Position
    
    /// Fallback method to retrieve the mouse cursor's position as a `CGRect`.
    /// - Returns: A `CGRect` representing the mouse cursor's position, or `nil` if unavailable.
    private func getMouseCursorRect() -> CGRect? {
        
        // Get the current mouse location in screen coordinates
        let mouseLocation = NSEvent.mouseLocation
        
        // Find the screen that contains the mouse location
        guard let screen = NSScreen.screens.first(where: { NSPointInRect(mouseLocation, $0.frame) }) else {
            return nil
        }
        
        // Get the screen's height and origin
        let screenHeight = screen.frame.height
        
        // Adjust the Y coordinate relative to the screen's origin
        let adjustedY = screenHeight - mouseLocation.y
        
        // Create a CGRect at the mouse location with a default size
        // This represents a 1x1 point rectangle at the cursor's position
        let cursorRect = CGRect(origin: CGPoint(x: mouseLocation.x, y: adjustedY), size: CGSize(width: 1, height: 1))
        
        return cursorRect
    }
    
    // MARK: - Helper Methods
    
    /// Retrieves the integer offset of the insertion caret.
    /// - Returns: The cursor's integer position within the text, or `nil` if unavailable.
    private func getCursorPosition() -> Int? {
        
        let kAXSelectedTextRange = "AXSelectedTextRange"
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            self,
            kAXSelectedTextRange as CFString,
            &rawValue
        )
        
        
        guard error == .success,
              let axRangeValue = castCF(rawValue, to: AXValue.self) else {
            return nil
        }
        
        var range = CFRange()
        if AXValueGetValue(axRangeValue, .cfRange, &range) {
            return range.location
        } else {
        }
        
        return nil
    }
    
    /// Retrieves the total length of the text in the focused element.
    /// - Returns: The total length of the text, or `nil` if unavailable.
    private func getTotalTextLength() -> Int? {
        
        let kAXValueAttribute = "AXValue"
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            self,
            kAXValueAttribute as CFString,
            &rawValue
        )
        
        
        guard error == .success,
              let axValue = castCF(rawValue, to: AXValue.self) else {
            return nil
        }
        
        // Assuming the AXValue is a string, retrieve its length
        var valueRef: AnyObject?
        if AXValueGetValue(axValue, .cgPoint, &valueRef) { // This might need adjustment
            if let stringValue = valueRef as? String {
                return stringValue.count
            }
        }
        
        // Alternative approach: Retrieve the AXTextAttribute for the focused element
        var textValue: CFTypeRef?
        let textError = AXUIElementCopyAttributeValue(
            self,
            kAXValueAttribute as CFString,
            &textValue
        )
        
        
        guard textError == .success,
              let textCF = castCF(textValue, to: AXValue.self) else {
            return nil
        }
        
        // Attempt to extract the string from AXValue
        var stringRef: AnyObject?
        if AXValueGetValue(textCF, .cfRange, &stringRef) {
            if let string = stringRef as? String {
                return string.count
            }
        }
        
        return nil
    }
    
    /// Retrieves a CGRect attribute from the AXUIElement.
    /// - Parameter attribute: The AX attribute to retrieve.
    /// - Returns: The `CGRect` value of the attribute, or `nil` if unavailable.
    private func getAttributeRect(attribute: String) -> CGRect? {
        
        var attributeValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, attribute as CFString, &attributeValue)
        
        
        guard error == .success,
              let axValue = castCF(attributeValue, to: AXValue.self) else {
            return nil
        }
        
        var rect = CGRect.zero
        if AXValueGetValue(axValue, .cgRect, &rect) {
            return rect
        }
        
        return nil
    }
}

// MARK: - Frontmost Focused Element Retrieval

/// Retrieves the frontmost focused `AXUIElement`, if available.
/// - Returns: The focused `AXUIElement`, or `nil` if unavailable.
func getFocusedElement() -> AXUIElement? {
    // Ensure accessibility permissions are granted
    guard AXIsProcessTrusted() else {
        return nil
    }

    let systemWideElement = AXUIElementCreateSystemWide()

    var appRef: CFTypeRef?
    let resultApp = AXUIElementCopyAttributeValue(
        systemWideElement,
        kAXFocusedApplicationAttribute as CFString,
        &appRef
    )


    guard resultApp == .success,
          let app = castCF(appRef, to: AXUIElement.self) else {
        return nil
    }


    var focusedElementRef: CFTypeRef?
    let resultElement = AXUIElementCopyAttributeValue(
        app,
        kAXFocusedUIElementAttribute as CFString,
        &focusedElementRef
    )


    guard resultElement == .success,
          let focused = castCF(focusedElementRef, to: AXUIElement.self) else {
        return nil
    }

    return focused
}

/// Retrieves the focused `AXUIElement` from a specific application by process ID.
///
/// Use this when you need to get the cursor position from an app that is not currently
/// the frontmost application (e.g., when your popup panel has taken focus).
///
/// - Parameter pid: The process ID of the target application
/// - Returns: The focused `AXUIElement` within that app, or `nil` if unavailable.
func getFocusedElement(forPID pid: pid_t) -> AXUIElement? {
    guard AXIsProcessTrusted() else {
        return nil
    }

    let appElement = AXUIElementCreateApplication(pid)

    var focusedElementRef: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(
        appElement,
        kAXFocusedUIElementAttribute as CFString,
        &focusedElementRef
    )

    guard result == .success,
          let focused = castCF(focusedElementRef, to: AXUIElement.self) else {
        return nil
    }

    return focused
}
