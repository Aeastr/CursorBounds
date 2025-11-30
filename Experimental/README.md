# Experimental: Chrome Extension for Caret Position

Chromium browsers don't expose caret position via macOS Accessibility API. This workaround uses a Chrome extension + native messaging.

## Components

- `ChromeExtension/` - Extension that tracks caret via DOM Selection API
- `NativeHost/` - Swift executable that receives position data
- `ChromeExtensionBridge.swift` - Swift helper to read position (copy to Sources if needed)

## Setup

1. Load extension: `chrome://extensions` → Developer mode → Load unpacked → select `ChromeExtension/`
2. Copy extension ID
3. Install native host:
   ```bash
   cd NativeHost
   sudo ./install.sh <extension-id>
   ```
4. Restart browser

## Usage

Copy `ChromeExtensionBridge.swift` to your project, then:

```swift
if let pos = ChromeExtensionBridge.shared.readFreshPosition() {
    // pos.x, pos.y, pos.charOffset, pos.isFresh
}
```

Position data written to `/tmp/cursorbounds_position.json`.

## Limitations

- Requires extension installed per browser
- ~50ms latency (file-based IPC)
- Only works when extension content script is active
