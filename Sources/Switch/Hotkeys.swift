import Carbon.HIToolbox

/// System-wide hotkeys through Carbon. They need no permission and swallow
/// the keystroke, so the frontmost app never sees it.
final class Hotkeys {
    // A singleton because the C event callback cannot capture state.
    static let shared = Hotkeys()

    var onTrigger: ((AppBinding) -> Void)?

    private var bindings: [AppBinding] = []
    private var refs: [EventHotKeyRef] = []
    private let signature: OSType = 0x5357_5443 // "SWTC"

    private init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, _ in
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            Hotkeys.shared.fire(Int(id.id))
            return noErr
        }, 1, &spec, nil, nil)
    }

    func set(_ new: [AppBinding]) {
        refs.forEach { UnregisterEventHotKey($0) }
        refs = []
        bindings = new
        for (index, binding) in new.enumerated() {
            var ref: EventHotKeyRef?
            RegisterEventHotKey(binding.keyCode, UInt32(controlKey),
                                EventHotKeyID(signature: signature, id: UInt32(index)),
                                GetEventDispatcherTarget(), 0, &ref)
            if let ref { refs.append(ref) }
        }
    }

    private func fire(_ index: Int) {
        guard bindings.indices.contains(index) else { return }
        onTrigger?(bindings[index])
    }
}
