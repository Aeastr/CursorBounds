//  GlobalHotKey.swift
//  CursorPlayground
//
//  Registers a system-wide keyboard shortcut using Carbon APIs (no external dependencies).
//  The default shortcut is ⇧⌘P (Shift + Command + P).
//  A closure is invoked whenever the hot-key is pressed.

import AppKit
import Carbon

final class GlobalHotKey {
    typealias Handler = () -> Void
    
    // MARK: - Properties
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var handler: Handler?
    
    // MARK: - Initialization
    init() {}
    
    deinit {
        unregister()
    }
    
    // MARK: - Registration
    /// Registers a system-wide hotkey.
    /// - Parameters:
    ///   - keyCode: Virtual key-code (e.g. `kVK_ANSI_P`).
    ///   - modifiers: Carbon modifier flags (e.g. `cmdKey | shiftKey`).
    ///   - handler: Callback executed when the shortcut is pressed.
    func register(keyCode: UInt32 = UInt32(kVK_ANSI_P),
                  modifiers: UInt32 = UInt32((cmdKey | shiftKey)),
                  handler: @escaping Handler) {
        unregister()
        self.handler = handler
        
        var hotKeyID = EventHotKeyID(signature: FourCharCode("CBHK"), id: 1)
        let status = RegisterEventHotKey(keyCode,
                                         modifiers,
                                         hotKeyID,
                                         GetEventDispatcherTarget(),
                                         0,
                                         &hotKeyRef)
        guard status == noErr else {
            NSLog("GlobalHotKey: Registration failed with status \(status)")
            return
        }
        
        // Install an application-level event handler for the hot-key command.
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        let callback: EventHandlerUPP = { _, eventRef, userData in
            if let userData = userData {
                let unmanaged = Unmanaged<GlobalHotKey>.fromOpaque(userData)
                unmanaged.takeUnretainedValue().hotKeyFired()
            }
            return noErr
        }
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetEventDispatcherTarget(), callback, 1, &eventType, selfPtr, &eventHandlerRef)
    }
    
    /// Unregisters any existing hot-key.
    func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
        hotKeyRef = nil
        eventHandlerRef = nil
        handler = nil
    }
    
    // MARK: - Action
    private func hotKeyFired() {
        DispatchQueue.main.async { [weak self] in
            self?.handler?()
        }
    }
}

// MARK: - FourCharCode convenience
private extension FourCharCode {
    /// Creates a FourCharCode from a 4-character String, e.g. "CBHK".
    init(_ string: String) {
        precondition(string.utf16.count == 4, "String must be 4 characters long")
        self = string.utf16.reduce(0) { ($0 << 8) + FourCharCode($1) }
    }
}
