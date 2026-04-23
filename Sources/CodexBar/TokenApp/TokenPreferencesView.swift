import CodexBarCore
import SwiftUI
import UniformTypeIdentifiers

private enum TokenPreferencesSection: String, CaseIterable, Identifiable {
    case general
    case display
    case theme
    case openAIWeb
    case dashboard
    case system

    var id: String {
        self.rawValue
    }

    var systemImage: String {
        switch self {
        case .general:
            "slider.horizontal.3"
        case .display:
            "eye"
        case .theme:
            "paintpalette"
        case .openAIWeb:
            "globe.badge.chevron.backward"
        case .dashboard:
            "square.grid.2x2"
        case .system:
            "internaldrive"
        }
    }

    var accent: Color {
        switch self {
        case .general:
            TokenMenuTheme.analyticsTint
        case .display:
            TokenMenuTheme.primaryQuotaTint
        case .theme:
            TokenMenuTheme.analyticsTint
        case .openAIWeb:
            TokenMenuTheme.creditsTint
        case .dashboard:
            TokenMenuTheme.reviewTint
        case .system:
            TokenMenuTheme.warningText
        }
    }

    func title(strings: AppStrings) -> String {
        switch self {
        case .general:
            strings.settingsGeneralCategoryTitle
        case .display:
            strings.settingsDisplayCategoryTitle
        case .theme:
            strings.settingsThemeCategoryTitle
        case .openAIWeb:
            strings.settingsOpenAIWebCategoryTitle
        case .dashboard:
            strings.settingsDashboardCategoryTitle
        case .system:
            strings.settingsSystemCategoryTitle
        }
    }

    func description(strings: AppStrings) -> String {
        switch self {
        case .general:
            strings.settingsGeneralCategoryDescription
        case .display:
            strings.settingsDisplayCategoryDescription
        case .theme:
            strings.settingsThemeCategoryDescription
        case .openAIWeb:
            strings.settingsOpenAIWebCategoryDescription
        case .dashboard:
            strings.settingsDashboardCategoryDescription
        case .system:
            strings.settingsSystemCategoryDescription
        }
    }
}

@MainActor
struct PreferencesView: View {
    @Bindable var settings: SettingsStore
    @Bindable var store: UsageStore

    @State private var selectedSection: TokenPreferencesSection = .general
    @State private var measuredPreviewNaturalHeight: CGFloat?
    @State private var measuredPreviewKey: TokenSettingsPreviewMeasurementKey?
    @State private var draggingDashboardModule: DashboardModule?

    private let previewScale: CGFloat = 0.78
    private let previewColumnWidth: CGFloat = 400
    private let menuBarPreviewTargetHeight: CGFloat = 28

    private var previewPanelWidth: CGFloat {
        MenuContent.preferredPanelWidth
    }

    private var strings: AppStrings {
        self.settings.strings
    }

    private var supportsVisualTokenSpeedMeter: Bool {
        TokenMenuSpeedMeterFeature.supportsVisualPresentation
    }

    var body: some View {
        ZStack {
            TokenMenuTheme.panelBackdrop()
                .ignoresSafeArea()

            NavigationSplitView {
                self.sidebarColumn
                    .padding(.leading, 24)
                    .padding(.trailing, 12)
                    .padding(.vertical, 24)
                    .navigationSplitViewColumnWidth(min: 220, ideal: 232, max: 244)
            } detail: {
                self.detailColumn
                    .padding(.leading, 12)
                    .padding(.trailing, 24)
                    .padding(.vertical, 24)
            }
            .navigationSplitViewStyle(.balanced)
        }
        .environment(\.locale, self.strings.locale)
        .frame(minWidth: 1100, minHeight: 820)
    }

    private var currentSection: TokenPreferencesSection {
        self.selectedSection
    }

    private var currentMenuBarAppearanceOption: MenuBarAppearanceOption {
        self.settings.menuBarAppearanceOption
    }

    private var previewMeasurementKey: TokenSettingsPreviewMeasurementKey {
        TokenSettingsPreviewMeasurementKey(settings: self.settings, store: self.store)
    }

    private var sidebarColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(self.strings.settings)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(TokenFloatingCardTheme.primaryText)

