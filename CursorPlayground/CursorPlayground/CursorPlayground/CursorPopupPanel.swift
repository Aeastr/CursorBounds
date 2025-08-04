//  CursorPopupPanel.swift
//  CursorPlayground
//
//  A lightweight non-activating panel that positions itself at a given cursor position
//  and closes automatically when it loses key status.

import AppKit
import SwiftUI
import CursorBounds

/// Simple content shown inside the popup. Replace with real UI later.
private struct PopupContent: View {
    let position: CursorPosition
    var body: some View {
        ZStack{
            VisualEffectView()
            
            VStack(spacing: 8) {
                Text("Cursor")
                    .font(.headline)
                Text("x: \(String(format: "%.1f", position.point.x))  y: \(String(format: "%.1f", position.point.y))")
                    .font(.monospacedDigit(.body)())
                Text(position.type.rawValue)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .frame(minWidth: 160)
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let visualEffectView = NSVisualEffectView()
    
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        return visualEffectView
    }
    
    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

final class CursorPopupPanel: NSPanel {
    // MARK: - Lifecycle
    init() {
        let size = NSSize(width: 200, height: 120)
        super.init(contentRect: NSRect(origin: .zero, size: size),
                   styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                   backing: .buffered,
                   defer: false)
        
        identifier = NSUserInterfaceItemIdentifier("CursorPopupPanel")
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.auxiliary, .moveToActiveSpace]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        
        isOpaque = false
        backgroundColor = .clear
        
        // Initialize with current cursor position
        do {
            let cursorBounds = CursorBounds()
            let cursorContext = CursorContext()
            let position = try cursorBounds.cursorPosition(correctionMode: .adjustForYAxis)
            if let info = cursorContext.windowInfo() { print(info) }
            contentView = NSHostingView(rootView: PopupContent(position: position))
            let origin = try frameOrigin()
            setFrameOrigin(origin)
        } catch {
            // Fallback if cursor position fails
            print("[CursorPopupPanel] Failed to get cursor position during init: \(error)")
            let fallbackPosition = CursorPosition(
                point: NSPoint(x: 100, y: 100),
                type: .mouseFallback,
                bounds: CGRect(x: 100, y: 100, width: 0, height: 0),
                screen: NSScreen.main ?? NSScreen.screens[0]
            )
            contentView = NSHostingView(rootView: PopupContent(position: fallbackPosition))
            setFrameOrigin(NSPoint(x: 100, y: 100))
        }
        
        // Rounded corners & shadow
        if let cv = contentView {
            // Apply to the window backing view to actually clip corners
            if let sv = cv.superview {
                sv.wantsLayer = true
                sv.layer?.cornerRadius = 12
                sv.layer?.masksToBounds = true
            }
            cv.wantsLayer = true
        }
        hasShadow = true
    }
    
    override var canBecomeKey: Bool { true }
    
    override func resignKey() {
        super.resignKey()
        close()
    }
    
    // MARK: - Positioning
    func reposition() {
        do {
            let origin = try frameOrigin()
            setFrameOrigin(origin)
            
            // Update content with current cursor position for display
            let cursorBounds = CursorBounds()
            let position = try cursorBounds.cursorPosition(correctionMode: .adjustForYAxis)
            if let hosting = contentView as? NSHostingView<PopupContent> {
                hosting.rootView = PopupContent(position: position)
            }
        } catch {
            print("[CursorPopupPanel] Failed to reposition: \(error)")
        }
    }
    
    private func frameOrigin() throws -> NSPoint {
        // Use the built-in smart positioning from CursorBounds package
        let cursorBounds = CursorBounds()
        return try cursorBounds.smartPosition(
            for: frame.size,
            preferredPosition: .below,
            margin: 12
        )
    }
}
