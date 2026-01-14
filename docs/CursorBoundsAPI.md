# CursorBounds - CursorBounds API

Precise cursor positioning and smart popup placement.

## Quick Start

```swift
let cursorBounds = CursorBounds()
let position = try cursorBounds.cursorPosition()
```

## Class Overview

```swift
public class CursorBounds {
    public init()
    static let shared: CursorBounds
}
```

## Primary Methods

### cursorPosition(correctionMode:corner:)

Gets the current cursor position and bounds information.

```swift
public func cursorPosition(
    correctionMode: ScreenCorrectionMode = .adjustForYAxis,
    corner: BoundsCorner = .topLeft
) throws -> CursorPosition
```

**Parameters:**
- `correctionMode`: Coordinate system handling
  - `.adjustForYAxis` (default): Convert to top-left origin coordinates
  - `.none`: Use raw macOS bottom-left origin coordinates
- `corner`: Which corner of the cursor bounds to use
  - `.topLeft` (default), `.topRight`, `.bottomLeft`, `.bottomRight`

**Returns:** `CursorPosition` containing point, type, bounds, and screen information

### cursorPoint(correctionMode:corner:)

Returns just the cursor point.

```swift
public func cursorPoint(
    correctionMode: ScreenCorrectionMode = .adjustForYAxis,
    corner: BoundsCorner = .topLeft
) throws -> NSPoint
```

### cursorType()

Returns just the detection method used.

```swift
public func cursorType() throws -> CursorType
```

### smartPosition(for:preferredPosition:margin:correctionMode:corner:)

Calculates optimal popup positioning relative to the cursor.

```swift
public func smartPosition(
    for size: CGSize,
    preferredPosition: PopupPosition = .auto,
    margin: CGFloat = 12,
    correctionMode: ScreenCorrectionMode = .adjustForYAxis,
    corner: BoundsCorner = .topLeft
) throws -> NSPoint
```

**Parameters:**
- `size`: Size of the popup to position
- `preferredPosition`: Where to position relative to cursor
  - `.auto` (default): Choose best position based on available space
  - `.below`: Position below cursor
  - `.above`: Position above cursor
- `margin`: Distance between cursor and popup edge (default: 12 points)

## Utility Methods

### isAccessibilityEnabled()

```swift
public static func isAccessibilityEnabled() -> Bool
```

### requestAccessibilityPermissions()

```swift
public static func requestAccessibilityPermissions()
```

## Data Structures

### CursorPosition

```swift
public struct CursorPosition {
    public let point: NSPoint
    public let type: CursorType
    public let bounds: CGRect
    public let screen: NSScreen

    public var x: CGFloat { point.x }
    public var y: CGFloat { point.y }
}
```

### CursorType

```swift
public enum CursorType: String, CaseIterable {
    case textCaret = "Text Caret"
    case textField = "Text Field"
    case mouseFallback = "Mouse Fallback"
}
```

### ScreenCorrectionMode

```swift
public enum ScreenCorrectionMode {
    case none           // Raw macOS coordinates (bottom-left origin)
    case adjustForYAxis // Flipped coordinates (top-left origin)
}
```

### BoundsCorner

```swift
public enum BoundsCorner {
    case topLeft, topRight, bottomLeft, bottomRight
}
```

### PopupPosition

```swift
public enum PopupPosition {
    case below
    case above
    case auto
}
```

## Examples

### Basic Position Detection

```swift
let cursorBounds = CursorBounds()

do {
    let position = try cursorBounds.cursorPosition()
    print("Cursor at: \(position.point)")
    print("Detection: \(position.type.rawValue)")
    print("Bounds: \(position.bounds)")
} catch {
    print("Error: \(error)")
}
```

### Smart Popup Positioning

```swift
let popupSize = CGSize(width: 300, height: 150)

do {
    let origin = try cursorBounds.smartPosition(
        for: popupSize,
        preferredPosition: .below,
        margin: 8
    )
    popup.setFrameOrigin(origin)
} catch {
    print("Could not position popup: \(error)")
}
```

### Coordinate System Handling

```swift
// For flipped coordinate systems (iOS-style, most UI frameworks)
let position = try cursorBounds.cursorPosition(
    correctionMode: .adjustForYAxis,
    corner: .topLeft
)

// For raw macOS coordinates
let position = try cursorBounds.cursorPosition(
    correctionMode: .none,
    corner: .bottomLeft
)
```

## Notes

- All methods that can fail throw `CursorBoundsError`
- See [Error Handling](ErrorHandling.md) for details
