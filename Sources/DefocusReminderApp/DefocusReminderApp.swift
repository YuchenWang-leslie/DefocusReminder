import AppKit
import SwiftUI
import DefocusReminderCore

@main
struct DefocusReminderApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MenuPanelView(
                model: model,
                openSettings: { presentWindow(id: "settings") },
                openStats: { presentWindow(id: "stats") }
            )
                .onAppear { model.start() }
        } label: {
            MenuBarStatusView(model: model)
                .onAppear { model.start() }
        }
        .menuBarExtraStyle(.window)

        Window(L.s("设置", "Settings", model.language), id: "settings") {
            SettingsView(model: model)
                .background(FloatingWindowConfigurator(id: "settings"))
        }
        .defaultSize(width: 560, height: 520)
        .windowResizability(.contentSize)

        Window(L.s("统计", "Stats", model.language), id: "stats") {
            StatsView(model: model)
                .background(FloatingWindowConfigurator(id: "stats"))
        }
        .defaultSize(width: 680, height: 460)

        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button(L.s("设置", "Settings", model.language)) {
                    presentWindow(id: "settings")
                }
                .keyboardShortcut(",", modifiers: .command)
                Button(L.s("统计", "Stats", model.language)) {
                    presentWindow(id: "stats")
                }
                .keyboardShortcut("1", modifiers: .command)
            }
        }
    }

    private func presentWindow(id: String) {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NSApp.activate(ignoringOtherApps: true)
            let identifier = NSUserInterfaceItemIdentifier(id)
            NSApp.windows
                .filter { $0.isVisible && $0.identifier == identifier }
                .forEach { $0.orderFrontRegardless() }
        }
    }
}

struct MenuBarStatusView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Text(model.menuBarTitle)
            .monospacedDigit()
    }
}

private struct FloatingWindowConfigurator: NSViewRepresentable {
    let id: String

    func makeNSView(context: Context) -> WindowConfigView {
        WindowConfigView(id: id)
    }

    func updateNSView(_ nsView: WindowConfigView, context: Context) {
        nsView.id = id
        nsView.configureWindow()
    }

    final class WindowConfigView: NSView {
        var id: String
        private weak var configuredWindow: NSWindow?

        init(id: String) {
            self.id = id
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            configureWindow()
        }

        func configureWindow() {
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = self.window else { return }
                let isNewWindow = self.configuredWindow !== window
                self.configuredWindow = window
                window.identifier = NSUserInterfaceItemIdentifier(self.id)
                window.level = .floating
                window.collectionBehavior.insert(.fullScreenAuxiliary)
                window.hidesOnDeactivate = false
                if isNewWindow {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
}
