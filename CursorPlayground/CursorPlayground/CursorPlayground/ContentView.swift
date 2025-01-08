//
//  ContentView.swift
//  CursorPlayground
//
//  Created by Aether on 08/01/2025.
//

import SwiftUI
import CursorBounds

struct ContentView: View {
    @State private var selectedView: SidebarItem? = .captureTimer
    @State private var currentOrigin: NSPoint? = nil
    @State private var capturedOrigins: [Origin] = []
    @State private var timerInterval: Double = 1.0 // Default timer interval in seconds
    @State private var timer: Timer? = nil

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SidebarItem.allCases, selection: $selectedView) { item in
                Label(item.rawValue, systemImage: item.iconName)
            }
            .navigationTitle("Cursor Playground")
        } detail: {
            // Detail views
            VStack {
                if selectedView == .currentOrigin {
                    CurrentOriginView(currentOrigin: $currentOrigin)
                } else if selectedView == .captureTimer {
                    CaptureTimerView(
                        capturedOrigins: $capturedOrigins,
                        timerInterval: $timerInterval,
                        startTimer: startTimer,
                        stopTimer: stopTimer
                    )
                }
            }
            .padding()
            .onAppear {
                if selectedView == .currentOrigin {
                    fetchOrigin()
                }
            }
        }
    }

    // Fetch the current origin and update the state
    private func fetchOrigin() {
        if let origin = CursorBounds().getOrigin() {
            currentOrigin = origin.NSPoint
        } else {
            currentOrigin = nil
        }
    }

    // Start the timer to capture the origin
    private func startTimer() {
        stopTimer() // Ensure any existing timer is invalidated
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
            if let origin = CursorBounds().getOrigin() {
                capturedOrigins.append(origin)
            }
        }
    }

    // Stop the timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct CurrentOriginView: View {
    @Binding var currentOrigin: NSPoint?

    var body: some View {
        VStack(spacing: 20) {
            Text("Current Origin")
                .font(.headline)

            if let origin = currentOrigin {
                Text("x: \(origin.x), y: \(origin.y)")
                    .font(.body)
                    .foregroundColor(.green)
            } else {
                Text("No origin captured.")
                    .font(.body)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .onAppear {
            currentOrigin = CursorBounds().getOrigin()?.NSPoint
        }
    }
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case currentOrigin = "Current Origin"
    case captureTimer = "Capture Timer"

    var id: String { self.rawValue }
    var iconName: String {
        switch self {
        case .currentOrigin: return "cursorarrow.rays"
        case .captureTimer: return "clock.arrow.circlepath"
        }
    }
}

#Preview {
    ContentView()
}
