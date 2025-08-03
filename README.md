<div align="center">
  <img width="270" height="270" src="/assets/icon.png" alt="Ibeam selecting text 'relia' against a mint green background">
  <h1><b>CursorBounds</b></h1>
  <p>Swift package that provides precise information about the position and bounds of the text cursor (caret) in macOS applications. It leverages the macOS Accessibility API to retrieve the caret's location and bounding rectangle, with fallbacks<br>
  <i>Compatible with macOS 12.0 and later</i></p>
</div>

<div align="center">
  <a href="https://swift.org">
    <img src="https://img.shields.io/badge/Swift-5.5-orange.svg" alt="Swift Version">
  </a>
  <a href="https://www.apple.com/ios/">
    <img src="https://img.shields.io/badge/macOS-12.0%2B-blue.svg" alt="macOS 12.0+">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
  </a>
</div>

---

## **Positioning**

| ![Example of a cursor caret](assets/caretExample.png) | ![Bounding rectangle of a focused text area](assets/textAreaExample.png) | ![Fallback method using cursor position](assets/fallbackExample.png) |
|:-----------------------------:|:-----------------------------:|:-----------------------------:|
| **Cursor Caret**                 | **Text Field/Area**               | **Cursor**             |
| Identifies the cursor caret, the blinking indicator that shows where text will be inserted. | Determines the bounding rectangle of the currently focused text area or input field. | Uses the screen position of the cursor if other methods are unavailable. |
| Works reliably in most text input scenarios. | Provides a general area when caret data is not accessible. | Acts as a backup to ensure the cursor's position is still available. |
| Preferred method for accuracy. | Handles cases where a text field is active but caret data cannot be retrieved. | Ensures functionality when no other data is accessible. |

CursorBounds primarily finds the cursor caret, _the blinking line or block that indicates where the next character will appear when typing_. 
If the caret's position cannot be retrieved, it falls back to the bounding rectangle of the focused text area or field. 
When neither the caret nor the bounding rectangle is accessible, it uses the position of the mouse cursor as a final fallback.

---

## **Features**
- Swift-native API with proper error handling using `throws`
- Retrieve the position of the text caret (cursor) in macOS apps
- Get the bounding rectangle of the caret for text fields and text areas
- Three-tier fallback system: Text Caret → Text Field Bounds → Mouse Cursor
- Built-in accessibility permission management
- Coordinate system correction for macOS vs iOS-style coordinates
- Convenience methods for common use cases

## **Requirements**

### **Accessibility Permissions**
**Required:** Accessibility permissions must be granted to use this package. The system will prompt users to grant these permissions.

### **App Sandbox**
**Internal** App Sandbox can remain enabled when tracking cursors within your own application.

**External** App Sandbox must be disabled **only** if you need to track cursors in *other* applications (external apps).

---

## **Installation**

### **Swift Package Manager**
To include `CursorBounds` in your project:

1. Open your Xcode project.
2. Go to **File > Add Packages...**.
3. Paste the following URL in the search bar:
   ```
   https://github.com/aeastr/CursorBounds.git/
   ```
4. Choose the desired version and click **Add Package**.

---

## **Usage**

### **Basic Usage**

```swift
import CursorBounds

let cursorBounds = CursorBounds()

do {
    let position = try cursorBounds.cursorPosition()
    print("Cursor at: (\(position.x), \(position.y))")
    print("Detection method: \(position.type)")
} catch {
    print("Error: \(error.localizedDescription)")
}
```

### **Error Handling**

```swift
do {
    let position = try cursorBounds.cursorPosition()
    // Use the position...
} catch CursorBoundsError.accessibilityPermissionDenied {
    print("Need accessibility permissions")
    CursorBounds.requestAccessibilityPermissions()
} catch CursorBoundsError.noFocusedElement {
    print("No text field is focused")
} catch CursorBoundsError.cursorPositionUnavailable {
    print("Could not detect cursor position")
} catch CursorBoundsError.screenNotFound {
    print("Cursor is outside screen bounds")
}
```

### **Convenience Methods**

```swift
// Just get the point
let point = try cursorBounds.cursorPoint()
print("Cursor at: (\(point.x), \(point.y))")

// Just get the detection method
let type = try cursorBounds.cursorType()
print("Using: \(type)") // "Text Caret", "Text Field", or "Mouse Fallback"
```

### **Permission Management**

```swift
// Check permissions first
guard CursorBounds.isAccessibilityEnabled() else {
    print("Accessibility permissions required")
    CursorBounds.requestAccessibilityPermissions()
    return
}

// Now safe to get cursor position
let position = try cursorBounds.cursorPosition()
```

### **Coordinate System Options**

The Accessibility API returns coordinates in macOS's native coordinate system, where (0,0) is at the **bottom-left** corner of the screen. However, many UI frameworks (especially those designed for cross-platform compatibility) expect coordinates with (0,0) at the **top-left** corner, similar to iOS.

This difference exists because macOS historically used a bottom-left origin system, while iOS and many modern UI frameworks use a top-left origin. When displaying UI elements like popups or overlays, you typically want the flipped coordinates.

```swift
// Use raw macOS coordinates (bottom-left origin)
let position = try cursorBounds.cursorPosition(
    correctionMode: .none,
    corner: .bottomRight
)

// Use flipped coordinates (top-left origin, default)
let position = try cursorBounds.cursorPosition(
    correctionMode: .adjustForYAxis,  // default
    corner: .topLeft                  // default
)
```

#### **What You Get Back**

The `CursorPosition` struct contains:

```swift
public struct CursorPosition {
    public let point: NSPoint     // Final calculated position
    public let type: CursorType   // Detection method used
    public let bounds: CGRect     // Raw bounding rectangle
    
    public var x: CGFloat { point.x }  // Convenience property
    public var y: CGFloat { point.y }  // Convenience property
}
```

#### **Detection Methods**

The `type` property indicates how the cursor was detected:

```swift
public enum CursorType {
    case textCaret      // Precise text cursor position
    case textField      // Text field bounding area
    case mouseFallback  // Mouse cursor position (fallback)
}
```

---

## Playground

[CursorPlayground](CursorPlayground) is included in this package, you can quickly test out the main function of CursorBounds here

---

## **Permissions**

**Accessibility permissions** are always required. You can check and request them programmatically:

```swift
// Check if permissions are granted
if CursorBounds.isAccessibilityEnabled() {
    // Ready to use CursorBounds
} else {
    // Request permissions (opens System Preferences)
    CursorBounds.requestAccessibilityPermissions()
}
```

**App Sandbox** only needs to be disabled if you want to track cursors in other applications. For most use cases (tracking cursors within your own app), App Sandbox can remain enabled.

---

## License

This project is released under the MIT License. See [LICENSE](LICENSE.md) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request!

## Support

If you like this project, please consider giving it a ⭐️

---

## Where to find me:  
- here, obviously.  
- [Twitter](https://x.com/AetherAurelia)  
- [Threads](https://www.threads.net/@aetheraurelia)  
- [Bluesky](https://bsky.app/profile/aethers.world)  
- [LinkedIn](https://www.linkedin.com/in/willjones24)

---

<p align="center">Built with 🍏🖱️🔲 by Aether</p>
