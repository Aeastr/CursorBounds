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
    init(position: CursorPosition) {
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
        
        contentView = NSHostingView(rootView: PopupContent(position: position))
        setFrameOrigin(frameOrigin(for: position))
        
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
    func reposition(to position: CursorPosition) {
        setFrameOrigin(frameOrigin(for: position))
        if let hosting = contentView as? NSHostingView<PopupContent> {
            hosting.rootView = PopupContent(position: position)
        }
    }
    
    private func frameOrigin(for pos: CursorPosition) -> NSPoint {
        // Use the built-in smart positioning from CursorBounds package
        let cursorBounds = CursorBounds()
        do {
            return try cursorBounds.smartPosition(
                for: frame.size,
                preferredPosition: .below,
                margin: 12
            )
        } catch {
            // Fallback to cursor position if smart positioning fails
            print("[CursorPopupPanel] Smart positioning failed: \(error), using cursor position")
            return pos.point
        }
    }
}
