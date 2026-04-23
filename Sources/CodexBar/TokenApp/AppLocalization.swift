import CodexBarCore
import Foundation

enum AppLanguage: String, CaseIterable, Codable, Sendable, Identifiable {
    case system
    case zhHans
    case en
    case ja

    var id: String {
        self.rawValue
    }

    static func resolvePreferredLanguage(_ preferredLanguages: [String]) -> AppLanguage {
        let first = preferredLanguages.first?.lowercased() ?? ""
        if first.hasPrefix("ja") { return .ja }
        if first.hasPrefix("en") { return .en }
        if first.hasPrefix("zh") { return .zhHans }
        return .zhHans
    }

    var localeIdentifier: String {
        switch self {
        case .system, .zhHans:
            "zh-Hans"
        case .en:
            "en"
        case .ja:
            "ja"
        }
    }
}

struct CompactTokenTextParts: Equatable, Sendable {
    let amountText: String
    let unitText: String?
}

struct AppStrings {
    let language: AppLanguage

    var locale: Locale {
        Locale(identifier: self.language.localeIdentifier)
    }

    var languageSectionTitle: String {
        self.text(zh: "语言", en: "Language", ja: "言語")
    }

    var refreshSectionTitle: String {
        self.text(zh: "刷新", en: "Refresh", ja: "更新")
    }

    var menuBarSectionTitle: String {
        self.text(zh: "菜单栏", en: "Menu Bar", ja: "メニューバー")
    }

    var controlPanelSectionTitle: String {
        self.text(zh: "控制面板", en: "Control Panel", ja: "コントロールパネル")
    }

    var startupSectionTitle: String {
        self.text(zh: "启动", en: "Startup", ja: "起動")
    }

    var storageSectionTitle: String {
        self.text(zh: "存储", en: "Storage", ja: "ストレージ")
    }

    var openAIWebSectionTitle: String {
        self.text(zh: "OpenAI 网页", en: "OpenAI Web", ja: "OpenAI Web")
    }

    var languageLabel: String {
        self.text(zh: "界面语言", en: "App language", ja: "表示言語")
    }

    var refreshFrequencyLabel: String {
        self.text(zh: "频率", en: "Frequency", ja: "頻度")
    }

    var quotaRefreshFrequencyLabel: String {
        self.text(zh: "额度刷新频率", en: "Quota refresh frequency", ja: "残量更新頻度")
    }

    var quotaRefreshFrequencyDescription: String {
        self.text(
            zh: "用于剩余额度数据。启动会立即刷新一次，后台按分钟级自动更新。",
            en: "Used for remaining quota data. Refreshes immediately on launch and then updates on a minute-level cadence.",
            ja: "残量データに使います。起動時に即時更新し、その後は分単位で自動更新します。")
    }

    var usageStatisticsRefreshFrequencyLabel: String {
        self.text(zh: "统计刷新频率", en: "Usage refresh frequency", ja: "統計更新頻度")
    }

    var usageStatisticsRefreshFrequencyDescription: String {
        self.text(
            zh: "用于 30 天、48 小时、消息统计等重计算数据。频率越低越省 CPU 和内存，但统计会更慢更新。",
            en: "Used for heavy statistics such as 30-day, 48-hour, and message activity data. Lower frequency saves CPU and memory but updates stats more slowly.",
            ja: "30 日、48 時間、メッセージ統計などの重い集計に使います。頻度を下げるほど CPU とメモリを節約できますが、統計の更新は遅くなります。")
    }

    var menuBarDisplayLabel: String {
        self.text(zh: "显示格式", en: "Display", ja: "表示形式")
    }

    var menuBarQuotaStyleLabel: String {
        self.text(zh: "5 小时剩余样式", en: "5-hour remaining style", ja: "5 時間残量のスタイル")
    }

    var menuBarQuotaStyleDescription: String {
        self.text(
            zh: "可切换 5 小时剩余的菜单栏样式，不影响今日输入 / 输出模式。",
            en: "Switches the 5-hour remaining menu bar style without affecting today's input / output mode.",
            ja: "5 時間残量のメニューバースタイルを切り替えます。今日の入力 / 出力モードには影響しません。")
    }

    var menuBarTokenSpeedMeterLabel: String {
        self.text(
            zh: "显示独立 token/s 速度计",
            en: "Show separate token/s meter",
            ja: "独立した token/s メーターを表示")
    }

    var menuBarTokenSpeedMeterDescription: String {
        self.text(
            zh: "在主 TokenBar 旁边增加一个独立速度图标；有吞吐时会在图标下方展开 token/s 连体气泡，不会替换原图标。",
            en: "Adds a separate speed icon next to the main TokenBar; when throughput is active it expands a connected token/s bubble below without replacing the original icon.",
            ja: "メインの TokenBar の横に独立した速度アイコンを追加し、スループットが発生すると下側に連結した token/s バブルを展開します。元のアイコンは置き換えません。")
    }

    var menuBarTokenSpeedMeterRequiresMacOS26: String {
        self.text(
            zh: "此样式需要 macOS 26 或更高版本；旧系统不会显示这个独立速度项。",
            en: "This style requires macOS 26 or later; earlier systems will not show the separate speed item.",
            ja: "このスタイルは macOS 26 以降が必要です。旧バージョンのシステムでは独立した速度項目は表示されません。")
    }

    var tokenSpeedCurveTitle: String {
        self.text(
            zh: "最近 600 秒吞吐曲线",
            en: "Last 600 Seconds Throughput",
            ja: "直近 600 秒のスループット")
    }

    var tokenSpeedHistoryTitle: String {
        self.text(
            zh: "吞吐记录",
            en: "Throughput History",
            ja: "スループット履歴")
    }

    func tokenSpeedFloatingChartButtonText(isPresented: Bool) -> String {
        if isPresented {
            return self.text(
                zh: "关闭桌面浮窗",
                en: "Close floating chart",
                ja: "フローティングチャートを閉じる")
        }

        return self.text(
            zh: "弹出桌面浮窗",
            en: "Pop out floating chart",
            ja: "フローティングチャートを開く")
    }

    var tokenSpeedFloatingTodayTokensLabel: String {
        self.text(
            zh: "token",
            en: "token",
            ja: "token")
    }

    var tokenSpeedFloatingTodayInstructionsLabel: String {
        self.text(
            zh: "指令",
            en: "instr",
            ja: "指示")
    }

    var noTokenSpeedHistoryData: String {
        self.text(
            zh: "还没有记录到非零吞吐。",
            en: "No non-zero throughput samples yet.",
            ja: "非ゼロのスループット記録はまだありません。")
    }

    var remainingQuotaStyleLabel: String {
        self.text(zh: "额度卡片样式", en: "Quota card style", ja: "利用枠カードのスタイル")
    }

    var remainingQuotaStyleDescription: String {
        self.text(
            zh: "影响顶部“Codex 额度”和“Spark 额度”卡片。",
            en: "Affects the top Codex quota and Spark quota cards.",
            ja: "上部の Codex 利用枠カードと Spark 利用枠カードに適用されます。")
    }

    var recentFortyEightHourChartStyleLabel: String {
        self.text(zh: "48 小时图表样式", en: "48-hour chart style", ja: "48時間チャートスタイル")
    }

    var recentFortyEightHourChartStyleDescription: String {
        self.text(
            zh: "切换“最近 48 小时”卡片的表现方式。新柱图会按小时显示用量，波浪图保留原有曲线样式。",
            en: "Switch the Last 48 Hours card between the new hourly bars and the original wave chart.",
            ja: "直近 48 時間カードを時間ごとの棒グラフ表示と従来の波形チャート表示で切り替えます。")
    }

