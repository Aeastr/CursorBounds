//
//  AppContext.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//

import Foundation
import AppKit

/// Represents contextual information about the application and window where the cursor is located
public struct WindowInfo {
    /// The name of the focused application
    public let appName: String?
    /// The bundle identifier of the focused application
    public let bundleIdentifier: String?
    /// The process ID of the focused application
    public let processID: pid_t?
    /// The title of the current window
    public let windowTitle: String?
    /// The role of the focused UI element (e.g., AXTextField, AXWebArea)
    public let elementRole: String?
    /// Specific context information based on the type of window/application
    public let content: ContentContext?

    public init(
        appName: String? = nil,
        bundleIdentifier: String? = nil,
        processID: pid_t? = nil,
        windowTitle: String? = nil,
        elementRole: String? = nil,
        content: ContentContext? = nil
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.processID = processID
        self.windowTitle = windowTitle
        self.elementRole = elementRole
        self.content = content
    }
}


/// Represents different types of window contexts with associated information
public enum ContentContext {
    /// Website context with URL, domain, and page information
    case website(WebsiteInfo)
}

public struct WebsiteInfo {
    /// The current URL (if detectable)
    public let url: String?
    
    /// The page title
    public let pageTitle: String?
    
    /// The domain extracted from the URL
    public let domain: String?
    
    /// Whether this appears to be a search field
    public let isSearchField: Bool
    
    public init(
        url: String? = nil,
        pageTitle: String? = nil,
        domain: String? = nil,
        isSearchField: Bool = false
    ) {
        self.url = url
        self.pageTitle = pageTitle
        self.domain = domain
        self.isSearchField = isSearchField
    }
    
    /// Convenience computed property to extract domain from URL
    public var extractedDomain: String? {
        guard let url = url,
              let urlComponents = URLComponents(string: url) else {
            return domain
        }
        return urlComponents.host
    }
}

public class CursorContext {
    public static let shared = CursorContext.init()
    public init(){}

    /// Gets comprehensive window and context information for the currently focused application
    /// - Returns: `WindowInfo` with available information
    /// - Throws: `CursorBoundsError` if window information cannot be determined
    public func windowInfo() throws -> WindowInfo {
        guard CursorBounds.isAccessibilityEnabled() else {
            throw CursorBoundsError.accessibilityPermissionDenied
        }
        
        let systemWideElement = AXUIElementCreateSystemWide()
        
        // Get focused application
        var appRef: CFTypeRef?
        let resultApp = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedApplicationAttribute as CFString,
            &appRef
        )
        
        guard resultApp == .success,
              let app = castCF(appRef, to: AXUIElement.self) else {
            throw CursorBoundsError.noFocusedElement
        }
        
        // Get app name
        let appName = app.getAttributeString(attribute: kAXTitleAttribute)
        
        // Try to get bundle identifier from accessibility
        var bundleId = app.getAttributeString(attribute: "AXBundleIdentifier")
        
        // If bundle ID is nil, try to get it from NSRunningApplication
        if bundleId == nil {
            var pid: pid_t = 0
            let pidResult = AXUIElementGetPid(app, &pid)
            if pidResult == .success {
                if let runningApp = NSRunningApplication(processIdentifier: pid) {
                    bundleId = runningApp.bundleIdentifier
                }
            }
        }
        let bundleIdentifier = bundleId
        
        // Get process ID
        var pid: pid_t = 0
        let pidResult = AXUIElementGetPid(app, &pid)
        let processID = pidResult == .success ? pid : nil
        
        // Get focused window and its title
        var windowRef: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(
            app,
            kAXFocusedWindowAttribute as CFString,
            &windowRef
        )
        
        var windowTitle: String? = nil
        if windowResult == .success,
           let window = castCF(windowRef, to: AXUIElement.self) {
            windowTitle = window.getAttributeString(attribute: kAXTitleAttribute)
        }
        
        // Get focused element and its role
        var focusedElementRef: CFTypeRef?
        let elementResult = AXUIElementCopyAttributeValue(
            app,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementRef
        )
        
        var elementRole: String? = nil
        if elementResult == .success,
           let focusedElement = castCF(focusedElementRef, to: AXUIElement.self) {
            elementRole = focusedElement.getAttributeString(attribute: kAXRoleAttribute)
        }
        
        // Extract context information based on the application type
        let context = self.extractWindowContext(
            bundleId: bundleIdentifier,
            windowTitle: windowTitle,
            elementRole: elementRole,
            app: app
        )
        
