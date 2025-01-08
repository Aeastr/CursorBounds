//
//  AXUIElement+Cursor.swift
//
//  Created by Aether on 02/01/2025.
//

import Cocoa
import AppKit
import ApplicationServices
import Accessibility
import OSLog

// MARK: - Debug Configuration

/// Global debug flag. Set to `true` to enable debug logging.
private let isDebugModeEnabled: Bool = true

// MARK: - Helper Function

/// Safely casts a `CFTypeRef` to a desired type.
/// - Parameters:
///   - value: The value to cast.
///   - type: The desired type.
/// - Returns: The casted value if successful, otherwise `nil`.
private func castCF<T, U>(_ value: T, to type: U.Type = U.self) -> U? {
    return value as? U
}

// MARK: - AXUIElement Extension
let cursorBounds = CursorBounds()

internal extension AXUIElement {
    /// Attempts to return the bounding rect of the insertion point (cursor) in the current text area.
    /// Fallback order: Caret Bounds → Caret Rect → Mouse Cursor Rect.
    /// - Returns: `cursorPositionResult` representing the bounding rectangle and type
    ///
    func resolveCursorPosition() -> CursorPositionResult? {
        cursorBounds.log("[resolveCursorPosition] Start", osLogLevel: .debug)

        // 1. Attempt to get caret bounds
        if let caretBounds = getCaretBounds() {
            cursorBounds.log("[resolveCursorPosition] Successfully obtained caret bounds: \(caretBounds)", osLogLevel: .debug)
            return CursorPositionResult(type: .caret, bounds: caretBounds)
        }
        cursorBounds.log("[resolveCursorPosition] Failed to obtain caret bounds. Attempting to get caret rect.", osLogLevel: .info)

        // 2. Attempt to get caret rect
        if let caretRect = getCaretRect() {
            cursorBounds.log("[resolveCursorPosition] Successfully obtained caret rect: \(caretRect)", osLogLevel: .debug)
            return CursorPositionResult(type: .rect, bounds: caretRect)
        }

        cursorBounds.log("[resolveCursorPosition] Failed to obtain caret rect. Attempting to get mouse cursor rect.", osLogLevel: .warning)

        // 3. Fallback to mouse cursor position
        if let mouseRect = getMouseCursorRect() {
            cursorBounds.log("[resolveCursorPosition] Successfully obtained mouse cursor rect: \(mouseRect)", osLogLevel: .debug)
            return CursorPositionResult(type: .mouseCursor, bounds: mouseRect)
        }

        cursorBounds.log("[resolveCursorPosition] Failed to obtain caret bounds, caret rect, and mouse cursor position.", osLogLevel: .error)
        return nil
    }
    
    // MARK: - Primary Method: Caret Bounds
    
