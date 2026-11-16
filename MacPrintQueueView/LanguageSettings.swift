import AppKit
import Observation

/// The languages the app is available in. `system` follows the language chosen in
/// System Settings.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case dutch = "nl"
    case turkish = "tr"

    var id: String { rawValue }

    /// Each language is shown in its own language, as is usual in language menus.
    var displayName: String {
        switch self {
        case .system: String(localized: "System Language")
        case .english: "English"
        case .dutch: "Nederlands"
        case .turkish: "Türkçe"
        }
    }
}

/// Lets the user choose the app's language.
///
/// The choice is stored as `AppleLanguages` in the app's own preferences: the same setting
/// macOS uses for a per-app language (System Settings → General → Language & Region → Apps).
/// macOS reads it at launch, so all text, including the standard menus, follows it after a restart.
@MainActor
@Observable
final class LanguageSettings {
    static let shared = LanguageSettings()

    private static let key = "AppleLanguages"

    /// The language the app was started with.
    let launchLanguage: AppLanguage

    var selected: AppLanguage {
        didSet { Self.store(selected) }
    }

    /// True when the chosen language only takes effect after a restart.
    var needsRestart: Bool { selected != launchLanguage }

    private init() {
        let current = Self.storedLanguage()
        launchLanguage = current
        selected = current
    }

    /// Starts a new instance of the app and quits this one.
    func restart() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, error in
            guard error == nil else { return }
            Task { @MainActor in NSApp.terminate(nil) }
        }
    }

    /// Reads the app's own language override (ignoring the system-wide language list).
    private static func storedLanguage() -> AppLanguage {
        guard let domain = Bundle.main.bundleIdentifier,
              let languages = UserDefaults.standard.persistentDomain(forName: domain)?[key] as? [String],
              let first = languages.first else { return .system }
        let code = Locale(identifier: first).language.languageCode?.identifier ?? first
        return AppLanguage(rawValue: code) ?? .system
    }

    private static func store(_ language: AppLanguage) {
        if language == .system {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            UserDefaults.standard.set([language.rawValue], forKey: key)
        }
    }
}
