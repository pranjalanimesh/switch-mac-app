import AppKit
import SwiftUI

/// The floating window list shown while cycling through an app's windows.
final class HUD {
    private let panel: NSPanel
    private let host = NSHostingView(rootView: HUDView(icon: nil, name: "", titles: [], selected: 0))

    init() {
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: true)
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let blur = NSVisualEffectView()
        blur.material = .hudWindow
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 16
        blur.layer?.masksToBounds = true
        host.autoresizingMask = [.width, .height]
        blur.addSubview(host)
        panel.contentView = blur
    }

    func show(icon: NSImage?, name: String, titles: [String], selected: Int) {
        host.rootView = HUDView(icon: icon, name: name, titles: titles, selected: selected)
        let size = host.fittingSize
        let screen = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        panel.setFrame(NSRect(x: screen.midX - size.width / 2, y: screen.midY - size.height / 2,
                              width: size.width, height: size.height), display: true)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }
}

private struct HUDView: View {
    let icon: NSImage?
    let name: String
    let titles: [String]
    let selected: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                if let icon {
                    Image(nsImage: icon).resizable().frame(width: 28, height: 28)
                }
                Text(name).font(.system(size: 15, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)

            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                Text(title.isEmpty ? "Untitled" : title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .foregroundStyle(index == selected ? Color.white : Color.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(index == selected ? Color.accentColor : Color.clear,
                                in: RoundedRectangle(cornerRadius: 7))
            }
        }
        .padding(12)
        .frame(width: 420)
    }
}
