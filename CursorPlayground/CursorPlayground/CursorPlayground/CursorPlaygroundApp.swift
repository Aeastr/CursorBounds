//
//  CursorPlaygroundApp.swift
//  CursorPlayground
//
//  Created by Aether on 08/01/2025.
//

import SwiftUI

@main
struct CursorPlaygroundApp: App {
    init() {
        // Initialize popup manager once to register the global hot-key
        _ = PopupManager.shared
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
