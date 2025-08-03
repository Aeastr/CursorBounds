//
//  ContentView.swift
//  CursorPlayground
//
//  Created by Aether on 08/01/2025.
//

import SwiftUI
import CursorBounds
import Combine

enum SidebarItem: String, CaseIterable, Identifiable {
    case currentOrigin = "Current Origin"
    case captureTimer = "Capture Timer"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .currentOrigin: return "cursorarrow.rays"
        case .captureTimer: return "clock.arrow.circlepath"
        }
    }
}

struct ContentView: View {
    @State private var selectedView: SidebarItem? = .captureTimer
    @State private var currentPosition: CursorPosition? = nil
    @State private var capturedPositions: [CursorPosition] = []
    @State private var timerInterval: Double = 1.0
    @State private var isCapturing = false
    
    // Continuous Monitor
    @State private var cursorMonitor = CursorMonitor()
    @State private var isMonitoring = false
    @State private var monitoredPosition: CursorPosition? = nil
    @State private var monitoringHistory: [CursorPosition] = []
    
    // Accessibility
    @State private var hasAccessibilityPermissions = false
    @State private var showPermissionsSheet = false
    
    // Timer via Combine (safer UI updates, easy to cancel)
    @State private var timerCancellable: AnyCancellable?
    
    var body: some View {
        
        NavigationSplitView {
            // Sidebar
            List(SidebarItem.allCases, id: \.id, selection: $selectedView) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.iconName)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Cursor Playground")
        } detail: {
            ZStack {
                // Detail View
                Group {
                    switch selectedView {
                    case .currentOrigin:
                        CurrentOriginView(
                            currentPosition: $currentPosition,
                            onRefresh: fetchPosition
                        )
                        .padding()
                    case .captureTimer:
                        CaptureTimerView(
                            capturedPositions: capturedPositions,
                            timerInterval: $timerInterval,
                            isCapturing: isCapturing,
                            onStartStop: {
                                if isCapturing { stopTimer() } else { startTimer() }
                            },
                            onClear: {
                                capturedPositions = []
                            }
                        )
                        .padding()
                    case .none:
                        ContentUnavailableView(
                            "Select a View",
                            systemImage: "sidebar.left",
                            description: Text("Choose an item from the sidebar.")
                        )
                        .padding()
                    }
                }
                .blur(radius: showPermissionsSheet || !hasAccessibilityPermissions ? 2 : 0)
                .animation(.easeInOut(duration: 0.2), value: showPermissionsSheet)
                .animation(.easeInOut(duration: 0.2), value: hasAccessibilityPermissions)
                
                if !hasAccessibilityPermissions {
                    PermissionOverlay {
                        showPermissionsSheet = true
                    }
                    .transition(.opacity)
                }
            }
        }
        .sheet(isPresented: $showPermissionsSheet) {
            PermissionsSheet {
                CursorBounds.requestAccessibilityPermissions()
            } onDismiss: {
                checkPermissions()
            }
        }
        
        .onAppear {
            checkPermissions()
        }
    }
    
    private func checkPermissions() {
        let enabled = CursorBounds.isAccessibilityEnabled()
        hasAccessibilityPermissions = enabled
        if !enabled {
            showPermissionsSheet = true
        }
    }
    
    private func fetchPosition() {
        guard hasAccessibilityPermissions else { return }
        do {
            currentPosition = try CursorBounds().cursorPosition()
        } catch {
            currentPosition = nil
            debugPrint("Error fetching cursor position: \(error.localizedDescription)")
        }
    }
    
    private func startTimer() {
        guard hasAccessibilityPermissions else {
            showPermissionsSheet = true
            return
        }
        stopTimer()
        isCapturing = true
        timerCancellable = Timer
            .publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                do {
                    let position = try CursorBounds().cursorPosition()
                    capturedPositions.append(position)
                } catch {
                    debugPrint("Error fetching cursor position: \(error.localizedDescription)")
                }
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isCapturing = false
    }
}

// MARK: - Permission UI

struct PermissionOverlay: View {
    var onOpen: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(.secondary)
            
            Text("Accessibility Permissions Required")
                .font(.title3.weight(.semibold))
            
            Text(
                "CursorPlayground needs accessibility permissions to read the " +
                "cursor position. Grant permissions in System Settings."
            )
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 460)
            
            HStack(spacing: 12) {
                Button("Open System Settings", action: onOpen)
                    .buttonStyle(.borderedProminent)
                Button("Not Now", role: .cancel) {}
                    .buttonStyle(.bordered)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: 12, y: 8)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}

