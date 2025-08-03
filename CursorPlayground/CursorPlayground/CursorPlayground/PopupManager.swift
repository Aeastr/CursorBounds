//  PopupManager.swift
//  CursorPlayground
//
//  Singleton that owns the GlobalHotKey and manages showing / hiding the CursorPopupPanel.

import Foundation
import CursorBounds
import AppKit
import KeyboardShortcuts

final class PopupManager {
    static let shared = PopupManager()
    private init() {
        setupHotKey()
    }
    
    // MARK: - Properties
    private var panel: CursorPopupPanel?
    private let cursorBounds = CursorBounds()
    
    // MARK: - Setup
    private func setupHotKey() {
        KeyboardShortcuts.onKeyUp(for: .togglePopup) { [weak self] in
            self?.togglePanel()
        }
    }
    
    // MARK: - Public
    /// Update the global hot-key with new values and persist them.
    func updateShortcut() {
        setupHotKey()
    }
    
    // MARK: - Panel Control
    private func togglePanel() {
        do {
            let position = try cursorBounds.cursorPosition(correctionMode: .adjustForYAxis)
            if let panel, panel.isVisible {
                panel.reposition(to: position)
            } else {
                let newPanel = CursorPopupPanel(position: position)
                newPanel.orderFrontRegardless()
                newPanel.makeKey()
                self.panel = newPanel
            }
        } catch {
            NSLog("PopupManager: Failed to obtain cursor position: \(error.localizedDescription)")
        }
    }
}
