import AppKit

/// The About window: the standard macOS About panel with the version and build in the app's
/// language, a one-line description and the version date (D46).
///
/// The version comes from `CFBundleShortVersionString` (`MARKETING_VERSION`) and the version date
/// from `MPQVVersionDate` (`MPQV_VERSION_DATE`, `yyyy-MM-dd`), both build settings of the app target;
/// the build number from `CFBundleVersion`, which the build phase "Increase Build Number"
/// (`Tools/increase-build-number.sh`) raises by one with every build (D47).
enum AboutPanel {
    /// The Info.plist key holding the version date as `yyyy-MM-dd`.
    static let versionDateKey = "MPQVVersionDate"

    @MainActor
    static func show() {
        let locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
        NSApplication.shared.orderFrontStandardAboutPanel(options: options(info: Bundle.main.infoDictionary ?? [:], locale: locale))
        NSApplication.shared.activate()
    }

    /// The panel options for an Info.plist dictionary; `locale` formats the version date.
    /// Shown by AppKit as: icon, name, "Version 1.0 (Build 1)", description, version date, copyright.
    static func options(info: [String: Any], locale: Locale) -> [NSApplication.AboutPanelOptionKey: Any] {
        var options: [NSApplication.AboutPanelOptionKey: Any] = [:]
        if let name = (info["CFBundleDisplayName"] ?? info["CFBundleName"]) as? String {
            options[.applicationName] = name
        }
        // Supplying the labels ourselves keeps AppKit from adding its own "Version" prefix and
        // shows the build as "(Build 1)" instead of "(1)".
        if let version = info["CFBundleShortVersionString"] as? String {
            options[.applicationVersion] = String(localized: "Version \(version)")
        }
        if let build = info["CFBundleVersion"] as? String {
            options[.version] = String(localized: "Build \(build)")
        }
        var credits = String(localized: "Shows what is actually being printed from the macOS print queue.")
        if let date = info[versionDateKey] as? String, !date.isEmpty {
            credits += "\n\n" + String(localized: "Version date: \(formattedDate(date, locale: locale))")
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        options[.credits] = NSAttributedString(string: credits, attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraph,
        ])
        return options
    }

    /// `yyyy-MM-dd` as a long date in `locale` ("November 16, 2026", "16 november 2026");
    /// a value that is not such a date is shown as it is.
    static func formattedDate(_ value: String, locale: Locale) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.calendar = Calendar(identifier: .gregorian)
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyyy-MM-dd"
        parser.isLenient = false
        guard let date = parser.date(from: value) else { return value }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
