# CursorBounds - CursorContext API

Contextual information about the focused application and browser content.

## Quick Start

```swift
let windowInfo = try CursorContext.shared.windowInfo()
print("App: \(windowInfo.appName ?? "Unknown")")
```

## Class Overview

```swift
public class CursorContext {
    public static let shared: CursorContext
    public var browsers: Set<Browser>

    public init(browsers: Set<Browser> = Browser.default)
}
```

## Properties

### browsers

Set of browsers to detect when gathering context information.

```swift
public var browsers: Set<Browser>
```

Default includes all known browsers. Customize to detect only specific browsers.

## Methods

### windowInfo()

Gets comprehensive window and context information.

```swift
public func windowInfo() throws -> WindowInfo
```

### contentContext()

Gets just the content context for the focused application.

```swift
public func contentContext() throws -> ContentContext?
```

Returns `ContentContext` if available (e.g., website info for browsers), or `nil`.

## Data Structures

### WindowInfo

```swift
public struct WindowInfo {
    public let appName: String?
    public let bundleIdentifier: String?
    public let processID: pid_t?
    public let windowTitle: String?
    public let elementRole: String?
    public let content: ContentContext?
}
```

### ContentContext

```swift
public enum ContentContext {
    case website(WebsiteInfo)
}
```

### WebsiteInfo

```swift
public struct WebsiteInfo {
    public let url: String?
    public let pageTitle: String?
    public let domain: String?
    public let isSearchField: Bool

    public var extractedDomain: String?
}
```

## Examples

### Basic Window Information

```swift
do {
    let windowInfo = try CursorContext.shared.windowInfo()

    print("App: \(windowInfo.appName ?? "Unknown")")
    print("Bundle ID: \(windowInfo.bundleIdentifier ?? "Unknown")")
    print("Window: \(windowInfo.windowTitle ?? "No title")")
    print("Element: \(windowInfo.elementRole ?? "Unknown")")
} catch {
    print("Error: \(error)")
}
```

### Browser Context Detection

```swift
do {
    let windowInfo = try CursorContext.shared.windowInfo()

    if case .website(let websiteInfo) = windowInfo.content {
        print("URL: \(websiteInfo.url ?? "No URL")")
        print("Domain: \(websiteInfo.domain ?? "No domain")")
        print("Title: \(websiteInfo.pageTitle ?? "No title")")

        if websiteInfo.isSearchField {
            print("User is in a search field")
        }
    }
} catch {
    print("Error: \(error)")
}
```

### Custom Browser Configuration

```swift
// Only detect specific browsers
let context = CursorContext(browsers: [.safari, .chrome, .firefox])

// Or modify the shared instance
CursorContext.shared.browsers = [.safari, .chrome]
```

See [Browser Detection](BrowserDetection.md) for complete browser configuration.

### Process ID Usage

```swift
do {
    let windowInfo = try CursorContext.shared.windowInfo()

    if let pid = windowInfo.processID {
        if let runningApp = NSRunningApplication(processIdentifier: pid) {
            print("App icon: \(runningApp.icon)")
            print("Launch date: \(runningApp.launchDate)")
        }
    }
} catch {
    print("Error: \(error)")
}
```

## Notes

- Window information gathering is lightweight and suitable for real-time use
- Browser URL extraction uses accessibility hierarchy traversal (may take a few milliseconds)
- Results are not cached - implement your own caching if needed
- See [Error Handling](ErrorHandling.md) for error management