struct PermissionsSheet: View {
    var onOpen: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lock.shield")
                
                Text("Accessibility Permissions")
                    .font(.title3.weight(.semibold))
                Spacer()
            }
            
            Text(
                "This app reads the current cursor position using Accessibility. " +
                "Click the button below to open System Settings and grant permission."
            )
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Button("Open System Settings", action: onOpen)
                    .buttonStyle(.borderedProminent)
                Button("Done") {
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            PermissionTips()
                .padding(.top, 4)
        }
        .padding(20)
        .frame(minWidth: 480)
        .onAppear {
            // Auto-poll lightly to update permission state when user returns
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onDismiss()
            }
        }
    }
}

struct PermissionTips: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tips")
                .font(.headline)
            Text("• System Settings > Privacy & Security > Accessibility")
            Text("• Click the lock to make changes, then enable CursorPlayground")
            Text("• Restart the app if it doesn’t update right away")
                .foregroundStyle(.secondary)
        }
        .font(.callout)
    }
}

// MARK: - Current Origin

struct CurrentOriginView: View {
    @Binding var currentPosition: CursorPosition?
    var onRefresh: () -> Void
    
    @State private var monitor = CursorMonitor()
    @State private var isMonitoring = false
    @State private var pollingInterval: Double = 0.1
    @State private var changeThreshold: CGFloat = 2.0
    
