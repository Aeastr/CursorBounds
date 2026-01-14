# CursorBounds - Browser Detection

Detect browsers and extract website information including URLs, domains, and page titles.

## Quick Start

```swift
if case .website(let websiteInfo) = windowInfo.content {
    print("URL: \(websiteInfo.url ?? "Not available")")
}
```

## Browser Struct

```swift
public struct Browser: Hashable {
    public let bundleID: String
    public let name: String
    public let isEnabled: Bool

    public init(bundleID: String, name: String, isEnabled: Bool = true)
}
```

## Built-in Browsers

18 browsers are supported out of the box:

```swift
// Major browsers
.safari, .chrome, .firefox, .edge, .arc

// Privacy-focused
.brave, .tor, .duckduckgo, .librewolf

// Alternative
.opera, .vivaldi, .orion, .waterfox, .chromium, .yandex, .helium, .dia, .zen
```

## Configuration

### Default (All Browsers)

```swift
let context = CursorContext()  // Uses Browser.default
```

### Specific Browsers Only

```swift
let context = CursorContext(browsers: [.safari, .chrome, .firefox])

// Or modify shared instance
CursorContext.shared.browsers = [.safari, .chrome]
```

### Adding Custom Browsers

```swift
let customBrowser = Browser(
    bundleID: "com.example.mybrowser",
    name: "My Browser"
)

// Add to existing set
CursorContext.shared.browsers.insert(customBrowser)

// Or use convenience method
let browsers = Browser.defaultWith(customBrowser)
CursorContext.shared.browsers = browsers

// Multiple custom browsers
let browsers = Browser.defaultWith([browser1, browser2])
```

### Enable/Disable Browsers

```swift
let disabledChrome = Browser.chrome.disabled()
let toggledBrowser = Browser.safari.toggled()
let enabledBrowser = Browser.firefox.enabled()

// Filter enabled only
let enabledBrowsers = CursorContext.shared.browsers.filter { $0.isEnabled }
```

## URL Extraction

### What Gets Detected

- Address bar URLs
- Page titles (from window titles)
- Search fields
- Domains (extracted from URLs)

### Example

```swift
do {
    let windowInfo = try CursorContext.shared.windowInfo()

    if case .website(let websiteInfo) = windowInfo.content {
        print("URL: \(websiteInfo.url ?? "Not available")")
        print("Domain: \(websiteInfo.domain ?? "Not available")")
        print("Title: \(websiteInfo.pageTitle ?? "Not available")")

        if websiteInfo.isSearchField {
            print("User is typing in a search field")
        }
    }
} catch {
    print("Error: \(error)")
}
```

### Domain Extraction

```swift
if case .website(let websiteInfo) = windowInfo.content {
    // Use provided domain
    let domain = websiteInfo.domain

    // Or extract from URL
    let extractedDomain = websiteInfo.extractedDomain

    // Prefer extracted if available
    let finalDomain = extractedDomain ?? domain ?? "Unknown"
}
```

## Configuration Examples

```swift
// Major browsers only
CursorContext.shared.browsers = [.safari, .chrome, .firefox, .edge]

// Privacy-focused setup
CursorContext.shared.browsers = [.safari, .brave, .tor, .duckduckgo]

// Development setup
CursorContext.shared.browsers = [.chrome, .chromium, .brave, .edge]
```

## Finding Bundle IDs

For custom browsers:

```bash
# When browser is running
lsappinfo list | grep -i "browser name"

# From application bundle
mdls -name kMDItemCFBundleIdentifier /Applications/Browser.app
```

Or programmatically:

```swift
if let runningApp = NSWorkspace.shared.runningApplications.first(where: {
    $0.localizedName?.contains("Browser Name") == true
}) {
    print("Bundle ID: \(runningApp.bundleIdentifier ?? "Unknown")")
}
```

## Troubleshooting

### URL Not Detected

1. Check browser is in detection set
2. Verify accessibility permissions
3. Some browsers may not expose URL via accessibility API

### Custom Browser Not Working

1. Verify bundle ID is correct
2. Check browser supports accessibility
3. Test with built-in browsers first

## Notes

- URL extraction involves accessibility hierarchy traversal
- May take a few milliseconds for complex browser UIs
- Consider caching results if calling frequently