    var menuPanelVersionLabel: String {
        self.text(zh: "面板版本", en: "Panel version", ja: "パネルバージョン")
    }

    var menuPanelVersionDescription: String {
        self.text(
            zh: "切换整张菜单面板的视觉版本。统一浮层紧凑版会一起调整高度、卡片和按钮风格。",
            en: """
            Switch the full menu panel design. The unified compact version also adjusts height, cards, and buttons.
            """,
            ja: "メニューパネル全体のデザインバージョンを切り替えます。統一コンパクト版では高さ、カード、ボタンもまとめて調整されます。")
    }

    var menuPopupStyleLabel: String {
        self.text(zh: "弹窗风格", en: "Popup style", ja: "ポップアップスタイル")
    }

    var menuPopupStyleDescription: String {
        self.text(
            zh: "切换点击菜单栏图标时使用的主弹窗容器。液态玻璃保留当前自定义面板，系统 popover 使用 macOS 原生弹窗。",
            en: "Switch the main popup container used when clicking the menu bar item. Liquid Glass keeps the current custom panel, while System Popover uses the native macOS popover.",
            ja: "メニューバーアイコンをクリックしたときに使うメインポップアップのコンテナを切り替えます。リキッドガラスは現在のカスタムパネルを維持し、システムポップオーバーは macOS 標準のポップオーバーを使います。")
    }

    var menuVisualThemeLabel: String {
        self.text(zh: "主题风格", en: "Theme style", ja: "テーマスタイル")
    }

    var menuVisualThemeDescription: String {
        self.text(
            zh: "为菜单面板选择显示主题。你可以在不改变交互方式的情况下，切换颜色、底纹与高亮风格。",
            en: "Choose a visual theme for the menu panel. Colors, textures, and accent look change without affecting behavior.",
            ja: "メニューパネルの外観テーマを選択します。操作挙動は変わらず、配色や質感、アクセントの見た目だけを切り替えます。")
    }

    var launchAtLoginLabel: String {
        self.text(zh: "登录时启动", en: "Launch at login", ja: "ログイン時に起動")
    }

    var currentPreviewLabel: String {
        self.text(zh: "当前预览", en: "Current preview", ja: "現在のプレビュー")
    }

    var controlPanelVisibilityDescription: String {
        self.text(
            zh: "控制菜单面板里各个大卡片是否显示，并拖动调整排序。",
            en: "Control which large cards appear in the menu panel and drag to reorder them.",
            ja: "メニューパネル内の大型カードの表示を切り替え、ドラッグして順序も調整できます。")
    }

    var openAIWebAccessLabel: String {
        self.text(zh: "启用 OpenAI 网页附加信息", en: "Enable OpenAI web extras", ja: "OpenAI Web 追加情報を有効化")
    }

    var openAIWebAccessDescription: String {
        self.text(
            zh: "可选功能。Codex 主额度和 Spark 额度默认都来自 OAuth/CLI 的结构化接口；这里只用于 Code review、Usage breakdown、Credits history，以及 Spark 额度在结构化接口缺失时的网页兜底。启用后若 OpenAI Cookies 设为“自动”或“Safari”，可能访问浏览器 Cookie 并触发 macOS 钥匙串提示。",
            en: "Optional. The main Codex quota and Spark quota now come from the structured OAuth/CLI usage API by default. OpenAI web extras are mainly for code review, usage breakdown, credits history, and Spark fallback when the structured response does not include Spark limits. If OpenAI cookies stay on Auto or Safari, enabling this may access browser cookies and trigger a macOS Keychain prompt.",
            ja: "任意機能です。Codex の主な利用枠と Spark 利用枠は、デフォルトでは OAuth/CLI の構造化 API から取得されます。OpenAI Web 追加情報は主に Code review、Usage breakdown、Credits history、および構造化レスポンスに Spark 利用枠が含まれない場合の Web フォールバックに使われます。OpenAI Cookies が「自動」または「Safari」のままだと、ブラウザ Cookie へアクセスし macOS のキーチェーン確認が表示されることがあります。")
    }

    var backgroundBrowserAutoImportLabel: String {
        self.text(
            zh: "后台自动导入浏览器登录态",
            en: "Auto-import browser session in background",
            ja: "バックグラウンドでブラウザのログイン状態を自動取り込み")
    }

    var backgroundBrowserAutoImportDescription: String {
        self.text(
            zh: "仅在 OpenAI Cookies 设为“自动”或“Safari”时生效。关闭后，后台刷新不会重导入浏览器登录态，但手动刷新仍会导入；因此保持关闭更适合避免意外的浏览器/钥匙串访问。",
            en: "Only applies when OpenAI cookies are set to Auto or Safari. When off, background refresh will not re-import the browser session, but manual refresh still will; leaving this off is the safer default if you want to avoid surprise browser or Keychain access.",
            ja: "OpenAI Cookies が「自動」または「Safari」のときだけ有効です。オフにするとバックグラウンド更新ではブラウザのログイン状態を再取り込みしませんが、手動更新では引き続き取り込みます。意図しないブラウザ／キーチェーンアクセスを避けるなら、オフのままが安全です。")
    }

    var cookieSourceLabel: String {
        self.text(zh: "OpenAI Cookies", en: "OpenAI cookies", ja: "OpenAI Cookies")
    }

    var manualCookieHeaderLabel: String {
        self.text(
            zh: "手动 Cookie Header",
            en: "Manual cookie header",
            ja: "手動 Cookie ヘッダー")
    }

    var manualCookieHeaderPlaceholder: String {
        self.text(
            zh: "粘贴浏览器里的完整 Cookie header",
            en: "Paste the full Cookie header from your browser",
            ja: "ブラウザの Cookie ヘッダー全体を貼り付け")
    }

    var cookieImportStatusLabel: String {
        self.text(zh: "Cookie 状态", en: "Cookie status", ja: "Cookie 状態")
    }

    var debugLogLabel: String {
        self.text(zh: "调试日志", en: "Debug log", ja: "デバッグログ")
    }

    var browserAccessHelpTitle: String {
        self.text(zh: "浏览器数据权限", en: "Browser Data Access", ja: "ブラウザデータのアクセス権")
    }

    var browserAccessHelpDescription: String {
        self.text(
            zh: "CodexTokenBar 是独立于原版 CodexBar 的另一款 app。即使你已经授权原版，当前这份 app 也需要重新获得浏览器数据访问权限。",
            en: "CodexTokenBar is a separate app from the original CodexBar. "
                + "Even if the original app is already allowed, this build needs its own browser-data permission.",
            ja: "CodexTokenBar は元の CodexBar とは別アプリです。元のアプリを許可済みでも、このビルドには個別にブラウザデータアクセス権が必要です。")
    }

    var openFullDiskAccessButton: String {
        self.text(zh: "打开完整磁盘访问权限", en: "Open Full Disk Access", ja: "フルディスクアクセスを開く")
    }

    var noDebugLog: String {
        self.text(zh: "暂无调试日志。", en: "No debug log yet.", ja: "デバッグログはまだありません。")
    }

    var manualRefreshHint: String {
        self.text(
            zh: "手动模式会关闭后台自动刷新，但你仍然可以在菜单面板里手动强制刷新。",
            en: "Manual mode disables background refresh, but you can still force refresh from the menu.",
            ja: "手動モードではバックグラウンド更新を停止しますが、メニューから強制更新できます。")
    }

