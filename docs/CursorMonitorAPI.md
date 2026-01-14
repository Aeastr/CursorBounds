# CursorBounds - CursorMonitor API

Continuous monitoring of cursor position with configurable polling and change detection.

## Quick Start

```swift
let monitor = CursorMonitor()
monitor.onPositionChanged = { position in
    print("Cursor moved to: \(position.point)")
}
monitor.startMonitoring()
```

## Class Overview

```swift
public class CursorMonitor {
    public init()
}
```

## Configuration Properties

### pollingInterval

How frequently to check cursor position (in seconds).

```swift
public var pollingInterval: TimeInterval = 0.1  // Default: 100ms
```

### changeThreshold

Minimum distance cursor must move to trigger an update (in pixels).

```swift
public var changeThreshold: CGFloat = 2.0  // Default: 2 pixels
```

Type changes always trigger updates regardless of this threshold.

### correctionMode

```swift
public var correctionMode: ScreenCorrectionMode = .adjustForYAxis
```

### corner

```swift
public var corner: BoundsCorner = .topLeft
```

## Callback Properties

```swift
public var onPositionChanged: ((CursorPosition) -> Void)?
public var onError: ((CursorBoundsError) -> Void)?
public var onMonitoringStarted: (() -> Void)?
public var onMonitoringStopped: (() -> Void)?
```

## State Properties

```swift
public private(set) var isMonitoring: Bool
public var currentPosition: CursorPosition?
```

## Control Methods

### startMonitoring()

Starts continuous monitoring. Runs on a background queue; callbacks execute on main queue.

```swift
public func startMonitoring()
```

### stopMonitoring()

```swift
public func stopMonitoring()
```

### checkNow()

Manually triggers a cursor position check.

```swift
@discardableResult
public func checkNow() -> CursorPosition?
```

## Factory Methods

### highResponsiveness()

```swift
static func highResponsiveness() -> CursorMonitor
// pollingInterval: 0.05s, changeThreshold: 1.0px
```

### balanced()

```swift
static func balanced() -> CursorMonitor
// pollingInterval: 0.1s, changeThreshold: 2.0px
```

### powerEfficient()

```swift
static func powerEfficient() -> CursorMonitor
// pollingInterval: 0.25s, changeThreshold: 5.0px
```

## Examples

### Basic Monitoring

```swift
let monitor = CursorMonitor()

monitor.onPositionChanged = { position in
    print("Cursor moved to: \(position.point)")
    print("Detection method: \(position.type.rawValue)")
}

monitor.onError = { error in
    print("Monitoring error: \(error)")
}

monitor.startMonitoring()
// Later: monitor.stopMonitoring()
```

### High-Performance Monitoring

```swift
let monitor = CursorMonitor.highResponsiveness()

monitor.onPositionChanged = { position in
    updateCursorIndicator(at: position.point)
}

monitor.startMonitoring()
```

### Custom Configuration

```swift
let monitor = CursorMonitor()
monitor.pollingInterval = 0.05
monitor.changeThreshold = 1.0
monitor.correctionMode = .none

monitor.onPositionChanged = { position in
    // Handle position changes
}

monitor.startMonitoring()
```

### Lifecycle Management

```swift
class MyViewController: NSViewController {
    private let monitor = CursorMonitor()

    override func viewDidAppear() {
        super.viewDidAppear()

        monitor.onPositionChanged = { [weak self] position in
            self?.handleCursorMove(position)
        }

        monitor.startMonitoring()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        monitor.stopMonitoring()
    }

    deinit {
        monitor.stopMonitoring()
    }
}
```

## Notes

- **Polling Interval**: Lower values = more responsive but more CPU usage
- **Change Threshold**: Higher values = fewer callbacks for small movements
- **Background Queue**: Monitoring runs on background queue to avoid blocking main thread
- **Automatic Cleanup**: Monitor automatically stops when deallocated

### Update Triggers

`onPositionChanged` fires when:
1. Cursor position changes beyond the `changeThreshold`, OR
2. Cursor type changes (regardless of position)
