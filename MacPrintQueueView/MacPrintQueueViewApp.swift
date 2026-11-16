import SwiftUI

@main
struct MacPrintQueueViewApp: App {
    /// The app name as shown to the user (window title, menu bar, Dock).
    static let displayName = "Mac Print Queue View"

    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Window(Self.displayName, id: "main") {
            ContentView()
                .frame(minWidth: 900, minHeight: 560)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(String(localized: "About \(Self.displayName)")) { AboutPanel.show() }
            }
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
