import Cocoa
import SwiftUI

@main
struct TransparentNotionApp: App {
    @NSApplicationDelegateAdaptor(AppSetup.self) var setup

    var body: some Scene {
        MenuBarExtra("Notion", systemImage: "quote.bubble.fill") {
            Button(setup.controller.isActive ? "Hide" : "Show") {
                setup.controller.toggle()
            }
            .keyboardShortcut("n", modifiers: [.command, .option])

            Divider()

            Menu("Model: \(setup.controller.selectedModelName)") {
                ForEach(setup.controller.availableModels, id: \.id) { m in
                    Button(m.name) { setup.controller.selectedModel = m.id }
                }
            }

            Button("Language: \(setup.controller.language == "ru" ? "Русский" : "English")") {
                setup.controller.language = setup.controller.language == "ru" ? "en" : "ru"
            }

            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

@MainActor final class AppSetup: NSObject, NSApplicationDelegate {
    let controller = OverlayController()
    func applicationDidFinishLaunching(_ notification: Notification) {
        controller.start()
    }
}

@MainActor
@Observable
final class OverlayController {
    var isActive = false
    var selectedModel = "claude-sonnet4.6"
    var language = "ru"

    struct ModelOption: Identifiable, Hashable {
        let id: String
        let name: String
    }

    let availableModels: [ModelOption] = [
        .init(id: "claude-sonnet4.6", name: "Claude Sonnet 4.6"),
        .init(id: "claude-opus4.6", name: "Claude Opus 4.6"),
        .init(id: "claude-opus4.7", name: "Claude Opus 4.7"),
        .init(id: "claude-opus4.8", name: "Claude Opus 4.8"),
        .init(id: "gpt-5.2", name: "GPT 5.2"),
        .init(id: "gpt-5.4", name: "GPT 5.4"),
        .init(id: "gpt-5.5", name: "GPT 5.5"),
        .init(id: "gemini-2.5flash", name: "Gemini 2.5 Flash"),
        .init(id: "gemini-3.1pro", name: "Gemini 3.1 Pro"),
        .init(id: "kimi-2.6", name: "Kimi 2.6"),
    ]

    var selectedModelName: String {
        availableModels.first(where: { $0.id == selectedModel })?.name ?? selectedModel
    }

    private var panel: OverlayPanel?

    func start() {
        createPanel()
        registerGlobalHotkey()
    }

    func toggle() {
        isActive ? deactivate() : activate()
    }

    func activate() {
        isActive = true
        panel?.setClickThrough(false)
        panel?.orderFrontRegardless()
        panel?.makeKey()
        NSApp.activate(ignoringOtherApps: true)
    }

    func deactivate() {
        isActive = false
        panel?.setClickThrough(true)
        panel?.orderBack(nil)
    }

    private func createPanel() {
        let p = OverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 640),
            styleMask: [.nonactivatingPanel, .resizable, .fullSizeContentView, .titled],
            backing: .buffered, defer: false
        )
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.isMovableByWindowBackground = true
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = false
        p.setClickThrough(true)

        let cv = ContentView(controller: self)
        let host = NSHostingView(rootView: cv)
        host.translatesAutoresizingMaskIntoConstraints = false
        p.contentView = host

        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: p.contentView!.topAnchor),
            host.bottomAnchor.constraint(equalTo: p.contentView!.bottomAnchor),
            host.leadingAnchor.constraint(equalTo: p.contentView!.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: p.contentView!.trailingAnchor),
        ])

        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            p.setFrame(NSRect(x: sf.maxX - 560, y: sf.midY - 320, width: 540, height: 640), display: false)
        }

        panel = p
    }

    private func registerGlobalHotkey() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let ref = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .defaultTap, eventsOfInterest: mask,
            callback: { _, _, event, refcon in
                let ctrl = Unmanaged<OverlayController>.fromOpaque(refcon!).takeUnretainedValue()
                let flags = event.flags
                let key = event.getIntegerValueField(.keyboardEventKeycode)
                if flags.contains(.maskCommand) && flags.contains(.maskAlternate) && key == 45 {
                    Task { @MainActor in ctrl.toggle() }
                    return nil
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: ref
        ) else { return }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }
}

final class OverlayPanel: NSPanel {
    func setClickThrough(_ enabled: Bool) {
        ignoresMouseEvents = enabled
        if !enabled { makeKeyAndOrderFront(nil) }
    }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