    /// Primary method to retrieve the bounding rect of the caret using `AXSelectedTextRange` and `AXBoundsForRange`.
    /// - Returns: The `CGRect` representing the caret's bounding rectangle, or `nil` if unavailable.
    private func getCaretBounds() -> CGRect? {
        cursorBounds.log("[getCaretBounds] Start", osLogLevel: .debug)
        
        // Obtain the cursor position
        guard let cursorPosition = getCursorPosition() else {
            cursorBounds.log("[getCaretBounds] Failed to get cursor position.", osLogLevel: .warning)
            return nil
        }
        
        cursorBounds.log("[getCaretBounds] Cursor position: \(cursorPosition)", osLogLevel: .debug)
        
        // Create a CFRange for the cursor position
        var cfRange = CFRange(location: cursorPosition, length: 1)
        guard let axValueRange = AXValueCreate(.cfRange, &cfRange) else {
            cursorBounds.log("[getCaretBounds] Failed to create AXValue from CFRange.", osLogLevel: .error)
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
        
        cursorBounds.log("[getCaretBounds] AXUIElementCopyParameterizedAttributeValue result: \(error.rawValue)", osLogLevel: .debug)
        
        guard error == .success,
              let boundsCF = castCF(rawBounds, to: AXValue.self) else {
            cursorBounds.log("[getCaretBounds] Failed to get or cast boundsCF.", osLogLevel: .error)
            return nil
        }
        
        // Extract CGRect from AXValue
        var rect = CGRect.zero
        if AXValueGetValue(boundsCF, .cgRect, &rect) {
            cursorBounds.log("[getCaretBounds] Successfully obtained rect: \(rect)", osLogLevel: .debug)
            return rect
        } else {
            cursorBounds.log("[getCaretBounds] Failed to extract CGRect from AXValue.", osLogLevel: .error)
        }
        
        return nil
    }
    
    // MARK: - Secondary Method: Caret Rect
    
    /// Secondary method to retrieve the caret's rect, especially useful when the caret is at the end of the text (caret has issues being accessed - will address later).
    /// Ensures that the bounds belong to a text-related element before returning (otherwise regular cursor fallback will never be triggered).
    /// - Returns: The `CGRect` representing the caret's rect, or `nil` if unavailable or invalid.
    private func getCaretRect() -> CGRect? {
        cursorBounds.log("[getCaretRect] Start", osLogLevel: .debug)
        
        // Retrieve the AXRole attribute to verify the element type
        guard let role = getAttributeString(attribute: kAXRoleAttribute) else {
            cursorBounds.log("[getCaretRect] Failed to retrieve AXRole.", osLogLevel: .error)
            return nil
        }
        
        cursorBounds.log("[getCaretRect] AXRole: \(role)", osLogLevel: .debug)
        
        // Define expected roles that are text-related
        let expectedRoles: Set<String> = ["AXTextField", "AXTextArea", "AXSearchField", "AXComboBox"]
        
        // Verify that the element's role is one of the expected text-related roles
        guard expectedRoles.contains(role) else {
            cursorBounds.log("[getCaretRect] AXRole '\(role)' is not a recognized text-related role. Skipping.", osLogLevel: .warning)
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
                cursorBounds.log("[getCaretRect] Successfully obtained AXFrame: \(frame)", osLogLevel: .debug)
                return frame
            } else {
                cursorBounds.log("[getCaretRect] Failed to extract CGRect from AXFrame.", osLogLevel: .error)
            }
        } else {
            cursorBounds.log("[getCaretRect] Failed to fetch AXFrame with error: \(frameError.description)", osLogLevel: .warning)
        }
        
        // Attempt to retrieve the AXPosition attribute as a fallback
        let kAXPositionAttributeStr = kAXPositionAttribute as String
        var positionValue: CFTypeRef?
        let positionError = AXUIElementCopyAttributeValue(self, kAXPositionAttributeStr as CFString, &positionValue)
        
        if positionError == .success, let axPosition = castCF(positionValue, to: AXValue.self) {
            var position = CGPoint.zero
            if AXValueGetValue(axPosition, .cgPoint, &position) {
                cursorBounds.log("[getCaretRect] Successfully obtained AXPosition: \(position)", osLogLevel: .debug)
                // Returning a CGRect with zero size at the caret's position
                return CGRect(origin: position, size: CGSize(width: 0, height: 0))
            } else {
                cursorBounds.log("[getCaretRect] Failed to extract CGPoint from AXPosition.", osLogLevel: .error)
            }
        } else {
            cursorBounds.log("[getCaretRect] Failed to fetch AXPosition with error: \(positionError.description)", osLogLevel: .warning)
        }
        
        cursorBounds.log("[getCaretRect] Unable to retrieve valid caret rect.", osLogLevel: .error)
        return nil
    }
    
    // MARK: - Helper Method: Retrieve String Attributes
    
    /// Retrieves a string attribute from the AXUIElement.
    /// - Parameter attribute: The AX attribute to retrieve (e.g., kAXRoleAttribute).
    /// - Returns: The string value of the attribute, or `nil` if unavailable.
    private func getAttributeString(attribute: String) -> String? {
        cursorBounds.log("[getAttributeString] Attempting to retrieve attribute: \(attribute)", osLogLevel: .debug)
        
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, attribute as CFString, &value)
        
        guard error == .success else {
            cursorBounds.log("[getAttributeString] Failed to retrieve attribute '\(attribute)' with error: \(error.description)", osLogLevel: .error)
            return nil
        }
        
