//
//  CursorMonitor.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//

import Foundation
import AppKit

/// Provides continuous monitoring of cursor position with configurable polling and change detection
///
/// The monitor will trigger updates when either:
/// - The cursor position changes beyond the specified threshold, OR
/// - The cursor type changes (regardless of position)
///
/// ## Usage
/// ```swift
/// let monitor = CursorMonitor()
/// monitor.pollingInterval = 0.05 // 50ms for high responsiveness
/// monitor.changeThreshold = 5.0  // 5 pixels minimum change
///
/// monitor.onPositionChanged = { position in
///     // Update UI with new cursor position
/// }
///
/// monitor.startMonitoring()
/// ```
public class CursorMonitor {
    
    // MARK: - Debug Configuration
    
    /// Enable or disable debug logging for cursor detection. Default is `false`.
    /// When enabled, prints detailed information about cursor position resolution,
    /// detection methods, and any issues encountered.
    public static var isDebugEnabled: Bool = false
    
    // MARK: - Configuration
    
    /// How frequently to check cursor position (in seconds)
    /// Default: 0.1 seconds (100ms)
    public var pollingInterval: TimeInterval = 0.1
    
    /// Minimum distance cursor must move to trigger an update (in pixels)
    /// Default: 2.0 pixels
    /// Note: Type changes will always trigger updates regardless of this threshold
    public var changeThreshold: CGFloat = 2.0
    
    /// Screen correction mode to use for cursor position
    /// Default: .adjustForYAxis
    public var correctionMode: ScreenCorrectionMode = .adjustForYAxis
    
    /// Which corner of the cursor bounds to use for positioning
    /// Default: .topLeft
    public var corner: BoundsCorner = .topLeft
    
    // MARK: - Callbacks
    
    /// Called when cursor position or type changes
    public var onPositionChanged: ((CursorPosition) -> Void)?
    
    /// Called when an error occurs during monitoring
    public var onError: ((CursorBoundsError) -> Void)?
    
    /// Called when monitoring starts
    public var onMonitoringStarted: (() -> Void)?
    
    /// Called when monitoring stops
    public var onMonitoringStopped: (() -> Void)?
    
    // MARK: - Private Properties
    
    private var timer: DispatchSourceTimer?
    private var lastPosition: CursorPosition?
    private let cursorBounds = CursorBounds()
    private let monitorQueue = DispatchQueue(label: "com.cursorbounds.monitor", qos: .userInteractive)
    
    // MARK: - Public Properties
    
    /// Whether the monitor is currently active
    public private(set) var isMonitoring: Bool = false
    
    /// The last known cursor position
    public var currentPosition: CursorPosition? {
        return lastPosition
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Control Methods
    
    /// Starts continuous monitoring of cursor position
    /// - Note: Monitoring runs on a background queue to avoid blocking the main thread
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // Create and configure timer
        timer = DispatchSource.makeTimerSource(queue: monitorQueue)
        timer?.schedule(deadline: .now(), repeating: pollingInterval)
        
        timer?.setEventHandler { [weak self] in
            self?.checkCursorPosition()
        }
        
        timer?.resume()
        
        // Notify on main queue
        DispatchQueue.main.async { [weak self] in
            self?.onMonitoringStarted?()
        }
    }
    
    /// Stops cursor monitoring
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        timer?.cancel()
        timer = nil
        lastPosition = nil
        
        // Notify on main queue
        DispatchQueue.main.async { [weak self] in
            self?.onMonitoringStopped?()
        }
    }
    
    /// Manually triggers a cursor position check
    /// - Returns: The current cursor position, if available
    @discardableResult
    public func checkNow() -> CursorPosition? {
        checkCursorPosition()
        return lastPosition
    }
    
    // MARK: - Private Methods
    
    private func checkCursorPosition() {
        do {
            let newPosition = try cursorBounds.cursorPosition(
                correctionMode: correctionMode,
                corner: corner
            )
            
            // Check if we should trigger an update
            if shouldTriggerUpdate(for: newPosition) {
                lastPosition = newPosition
                
                // Notify on main queue
                DispatchQueue.main.async { [weak self] in
                    self?.onPositionChanged?(newPosition)
                }
            }
            
        } catch {
            // Handle cursor bounds errors
            if let cursorError = error as? CursorBoundsError {
                DispatchQueue.main.async { [weak self] in
                    self?.onError?(cursorError)
                }
            }
        }
    }
    
    private func shouldTriggerUpdate(for newPosition: CursorPosition) -> Bool {
        guard let lastPosition = lastPosition else {
            // First position always triggers update
            return true
        }
        
        // Always trigger if cursor type changed
        if newPosition.type != lastPosition.type {
            return true
        }
        
        // Check if position changed beyond threshold
        let distance = sqrt(
            pow(newPosition.point.x - lastPosition.point.x, 2) +
            pow(newPosition.point.y - lastPosition.point.y, 2)
        )
        
        return distance >= changeThreshold
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - Convenience Extensions

public extension CursorMonitor {
    
    /// Creates a monitor with high responsiveness settings
    /// - Returns: A monitor configured for real-time tracking
    static func highResponsiveness() -> CursorMonitor {
        let monitor = CursorMonitor()
        monitor.pollingInterval = 0.05 // 50ms
        monitor.changeThreshold = 1.0  // 1 pixel
        return monitor
    }
    
    /// Creates a monitor with balanced performance settings
    /// - Returns: A monitor configured for balanced performance
    static func balanced() -> CursorMonitor {
        let monitor = CursorMonitor()
        monitor.pollingInterval = 0.1  // 100ms
        monitor.changeThreshold = 2.0  // 2 pixels
        return monitor
    }
    
    /// Creates a monitor with power-efficient settings
    /// - Returns: A monitor configured for minimal CPU usage
    static func powerEfficient() -> CursorMonitor {
        let monitor = CursorMonitor()
        monitor.pollingInterval = 0.25 // 250ms
        monitor.changeThreshold = 5.0  // 5 pixels
        return monitor
    }
}