    var storageDescription: String {
        self.text(
            zh: "历史会缓存在本地，即使旧 session 文件被删除，也会保留到你手动重建缓存为止。",
            en: "History stays cached locally until you rebuild the cache.",
            ja: "履歴はローカルに保持され、キャッシュを再構築するまで消えません。")
    }

    var remainingQuotaTitle: String {
        self.text(zh: "Codex 额度", en: "Codex Quota", ja: "Codex 利用枠")
    }

    var sparkQuotaTitle: String {
        self.text(zh: "Spark 额度", en: "Spark Quota", ja: "Spark 利用枠")
    }

    var sparkQuotaToggleLabel: String {
        self.text(
            zh: "显示 GPT-5.3-Codex-Spark 额度",
            en: "Show GPT-5.3-Codex-Spark quota",
            ja: "GPT-5.3-Codex-Spark 利用枠を表示")
    }

    var codeReviewTitle: String {
        self.text(zh: "Code review", en: "Code review", ja: "Code review")
    }

    var usageBreakdownTitle: String {
        self.text(zh: "Usage breakdown", en: "Usage breakdown", ja: "Usage breakdown")
    }

    var creditsHistoryTitle: String {
        self.text(zh: "Credits history", en: "Credits history", ja: "Credits history")
    }

    var lastSevenDaysTitle: String {
        self.text(zh: "最近 7 天", en: "Last 7 Days", ja: "直近 7 日")
    }

    var lastThirtyDaysTitle: String {
        self.text(zh: "30 天（主线程）", en: "Last 30 Days", ja: "直近 30 日")
    }

    var recentTwentyFourHoursTitle: String {
        self.text(zh: "最近 24 小时", en: "Last 24 Hours", ja: "直近 24 時間")
    }

    var recentFortyEightHoursTitle: String {
        self.text(zh: "48 小时（主线程）", en: "Last 48 Hours", ja: "直近 48 時間")
    }

    var messageActivityTitle: String {
        self.text(zh: "人类发送指令统计", en: "Human Instruction Activity", ja: "人間の指示統計")
    }

    var totalsTitle: String {
        self.text(zh: "汇总", en: "Totals", ja: "合計")
    }

    var totalsNumericTitle: String {
        self.text(zh: "汇总数字版", en: "Totals Numeric", ja: "合計数値版")
    }

    var todayUsageTitle: String {
        self.text(zh: "今日", en: "Today", ja: "今日")
    }

    var inputLabel: String {
        self.text(zh: "输入", en: "Input", ja: "入力")
    }

    var outputLabel: String {
        self.text(zh: "输出", en: "Output", ja: "出力")
    }

    var totalConsumptionLabel: String {
        self.text(zh: "总量", en: "Total", ja: "総消費")
    }

    var mainThreadLabel: String {
        self.text(zh: "主线程", en: "Main thread", ja: "メインスレッド")
    }

    func compactTokenParts(_ value: Int) -> CompactTokenTextParts {
        self.compactTokenParts(from: self.compactTokenText(value))
    }

    func totalTokenText(_ value: Int) -> String {
        "\(self.totalConsumptionLabel) \(self.compactTokenText(value))"
    }

    func mainThreadTokenText(_ value: Int) -> String {
        "\(self.mainThreadLabel) \(self.compactTokenText(value))"
    }

    func usageOverviewNumericAccessibilityText(
        title: String,
        totalValue: Int,
        mainThreadValue: Int)
        -> String
    {
        switch self.resolvedLanguage {
        case .system, .zhHans:
            "\(title)，\(self.totalTokenText(totalValue))，\(self.mainThreadTokenText(mainThreadValue))"
        case .ja:
            "\(title)、\(self.totalTokenText(totalValue))、\(self.mainThreadTokenText(mainThreadValue))"
        case .en:
            "\(title), \(self.totalTokenText(totalValue)), \(self.mainThreadTokenText(mainThreadValue))"
        }
    }