        // Use castCF to safely cast the value to CFString
        if let cfString = castCF(value, to: CFString.self) {
            let string = cfString as String
            cursorBounds.log("[getAttributeString] Successfully retrieved attribute '\(attribute)': \(string)", osLogLevel: .debug)
            return string
        } else {
            cursorBounds.log("[getAttributeString] Attribute '\(attribute)' is not a CFString.", osLogLevel: .warning)
            return nil
        }
    }
    
    
    
    // MARK: - Fallback Method: Mouse Cursor Position
    
    /// Fallback method to retrieve the mouse cursor's position as a `CGRect`.
    /// - Returns: A `CGRect` representing the mouse cursor's position, or `nil` if unavailable.
    private func getMouseCursorRect() -> CGRect? {
        cursorBounds.log("[getMouseCursorRect] Start", osLogLevel: .debug)
        
        // Get the current mouse location in screen coordinates
        let mouseLocation = NSEvent.mouseLocation
        cursorBounds.log("[getMouseCursorRect] Mouse location: \(mouseLocation)", osLogLevel: .debug)
        
        // Find the screen that contains the mouse location
        guard let screen = NSScreen.screens.first(where: { NSPointInRect(mouseLocation, $0.frame) }) else {
            cursorBounds.log("[getMouseCursorRect] Failed to find screen containing mouse location.", osLogLevel: .error)
            return nil
        }
        
        // Get the screen's height and origin
        let screenHeight = screen.frame.height
        let screenOriginY = screen.frame.origin.y
        
        // Adjust the Y coordinate relative to the screen's origin
        let adjustedY = screenHeight - mouseLocation.y
        
        cursorBounds.log("[getMouseCursorRect] Screen Height: \(screenHeight), Screen Origin Y: \(screenOriginY), Adjusted Y: \(adjustedY)", osLogLevel: .debug)
        
        // Create a CGRect at the mouse location with a default size
        // This represents a 1x1 point rectangle at the cursor's position
        let cursorRect = CGRect(origin: CGPoint(x: mouseLocation.x, y: adjustedY), size: CGSize(width: 1, height: 1))
        
        cursorBounds.log("[getMouseCursorRect] Cursor rect: \(cursorRect)", osLogLevel: .debug)
        return cursorRect
    }
    
    // MARK: - Helper Methods
    
    /// Retrieves the integer offset of the insertion caret.
    /// - Returns: The cursor's integer position within the text, or `nil` if unavailable.
    private func getCursorPosition() -> Int? {
        cursorBounds.log("[getCursorPosition] Start", osLogLevel: .debug)
        
        let kAXSelectedTextRange = "AXSelectedTextRange"
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            self,
            kAXSelectedTextRange as CFString,
            &rawValue
        )
        
        cursorBounds.log("[getCursorPosition] AXUIElementCopyAttributeValue result: \(error.rawValue)", osLogLevel: .debug)
        
        guard error == .success,
              let axRangeValue = castCF(rawValue, to: AXValue.self) else {
            cursorBounds.log("[getCursorPosition] Failed to get or cast rawValue.", osLogLevel: .error)
            return nil
        }
        
        var range = CFRange()
        if AXValueGetValue(axRangeValue, .cfRange, &range) {
            cursorBounds.log("[getCursorPosition] Retrieved CFRange: location=\(range.location), length=\(range.length)", osLogLevel: .debug)
            return range.location
        } else {
            cursorBounds.log("[getCursorPosition] Failed to extract CFRange from AXValue.", osLogLevel: .error)
        }
        
        return nil
    }
    
    /// Retrieves the total length of the text in the focused element.
    /// - Returns: The total length of the text, or `nil` if unavailable.
    private func getTotalTextLength() -> Int? {
        cursorBounds.log("[getTotalTextLength] Start", osLogLevel: .debug)
        
        let kAXValueAttribute = "AXValue"
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            self,
            kAXValueAttribute as CFString,
            &rawValue
        )
        
        cursorBounds.log("[getTotalTextLength] AXUIElementCopyAttributeValue result: \(error.rawValue)", osLogLevel: .debug)
        
        guard error == .success,
              let axValue = castCF(rawValue, to: AXValue.self) else {
            cursorBounds.log("[getTotalTextLength] Failed to get or cast rawValue.", osLogLevel: .error)
            return nil
        }
        
        // Assuming the AXValue is a string, retrieve its length
        var valueRef: AnyObject?
        if AXValueGetValue(axValue, .cgPoint, &valueRef) { // This might need adjustment
            if let stringValue = valueRef as? String {
                cursorBounds.log("[getTotalTextLength] Retrieved string value: \(stringValue)", osLogLevel: .debug)
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
        
        cursorBounds.log("[getTotalTextLength] AXUIElementCopyAttributeValue for text result: \(textError.rawValue)", osLogLevel: .debug)
        
        guard textError == .success,
              let textCF = castCF(textValue, to: AXValue.self) else {
            cursorBounds.log("[getTotalTextLength] Failed to get or cast textCF.", osLogLevel: .error)
            return nil
        }
        
        // Attempt to extract the string from AXValue
        var stringRef: AnyObject?
        if AXValueGetValue(textCF, .cfRange, &stringRef) {
            if let string = stringRef as? String {
                cursorBounds.log("[getTotalTextLength] Retrieved string value: \(string)", osLogLevel: .debug)
                return string.count
            }
        }
        
        cursorBounds.log("[getTotalTextLength] Failed to extract string value from AXValue.", osLogLevel: .error)
        return nil
    }
    
    /// Retrieves a CGRect attribute from the AXUIElement.
    /// - Parameter attribute: The AX attribute to retrieve.
    /// - Returns: The `CGRect` value of the attribute, or `nil` if unavailable.
    private func getAttributeRect(attribute: String) -> CGRect? {
        cursorBounds.log("[getAttributeRect] Start for attribute: \(attribute)", osLogLevel: .debug)
        
        var attributeValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, attribute as CFString, &attributeValue)
        
        cursorBounds.log("[getAttributeRect] AXUIElementCopyAttributeValue result: \(error.rawValue)", osLogLevel: .debug)
        
        guard error == .success,
              let axValue = castCF(attributeValue, to: AXValue.self) else {
            cursorBounds.log("[getAttributeRect] Failed to get or cast axValue.", osLogLevel: .error)
            return nil
        }
        
        var rect = CGRect.zero
        if AXValueGetValue(axValue, .cgRect, &rect) {
            cursorBounds.log("[getAttributeRect] Successfully obtained rect: \(rect)", osLogLevel: .debug)
            return rect
        }
        
        cursorBounds.log("[getAttributeRect] Failed to extract CGRect from AXValue.", osLogLevel: .error)
        return nil
    }
}

