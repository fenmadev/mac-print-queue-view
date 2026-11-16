// E02 — renders the app's About panel (AboutPanel.options + the standard AppKit panel) to a PNG.
// Build (from the repository root): swiftc -swift-version 5 _docs/phases/phase-02/evidence/E02/main.swift MacPrintQueueView/AboutPanel.swift -o /tmp/about-harness
// Copy the built app to a temporary folder, put about-harness into its Contents/MacOS (so Bundle.main is the app) and run
// <copy>.app/Contents/MacOS/about-harness <out.png> <light|dark> -AppleLanguages "(en)"   (also nl, tr)
import AppKit
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.appearance = NSAppearance(named: CommandLine.arguments[2] == "dark" ? .darkAqua : .aqua)
let locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
app.orderFrontStandardAboutPanel(options: AboutPanel.options(info: Bundle.main.infoDictionary ?? [:], locale: locale))
let win = app.windows.first { $0.isVisible }!
// macOS renders the shaped app icon asynchronously; let the run loop finish it before drawing.
RunLoop.main.run(until: Date().addingTimeInterval(2))
win.setFrameOrigin(NSPoint(x: -5000, y: -5000))
let view = win.contentView!.superview!
view.layoutSubtreeIfNeeded(); view.displayIfNeeded()
let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
view.cacheDisplay(in: view.bounds, to: rep)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print(Bundle.main.preferredLocalizations.first ?? "?", Int(view.bounds.width), Int(view.bounds.height))