                Text(self.currentSection.description(strings: self.strings))
                    .font(.system(size: 12))
                    .foregroundStyle(TokenFloatingCardTheme.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(TokenPreferencesSection.allCases) { section in
                    self.sidebarButton(for: section)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            TokenFloatingCardBackground(
                cornerRadius: 30,
                tint: TokenMenuTheme.panelGlassTint))
    }

    private var detailColumn: some View {
        GeometryReader { proxy in
            HStack(alignment: .top, spacing: 20) {
                self.settingsContentColumn
                self.previewColumn(availableHeight: proxy.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var settingsContentColumn: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                PreferencesSectionHeader(
                    title: self.currentSection.title(strings: self.strings),
                    detail: self.currentSection.description(strings: self.strings))

                self.sectionCards(for: self.currentSection)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            TokenFloatingCardBackground(
                cornerRadius: 30,
                tint: TokenMenuTheme.panelGlassTint))
    }

    private func previewColumn(availableHeight: CGFloat) -> some View {
        let measurementKey = self.previewMeasurementKey

        return self.previewCard(availableHeight: availableHeight)
            .frame(width: self.previewColumnWidth, height: availableHeight, alignment: .top)
            .task(id: measurementKey) {
                await self.measurePreviewNaturalHeight(for: measurementKey)
            }
    }

    private func sidebarButton(for section: TokenPreferencesSection) -> some View {
        let isSelected = section == self.currentSection

        return Button {
            self.selectedSection = section
        } label: {
            HStack(spacing: 12) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 18, alignment: .center)
                    .foregroundStyle(isSelected ? TokenFloatingCardTheme.primaryText : section.accent)

                Text(section.title(strings: self.strings))
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(
                        isSelected
                            ? TokenFloatingCardTheme.primaryText
                            : TokenFloatingCardTheme.secondaryText)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .background {
                if isSelected {
                    TokenFloatingInsetBackground(cornerRadius: 16, tint: section.accent)
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.001))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sectionCards(for section: TokenPreferencesSection) -> some View {
        switch section {
        case .general:
            self.generalCard

        case .display:
            self.menuBarCard

        case .theme:
            self.themeCard

        case .openAIWeb:
            self.openAIWebCard

        case .dashboard:
            self.controlPanelCard

        case .system:
            self.startupCard
            self.storageCard
        }
    }

    private func previewCard(availableHeight: CGFloat) -> some View {
        PreferencesCard(
            title: self.strings.currentPreviewLabel,
            systemImage: "sparkles.rectangle.stack",
            expandsVertically: true)
        {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(self.strings.previewAppearanceLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(TokenFloatingCardTheme.secondaryText)

                        Text(self.strings.menuVisualThemeTitle(self.settings.menuVisualTheme))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(TokenFloatingCardTheme.primaryText)

                        Text("\(self.strings.previewContainerStyleLabel) · \(self.strings.menuPopupStyleTitle(self.settings.menuPopupStyle))")
                            .font(.system(size: 12))
                            .foregroundStyle(TokenFloatingCardTheme.tertiaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    self.menuBarPreview(
                        mode: self.settings.menuBarDisplayMode,
                        metrics: self.store.menuBarDisplayMetrics,
                        quotaStyle: self.settings.menuBarQuotaStyle,
                        fallbackText: self.store.menuBarText(for: self.settings.menuBarDisplayMode))
                }

                PreferencesDivider()

                GeometryReader { proxy in
                    self.embeddedPanelPreview(availableDisplayHeight: proxy.size.height)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(height: availableHeight, alignment: .top)
    }

    private var generalCard: some View {
        PreferencesCard(title: self.strings.settingsGeneralCategoryTitle, systemImage: "slider.horizontal.3") {
            VStack(alignment: .leading, spacing: 16) {
                self.pickerRow(title: self.strings.languageLabel) {
                    PreferencesMenuPicker(
                        title: self.strings.languageLabel,
                        selection: self.$settings.appLanguage,
                        options: AppLanguage.allCases,
                        width: 180)
                    { language in
                        self.strings.languageOptionLabel(language)
                    }
                }

                PreferencesDivider()

                VStack(alignment: .leading, spacing: 10) {
                    self.pickerRow(title: self.strings.quotaRefreshFrequencyLabel) {
                        PreferencesMenuPicker(
                            title: self.strings.quotaRefreshFrequencyLabel,
                            selection: self.$settings.refreshFrequency,
                            options: RefreshFrequency.allCases,
                            width: 180)
                        { frequency in
                            self.strings.refreshFrequencyTitle(frequency)
                        }
                    }

                    PreferencesNote(self.strings.quotaRefreshFrequencyDescription)

                    PreferencesDivider()

                    self.pickerRow(title: self.strings.usageStatisticsRefreshFrequencyLabel) {
                        PreferencesMenuPicker(
                            title: self.strings.usageStatisticsRefreshFrequencyLabel,
                            selection: self.$settings.usageStatisticsRefreshFrequency,
                            options: UsageStatisticsRefreshFrequency.allCases,
                            width: 180)
                        { frequency in
                            self.strings.usageStatisticsRefreshFrequencyTitle(frequency)
                        }
                    }

                    PreferencesNote(self.strings.usageStatisticsRefreshFrequencyDescription)
                    PreferencesNote(self.strings.manualRefreshHint)
                }
            }
        }
    }

    private var menuBarCard: some View {
        PreferencesCard(title: self.strings.menuBarSectionTitle, systemImage: "rectangle.topthird.inset.filled") {
            VStack(alignment: .leading, spacing: 16) {
                PreferencesNote(self.strings.menuBarAppearanceSelectionDescription)

                PreferencesToggleRow(
                    title: self.strings.menuBarTokenSpeedMeterLabel,
                    systemImage: "speedometer",
                    isOn: self.$settings.showsMenuBarTokenSpeedMeter)
                    .disabled(!self.supportsVisualTokenSpeedMeter)

                PreferencesNote(self.strings.menuBarTokenSpeedMeterDescription)

                if !self.supportsVisualTokenSpeedMeter {
                    PreferencesNote(self.strings.menuBarTokenSpeedMeterRequiresMacOS26)
                }

                PreferencesDivider()

                ForEach(MenuBarAppearanceOption.allCases) { option in
                    self.menuBarAppearanceButton(for: option)
                }
            }
        }
    }

    private var themeCard: some View {
        PreferencesCard(title: self.strings.settingsThemeCategoryTitle, systemImage: "paintpalette") {
            VStack(alignment: .leading, spacing: 16) {
                self.pickerRow(title: self.strings.menuVisualThemeLabel) {
                    PreferencesMenuPicker(
                        title: self.strings.menuVisualThemeLabel,
                        selection: self.$settings.menuVisualTheme,
                        options: MenuVisualTheme.allCases,
                        width: 220)
                    { theme in
                        self.strings.menuVisualThemeTitle(theme)
                    }
                }

                PreferencesNote(self.strings.menuVisualThemeDescription)

                PreferencesDivider()

                self.pickerRow(title: self.strings.menuPopupStyleLabel) {
                    PreferencesMenuPicker(
                        title: self.strings.menuPopupStyleLabel,
                        selection: self.$settings.menuPopupStyle,
                        options: MenuPopupStyle.allCases,
                        width: 180)
                    { style in
                        self.strings.menuPopupStyleTitle(style)
                    }
                }

                PreferencesNote(self.strings.menuPopupStyleDescription)
            }
        }
    }

    private var openAIWebCard: some View {
        PreferencesCard(title: self.strings.openAIWebSectionTitle, systemImage: "globe.badge.chevron.backward") {
            VStack(alignment: .leading, spacing: 16) {
                Toggle(self.strings.openAIWebAccessLabel, isOn: self.$settings.openAIWebAccessEnabled)
                    .toggleStyle(.switch)

                PreferencesNote(self.strings.openAIWebAccessDescription)

                if self.settings.openAIWebAccessEnabled {
                    PreferencesDivider()

                    self.pickerRow(title: self.strings.cookieSourceLabel) {
                        PreferencesMenuPicker(
                            title: self.strings.cookieSourceLabel,
                            selection: self.$settings.codexCookieSource,
                            options: ProviderCookieSource.allCases,
                            width: 220)
                        { source in
                            self.strings.cookieSourceTitle(source)
                        }
                    }

                    Toggle(
                        self.strings.backgroundBrowserAutoImportLabel,
                        isOn: self.$settings.backgroundBrowserAutoImportEnabled)
                        .toggleStyle(.switch)
                        .disabled(![ProviderCookieSource.auto, .safari].contains(self.settings.codexCookieSource))

                    PreferencesNote(self.strings.backgroundBrowserAutoImportDescription)

                    if self.settings.codexCookieSource == .manual {
                        PreferencesDivider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text(self.strings.manualCookieHeaderLabel)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(TokenFloatingCardTheme.secondaryText)

                            TextEditor(text: self.$settings.codexCookieHeader)
                                .font(.footnote.monospaced())
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 110)
                                .padding(10)
                                .background(
                                    TokenFloatingInsetBackground(
                                        cornerRadius: 14,
                                        tint: TokenMenuTheme.analyticsTint))

                            PreferencesNote(self.strings.manualCookieHeaderPlaceholder)
                        }
                    }

                    PreferencesDivider()

                    Button(self.strings.fetchFromSafari) {
                        Task {
                            await self.store.forceRefreshOpenAIDashboardFromSafari()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    self.infoBlock(
                        title: self.strings.cookieImportStatusLabel,
                        content: self.store.openAIDashboardCookieImportStatus ?? self.strings.noDebugLog)

                    self.infoBlock(
                        title: self.strings.debugLogLabel,
                        content: self.store.openAIDashboardCookieImportDebugLog ?? self.strings.noDebugLog,
                        monospaced: true,
                        scrollable: true)

                    if self.store.openAIDashboardPermissionDenied {
                        PreferencesDivider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text(self.strings.browserAccessHelpTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(TokenFloatingCardTheme.secondaryText)

                            PreferencesNote(self.strings.browserAccessHelpDescription)

                            Button(self.strings.openFullDiskAccessButton) {
                                TokenSystemSettingsLinks.openFullDiskAccess()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
    }

    private var controlPanelCard: some View {
        PreferencesCard(title: self.strings.settingsDashboardCategoryTitle, systemImage: "square.grid.2x2") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    self.sectionTitle(self.strings.dashboardLargeCardsSectionTitle)
                    PreferencesNote(self.strings.dashboardLargeCardsSectionDescription)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(self.settings.dashboardModuleOrder) { module in
                            DashboardModuleToggleRow(
                                module: module,
                                strings: self.strings,
                                isOn: self.dashboardModuleVisibilityBinding(for: module),
                                draggingModule: self.$draggingDashboardModule,
                                modules: self.settings.dashboardModuleOrder,
                                moveModules: { offsets, destination in
                                    self.settings.moveDashboardModules(fromOffsets: offsets, toOffset: destination)
                                })
                        }

                        PreferencesToggleRow(
                            title: self.strings.sparkQuotaToggleLabel,
                            systemImage: "sparkles",
                            isOn: self.$settings.showSparkQuotaCard)
                    }
                }

                PreferencesDivider()

                VStack(alignment: .leading, spacing: 10) {
                    self.sectionTitle(self.strings.dashboardOverviewRowsSectionTitle)
                    PreferencesNote(self.strings.dashboardOverviewRowsSectionDescription)

                    VStack(alignment: .leading, spacing: 10) {
                        self.overviewToggleRow(
                            title: self.strings.todayUsageTitle,
                            isOn: self.$settings.showTodayUsageCard)
                        self.overviewToggleRow(
                            title: self.strings.sevenDayTotalTitle(),
                            isOn: self.$settings.showSevenDayUsageCard)
                        self.overviewToggleRow(
                            title: self.strings.thirtyDayTotalTitle(),
                            isOn: self.$settings.showThirtyDayUsageCard)
                        self.overviewToggleRow(
                            title: self.strings.allTimeTotalTitle(),
                            isOn: self.$settings.showAllTimeUsageCard)
                    }
                }

                PreferencesNote(self.strings.controlPanelVisibilityDescription)
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(TokenFloatingCardTheme.secondaryText)
    }

    private func dashboardModuleVisibilityBinding(for module: DashboardModule) -> Binding<Bool> {
        Binding(
            get: { self.settings.isDashboardModuleVisible(module) },
            set: { self.settings.setDashboardModuleVisible($0, for: module) })
    }

    private func overviewToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        PreferencesToggleRow(
            title: self.strings.cardVisibilityLabel(title: title),
            systemImage: "sum",
            isOn: isOn)
    }

    private var startupCard: some View {
        PreferencesCard(title: self.strings.startupSectionTitle, systemImage: "power") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(self.strings.launchAtLoginLabel, isOn: self.$settings.launchAtLoginEnabled)
                    .toggleStyle(.switch)

                if let launchAtLoginError = self.settings.launchAtLoginError, !launchAtLoginError.isEmpty {
                    Label(launchAtLoginError, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(TokenMenuTheme.warningText)
                        .font(.footnote)
                }
            }
        }
    }

    private var storageCard: some View {
        PreferencesCard(title: self.strings.storageSectionTitle, systemImage: "internaldrive") {
            VStack(alignment: .leading, spacing: 10) {
                Text(TokenHistoryStore.defaultFileURL.path)
                    .font(.footnote.monospaced())
                    .foregroundStyle(TokenFloatingCardTheme.primaryText)
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        TokenFloatingInsetBackground(
                            cornerRadius: 14,
                            tint: TokenMenuTheme.analyticsTint))

                PreferencesNote(self.strings.storageDescription)
            }
        }
    }

    private func menuBarAppearanceButton(for option: MenuBarAppearanceOption) -> some View {
        let isSelected = option == self.currentMenuBarAppearanceOption

        return Button {
            self.settings.menuBarAppearanceOption = option
        } label: {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        isSelected
                            ? TokenMenuTheme.primaryQuotaTint
                            : TokenFloatingCardTheme.tertiaryText)

                VStack(alignment: .leading, spacing: 6) {
                    Text(self.strings.menuBarAppearanceTitle(option))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TokenFloatingCardTheme.primaryText)

                    Text(self.strings.menuBarAppearanceDescription(option))
                        .font(.system(size: 12))
                        .foregroundStyle(TokenFloatingCardTheme.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 20)

                self.menuBarAppearancePreview(for: option, isSelected: isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    TokenFloatingInsetBackground(
                        cornerRadius: 18,
                        tint: TokenMenuTheme.primaryQuotaTint)
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(TokenFloatingCardTheme.selectionBand.opacity(0.55))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected
                            ? TokenMenuTheme.primaryQuotaTint.opacity(0.34)
                            : TokenFloatingCardTheme.stroke.opacity(0.55),
                        lineWidth: isSelected ? 1.0 : 0.8)
            }
            .shadow(
                color: isSelected ? TokenMenuTheme.primaryQuotaTint.opacity(0.18) : .clear,
                radius: 12,
                x: 0,
                y: 5)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func menuBarAppearancePreview(for option: MenuBarAppearanceOption, isSelected _: Bool) -> some View {
        self.menuBarPreview(
            mode: option.menuBarDisplayMode,
            metrics: self.store.menuBarDisplayMetrics,
            quotaStyle: option.previewQuotaStyle,
            fallbackText: self.store.menuBarText(for: option.menuBarDisplayMode))
    }

    private func menuBarPreview(
        mode: MenuBarDisplayMode,
        metrics: MenuBarDisplayMetrics,
        quotaStyle: MenuBarQuotaStyle,
        fallbackText: String) -> some View
    {
        MenuBarPreviewPlate {
            HStack(alignment: .center, spacing: 8) {
                RenderedMenuBarPreview(
                    mode: mode,
                    metrics: metrics,
                    quotaStyle: quotaStyle,
                    fallbackText: fallbackText,
                    targetHeight: self.menuBarPreviewTargetHeight)

                if self.settings.showsMenuBarTokenSpeedMeter, self.supportsVisualTokenSpeedMeter {
                    TokenMenuSpeedMeterPreviewView(
                        metrics: self.store.menuBarTokenSpeedMetrics)
                }
            }
        }
    }

    private func previewPanelSizing(availableDisplayHeight: CGFloat) -> TokenSettingsPreviewSizing {
        let measuredPreviewNaturalHeight: CGFloat? = if self.measuredPreviewKey == self.previewMeasurementKey {
            self.measuredPreviewNaturalHeight
        } else {
            nil
        }

        return TokenSettingsPreviewSizing(
            naturalPanelHeight: measuredPreviewNaturalHeight,
            availableDisplayHeight: availableDisplayHeight,
            scale: self.previewScale)
    }

    @ViewBuilder
    private func embeddedPanelPreview(availableDisplayHeight: CGFloat) -> some View {
        let sizing = self.previewPanelSizing(availableDisplayHeight: availableDisplayHeight)

        HStack {
            Spacer(minLength: 0)

            if sizing.maxDisplayedHeight > 0 {
                MenuContent(
                    store: self.store,
                    settings: self.settings,
                    panelContainerContext: .embeddedPreview,
                    layoutMode: .display(
                        height: sizing.visibleUnscaledHeight,
                        allowsScrolling: sizing.allowsScrolling),
                    previewMode: true)
                    .frame(width: self.previewPanelWidth, height: sizing.visibleUnscaledHeight)
                    .scaleEffect(self.previewScale, anchor: .top)
                    .frame(
                        width: self.previewPanelWidth * self.previewScale,
                        height: sizing.maxDisplayedHeight,
                        alignment: .top)
                    .allowsHitTesting(false)
            } else {
                Color.clear
                    .frame(width: self.previewPanelWidth * self.previewScale, height: 0)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func pickerRow(title: String, @ViewBuilder content: () -> some View) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TokenFloatingCardTheme.secondaryText)
            }

            Spacer(minLength: 12)
            content()
        }
    }

    private func infoBlock(
        title: String,
        content: String,
        monospaced: Bool = false,
        scrollable: Bool = false) -> some View
    {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TokenFloatingCardTheme.secondaryText)

            if scrollable {
                ScrollView(.vertical, showsIndicators: true) {
                    self.infoText(content, monospaced: monospaced)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 92, maxHeight: 160)
                .padding(10)
                .background(
                    TokenFloatingInsetBackground(
                        cornerRadius: 14,
                        tint: TokenMenuTheme.analyticsTint))
            } else {
                self.infoText(content, monospaced: monospaced)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        TokenFloatingInsetBackground(
                            cornerRadius: 14,
                            tint: TokenMenuTheme.analyticsTint))
            }
        }
    }

    private func infoText(_ content: String, monospaced: Bool) -> some View {
        Text(content)
            .font(monospaced ? .footnote.monospaced() : .footnote)
            .foregroundStyle(TokenFloatingCardTheme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }

    private func measurePreviewNaturalHeight(for key: TokenSettingsPreviewMeasurementKey) async {
        await Task.yield()

        guard self.previewMeasurementKey == key else { return }

        let measuredHeight = MenuContent.preferredPanelHeight(
            store: self.store,
            settings: self.settings,
            panelContainerContext: .embeddedPreview,
            previewMode: true,
            availableScreenHeight: nil)

        guard self.previewMeasurementKey == key else { return }

        if self.measuredPreviewKey == key,
           let currentHeight = self.measuredPreviewNaturalHeight,
           abs(currentHeight - measuredHeight) < 0.5
        {
            return
        }

        self.measuredPreviewKey = key
        self.measuredPreviewNaturalHeight = measuredHeight
    }
}

struct TokenSettingsPreviewMeasurementKey: Equatable {
    let menuPanelVersion: MenuPanelVersion
    let menuPopupStyle: MenuPopupStyle
    let menuVisualTheme: MenuVisualTheme
    let dashboardModuleOrder: [DashboardModule]
    let showRemainingQuotaCard: Bool
    let showSparkQuotaCard: Bool
    let showThirtyDayChartCard: Bool
    let showRecentTwentyFourHourChartCard: Bool
    let showMessageActivityCard: Bool
    let showUsageOverviewCard: Bool
    let showUsageOverviewNumericCard: Bool
    let showCodeReviewCard: Bool
    let showCreditsCard: Bool
    let showUsageBreakdownCard: Bool
    let showCreditsHistoryCard: Bool
    let showTodayUsageCard: Bool
    let showSevenDayUsageCard: Bool
    let showThirtyDayUsageCard: Bool
    let showAllTimeUsageCard: Bool
    let codexQuotaSnapshot: CodexQuotaSnapshot?
    let codexQuotaErrorMessage: String?
    let openAIDashboard: OpenAIDashboardSnapshot?
    let openAIAccountPlanFallback: String?
    let lastOpenAIDashboardError: String?
    let lastError: String?
    let isOpenAIWebEnabled: Bool

    @MainActor
    init(settings: SettingsStore, store: UsageStore) {
        self.menuPanelVersion = settings.menuPanelVersion
        self.menuPopupStyle = settings.menuPopupStyle
        self.menuVisualTheme = settings.menuVisualTheme
        self.dashboardModuleOrder = settings.dashboardModuleOrder
        self.showRemainingQuotaCard = settings.showRemainingQuotaCard
        self.showSparkQuotaCard = settings.showSparkQuotaCard
        self.showThirtyDayChartCard = settings.showThirtyDayChartCard
        self.showRecentTwentyFourHourChartCard = settings.showRecentTwentyFourHourChartCard
        self.showMessageActivityCard = settings.showMessageActivityCard
        self.showUsageOverviewCard = settings.showUsageOverviewCard
        self.showUsageOverviewNumericCard = settings.showUsageOverviewNumericCard
        self.showCodeReviewCard = settings.showCodeReviewCard
        self.showCreditsCard = settings.showCreditsCard
        self.showUsageBreakdownCard = settings.showUsageBreakdownCard
        self.showCreditsHistoryCard = settings.showCreditsHistoryCard
        self.showTodayUsageCard = settings.showTodayUsageCard
        self.showSevenDayUsageCard = settings.showSevenDayUsageCard
        self.showThirtyDayUsageCard = settings.showThirtyDayUsageCard
        self.showAllTimeUsageCard = settings.showAllTimeUsageCard
        self.codexQuotaSnapshot = store.codexQuotaSnapshot
        self.codexQuotaErrorMessage = store.codexQuotaErrorMessage
        self.openAIDashboard = store.openAIDashboard
        self.openAIAccountPlanFallback = store.openAIAccountPlanFallback
        self.lastOpenAIDashboardError = store.lastOpenAIDashboardError
        self.lastError = store.lastError
        self.isOpenAIWebEnabled = store.isOpenAIWebEnabled
    }
}

private struct PreferencesCard<Content: View>: View {
    let title: String
    let systemImage: String
    let expandsVertically: Bool
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        systemImage: String,
        expandsVertically: Bool = false,
        @ViewBuilder content: @escaping () -> Content)
    {
        self.title = title
        self.systemImage = systemImage
        self.expandsVertically = expandsVertically
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(self.title, systemImage: self.systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(TokenFloatingCardTheme.primaryText)
                .labelStyle(.titleAndIcon)

            self.content()
        }
        .padding(20)
        .frame(
            maxWidth: .infinity,
            maxHeight: self.expandsVertically ? .infinity : nil,
            alignment: .topLeading)
        .background(
            TokenFloatingCardBackground(
                cornerRadius: 28,
                tint: TokenMenuTheme.panelGlassTint))
    }
}

private struct PreferencesDivider: View {
    var body: some View {
        Rectangle()
            .fill(TokenMenuTheme.quotaDivider.opacity(0.92))
            .frame(height: 1)
    }
}

private struct PreferencesNote: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(self.text)
            .font(.system(size: 12))
            .foregroundStyle(TokenFloatingCardTheme.tertiaryText)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct PreferencesMenuPicker<Option: Hashable>: View {
    let title: String
    @Binding var selection: Option
    let options: [Option]
    let width: CGFloat
    let titleForOption: (Option) -> String

    @State private var isHovered = false

    var body: some View {
        Menu {
            ForEach(self.options, id: \.self) { option in
                Button {
                    self.selection = option
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: option == self.selection ? "checkmark" : "circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(
                                option == self.selection
                                    ? TokenFloatingCardTheme.primaryText
                                    : TokenFloatingCardTheme.tertiaryText.opacity(0.34))

                        Text(self.titleForOption(option))
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Text(self.titleForOption(self.selection))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TokenFloatingCardTheme.primaryText)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(TokenFloatingCardTheme.secondaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(width: self.width, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(self.backgroundFill))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(self.borderStroke, lineWidth: 0.9)
            }
            .shadow(color: self.shadowColor, radius: 10, x: 0, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            self.isHovered = isHovered
        }
        .accessibilityLabel(self.title)
    }

    private var backgroundFill: Color {
        if self.isHovered {
            return TokenFloatingCardTheme.selectionBand.opacity(0.78)
        }

        return TokenFloatingCardTheme.selectionBand.opacity(0.58)
    }

    private var borderStroke: Color {
        if self.isHovered {
            return TokenFloatingCardTheme.stroke.opacity(0.92)
        }

        return TokenFloatingCardTheme.stroke.opacity(0.7)
    }

    private var shadowColor: Color {
        if self.isHovered {
            return TokenFloatingCardTheme.outerShadow.opacity(0.16)
        }

        return TokenFloatingCardTheme.outerShadow.opacity(0.08)
    }
}

private struct PreferencesToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: self.systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TokenFloatingCardTheme.tertiaryText)
                .frame(width: 16)

            Text(self.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(TokenFloatingCardTheme.primaryText)

            Spacer(minLength: 12)

            Toggle("", isOn: self.$isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            TokenFloatingInsetBackground(
                cornerRadius: 16,
                tint: TokenMenuTheme.analyticsTint))
    }
}

@MainActor
private struct DashboardModuleToggleRow: View {
    let module: DashboardModule
    let strings: AppStrings
    @Binding var isOn: Bool
    @Binding var draggingModule: DashboardModule?
    let modules: [DashboardModule]
    let moveModules: (IndexSet, Int) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            DashboardModuleReorderHandle()
                .contentShape(Rectangle())
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
                .onDrag {
                    self.draggingModule = self.module
                    return NSItemProvider(object: self.module.rawValue as NSString)
                }

            Label(
                self.strings.cardVisibilityLabel(title: self.module.title(strings: self.strings)),
                systemImage: self.module.systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(TokenFloatingCardTheme.primaryText)
                .labelStyle(.titleAndIcon)
                .imageScale(.small)

            Spacer(minLength: 12)

            Toggle("", isOn: self.$isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            TokenFloatingInsetBackground(
                cornerRadius: 16,
                tint: TokenMenuTheme.analyticsTint))
        .onDrop(
            of: [UTType.plainText],
            delegate: DashboardModuleDropDelegate(
                item: self.module,
                modules: self.modules,
                dragging: self.$draggingModule,
                moveModules: self.moveModules))
    }
}

private struct DashboardModuleReorderHandle: View {
    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 3) {
                    Circle()
                        .frame(width: 3, height: 3)
                    Circle()
                        .frame(width: 3, height: 3)
                }
            }
        }
        .frame(width: 18, height: 18)
        .foregroundStyle(TokenFloatingCardTheme.tertiaryText)
        .accessibilityLabel("Reorder")
    }
}

private struct DashboardModuleDropDelegate: DropDelegate {
    let item: DashboardModule
    let modules: [DashboardModule]
    @Binding var dragging: DashboardModule?
    let moveModules: (IndexSet, Int) -> Void

    func dropEntered(info _: DropInfo) {
        guard let dragging, dragging != self.item else { return }
        guard let fromIndex = self.modules.firstIndex(of: dragging),
              let toIndex = self.modules.firstIndex(of: self.item)
        else { return }

        if fromIndex == toIndex { return }
        let adjustedIndex = toIndex > fromIndex ? toIndex + 1 : toIndex
        self.moveModules(IndexSet(integer: fromIndex), adjustedIndex)
    }

    func dropUpdated(info _: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info _: DropInfo) -> Bool {
        self.dragging = nil
        return true
    }
}

private struct PreferencesSectionHeader: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(self.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(TokenFloatingCardTheme.primaryText)

            Text(self.detail)
                .font(.system(size: 13))
                .foregroundStyle(TokenFloatingCardTheme.tertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
