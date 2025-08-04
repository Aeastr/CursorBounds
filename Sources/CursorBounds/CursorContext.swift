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
    
    /// Browsers to detect
    public var browsers: Set<Browser>
    
    public init(browsers: Set<Browser> = Browser.default) {
        self.browsers = browsers
    }

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
        return browsers.contains { $0.bundleID == bundleId && $0.isEnabled }
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

/// Represents a browser that can be detected
public struct Browser: Hashable {
    public let bundleID: String
    public let name: String
    public let isEnabled: Bool
    
    public init(bundleID: String, name: String, isEnabled: Bool = true) {
        self.bundleID = bundleID
        self.name = name
        self.isEnabled = isEnabled
    }
    
    /// Returns a copy of this browser with enabled state toggled
    public func toggled() -> Browser {
        return Browser(bundleID: bundleID, name: name, isEnabled: !isEnabled)
    }
    
    /// Returns a copy of this browser with enabled state set
    public func enabled(_ enabled: Bool = true) -> Browser {
        return Browser(bundleID: bundleID, name: name, isEnabled: enabled)
    }
    
    /// Returns a copy of this browser disabled
    public func disabled() -> Browser {
        return enabled(false)
    }
}

// MARK: - Built-in Browser Convenience
public extension Browser {
    static let safari = Browser(bundleID: "com.apple.Safari", name: "Safari")
    static let chrome = Browser(bundleID: "com.google.Chrome", name: "Chrome")
    static let firefox = Browser(bundleID: "org.mozilla.firefox", name: "Firefox")
    static let edge = Browser(bundleID: "com.microsoft.edgemac", name: "Edge")
    static let arc = Browser(bundleID: "company.thebrowser.Browser", name: "Arc")
    static let brave = Browser(bundleID: "com.brave.Browser", name: "Brave")
    static let opera = Browser(bundleID: "com.operasoftware.Opera", name: "Opera")
    static let vivaldi = Browser(bundleID: "com.vivaldi.Vivaldi", name: "Vivaldi")
    static let tor = Browser(bundleID: "com.torproject.tor", name: "Tor")
    static let helium = Browser(bundleID: "net.imput.helium", name: "Helium")
    static let orion = Browser(bundleID: "com.kagi.kagimacOS", name: "Orion")
    static let duckduckgo = Browser(bundleID: "com.duckduckgo.macos.browser", name: "DuckDuckGo")
    static let waterfox = Browser(bundleID: "net.waterfox.waterfox", name: "Waterfox")
    static let librewolf = Browser(bundleID: "io.gitlab.librewolf-community", name: "LibreWolf")
    static let chromium = Browser(bundleID: "org.chromium.Chromium", name: "Chromium")
    static let yandex = Browser(bundleID: "ru.yandex.desktop.yandex-browser", name: "Yandex")
    static let dia = Browser(bundleID: "org.gnome.Dia", name: "Dia")
    static let zen = Browser(bundleID: "app.zen-browser.zen", name: "Zen")
    
    /// All commonly known browsers
    static let all: Set<Browser> = [
        .safari, .chrome, .firefox, .edge, .arc, .brave, .opera, .vivaldi, .tor, .helium,
        .orion, .duckduckgo, .waterfox, .librewolf, .chromium, .yandex, .dia, .zen
    ]
    
    /// Default browser detection (all known browsers)
    static let `default`: Set<Browser> = Browser.all
    
    /// Default browsers plus additional custom browsers
    static func defaultWith(_ additionalBrowsers: Browser...) -> Set<Browser> {
        return Browser.all.union(additionalBrowsers)
    }
    
    /// Default browsers plus additional custom browsers from array
    static func defaultWith(_ additionalBrowsers: [Browser]) -> Set<Browser> {
        return Browser.all.union(additionalBrowsers)
    }
}
