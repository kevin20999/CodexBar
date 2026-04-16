import CodexBarCore

enum ProviderCookieSourceUI {
    static let keychainDisabledPrefix =
        "Keychain access is disabled in Advanced, so browser cookie import is unavailable."

    static func options(
        allowsOff: Bool,
        keychainDisabled: Bool,
        allowsSafari: Bool = false) -> [ProviderSettingsPickerOption]
    {
        var options: [ProviderSettingsPickerOption] = []
        if !keychainDisabled {
            options.append(ProviderSettingsPickerOption(
                id: ProviderCookieSource.auto.rawValue,
                title: ProviderCookieSource.auto.displayName))
            if allowsSafari {
                options.append(ProviderSettingsPickerOption(
                    id: ProviderCookieSource.safari.rawValue,
                    title: ProviderCookieSource.safari.displayName))
            }
        }
        options.append(ProviderSettingsPickerOption(
            id: ProviderCookieSource.manual.rawValue,
            title: ProviderCookieSource.manual.displayName))
        if allowsOff {
            options.append(ProviderSettingsPickerOption(
                id: ProviderCookieSource.off.rawValue,
                title: ProviderCookieSource.off.displayName))
        }
        return options
    }

    static func subtitle(
        source: ProviderCookieSource,
        keychainDisabled: Bool,
        auto: String,
        safari: String? = nil,
        manual: String,
        off: String) -> String
    {
        if keychainDisabled {
            return source == .off ? off : "\(self.keychainDisabledPrefix) \(manual)"
        }
        switch source {
        case .auto:
            return auto
        case .safari:
            return safari ?? auto
        case .manual:
            return manual
        case .off:
            return off
        }
    }
}