    func compactTokenText(_ value: Int) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            if value >= 100_000_000 {
                return self.localizedCompactNumber(value, divisor: 100_000_000, unit: "亿", spacedUnit: true)
            }
            if value >= 10000 {
                return self.localizedCompactNumber(value, divisor: 10000, unit: "万", spacedUnit: true)
            }
        case .ja:
            if value >= 100_000_000 {
                return self.localizedCompactNumber(value, divisor: 100_000_000, unit: "億", spacedUnit: true)
            }
            if value >= 10000 {
                return self.localizedCompactNumber(value, divisor: 10000, unit: "万", spacedUnit: true)
            }
        case .en:
            if value >= 1_000_000_000 {
                return self.localizedCompactNumber(value, divisor: 1_000_000_000, unit: "B", spacedUnit: false)
            }
            if value >= 1_000_000 {
                return self.localizedCompactNumber(value, divisor: 1_000_000, unit: "M", spacedUnit: false)
            }
            if value >= 1000 {
                return self.localizedCompactNumber(value, divisor: 1000, unit: "K", spacedUnit: false)
            }
        default:
            break
        }

        return UsageStore.exactTokenText(value, locale: self.locale)
    }

    func chartCompactTokenText(_ value: Int) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            if value >= 100_000_000 {
                return self.localizedCompactNumber(value, divisor: 100_000_000, unit: "亿", spacedUnit: false)
            }
            if value >= 10000 {
                return self.localizedCompactNumber(value, divisor: 10000, unit: "万", spacedUnit: false)
            }
        case .ja:
            if value >= 100_000_000 {
                return self.localizedCompactNumber(value, divisor: 100_000_000, unit: "億", spacedUnit: false)
            }
            if value >= 10000 {
                return self.localizedCompactNumber(value, divisor: 10000, unit: "万", spacedUnit: false)
            }
        case .en:
            if value >= 1_000_000_000 {
                return self.localizedCompactNumber(value, divisor: 1_000_000_000, unit: "B", spacedUnit: false)
            }
            if value >= 1_000_000 {
                return self.localizedCompactNumber(value, divisor: 1_000_000, unit: "M", spacedUnit: false)
            }
            if value >= 1000 {
                return self.localizedCompactNumber(value, divisor: 1000, unit: "K", spacedUnit: false)
            }
        default:
            break
        }

        return UsageStore.exactTokenText(value, locale: self.locale)
    }

    func thirtyDayPeakTokenText(_ value: Int) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            self.localizedCompactNumber(value, divisor: 100_000_000, unit: "亿", spacedUnit: false)
        case .en, .ja:
            self.chartCompactTokenText(value)
        default:
            self.chartCompactTokenText(value)
        }
    }

    func messageActivityPeakBubbleText(_ value: Int) -> String {
        let countText = UsageStore.exactTokenText(value, locale: self.locale)

        return switch self.resolvedLanguage {
        case .zhHans:
            "\(countText) 次"
        case .en:
            "\(countText) instr"
        case .ja:
            "\(countText)回"
        default:
            "\(countText) 次"
        }
    }

    func menuBarTokenSpeedTooltip(tokensPerSecond: Int) -> String {
        self.text(
            zh: "当前 Codex 吞吐：\(tokensPerSecond) token/s",
            en: "Current Codex throughput: \(tokensPerSecond) token/s",
            ja: "現在の Codex スループット: \(tokensPerSecond) token/s")
    }

    func tokenSpeedHistoryValueText(_ value: Int) -> String {
        "\(UsageStore.exactTokenText(value, locale: self.locale)) tokens"
    }

    var refreshNow: String {
        self.text(zh: "强制刷新", en: "Force Refresh", ja: "強制更新")
    }

    var fetchFromSafari: String {
        self.text(zh: "从 Safari 获取", en: "Fetch from Safari", ja: "Safari から取得")
    }

    var manualDashboardRefreshRequiredMessage: String {
        self.text(
            zh: "当前显示缓存数据。需要时请手动强制刷新。",
            en: "Showing cached quota data. Force refresh when you need the latest value.",
            ja: "現在はキャッシュ済みの利用枠を表示しています。最新値が必要なときは強制更新してください。")
    }

    var rebuildCache: String {
        self.text(zh: "重建缓存", en: "Rebuild Cache", ja: "キャッシュを再構築")
    }

    var settings: String {
        self.text(zh: "设置", en: "Settings", ja: "設定")
    }

    var quit: String {
        self.text(zh: "退出", en: "Quit", ja: "終了")
    }

    var quotaCreditsLabel: String {
        self.text(zh: "剩余 Credits", en: "Credits Left", ja: "残り Credits")
    }

    var quotaCachedBadge: String {
        self.text(zh: "缓存", en: "Cached", ja: "キャッシュ")
    }

    var quotaNeedsLoginMessage: String {
        self.text(
            zh: "需要登录 OpenAI 网页才能读取额度信息。",
            en: "Sign in to the OpenAI web dashboard to load quota information.",
            ja: "利用枠を表示するには OpenAI Web ダッシュボードへのログインが必要です。")
    }

    var browserAccessDeniedMessage: String {
        self.text(
            zh: "无法读取浏览器登录态，请检查浏览器 Cookie 访问权限。",
            en: "Unable to read browser login state. Check browser cookie permissions.",
            ja: "ブラウザのログイン状態を読み取れません。Cookie へのアクセス権限を確認してください。")
    }

    var quotaUnavailableMessage: String {
        self.text(
            zh: "暂时无法读取额度信息，请稍后重试。",
            en: "Quota information is temporarily unavailable. Please try again.",
            ja: "利用枠情報を一時的に取得できません。しばらくしてから再試行してください。")
    }

    var codexQuotaUnavailableMessage: String {
        self.text(
            zh: "暂时无法读取 Codex 主额度，请稍后重试。",
            en: "The main Codex quota is temporarily unavailable. Please try again.",
            ja: "Codex の主な利用枠を一時的に取得できません。しばらくしてから再試行してください。")
    }

    var sparkQuotaUnavailableMessage: String {
        self.text(
            zh: "暂时无法读取 Spark 额度，请稍后重试。",
            en: "Spark quota is temporarily unavailable. Please try again later.",
            ja: "Spark 利用枠を一時的に取得できません。しばらくしてから再試行してください。")
    }

    var manualCookieInvalidMessage: String {
        self.text(
            zh: "手动 Cookie Header 无效，缺少可用的 OpenAI 登录态。",
            en: "The manual Cookie header is invalid or missing a usable OpenAI session.",
            ja: "手動 Cookie ヘッダーが無効か、有効な OpenAI セッションがありません。")
    }

    var openAIWebDisabledMessage: String {
        self.text(
            zh: "已关闭 OpenAI 网页附加信息。",
            en: "OpenAI web extras are turned off.",
            ja: "OpenAI Web 追加情報はオフです。")
    }

    var openAIWebAutoImportDeferredMessage: String {
        self.text(
            zh: "后台自动导入浏览器登录态已关闭。需要时请手动刷新。",
            en: "Background browser session import is turned off. Refresh manually when needed.",
            ja: "バックグラウンドでのブラウザのログイン状態の自動取り込みはオフです。必要なときに手動で更新してください。")
    }

    var noCodeReviewData: String {
        self.text(zh: "暂无 Code review 数据。", en: "No code review data.", ja: "Code review データはありません。")
    }

    var noUsageBreakdownData: String {
        self.text(zh: "暂无 Usage breakdown 数据。", en: "No usage breakdown data.", ja: "Usage breakdown データはありません。")
    }

    var noCreditsHistoryData: String {
        self.text(zh: "暂无 Credits history 数据。", en: "No credits history data.", ja: "Credits history データはありません。")
    }

    var noRecentTwentyFourHourData: String {
        self.text(zh: "最近 24 小时暂无用量数据。", en: "No usage data in the last 24 hours.", ja: "直近 24 時間の利用データはありません。")
    }

    var noRecentFortyEightHourData: String {
        self.text(zh: "最近 48 小时暂无用量数据。", en: "No usage data in the last 48 hours.", ja: "直近 48 時間の利用データはありません。")
    }

    var noMessageActivityData: String {
        self.text(
            zh: "还没有检测到人类指令记录。",
            en: "No human instruction activity yet.",
            ja: "人間の指示記録はまだありません。")
    }

    var instructionCountTitle: String {
        self.text(zh: "指令次数", en: "Instructions", ja: "指示回数")
    }

    var characterCountTitle: String {
        self.text(zh: "字符量", en: "Characters", ja: "文字量")
    }

    var messageActivityTodayTitle: String {
        self.text(zh: "今天", en: "Today", ja: "今日")
    }

    var messageActivitySevenDayTitle: String {
        self.text(zh: "7 天", en: "7 days", ja: "7 日")
    }

    var messageActivityThirtyDayTitle: String {
        self.text(zh: "30 天", en: "30 days", ja: "30 日")
    }

    var messageActivityCumulativeTitle: String {
        self.text(zh: "累计", en: "All time", ja: "累計")
    }

    var lastThirtyDaysInstructionTrendTitle: String {
        self.text(zh: "最近 30 天指令趋势", en: "Last 30 Days Instructions", ja: "直近 30 日の指示回数")
    }

    var totalSentCharactersTitle: String {
        self.text(zh: "累计字符", en: "Total chars", ja: "累計文字")
    }

    var todaySentCharactersTitle: String {
        self.text(zh: "今日字符", en: "Today chars", ja: "今日の文字")
    }

    var todaySentMessagesTitle: String {
        self.text(zh: "今日消息", en: "Today msgs", ja: "今日の件数")
    }

    var lastThirtyDaysCharactersTitle: String {
        self.text(zh: "最近 30 天字符趋势", en: "Last 30 Days Characters", ja: "直近 30 日の文字数")
    }

    func cardVisibilityLabel(title: String) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            "显示 \(title)"
        case .en:
            "Show \(title)"
        case .ja:
            "\(title) を表示"
        default:
            "显示 \(title)"
        }
    }

    func remainingQuotaStyleTitle(_ style: RemainingQuotaCardStyle) -> String {
        switch (self.resolvedLanguage, style) {
        case (.zhHans, .glass):
            "系统玻璃"
        case (.zhHans, .fitness):
            "暗色运动"
        case (.en, .glass):
            "System Glass"
        case (.en, .fitness):
            "Dark Fitness"
        case (.ja, .glass):
            "システムガラス"
        case (.ja, .fitness):
            "ダークフィットネス"
        default:
            "系统玻璃"
        }
    }

    func recentFortyEightHourChartStyleTitle(_ style: RecentFortyEightHourChartStyle) -> String {
        switch (self.resolvedLanguage, style) {
        case (.zhHans, .bars):
            "小时柱图"
        case (.zhHans, .wave):
            "波浪曲线"
        case (.en, .bars):
            "Hourly Bars"
        case (.en, .wave):
            "Wave Chart"
        case (.ja, .bars):
            "時間バー"
        case (.ja, .wave):
            "波形チャート"
        default:
            "小时柱图"
        }
    }

    func recentFortyEightHourChartStyleDescription(_ style: RecentFortyEightHourChartStyle) -> String {
        switch (self.resolvedLanguage, style) {
        case (.zhHans, .bars):
            "与最近 30 天一致的蓝色柱状图，每小时一根柱子。"
        case (.zhHans, .wave):
            "保留当前的波浪面积曲线，适合观察连续趋势。"
        case (.en, .bars):
            "Blue hourly bars matching the Last 30 Days card, with one bar per hour."
        case (.en, .wave):
            "Keep the current filled wave line for a more continuous trend view."
        case (.ja, .bars):
            "直近 30 日カードに合わせた青い棒グラフで、1時間ごとに1本表示します。"
        case (.ja, .wave):
            "現在の波形エリアチャートを維持し、連続した推移を見やすくします。"
        default:
            "与最近 30 天一致的蓝色柱状图，每小时一根柱子。"
        }
    }

    func menuBarQuotaStyleTitle(_ style: MenuBarQuotaStyle) -> String {
        switch (self.resolvedLanguage, style) {
        case (.zhHans, .capsule):
            "经典胶囊"
        case (.zhHans, .split):
            "分栏徽记"
        case (.zhHans, .meter):
            "极细仪表"
        case (.zhHans, .outline):
            "描边轻量"
        case (.zhHans, .codexMinimal):
            "Codex 极简"
        case (.en, .capsule):
            "Classic Capsule"
        case (.en, .split):
            "Split Badge"
        case (.en, .meter):
            "Slim Meter"
        case (.en, .outline):
            "Light Outline"
        case (.en, .codexMinimal):
            "Codex Minimal"
        case (.ja, .capsule):
            "クラシックカプセル"
        case (.ja, .split):
            "分割バッジ"
        case (.ja, .meter):
            "スリムメーター"
        case (.ja, .outline):
            "ライトアウトライン"
        case (.ja, .codexMinimal):
            "Codex ミニマル"
        default:
            "经典胶囊"
        }
    }

    func menuPanelVersionTitle(_ version: MenuPanelVersion) -> String {
        switch (self.resolvedLanguage, version) {
        case (.zhHans, .current):
            "当前版本"
        case (.zhHans, .unifiedCompact):
            "统一浮层紧凑版"
        case (.en, .current):
            "Current"
        case (.en, .unifiedCompact):
            "Unified Compact"
        case (.ja, .current):
            "現在のバージョン"
        case (.ja, .unifiedCompact):
            "統一コンパクト版"
        default:
            "当前版本"
        }
    }

    func menuPopupStyleTitle(_ style: MenuPopupStyle) -> String {
        switch (self.resolvedLanguage, style) {
        case (.zhHans, .liquidGlass):
            "液态玻璃"
        case (.zhHans, .systemPopover):
            "系统 popover"
        case (.en, .liquidGlass):
            "Liquid Glass"
        case (.en, .systemPopover):
            "System Popover"
        case (.ja, .liquidGlass):
            "リキッドガラス"
        case (.ja, .systemPopover):
            "システムポップオーバー"
        default:
            "液态玻璃"
        }
    }

    func menuVisualThemeTitle(_ theme: MenuVisualTheme) -> String {
        switch (self.resolvedLanguage, theme) {
        case (.zhHans, .liquidGlassClassic):
            "液态玻璃经典"
        case (.zhHans, .pureLiquidGlass):
            "纯粹液态玻璃"
        case (.zhHans, .pixelGame):
            "像素游戏"
        case (.zhHans, .pixelArcade):
            "像素街机"
        case (.zhHans, .insCream):
            "INS 奶油"
        case (.zhHans, .handbookCollage):
            "手帐拼贴"
        case (.zhHans, .diaryPaper):
            "日记纸感"
        case (.zhHans, .retroCopper):
            "复古铜棕"
        case (.zhHans, .cyberNeon):
            "赛博霓虹"
        case (.zhHans, .sakura):
            "少女樱花"
        case (.zhHans, .literaryFresh):
            "文艺清新"
        case (.zhHans, .minimalBlackWhite):
            "极简黑白"
        case (.zhHans, .midnightBlue):
            "深夜蓝调"
        case (.zhHans, .forestMatcha):
            "森林抹茶"
        case (.zhHans, .citrusSunset):
            "柑橘日落"
        case (.zhHans, .seaSaltMint):
            "海盐薄荷"
        case (.zhHans, .purpleMist):
            "紫雾梦境"
        case (.zhHans, .amberFilm):
            "琥珀胶片"
        case (.zhHans, .nordicCoolGray):
            "北欧冷灰"
        case (.zhHans, .industrialUtility):
            "机能工业"
        case (.zhHans, .frenchCafe):
            "法式奶咖"

        case (.en, .liquidGlassClassic):
            "Liquid Glass Classic"
        case (.en, .pureLiquidGlass):
            "Pure Liquid Glass"
        case (.en, .pixelGame):
            "Pixel Game"
        case (.en, .pixelArcade):
            "Pixel Arcade"
        case (.en, .insCream):
            "INS Cream"
        case (.en, .handbookCollage):
            "Handbook Collage"
        case (.en, .diaryPaper):
            "Diary Paper"
        case (.en, .retroCopper):
            "Retro Copper"
        case (.en, .cyberNeon):
            "Cyber Neon"
        case (.en, .sakura):
            "Sakura Bloom"
        case (.en, .literaryFresh):
            "Literary Fresh"
        case (.en, .minimalBlackWhite):
            "Minimal Black & White"
        case (.en, .midnightBlue):
            "Midnight Blue"
        case (.en, .forestMatcha):
            "Forest Matcha"
        case (.en, .citrusSunset):
            "Citrus Sunset"
        case (.en, .seaSaltMint):
            "Sea Salt Mint"
        case (.en, .purpleMist):
            "Purple Mist"
        case (.en, .amberFilm):
            "Amber Film"
        case (.en, .nordicCoolGray):
            "Nordic Cool Gray"
        case (.en, .industrialUtility):
            "Industrial Utility"
        case (.en, .frenchCafe):
            "French Cafe"

        case (.ja, .liquidGlassClassic):
            "リキッドガラス クラシック"
        case (.ja, .pureLiquidGlass):
            "ピュアリキッドガラス"
        case (.ja, .pixelGame):
            "ピクセルゲーム"
        case (.ja, .pixelArcade):
            "ピクセルアーケード"
        case (.ja, .insCream):
            "INS クリーム"
        case (.ja, .handbookCollage):
            "手帳コラージュ"
        case (.ja, .diaryPaper):
            "日記ペーパー"
        case (.ja, .retroCopper):
            "レトロコッパー"
        case (.ja, .cyberNeon):
            "サイバーネオン"
        case (.ja, .sakura):
            "さくらブロッサム"
        case (.ja, .literaryFresh):
            "文芸フレッシュ"
        case (.ja, .minimalBlackWhite):
            "ミニマル白黒"
        case (.ja, .midnightBlue):
            "ミッドナイトブルー"
        case (.ja, .forestMatcha):
            "フォレスト抹茶"
        case (.ja, .citrusSunset):
            "シトラスサンセット"
        case (.ja, .seaSaltMint):
            "シーソルトミント"
        case (.ja, .purpleMist):
            "パープルミスト"
        case (.ja, .amberFilm):
            "アンバーフィルム"
        case (.ja, .nordicCoolGray):
            "北欧クールグレー"
        case (.ja, .industrialUtility):
            "インダストリアルユーティリティ"
        case (.ja, .frenchCafe):
            "フレンチカフェ"
        default:
            "Liquid Glass Classic"
        }
    }

    var hoverForDetails: String {
        self.text(zh: "将鼠标移动到柱子上查看详情", en: "Hover a bar for details", ja: "バーにカーソルを合わせると詳細を表示")
    }

    var sessionFallbackLabel: String {
        self.text(zh: "会话", en: "Session", ja: "セッション")
    }

    var weeklyFallbackLabel: String {
        self.text(zh: "每周", en: "Weekly", ja: "週間")
    }

    func languageOptionLabel(_ language: AppLanguage) -> String {
        switch language {
        case .system:
            self.text(zh: "跟随系统", en: "Follow System", ja: "システムに従う")
        case .zhHans:
            "中文"
        case .en:
            "English"
        case .ja:
            "日本語"
        }
    }

    func refreshFrequencyTitle(_ frequency: RefreshFrequency) -> String {
        switch (self.resolvedLanguage, frequency) {
        case (.zhHans, .fiveSeconds):
            "每 5 秒"
        case (.zhHans, .tenSeconds):
            "每 10 秒"
        case (.zhHans, .fifteenSeconds):
            "每 15 秒"
        case (.zhHans, .oneMinute):
            "每 1 分钟"
        case (.zhHans, .manual):
            "仅手动"
        case (.en, .fiveSeconds):
            "Every 5 seconds"
        case (.en, .tenSeconds):
            "Every 10 seconds"
        case (.en, .fifteenSeconds):
            "Every 15 seconds"
        case (.en, .oneMinute):
            "Every 1 minute"
        case (.en, .manual):
            "Manual only"
        case (.ja, .fiveSeconds):
            "5 秒ごと"
        case (.ja, .tenSeconds):
            "10 秒ごと"
        case (.ja, .fifteenSeconds):
            "15 秒ごと"
        case (.ja, .oneMinute):
            "1 分ごと"
        case (.ja, .manual):
            "手動のみ"
        default:
            "每 10 秒"
        }
    }

    func usageStatisticsRefreshFrequencyTitle(_ frequency: UsageStatisticsRefreshFrequency) -> String {
        switch (self.resolvedLanguage, frequency) {
        case (.zhHans, .fifteenMinutes):
            "每 15 分钟"
        case (.zhHans, .thirtyMinutes):
            "每 30 分钟"
        case (.zhHans, .sixtyMinutes):
            "每 60 分钟"
        case (.zhHans, .manual):
            "仅手动"
        case (.en, .fifteenMinutes):
            "Every 15 minutes"
        case (.en, .thirtyMinutes):
            "Every 30 minutes"
        case (.en, .sixtyMinutes):
            "Every 60 minutes"
        case (.en, .manual):
            "Manual only"
        case (.ja, .fifteenMinutes):
            "15 分ごと"
        case (.ja, .thirtyMinutes):
            "30 分ごと"
        case (.ja, .sixtyMinutes):
            "60 分ごと"
        case (.ja, .manual):
            "手動のみ"
        default:
            "每 30 分钟"
        }
    }

    func cookieSourceTitle(_ source: ProviderCookieSource) -> String {
        switch (self.resolvedLanguage, source) {
        case (.zhHans, .auto):
            "自动"
        case (.zhHans, .safari):
            "Safari"
        case (.zhHans, .manual):
            "手动"
        case (.zhHans, .off):
            "关闭"
        case (.en, .auto):
            "Auto"
        case (.en, .safari):
            "Safari"
        case (.en, .manual):
            "Manual"
        case (.en, .off):
            "Off"
        case (.ja, .auto):
            "自動"
        case (.ja, .safari):
            "Safari"
        case (.ja, .manual):
            "手動"
        case (.ja, .off):
            "オフ"
        default:
            "自动"
        }
    }

    func sevenDayTotalTitle() -> String {
        self.text(zh: "7 天", en: "7 days", ja: "7 日")
    }

    func thirtyDayTotalTitle() -> String {
        self.text(zh: "30 天", en: "30 days", ja: "30 日")
    }

    func allTimeTotalTitle() -> String {
        self.text(zh: "累计", en: "Local history", ja: "ローカル累計")
    }

    func compactCharacterText(_ value: Int) -> String {
        self.compactTokenText(value)
    }

    func menuBarTodaySummary(input: String, output: String) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            "输入 \(input) 输出 \(output)"
        case .en:
            "In \(input) Out \(output)"
        case .ja:
            "入力 \(input) 出力 \(output)"
        default:
            "输入 \(input) 输出 \(output)"
        }
    }

    func updatedDescription(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = self.locale
        formatter.unitsStyle = .short
        let relative = formatter.localizedString(for: date, relativeTo: Date())

        switch self.resolvedLanguage {
        case .zhHans:
            return "更新于\(relative)"
        case .en:
            return "Updated \(relative)"
        case .ja:
            return "更新 \(relative)"
        default:
            return "更新于\(relative)"
        }
    }

    func durationLabel(for windowMinutes: Int?, fallbackPrimary: Bool) -> String {
        guard let windowMinutes, windowMinutes > 0 else {
            return fallbackPrimary ? self.sessionFallbackLabel : self.weeklyFallbackLabel
        }

        if windowMinutes % (7 * 24 * 60) == 0 {
            let weeks = windowMinutes / (7 * 24 * 60)
            return self.localizedCount(weeks, zhUnit: "周", enUnit: "week", jaUnit: "週間")
        }
        if windowMinutes % (24 * 60) == 0 {
            let days = windowMinutes / (24 * 60)
            return self.localizedCount(days, zhUnit: "天", enUnit: "day", jaUnit: "日")
        }
        if windowMinutes % 60 == 0 {
            let hours = windowMinutes / 60
            return self.localizedCount(hours, zhUnit: "小时", enUnit: "hour", jaUnit: "時間")
        }
        return self.localizedCount(windowMinutes, zhUnit: "分钟", enUnit: "minute", jaUnit: "分")
    }

    func resetText(for window: RateWindow?, now: Date = .init()) -> String {
        guard let window else { return "--" }
        if let resetsAt = window.resetsAt {
            return self.formattedResetDate(
                resetsAt,
                windowMinutes: window.windowMinutes,
                includeTime: true,
                now: now)
        }
        guard let resetDescription = window.resetDescription,
              !resetDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return "--"
        }
        return self.compactResetValue(resetDescription, windowMinutes: window.windowMinutes, now: now)
    }

    func quotaDetailText(for window: RateWindow?, now: Date = .init()) -> String {
        let baseText = self.resetText(for: window, now: now)
        guard let window,
              let supplement = self.multiDayQuotaSupplement(for: window, now: now),
              baseText != "--"
        else {
            return baseText
        }

        switch self.resolvedLanguage {
        case .ja:
            return "\(baseText) ・ \(supplement)"
        default:
            return "\(baseText) · \(supplement)"
        }
    }

    func resetSubtitle(_ value: String) -> String {
        let displayValue = self.normalizedResetValue(value)
        switch self.resolvedLanguage {
        case .zhHans:
            return "重置时间 \(displayValue)"
        case .en:
            return "Reset \(displayValue)"
        case .ja:
            return "リセット \(displayValue)"
        default:
            return "重置时间 \(displayValue)"
        }
    }

    func codeReviewRemainingText(_ percent: Double) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            "\(Int(percent.rounded()))% 剩余"
        case .en:
            "\(Int(percent.rounded()))% remaining"
        case .ja:
            "\(Int(percent.rounded()))% 残り"
        default:
            "\(Int(percent.rounded()))% 剩余"
        }
    }

    func total30DaysCredits(_ value: Double) -> String {
        let formatted = value.formatted(.number.precision(.fractionLength(0...2)))
        switch self.resolvedLanguage {
        case .zhHans:
            return "近 30 天总计: \(formatted) credits"
        case .en:
            return "Total (30d): \(formatted) credits"
        case .ja:
            return "直近 30 日合計: \(formatted) credits"
        default:
            return "近 30 天总计: \(formatted) credits"
        }
    }

    func cookieImportStatusText(
        sourceLabel: String,
        cookieCount: Int,
        signedInEmail: String?,
        matchesCodex: Bool,
        allowAnyAccount: Bool) -> String
    {
        let emailPart = signedInEmail?.trimmingCharacters(in: .whitespacesAndNewlines)
        switch self.resolvedLanguage {
        case .zhHans:
            if let emailPart, !emailPart.isEmpty {
                if allowAnyAccount {
                    return "已使用 \(sourceLabel) Cookie（\(cookieCount) 个），当前登录为 \(emailPart)。"
                }
                let matchText = matchesCodex ? "一致" : "不一致"
                return "已使用 \(sourceLabel) Cookie（\(cookieCount) 个），当前登录为 \(emailPart)；与 Codex \(matchText)。"
            }
            return "已使用 \(sourceLabel) Cookie（\(cookieCount) 个）。"
        case .en:
            if let emailPart, !emailPart.isEmpty {
                if allowAnyAccount {
                    return "Using \(sourceLabel) cookies (\(cookieCount)). Signed in as \(emailPart)."
                }
                let matchText = matchesCodex ? "matches" : "does not match"
                return "Using \(sourceLabel) cookies (\(cookieCount)). Signed in as \(emailPart) (\(matchText) Codex)."
            }
            return "Using \(sourceLabel) cookies (\(cookieCount))."
        case .ja:
            if let emailPart, !emailPart.isEmpty {
                if allowAnyAccount {
                    return "\(sourceLabel) の Cookie（\(cookieCount) 件）を使用中。\(emailPart) でログインしています。"
                }
                let matchText = matchesCodex ? "一致" : "不一致"
                return "\(sourceLabel) の Cookie（\(cookieCount) 件）を使用中。\(emailPart) でログインしています。Codex とは \(matchText) です。"
            }
            return "\(sourceLabel) の Cookie（\(cookieCount) 件）を使用中。"
        default:
            return "已使用 \(sourceLabel) Cookie（\(cookieCount) 个）。"
        }
    }

    func noSignedInSessionFoundMessage(found: String) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            found.isEmpty
                ? "没有找到已登录的 OpenAI 网页会话。"
                : "没有找到匹配的 OpenAI 网页会话。已发现: \(found)"
        case .en:
            found.isEmpty
                ? "No signed-in OpenAI web session found."
                : "No matching OpenAI web session found. Found: \(found)"
        case .ja:
            found.isEmpty
                ? "ログイン済みの OpenAI Web セッションが見つかりません。"
                : "一致する OpenAI Web セッションが見つかりません。検出: \(found)"
        default:
            found.isEmpty
                ? "没有找到已登录的 OpenAI 网页会话。"
                : "没有找到匹配的 OpenAI 网页会话。已发现: \(found)"
        }
    }

    func accountMismatchMessage(expected: String?, found: String) -> String {
        let expectedText = expected?.isEmpty == false ? expected! : self.text(
            zh: "当前 Codex 账号",
            en: "the current Codex account",
            ja: "現在の Codex アカウント")
        switch self.resolvedLanguage {
        case .zhHans:
            return "浏览器登录账号与 Codex 不一致。期望 \(expectedText)，但发现 \(found)。"
        case .en:
            return "The browser session does not match Codex. Expected \(expectedText), but found \(found)."
        case .ja:
            return "ブラウザのログインアカウントが Codex と一致しません。期待値は \(expectedText)、検出は \(found) です。"
        default:
            return "浏览器登录账号与 Codex 不一致。期望 \(expectedText)，但发现 \(found)。"
        }
    }

    func cookieImportFailedMessage(_ detail: String) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            "Cookie 导入失败：\(detail)"
        case .en:
            "Cookie import failed: \(detail)"
        case .ja:
            "Cookie の取り込みに失敗しました: \(detail)"
        default:
            "Cookie 导入失败：\(detail)"
        }
    }

    func usingSavedSessionMessage(email: String?) -> String {
        guard let email, !email.isEmpty else {
            return self.text(
                zh: "正在使用已保存的 OpenAI 网页会话。",
                en: "Using the saved OpenAI web session.",
                ja: "保存済みの OpenAI Web セッションを使用中です。")
        }
        switch self.resolvedLanguage {
        case .zhHans:
            return "正在使用已保存的 OpenAI 网页会话：\(email)"
        case .en:
            return "Using the saved OpenAI web session: \(email)"
        case .ja:
            return "保存済みの OpenAI Web セッションを使用中です: \(email)"
        default:
            return "正在使用已保存的 OpenAI 网页会话：\(email)"
        }
    }

    var resolvedLanguage: AppLanguage {
        switch self.language {
        case .system:
            .zhHans
        case let other:
            other
        }
    }

    private func localizedCount(_ value: Int, zhUnit: String, enUnit: String, jaUnit: String) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            "\(value) \(zhUnit)"
        case .en:
            "\(value) \(value == 1 ? enUnit : "\(enUnit)s")"
        case .ja:
            "\(value)\(jaUnit)"
        default:
            "\(value) \(zhUnit)"
        }
    }

    private func localizedCompactNumber(_ value: Int, divisor: Double, unit: String, spacedUnit: Bool) -> String {
        let formatter = NumberFormatter()
        formatter.locale = self.locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0

        let scaled = Double(value) / divisor
        let number = formatter.string(from: NSNumber(value: scaled)) ?? "\(scaled)"
        let separator = spacedUnit ? " " : ""
        return "\(number)\(separator)\(unit)"
    }

    private func compactTokenParts(from text: String) -> CompactTokenTextParts {
        let characters = Array(text)
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
        var amountCharacters: [Character] = []
        var unitCharacters: [Character] = []
        var isReadingAmount = true

        for character in characters {
            let scalar = String(character).unicodeScalars.first
            let isAmountCharacter = scalar.map { allowedCharacters.contains($0) } ?? false

            if isReadingAmount, isAmountCharacter {
                amountCharacters.append(character)
            } else {
                isReadingAmount = false
                unitCharacters.append(character)
            }
        }

        let amountText = String(amountCharacters).trimmingCharacters(in: .whitespacesAndNewlines)
        let unitText = String(unitCharacters).trimmingCharacters(in: .whitespacesAndNewlines)

        if amountText.isEmpty {
            return CompactTokenTextParts(amountText: text, unitText: nil)
        }

        return CompactTokenTextParts(
            amountText: amountText,
            unitText: unitText.isEmpty ? nil : unitText)
    }

    func text(zh: String, en: String, ja: String) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            zh
        case .en:
            en
        case .ja:
            ja
        default:
            zh
        }
    }
}