        return WindowInfo(
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            processID: processID,
            windowTitle: windowTitle,
            elementRole: elementRole,
            content: context
        )
    }

    /// Gets just the content context for the currently focused application
    /// - Returns: `ContentContext` if available, or `nil` if unavailable
    /// - Throws: `CursorBoundsError` if window information cannot be determined
    public func contentContext() throws -> ContentContext? {
        return try windowInfo().content
    }
    
    // MARK: - Private Helper Methods
    
    /// Extracts window context information based on the application type
    private func extractWindowContext(bundleId: String?, windowTitle: String?, elementRole: String?, app: AXUIElement) -> ContentContext? {
        guard let bundleId = bundleId, let windowTitle = windowTitle else {
            return nil
        }
        
        // Check if this is a browser and extract website information
        if isBrowser(bundleId: bundleId) {
            if let websiteInfo = extractWebsiteInfo(bundleId: bundleId, windowTitle: windowTitle, elementRole: elementRole, app: app) {
                return .website(websiteInfo)
            }
        }
        
        return nil
    }
    
    /// Extracts website information from browser apps
    private func extractWebsiteInfo(bundleId: String, windowTitle: String, elementRole: String?, app: AXUIElement) -> WebsiteInfo? {
        var url: String? = nil
        var domain: String? = nil
        let isSearchField = elementRole == "AXSearchField"
        
        // Try to extract URL from browser address bar via accessibility API
        url = extractUrlFromAddressBar(app: app)
        
        if let url = url, !url.isEmpty {
            // Extract domain from URL
            if let parsedDomain = extractDomainFromUrl(url) {
                domain = parsedDomain
            }
        }
        
        // Get page title from window title
        let pageTitle = windowTitle
        
        if url != nil || domain != nil || pageTitle != nil || isSearchField {
            return WebsiteInfo(
                url: url,
                pageTitle: pageTitle,
                domain: domain,
                isSearchField: isSearchField
            )
        }
        
        return nil
    }
    
    /// Checks if an application is a web browser based on its bundle ID
    private func isBrowser(bundleId: String) -> Bool {
        // Common browser bundle identifiers
        let knownBrowsers = [
            "com.apple.Safari",                // Safari
            "com.google.Chrome",               // Chrome
            "org.mozilla.firefox",             // Firefox
            "com.microsoft.edgemac",           // Edge
            "com.brave.Browser",               // Brave
            "com.operasoftware.Opera",         // Opera
            "com.vivaldi.Vivaldi",            // Vivaldi
            "com.torproject.tor",              // Tor
            "net.imput.helium",               // Helium
            "com.electron.browser"             // Electron-based browsers
        ]
        
        // Check against known browser bundle IDs
        if knownBrowsers.contains(bundleId) {
            return true
        }
        
        // Check if the bundle ID contains browser-like keywords
        let browserKeywords = ["browser", "chrome", "safari", "firefox", "edge", "opera", "web"]
        for keyword in browserKeywords {
            if bundleId.lowercased().contains(keyword) {
                return true
            }
        }
        
        return false
    }
    
    /// Extracts domain from a URL string
    private func extractDomainFromUrl(_ urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return nil
        }
        
        // Remove www. prefix if present
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return domain
    }
    
    /// Attempts to extract URL from browser address bar
    private func extractUrlFromAddressBar(app: AXUIElement) -> String? {
        // Get all windows
        var windowListRef: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(
            app,
            kAXWindowsAttribute as CFString,
            &windowListRef
        )
        
        guard windowResult == .success,
              let windowList = windowListRef as? [AXUIElement],
              let mainWindow = windowList.first else {
            return nil
        }
        
        // Look for address bar in the main window
        return CursorContext.shared.findAddressBarUrl(in: mainWindow, depth: 0, maxDepth: 12)
    }
    /// Recursively searches for address bar URL in the accessibility hierarchy
    internal func findAddressBarUrl(in element: AXUIElement, depth: Int, maxDepth: Int) -> String? {
        guard depth <= maxDepth else {
            return nil 
        }
        
        // Check if this element is an address bar
        if let role = element.getAttributeString(attribute: kAXRoleAttribute) {
            let label = element.getAttributeString(attribute: kAXTitleAttribute) ?? 
                       element.getAttributeString(attribute: kAXDescriptionAttribute) ??
                       element.getAttributeString(attribute: "AXLabel")
            
            if let value = element.getAttributeString(attribute: kAXValueAttribute) {
                // Look for text fields that might be address bars
                if role == "AXTextField" || role == "AXComboBox" {
                    // Check if this is specifically an address bar by label
                    let isAddressBar = label?.lowercased().contains("address") == true ||
                                      label?.lowercased().contains("url") == true ||
                                      label?.lowercased().contains("search bar") == true
                    
                    // Check if the value looks like a URL
                    let looksLikeURL = value.hasPrefix("http://") || value.hasPrefix("https://") || 
                                      (value.contains(".") && value.count > 3)
                    
                    if isAddressBar || looksLikeURL {
                        return value
                    }
                }
            }
        }
        
        // Recursively search children
        var childrenRef: CFTypeRef?
        let childrenResult = AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &childrenRef
        )
        
        if childrenResult == .success,
           let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let url = findAddressBarUrl(in: child, depth: depth + 1, maxDepth: maxDepth) {
                    return url
                }
            }
        }
        
        return nil
    }
}

/// Browser types that we can detect and extract additional context from
public enum BrowserType: String, CaseIterable {
    case safari = "com.apple.Safari"
    case chrome = "com.google.Chrome"
    case firefox = "org.mozilla.firefox"
    case edge = "com.microsoft.edgemac"
    case arc = "company.thebrowser.Browser"
    case brave = "com.brave.Browser"
    
    /// User-friendly name for the browser
    public var displayName: String {
        switch self {
        case .safari: return "Safari"
        case .chrome: return "Chrome"
        case .firefox: return "Firefox"
        case .edge: return "Edge"
        case .arc: return "Arc"
        case .brave: return "Brave"
        }
    }
    
    /// Whether this browser typically includes URL in window titles
    public var includesUrlInTitle: Bool {
        switch self {
        case .safari, .chrome, .firefox: return true
        case .edge, .arc, .brave: return false
        }
    }
}
