# CursorBounds - Error Handling

Swift error handling with the `CursorBoundsError` enum.

## Quick Start

```swift
do {
    let position = try cursorBounds.cursorPosition()
} catch CursorBoundsError.accessibilityPermissionDenied {
    CursorBounds.requestAccessibilityPermissions()
} catch {
    print("Error: \(error)")
}
```

## CursorBoundsError

```swift
public enum CursorBoundsError: Error, LocalizedError {
    case accessibilityPermissionDenied
    case noFocusedElement
    case cursorPositionUnavailable
    case screenNotFound
}
```

## Error Types

### accessibilityPermissionDenied

User has not granted accessibility permissions.

```swift
catch CursorBoundsError.accessibilityPermissionDenied {
    if !CursorBounds.isAccessibilityEnabled() {
        CursorBounds.requestAccessibilityPermissions()
    }
}
```

### noFocusedElement

No UI element is currently focused.

```swift
catch CursorBoundsError.noFocusedElement {
    // Often not critical - system will use mouse fallback
}
```

### cursorPositionUnavailable

Cursor position cannot be determined through any method.

```swift
catch CursorBoundsError.cursorPositionUnavailable {
    // Consider using a default position
}
```

### screenNotFound

Cursor position is outside all available screen bounds.

```swift
catch CursorBoundsError.screenNotFound {
    // Screen configuration may have changed
}
```

## Error Recovery Patterns

### Basic Error Handling

```swift
func getCursorPosition() -> CursorPosition? {
    do {
        return try CursorBounds().cursorPosition()
    } catch CursorBoundsError.accessibilityPermissionDenied {
        CursorBounds.requestAccessibilityPermissions()
        return nil
    } catch CursorBoundsError.noFocusedElement {
        return nil  // Not critical
    } catch CursorBoundsError.cursorPositionUnavailable {
        return nil
    } catch CursorBoundsError.screenNotFound {
        return nil
    } catch {
        print("Unexpected error: \(error)")
        return nil
    }
}
```

### Permission Check Pattern

```swift
func ensureAccessibilityPermissions() -> Bool {
    guard CursorBounds.isAccessibilityEnabled() else {
        CursorBounds.requestAccessibilityPermissions()
        return false
    }
    return true
}

func safeGetCursorPosition() -> CursorPosition? {
    guard ensureAccessibilityPermissions() else { return nil }

    do {
        return try CursorBounds().cursorPosition()
    } catch {
        print("Error: \(error.localizedDescription)")
        return nil
    }
}
```

### Monitoring Error Handling

```swift
let monitor = CursorMonitor()

monitor.onError = { error in
    switch error {
    case .accessibilityPermissionDenied:
        monitor.stopMonitoring()

    case .noFocusedElement:
        break  // Common and usually not critical

    case .cursorPositionUnavailable:
        print("Temporary issue")

    case .screenNotFound:
        print("Screen configuration may have changed")
    }
}
```

### Retry Pattern

```swift
func getCursorPositionWithRetry(maxAttempts: Int = 3) -> CursorPosition? {
    for attempt in 1...maxAttempts {
        do {
            return try CursorBounds().cursorPosition()
        } catch CursorBoundsError.accessibilityPermissionDenied {
            return nil  // Don't retry permission errors
        } catch {
            print("Attempt \(attempt) failed: \(error)")
            if attempt < maxAttempts {
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
    return nil
}
```

## Localized Error Messages

All errors provide localized descriptions and recovery suggestions:

```swift
do {
    let position = try cursorBounds.cursorPosition()
} catch let error as CursorBoundsError {
    print("Error: \(error.localizedDescription)")
    if let suggestion = error.recoverySuggestion {
        print("Suggestion: \(suggestion)")
    }
}
```

## Best Practices

1. **Always check permissions first** using `CursorBounds.isAccessibilityEnabled()`
2. **Handle permission errors gracefully** by guiding users to grant access
3. **Don't treat `noFocusedElement` as critical** - it's often expected
4. **Use monitoring error callbacks** for ongoing issues
5. **Implement retry logic** for transient errors
6. **Provide fallback behavior** when cursor detection fails
