import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = Store()
    private let switcher = Switcher()
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.2.swap", accessibilityDescription: "Switch")
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Switch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        Hotkeys.shared.onTrigger = { [switcher] in switcher.trigger($0) }
        store.onChange = { [store] in Hotkeys.shared.set(store.bindings) }
        Hotkeys.shared.set(store.bindings)

        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification] {
            workspace.addObserver(self, selector: #selector(refresh), name: name, object: nil)
        }
        // Picks up an Accessibility grant when the user comes back from System Settings.
        NotificationCenter.default.addObserver(self, selector: #selector(refresh),
                                               name: NSApplication.didBecomeActiveNotification, object: nil)

        if store.bindings.isEmpty { showSettings() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showSettings()
        return true
    }

    @objc private func refresh() {
        store.refresh()
    }

    @objc private func showSettings() {
        store.refresh()
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(store: store)))
            window.title = "Switch"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
