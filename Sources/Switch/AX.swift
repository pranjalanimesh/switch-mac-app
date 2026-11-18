import AppKit
import ApplicationServices

/// Private call that builds an accessibility element from a raw token.
/// The public window list leaves out windows on other Spaces, which includes
/// every fullscreen window, so those have to be looked up by element ID.
@_silgen_name("_AXUIElementCreateWithRemoteToken")
private func _AXUIElementCreateWithRemoteToken(_ token: CFData) -> Unmanaged<AXUIElement>?

/// Accessibility helpers for listing and raising another app's windows.
enum AX {
    static var trusted: Bool { AXIsProcessTrusted() }

    static func requestAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Standard windows on every Space, oldest first. The order does not
    /// change when windows are raised, so repeated presses walk through all of them.
    static func windows(of app: NSRunningApplication) -> [AXUIElement] {
        let element = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(element, 0.25)
        // A hung app would stall every lookup below, so check it answers first.
        guard let role: String = value(element, kAXRoleAttribute), !role.isEmpty else { return [] }

        var windows = windowsOnAllSpaces(pid: app.processIdentifier)
        // The ID scan stops at 1000, so add anything the public list has that it missed.
        for window in value(element, kAXWindowsAttribute) ?? [AXUIElement]()
        where isStandard(window) && !windows.contains(where: { CFEqual($0, window) }) {
            windows.append(window)
        }
        return windows
    }

    /// Index of the app's current main window in `windows`.
    static func mainWindowIndex(of app: NSRunningApplication, in windows: [AXUIElement]) -> Int? {
        let element = AXUIElementCreateApplication(app.processIdentifier)
        guard let main: AXUIElement = value(element, kAXMainWindowAttribute) else { return nil }
        return windows.firstIndex { CFEqual($0, main) }
    }

    static func title(of window: AXUIElement) -> String {
        value(window, kAXTitleAttribute) ?? ""
    }

    static func raise(_ window: AXUIElement, of app: NSRunningApplication) {
        if value(window, kAXMinimizedAttribute) == true {
            AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        }
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, kCFBooleanTrue)
        app.activate()
    }

    /// Tries element IDs 0..<1000 for the process and keeps the standard windows.
    /// The token is 20 bytes: pid, zero, the tag "coco", then the element ID.
    private static func windowsOnAllSpaces(pid: pid_t) -> [AXUIElement] {
        var token = Data(count: 20)
        token.replaceSubrange(0..<4, with: withUnsafeBytes(of: pid) { Data($0) })
        token.replaceSubrange(8..<12, with: withUnsafeBytes(of: Int32(0x636F_636F)) { Data($0) })
        var windows: [AXUIElement] = []
        for id: UInt64 in 0..<1000 {
            token.replaceSubrange(12..<20, with: withUnsafeBytes(of: id) { Data($0) })
            if let window = _AXUIElementCreateWithRemoteToken(token as CFData)?.takeRetainedValue(),
               isStandard(window) {
                windows.append(window)
            }
        }
        return windows
    }

    private static func isStandard(_ window: AXUIElement) -> Bool {
        value(window, kAXSubroleAttribute) == kAXStandardWindowSubrole as String
    }

    private static func value<T>(_ element: AXUIElement, _ attribute: String) -> T? {
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &result) == .success else { return nil }
        return result as? T
    }
}
