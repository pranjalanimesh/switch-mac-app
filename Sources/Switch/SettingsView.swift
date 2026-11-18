import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var store: Store
    @State private var opensAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Shortcuts").font(.title2.weight(.semibold))
                Text("Pick a number for each app. Press ⌃ and that number anywhere to switch to it. Press it again for the app's next window.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            List(store.apps) { app in
                HStack(spacing: 10) {
                    Image(nsImage: app.icon).resizable().frame(width: 26, height: 26)
                    Text(app.name)
                    Spacer()
                    Picker("", selection: Binding(get: { store.number(for: app) },
                                                  set: { store.setNumber($0, for: app) })) {
                        Text("None").tag(Int?.none)
                        Divider()
                        ForEach(AppBinding.numbers, id: \.self) { number in
                            Text("⌃\(number)").tag(Int?.some(number))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 84)
                }
                .padding(.vertical, 3)
            }
            .listStyle(.inset)

            if !store.trusted {
                Divider()
                HStack {
                    Text("Stepping through an app's windows needs Accessibility access.")
                        .font(.callout)
                    Spacer()
                    Button("Allow…") { AX.requestAccess() }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.yellow.opacity(0.12))
            }

            Divider()
            HStack {
                Button("Add App…", action: addApp)
                Spacer()
                Toggle("Open at login", isOn: $opensAtLogin)
                    .onChange(of: opensAtLogin) { _, enabled in
                        try? enabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                        opensAtLogin = SMAppService.mainApp.status == .enabled
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 460, height: 580)
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        if panel.runModal() == .OK, let url = panel.url {
            store.add(appAt: url)
        }
    }
}
