//  PopupManager.swift
//  CursorPlayground
//
//  Singleton that owns the GlobalHotKey and manages showing / hiding the CursorPopupPanel.

import Foundation
import CursorBounds
import AppKit

final class PopupManager {
    static let shared = PopupManager()
    private init() {
        setupHotKey()
    }
    
    // MARK: - Properties
    private let hotKey = GlobalHotKey()
    private var panel: CursorPopupPanel?
    private let cursorBounds = CursorBounds()
    
    // MARK: - Setup
    private func setupHotKey() {
        hotKey.register { [weak self] in
            self?.togglePanel()
        }
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