// MARK: - Frontmost Focused Element Retrieval

/// Retrieves the frontmost focused `AXUIElement`, if available.
/// - Returns: The focused `AXUIElement`, or `nil` if unavailable.
func getFocusedElement() -> AXUIElement? {
    // Ensure accessibility permissions are granted
    guard AXIsProcessTrusted() else {
        cursorBounds.log("[getFocusedElement] Accessibility permissions not granted.", osLogLevel: .critical)
        return nil
    }
    
    let systemWideElement = AXUIElementCreateSystemWide()
    cursorBounds.log("[getFocusedElement] Created systemWideElement.", osLogLevel: .info)
    
    var appRef: CFTypeRef?
    let resultApp = AXUIElementCopyAttributeValue(
        systemWideElement,
        kAXFocusedApplicationAttribute as CFString,
        &appRef
    )
    
    cursorBounds.log("[getFocusedElement] AXUIElementCopyAttributeValue for app result: \(resultApp.rawValue)", osLogLevel: .info)
    
    guard resultApp == .success,
          let app = castCF(appRef, to: AXUIElement.self) else {
        cursorBounds.log("[getFocusedElement] Failed to retrieve focused application.", osLogLevel: .fault)
        return nil
    }
    
    cursorBounds.log("[getFocusedElement] Successfully retrieved focused application.", osLogLevel: .debug)
    
    var focusedElementRef: CFTypeRef?
    let resultElement = AXUIElementCopyAttributeValue(
        app,
        kAXFocusedUIElementAttribute as CFString,
        &focusedElementRef
    )
    
    cursorBounds.log("[getFocusedElement] AXUIElementCopyAttributeValue for element result: \(resultElement.rawValue)", osLogLevel: .debug)
    
    guard resultElement == .success,
          let focused = castCF(focusedElementRef, to: AXUIElement.self) else {
        cursorBounds.log("[getFocusedElement] Failed to retrieve focused element.", osLogLevel: .warning)
        return nil
    }
    
    cursorBounds.log("[getFocusedElement] Successfully retrieved focused element.", osLogLevel: .debug)
    return focused
}
