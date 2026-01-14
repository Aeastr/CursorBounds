<div align="center">
  <img width="128" height="128" src="/resources/icons/icon.png" alt="CursorBounds Icon">
  <h1><b>CursorBounds</b></h1>
  <p>
    Precise cursor positioning and contextual information for macOS applications.
  </p>
</div>

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.5+-F05138?logo=swift&logoColor=white" alt="Swift 5.5+"></a>
  <a href="https://developer.apple.com"><img src="https://img.shields.io/badge/macOS-12+-000000?logo=apple" alt="macOS 12+"></a>
</p>


## Overview

- **Cursor positioning** - Get precise caret position, text field bounds, or mouse cursor location
- **App context** - Identify focused application and window
- **Browser intelligence** - Extract URLs, domains, and page titles (18+ browsers)
- **Smart positioning** - Calculate optimal popup/overlay placement

| ![Cursor Caret](/resources/examples/caretExample.png) | ![Text Field](/resources/examples/textAreaExample.png) | ![Mouse Fallback](/resources/examples/fallbackExample.png) |
|:---:|:---:|:---:|
| Text Caret | Text Field Bounds | Mouse Fallback |


## Requirements

| Requirement | Description |
|-------------|-------------|
| **Accessibility Permissions** | Required. System will prompt users to grant access. |
| **App Sandbox** | Optional for internal use. Must be disabled to track cursors in other apps. |


## Installation

```swift
dependencies: [
    .package(url: "https://github.com/aeastr/CursorBounds.git", from: "1.0.0")
]
```

```swift
import CursorBounds
```


## Usage

### Check Permissions

```swift
if CursorBounds.isAccessibilityEnabled() {
    // Ready to use
} else {
    CursorBounds.requestAccessibilityPermissions()
}
```

### Get Cursor Position

```swift
// Get current cursor origin (caret → text field → mouse fallback)
let origin = CursorBounds.currentOrigin()

// Get specific bounds
let caretBounds = CursorBounds.caretBounds()
let fieldBounds = CursorBounds.textFieldBounds()
let mouseBounds = CursorBounds.mouseBounds()
```

### Smart Popup Positioning

```swift
let popupFrame = CursorBounds.smartPosition(
    for: popupSize,
    preferredPosition: .below,
    margin: 8
)
```

### App & Browser Context

```swift
let context = CursorContext()

// Focused app info
context.appName        // "Safari"
context.bundleID       // "com.apple.Safari"
context.windowTitle    // "GitHub - Aeastr/CursorBounds"

// Browser-specific
context.currentURL     // "https://github.com/Aeastr/CursorBounds"
context.currentDomain  // "github.com"
context.isSearchField  // true/false
```

### Monitor Cursor Changes

```swift
let monitor = CursorMonitor()
monitor.startMonitoring { bounds in
    print("Cursor moved to: \(bounds.origin)")
}
```

> See [docs/](docs/) for complete API documentation.


## Demo App

The included `CursorPlayground` app demonstrates all features:

| ![Current Origin](/resources/screenshots/Playground%20CurrentOrigin.png) | ![Capture Timer](/resources/screenshots/Playground%20CaptureTimer.png) |
|:---:|:---:|
| Live cursor tracking | Interval-based sampling |

Open the Xcode workspace, select `CursorPlayground`, and run.


## Contributing

Contributions welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.


## License

MIT. See [LICENSE](LICENSE) for details.
