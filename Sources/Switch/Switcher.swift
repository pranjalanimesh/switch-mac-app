import AppKit

/// Turns a hotkey press into an app switch.
///
/// A press focuses the app. A press while the app is already in front moves
/// to its next window, so pressing again and again walks through all of them.
/// While ⌃ stays held the HUD shows the selection, and releasing ⌃ focuses it.
final class Switcher {
    private struct Session {
        let binding: AppBinding
        let app: NSRunningApplication
        let windows: [AXUIElement]
        let start: Int
        var index: Int
    }

    private var session: Session?
    private var releaseTimer: Timer?
    private let hud = HUD()

    func trigger(_ binding: AppBinding) {
        if var current = session, current.binding.bundleID == binding.bundleID {
            current.index = (current.index + 1) % current.windows.count
            session = current
            showHUD(current)
            return
        }
        end()

        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: binding.bundleID).first else {
            open(binding)
            return
        }
        // Focus first so the switch does not wait on the window lookup.
        let wasFrontmost = app.isActive
        if !wasFrontmost {
            app.unhide()
            app.activate()
        }
        // Without Accessibility access we cannot see windows.
        guard AX.trusted else { return }

        let windows = AX.windows(of: app)
        guard !windows.isEmpty else {
            open(binding) // running with no window: ask it to reopen one
            return
        }
        var start = AX.mainWindowIndex(of: app, in: windows)
        if start == nil, !wasFrontmost {
            // No main window, for example all minimized. Bring one back.
            AX.raise(windows[0], of: app)
            start = 0
        }
        guard windows.count > 1, let start else { return }

        // Already in the app: the press means "next window".
        let started = Session(binding: binding, app: app, windows: windows, start: start,
                              index: wasFrontmost ? (start + 1) % windows.count : start)
        session = started
        if wasFrontmost { showHUD(started) }
        watchForRelease()
    }

    private func open(_ binding: AppBinding) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: binding.bundleID) else {
            NSSound.beep()
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    private func showHUD(_ session: Session) {
        hud.show(icon: session.app.icon,
                 name: session.binding.name,
                 titles: session.windows.map(AX.title(of:)),
                 selected: session.index)
    }

    /// Polls the modifier key while a session is open. A poll that lives for
    /// one key hold is simpler than a global event monitor, which only works
    /// if Accessibility access was granted before the monitor was installed.
    private func watchForRelease() {
        let timer = Timer(timeInterval: 0.02, repeats: true) { [weak self] _ in
            if !NSEvent.modifierFlags.contains(AppBinding.modifier) { self?.commit() }
        }
        RunLoop.main.add(timer, forMode: .common)
        releaseTimer = timer
        timer.fire()
    }

    private func commit() {
        if let session, session.index != session.start {
            AX.raise(session.windows[session.index], of: session.app)
        }
        end()
    }

    private func end() {
        releaseTimer?.invalidate()
        releaseTimer = nil
        session = nil
        hud.hide()
    }
}
