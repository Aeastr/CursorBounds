//
//  CaptureTimerView.swift
//  CursorPlayground
//
//  Created by Aether on 08/01/2025.
//

import SwiftUI
import CursorBounds

struct CaptureTimerView: View {
    @Binding var capturedOrigins: [Origin]
    @Binding var timerInterval: Double
    var startTimer: () -> Void
    var stopTimer: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 20) {
                Text("Capture Timer")
                    .font(.headline)
                
                // Timer settings
                VStack {
                    Text("Timer Interval (seconds):")
                        .font(.subheadline)
                    HStack {
                        Text("\(String(format: "%.1f", timerInterval))")
                            .frame(width: 50)
                        Slider(value: $timerInterval, in: 0.5...10, step: 0.5)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .frame(maxHeight: .infinity, alignment: .top)

            // Captured origins
            VStack(alignment: .leading) {
                HStack {
                    Text("Captured Origins:")
                        .font(.subheadline)
                    
                    HStack {
                        Button("Start") {
                            startTimer()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Stop") {
                            stopTimer()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                scrollSection()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    func scrollSection() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                ForEach(capturedOrigins, id: \.self) { origin in
                    VStack(alignment: .leading) {
                        Text("Type: \(origin.type.rawValue)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("x: \(origin.NSPoint.x), y: \(origin.NSPoint.y)")
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .id(origin.id) // Assign a unique ID for each item
                }
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .onChange(of: capturedOrigins) { _ in
                // Scroll to the last item when the list changes
                if let lastItem = capturedOrigins.last {
                    proxy.scrollTo(lastItem.id, anchor: .bottom)
                }
            }
        }
    }
}