extension AppStrings {
    private func formattedResetDate(_ date: Date, windowMinutes: Int?, includeTime: Bool, now: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = self.locale
        formatter.timeZone = TimeZone.current

        if Calendar.current.isDate(date, inSameDayAs: now) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }

        if self.usesCompactResetDateTime(windowMinutes: windowMinutes, includeTime: includeTime) {
            switch self.resolvedLanguage {
            case .zhHans:
                formatter.dateFormat = "M.d HH:mm"
            case .en:
                formatter.dateFormat = "M/d HH:mm"
            case .ja:
                formatter.dateFormat = "M/d HH:mm"
            default:
                formatter.dateFormat = "M.d HH:mm"
            }
            return formatter.string(from: date)
        }

        formatter.timeStyle = .none
        switch self.resolvedLanguage {
        case .zhHans:
            formatter.dateFormat = "M月d日"
        case .en:
            formatter.dateFormat = "MMM d"
        case .ja:
            formatter.dateFormat = "M月d日"
        default:
            formatter.dateFormat = "M月d日"
        }
        return formatter.string(from: date)
    }

    private func compactResetValue(_ value: String, windowMinutes: Int?, now: Date) -> String {
        let normalized = self.normalizedResetValue(value)
        guard normalized != "--" else { return normalized }
        if let parsedDate = self.parsedResetDate(from: normalized, now: now) {
            return self.formattedResetDate(
                parsedDate,
                windowMinutes: windowMinutes,
                includeTime: self.resetValueContainsExplicitTime(normalized),
                now: now)
        }
        return normalized
    }

    private func multiDayQuotaSupplement(for window: RateWindow, now: Date) -> String? {
        guard let windowMinutes = window.windowMinutes, windowMinutes >= 48 * 60 else { return nil }
        guard let resetDate = self.resolvedResetDate(for: window, now: now) else { return nil }

        let timeUntilReset = resetDate.timeIntervalSince(now)
        guard timeUntilReset > 0 else { return nil }

        let remainingDays = max(1, Int(ceil(timeUntilReset / (24 * 60 * 60))))
        let dailyBudgetText = self.dailyQuotaBudgetText(window.remainingPercent / Double(remainingDays))

        switch self.resolvedLanguage {
        case .zhHans:
            return "剩 \(remainingDays) 天 · 日均 \(dailyBudgetText)"
        case .en:
            return "\(remainingDays)d left · \(dailyBudgetText)/day"
        case .ja:
            return "残り\(remainingDays)日 ・ 1日\(dailyBudgetText)"
        default:
            return "剩 \(remainingDays) 天 · 日均 \(dailyBudgetText)"
        }
    }

    private func resolvedResetDate(for window: RateWindow, now: Date) -> Date? {
        if let resetsAt = window.resetsAt {
            return resetsAt
        }
        guard let resetDescription = window.resetDescription,
              !resetDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }
        let normalized = self.normalizedResetValue(resetDescription)
        guard normalized != "--" else { return nil }
        return self.parsedResetDate(from: normalized, now: now)
    }

    private func dailyQuotaBudgetText(_ value: Double) -> String {
        let clampedValue = max(0, value)
        if clampedValue > 0, clampedValue < 1 {
            return "<1%"
        }
        return "\(Int(floor(clampedValue)))%"
    }

    private func usesCompactResetDateTime(windowMinutes: Int?, includeTime: Bool) -> Bool {
        guard includeTime else { return false }
        guard let windowMinutes else { return false }
        return windowMinutes >= 7 * 24 * 60
    }

    private func normalizedResetValue(_ value: String) -> String {
        var text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "--" }

        text = text.replacingOccurrences(
            of: #"^(?:(?:重置时间|重置|リセット)\s*[：:]?\s*|(?:reset(?:\s*time)?|resets?(?:\s*(?:at|on))?)\s*[：:]?\s*)"#,
            with: "",
            options: [.regularExpression, .caseInsensitive])
        text = text.trimmingCharacters(
            in: CharacterSet(charactersIn: "：:,， ").union(.whitespacesAndNewlines))

        return text.isEmpty ? "--" : text
    }

    private func resetValueContainsExplicitTime(_ value: String) -> Bool {
        value.range(of: #"\b\d{1,2}:\d{2}\b"#, options: .regularExpression) != nil
    }

    private func parsedResetDate(from value: String, now: Date) -> Date? {
        var candidate = value
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "：", with: ":")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else { return nil }

        let lowercased = candidate.lowercased()
        if lowercased.hasPrefix("today") || lowercased.hasPrefix("tomorrow") {
            let dayOffset = lowercased.hasPrefix("tomorrow") ? 1 : 0
            let stripped = candidate.replacingOccurrences(
                of: #"(?i)^(today|tomorrow)[, ]*"#,
                with: "",
                options: [.regularExpression])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let timeOnlyDate = self.parsedDate(
                from: stripped,
                locale: Locale(identifier: "en_US_POSIX"),
                formats: Self.timeOnlyResetFormats,
                defaultDate: now)
            {
                let calendar = Calendar.current
                let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
                var components = calendar.dateComponents([.year, .month, .day], from: targetDay)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOnlyDate)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                return calendar.date(from: components)
            }
        }

        if candidate.contains("T") {
            let isoFormatter = ISO8601DateFormatter()
            if let isoDate = isoFormatter.date(from: candidate) {
                return isoDate
            }
        }

        candidate = candidate
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let locales = [
            Locale(identifier: "en_US_POSIX"),
            self.locale,
            Locale(identifier: "zh_Hans"),
            Locale(identifier: "ja_JP"),
        ]
        for locale in locales {
            if let parsedDate = self.parsedDate(
                from: candidate,
                locale: locale,
                formats: Self.absoluteResetFormats + Self.cjkResetFormats + Self.timeOnlyResetFormats,
                defaultDate: now)
            {
                return parsedDate
            }
        }

        return nil
    }

    private func parsedDate(from value: String, locale: Locale, formats: [String], defaultDate: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone.current
        formatter.defaultDate = defaultDate

        for format in formats {
            formatter.dateFormat = format
            if let parsedDate = formatter.date(from: value) {
                return parsedDate
            }
        }

        return nil
    }

    private static let absoluteResetFormats: [String] = [
        "MMM d yyyy HH:mm",
        "MMM d yyyy H:mm",
        "MMM d yyyy h:mm a",
        "MMM d yyyy h:mma",
        "MMM d HH:mm",
        "MMM d H:mm",
        "MMM d h:mm a",
        "MMM d h:mma",
        "MMMM d yyyy HH:mm",
        "MMMM d yyyy h:mm a",
        "MMMM d HH:mm",
        "MMMM d h:mm a",
        "MMM d yyyy",
        "MMMM d yyyy",
        "MMM d",
        "MMMM d",
        "M/d/yyyy HH:mm",
        "M/d/yyyy H:mm",
        "M/d/yyyy h:mm a",
        "M/d/yyyy h:mma",
        "M/d HH:mm",
        "M/d H:mm",
        "M/d h:mm a",
        "M/d h:mma",
        "M/d/yyyy",
        "M/d/yy",
        "M/d",
        "yyyy-MM-dd HH:mm",
        "yyyy-MM-dd H:mm",
        "yyyy-MM-dd h:mm a",
        "yyyy-MM-dd",
        "yyyy/MM/dd HH:mm",
        "yyyy/MM/dd H:mm",
        "yyyy/MM/dd h:mm a",
        "yyyy/MM/dd",
    ]

    private static let cjkResetFormats: [String] = [
        "yyyy年M月d日 HH:mm",
        "yyyy年M月d日 H:mm",
        "yyyy年M月d日 h:mm a",
        "M月d日 HH:mm",
        "M月d日 H:mm",
        "M月d日 h:mm a",
        "yyyy年M月d日",
        "M月d日",
    ]

    private static let timeOnlyResetFormats: [String] = [
        "HH:mm",
        "H:mm",
        "h:mm a",
        "h:mma",
    ]
}
