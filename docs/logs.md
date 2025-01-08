
# Log Levels Key

This document outlines the log types used in the project, categorized by **OSLogLevel** and their intended purposes.

By default, log level is `.error`, you can set this when calling `CursorBounds()`

swift```
CursorBounds(logLevel: .debug)
```

---

## Log Levels

| **OSLogLevel**                  | **Icon**   | **Description**                                                                                   |
|----------------------------------|------------|---------------------------------------------------------------------------------------------------|
| `.log` / `.trace` / `.debug`    | 🔍 [DEBUG] | Provides detailed, low-level information useful for debugging or tracing application flow.       |
| `.info`                         | ℹ️ [INFO]  | Highlights informational messages about the application's state or operations.                  |
| `.notice`                       | 🗒️ [NOTICE] | Indicates noteworthy events that don’t require attention but are worth logging.                 |
| `.warning`                      | ⚠️ [WARNING] | Reports potential issues or recoverable errors that may affect the application's behavior.       |
| `.error`                        | 🚨 [ERROR] | Signals critical failures requiring immediate attention to prevent or resolve issues.            |
| `.critical`                     | 🚫 [CRITICAL] | Indicates severe errors causing disruption in functionality or requiring urgent action.          |
| `.fault`                        | ❗ [FAULT] | Logs significant system-level errors indicating potential issues in the operating environment.   |

---

## Examples

### Debug Logs
- Used for detailed tracing and debugging purposes.
- Example:
  ```
  🔍 [DEBUG] [getMouseCursorRect] Start
  🔍 [DEBUG] [getCaretBounds] Successfully obtained AXValue: (x: 10, y: 20, width: 100, height: 50)
  ```

### Info Logs
- Highlights normal, significant events or state transitions.
- Example:
  ```
  ℹ️ [INFO] [getCursorPosition] Successfully retrieved cursor position: 42
  ```

### Notice Logs
- Logs noteworthy, but non-critical events.
- Example:
  ```
  🗒️ [NOTICE] [getAttributeString] Attribute 'AXRole' was unexpectedly empty but processing continues.
  ```

### Warning Logs
- Reports potential issues or recoverable problems.
- Example:
  ```
  ⚠️ [WARNING] [getMouseCursorRect] Failed to find screen containing mouse location.
  ```

### Error Logs
- Logs critical application errors.
- Example:
  ```
  🚨 [ERROR] [getCaretRect] Failed to retrieve AXFrame attribute.
  ```

### Critical Logs
- Indicates severe errors requiring immediate attention.
- Example:
  ```
  🚫 [CRITICAL] [getAttributeRect] Unexpected nil value for critical attribute AXFrame.
  ```

### Fault Logs
- Reserved for system-level errors indicating significant problems.
- Example:
  ```
  ❗ [FAULT] [getCursorPosition] System-level error: AXUIElement not responding.
  ```

---

## Logging Behavior

The logging function adheres to a threshold defined by `currentLogLevel`, ensuring only logs meeting or exceeding the set level are printed. Each log type uses the appropriate `OSLogLevel` and is formatted with an icon for clarity.

This setup provides structured, concise, and actionable logging to streamline development and debugging processes.
