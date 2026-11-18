import AppKit
import Carbon.HIToolbox

struct AppInfo: Identifiable, Equatable {
    let bundleID: String
    let name: String
    var id: String { bundleID }

    var url: URL? { NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) }

    var icon: NSImage {
        guard let url else { return NSWorkspace.shared.icon(for: .application) }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}

/// An app bound to ⌃ plus a number key.
struct AppBinding: Codable, Equatable {
    /// Number keys in the order they sit on the keyboard.
    static let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]
    static let modifier: NSEvent.ModifierFlags = .control

    private static let keyCodes = [
        kVK_ANSI_0, kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4,
        kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9,
    ]

    var bundleID: String
    var name: String
    var number: Int

    var keyCode: UInt32 { UInt32(Self.keyCodes[number]) }
}

final class Store: ObservableObject {
    private static let key = "numberBindings"

    /// Called when the set of hotkeys to register changes.
    var onChange: (() -> Void)?

    @Published private(set) var bindings: [AppBinding] {
        didSet {
            UserDefaults.standard.set(try? JSONEncoder().encode(bindings), forKey: Self.key)
            onChange?()
        }
    }
    @Published private(set) var openApps: [AppInfo] = []
    @Published private(set) var addedApps: [AppInfo] = []
    @Published private(set) var trusted = AX.trusted

    init() {
        let data = UserDefaults.standard.data(forKey: Self.key)
        bindings = data.flatMap { try? JSONDecoder().decode([AppBinding].self, from: $0) } ?? []
    }

    /// Bound apps, open apps and manually added apps, one row each.
    var apps: [AppInfo] {
        var seen = Set<String>()
        let bound = bindings.map { AppInfo(bundleID: $0.bundleID, name: $0.name) }
        return (bound + openApps + addedApps)
            .filter { seen.insert($0.bundleID).inserted }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func number(for app: AppInfo) -> Int? {
        bindings.first { $0.bundleID == app.bundleID }?.number
    }

    func setNumber(_ number: Int?, for app: AppInfo) {
        // A number can only open one app, so the newest binding wins.
        var next = bindings.filter { $0.bundleID != app.bundleID && $0.number != number }
        if let number {
            next.append(AppBinding(bundleID: app.bundleID, name: app.name, number: number))
        }
        bindings = next
    }

    func refresh() {
        trusted = AX.trusted
        openApps = NSWorkspace.shared.runningApplications.compactMap { app in
            guard app.activationPolicy == .regular,
                  let id = app.bundleIdentifier,
                  id != Bundle.main.bundleIdentifier
            else { return nil }
            return AppInfo(bundleID: id, name: app.localizedName ?? id)
        }
    }

    func add(appAt url: URL) {
        guard let id = Bundle(url: url)?.bundleIdentifier else { return }
        addedApps.append(AppInfo(bundleID: id, name: FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")))
    }
}
