import SwiftUI

/// The app's Settings window (⌘,).
struct SettingsView: View {
    @Bindable private var language = LanguageSettings.shared

    var body: some View {
        Form {
            Section {
                Picker("Language", selection: $language.selected) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(verbatim: option.displayName).tag(option)
                    }
                }
            } footer: {
                if language.needsRestart {
                    HStack(alignment: .firstTextBaseline) {
                        Text("The app uses the new language after restarting.")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Restart Now") { language.restart() }
                    }
                } else {
                    Text("System Language follows the language set in System Settings.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }
}