    // Alert states for direct input
    @State private var showPollingAlert = false
    @State private var showThresholdAlert = false
    @State private var pollingInputText = ""
    @State private var thresholdInputText = ""
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            
            // Settings (Left side)
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.title3.weight(.semibold))
                
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Polling interval
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Polling Rate")
                        HStack(spacing: 12) {
                            Slider(value: $pollingInterval, in: 0.05...0.5)
                            Button {
                                pollingInputText = String(format: "%.0f", pollingInterval * 1000)
                                showPollingAlert = true
                            } label: {
                                Text("\(String(format: "%.0f", pollingInterval * 1000))ms")
                                    .contentTransition(.numericText(value: pollingInterval))
                                    .animation(.smooth, value: pollingInterval)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Change threshold
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Change Threshold")
                        HStack(spacing: 12) {
                            Slider(value: $changeThreshold, in: 1.0...10.0)
                            Button {
                                thresholdInputText = String(format: "%.1f", changeThreshold)
                                showThresholdAlert = true
                            } label: {
                                Text("\(String(format: "%.1f", changeThreshold))px")
                                    .contentTransition(.numericText(value: changeThreshold))
                                    .animation(.smooth, value: changeThreshold)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: 240)
            
            // Results (Right side)
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Position")
                    .font(.title3.weight(.semibold))
                
                Group {
                    if let position = currentPosition {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Type", systemImage: "cursorarrow")
                                    .foregroundStyle(.secondary)
                                Text(position.type.rawValue)
                                    .font(.body.monospaced())
                                    .monospacedDigit()
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Coordinates", systemImage: "mappin.and.ellipse")
                                    .foregroundStyle(.secondary)
                                Text("x: \(format(position.point.x)), y: \(format(position.point.y))")
                                    .font(.body.monospaced())
                                    .monospacedDigit()
                                //                                        .contentTransition(.numericText())
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Bounds", systemImage: "square.dashed")
                                    .foregroundStyle(.secondary)
                                Text(position.bounds.debugDescription)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                    .monospacedDigit()
                            }
                            
                            
                            if isMonitoring {
                                HStack {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 8, height: 8)
                                    Text("Live monitoring active")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(16)
                    } else {
                        ContentUnavailableView(
                            "No position captured",
                            systemImage: "questionmark.circle",
                            description: Text(isMonitoring ? "Monitoring for cursor movement..." : "Click Refresh or Start monitoring to track cursor position.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    }
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(.thinMaterial))
                .onChange(of: pollingInterval) { newValue in
                    updateMonitorSettings()
                }
                .onChange(of: changeThreshold) { newValue in
                    updateMonitorSettings()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    if isMonitoring {
                        stopMonitoring()
                    } else {
                        startMonitoring()
                    }
                } label: {
                    Label(isMonitoring ? "Stop" : "Start",
                          systemImage: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                }
                .keyboardShortcut(.space, modifiers: [])
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Refresh", action: onRefresh)
                    .disabled(isMonitoring)
                    .keyboardShortcut("r", modifiers: .command)
            }
        }
        .alert("Set Polling Rate", isPresented: $showPollingAlert) {
            TextField("Milliseconds (50-500)", text: $pollingInputText)
            Button("Cancel", role: .cancel) { }
            Button("Set") {
                if let value = Double(pollingInputText), value >= 50, value <= 500 {
                    pollingInterval = value / 1000.0
                }
            }
        } message: {
            Text("Enter polling rate in milliseconds (50-500)")
        }
        .alert("Set Change Threshold", isPresented: $showThresholdAlert) {
            TextField("Pixels (1.0-10.0)", text: $thresholdInputText)
            Button("Cancel", role: .cancel) { }
            Button("Set") {
                if let value = Double(thresholdInputText), value >= 1.0, value <= 10.0 {
                    changeThreshold = CGFloat(value)
                }
            }
        } message: {
            Text("Enter change threshold in pixels (1.0-10.0)")
        }
        .onAppear {
            setupMonitor()
            onRefresh()
        }
        .onDisappear {
            stopMonitoring()
        }
    }
    
    private func setupMonitor() {
        monitor.pollingInterval = pollingInterval
        monitor.changeThreshold = changeThreshold
        
        monitor.onPositionChanged = { position in
            currentPosition = position
        }
    }
    
    private func startMonitoring() {
        updateMonitorSettings()
        monitor.startMonitoring()
        isMonitoring = true
    }
    
    private func stopMonitoring() {
        monitor.stopMonitoring()
        isMonitoring = false
    }
    
    private func updateMonitorSettings() {
        monitor.pollingInterval = pollingInterval
        monitor.changeThreshold = changeThreshold
        
        // Restart monitoring with new settings if currently active
        if isMonitoring {
            monitor.stopMonitoring()
            monitor.startMonitoring()
        }
    }
    
    private func format(_ d: CGFloat) -> String {
        String(format: "%.1f", d)
    }
}

// MARK: - Capture Timer

struct CaptureTimerView: View {
    var capturedPositions: [CursorPosition]
    @Binding var timerInterval: Double
    var isCapturing: Bool
    var onStartStop: () -> Void
    var onClear: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 20){
            
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.title3.weight(.semibold))
                VStack(alignment: .leading, spacing: 8){
                    Text("Interval")
                    HStack(spacing: 12) {
                        
                        Slider(value: $timerInterval, in: 0.2 ... 10)
                        
                        Text("\(String(format: "%.1f", timerInterval))s")
                            .contentTransition(.numericText(value: timerInterval))
                            .animation(.smooth, value: timerInterval)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: 240)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Captured Positions")
                    .font(.title3.weight(.semibold))
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(capturedPositions) { position in
                                CapturedRow(position: position)
                                    .id(position.id)
                            }
                        }
                        .padding(8)
                    }
                    .background(RoundedRectangle(cornerRadius: 10).fill(.thinMaterial))
                    .onChange(of: capturedPositions) { _ in
                        if let last = capturedPositions.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .overlay{
                    if capturedPositions.isEmpty {
                        ContentUnavailableView(
                            "No positions yet",
                            systemImage: "rectangle.and.text.magnifyingglass",
                            description: Text("Press Start to begin capturing.")
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    onStartStop()
                } label: {
                    Label(isCapturing ? "Stop" : "Start",
                          systemImage: isCapturing ? "stop.circle.fill" : "play.circle.fill")
                }
                .keyboardShortcut(.space, modifiers: [])
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    onClear()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(capturedPositions.isEmpty)
            }
            
            ToolbarItem(placement: .confirmationAction) {
                StatusPill(
                    isCapturing: isCapturing,
                    count: capturedPositions.count
                )
            }
        }
    }
}



struct CapturedRow: View {
    let position: CursorPosition
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cursorarrow")
            
            VStack(alignment: .leading, spacing: 2) {
                Text(position.type.rawValue)
                    .font(.subheadline.weight(.semibold))
                
                Text("x: \(fmt(position.point.x))  y: \(fmt(position.point.y))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.08))
        )
    }
    
    private func fmt(_ d: CGFloat) -> String {
        String(format: "%.1f", d)
    }
}

// MARK: - Common UI

struct StatusPill: View {
    var isCapturing: Bool
    var count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isCapturing ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isCapturing ? "Capturing" : "Idle")
                .font(.callout)
            Divider()
                .frame(height: 12)
            Text("\(count) captured")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .frame(width: 1000, height: 400)
}
