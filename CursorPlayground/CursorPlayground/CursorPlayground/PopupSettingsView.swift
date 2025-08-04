//  PopupSettingsView.swift
//  CursorPlayground
//  Refactored to use KeyboardShortcuts for persistent global shortcut handling.

import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePopup = Self("togglePopup")
}

struct PopupSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popup Configuration")
                .font(.title3.weight(.semibold))
            Text("Choose the keyboard shortcut that toggles the popup. The setting is stored automatically by KeyboardShortcuts.")
                .foregroundStyle(.secondary)

            KeyboardShortcuts.Recorder("Shortcut:", name: .togglePopup)
                .padding(.vertical, 4)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    PopupSettingsView()
        .frame(width: 400, height: 120)
}
