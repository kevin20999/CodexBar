import CodexBarCore
import Foundation
import XCTest
@testable import CodexBar

final class LocalizationTests: XCTestCase {
    func test_resolvePreferredLanguageFallsBackToChinese() {
        XCTAssertEqual(AppLanguage.resolvePreferredLanguage(["fr-FR"]), .zhHans)
        XCTAssertEqual(AppLanguage.resolvePreferredLanguage(["zh-CN"]), .zhHans)
        XCTAssertEqual(AppLanguage.resolvePreferredLanguage(["en-US"]), .en)
        XCTAssertEqual(AppLanguage.resolvePreferredLanguage(["ja-JP"]), .ja)
    }

    func test_durationLabelsUseLocalizedUnits() {
        XCTAssertEqual(AppStrings(language: .zhHans).durationLabel(for: 5 * 60, fallbackPrimary: true), "5 小时")
        XCTAssertEqual(AppStrings(language: .en).durationLabel(for: 2 * 7 * 24 * 60, fallbackPrimary: false), "2 weeks")
        XCTAssertEqual(AppStrings(language: .ja).durationLabel(for: 15, fallbackPrimary: true), "15分")
    }

    func test_lastThirtyDaysTitleIsLocalized() {
        XCTAssertEqual(AppStrings(language: .zhHans).lastThirtyDaysTitle, "30 天（主线程）")
        XCTAssertEqual(AppStrings(language: .en).lastThirtyDaysTitle, "Last 30 Days")
        XCTAssertEqual(AppStrings(language: .ja).lastThirtyDaysTitle, "直近 30 日")
    }

    func test_recentTwentyFourHoursStringsAreLocalized() {
        XCTAssertEqual(AppStrings(language: .zhHans).recentTwentyFourHoursTitle, "最近 24 小时")
        XCTAssertEqual(AppStrings(language: .en).recentTwentyFourHoursTitle, "Last 24 Hours")
        XCTAssertEqual(AppStrings(language: .ja).recentTwentyFourHoursTitle, "直近 24 時間")
        XCTAssertEqual(AppStrings(language: .zhHans).noRecentTwentyFourHourData, "最近 24 小时暂无用量数据。")
        XCTAssertEqual(AppStrings(language: .en).noRecentTwentyFourHourData, "No usage data in the last 24 hours.")
        XCTAssertEqual(AppStrings(language: .ja).noRecentTwentyFourHourData, "直近 24 時間の利用データはありません。")
    }

    func test_recentFortyEightHoursStringsAreLocalized() {
        XCTAssertEqual(AppStrings(language: .zhHans).recentFortyEightHoursTitle, "48 小时（主线程）")
        XCTAssertEqual(AppStrings(language: .en).recentFortyEightHoursTitle, "Last 48 Hours")
        XCTAssertEqual(AppStrings(language: .ja).recentFortyEightHoursTitle, "直近 48 時間")
        XCTAssertEqual(AppStrings(language: .zhHans).noRecentFortyEightHourData, "最近 48 小时暂无用量数据。")
        XCTAssertEqual(AppStrings(language: .en).noRecentFortyEightHourData, "No usage data in the last 48 hours.")
        XCTAssertEqual(AppStrings(language: .ja).noRecentFortyEightHourData, "直近 48 時間の利用データはありません。")
    }

    func test_messageActivityStringsAreLocalized() {
        let zh = AppStrings(language: .zhHans)
        XCTAssertEqual(zh.messageActivityTitle, "人类发送指令统计")
        XCTAssertEqual(zh.messageActivityTodayTitle, "今天")
        XCTAssertEqual(zh.messageActivitySevenDayTitle, "7 天")
        XCTAssertEqual(zh.messageActivityThirtyDayTitle, "30 天")
        XCTAssertEqual(zh.messageActivityCumulativeTitle, "累计")
        XCTAssertEqual(zh.noMessageActivityData, "还没有检测到人类指令记录。")

        let en = AppStrings(language: .en)
        XCTAssertEqual(en.messageActivityTitle, "Human Instruction Activity")
        XCTAssertEqual(en.noMessageActivityData, "No human instruction activity yet.")

        let ja = AppStrings(language: .ja)
        XCTAssertEqual(ja.messageActivityTitle, "人間の指示統計")
    }

    func test_usageOverviewDualMetricLabelsAreLocalized() {
        let zh = AppStrings(language: .zhHans)
        XCTAssertEqual(zh.totalConsumptionLabel, "总量")
        XCTAssertEqual(zh.mainThreadLabel, "主线程")
        XCTAssertEqual(zh.allTimeTotalTitle(), "累计")
        XCTAssertEqual(zh.totalTokenText(160_000_000), "总量 1.6 亿")
        XCTAssertEqual(zh.mainThreadTokenText(160_000_000), "主线程 1.6 亿")
        XCTAssertEqual(zh.compactTokenParts(160_000_000), CompactTokenTextParts(amountText: "1.6", unitText: "亿"))
        XCTAssertEqual(
            zh.usageOverviewNumericAccessibilityText(title: "今日", totalValue: 160_000_000, mainThreadValue: 40_000_000),
            "今日，总量 1.6 亿，主线程 4,000 万")

        let en = AppStrings(language: .en)
        XCTAssertEqual(en.totalConsumptionLabel, "Total")
        XCTAssertEqual(en.mainThreadLabel, "Main thread")
        XCTAssertEqual(en.allTimeTotalTitle(), "Local history")
        XCTAssertEqual(en.totalTokenText(160_000_000), "Total 160M")
        XCTAssertEqual(en.mainThreadTokenText(160_000_000), "Main thread 160M")
        XCTAssertEqual(en.compactTokenParts(160_000_000), CompactTokenTextParts(amountText: "160", unitText: "M"))

        let ja = AppStrings(language: .ja)
        XCTAssertEqual(ja.totalConsumptionLabel, "総消費")
        XCTAssertEqual(ja.mainThreadLabel, "メインスレッド")
        XCTAssertEqual(ja.allTimeTotalTitle(), "ローカル累計")
        XCTAssertEqual(ja.totalTokenText(160_000_000), "総消費 1.6 億")
        XCTAssertEqual(ja.mainThreadTokenText(160_000_000), "メインスレッド 1.6 億")
        XCTAssertEqual(ja.compactTokenParts(160_000_000), CompactTokenTextParts(amountText: "1.6", unitText: "億"))
    }

    func test_instructionCountTitleIsLocalized() {
        XCTAssertEqual(AppStrings(language: .zhHans).instructionCountTitle, "指令次数")
        XCTAssertEqual(AppStrings(language: .en).instructionCountTitle, "Instructions")
        XCTAssertEqual(AppStrings(language: .ja).instructionCountTitle, "指示回数")
    }

    func test_lastThirtyDaysInstructionTrendTitleIsLocalized() {
        XCTAssertEqual(AppStrings(language: .zhHans).lastThirtyDaysInstructionTrendTitle, "最近 30 天指令趋势")
        XCTAssertEqual(AppStrings(language: .en).lastThirtyDaysInstructionTrendTitle, "Last 30 Days Instructions")
        XCTAssertEqual(AppStrings(language: .ja).lastThirtyDaysInstructionTrendTitle, "直近 30 日の指示回数")
    }

    func test_menuBarTokenSpeedMeterStringsAreLocalized() {
        XCTAssertEqual(AppStrings(language: .zhHans).menuBarTokenSpeedMeterLabel, "显示独立 token/s 速度计")
        XCTAssertEqual(
            AppStrings(language: .en).menuBarTokenSpeedMeterLabel,
            "Show separate token/s meter")
        XCTAssertEqual(
            AppStrings(language: .ja).menuBarTokenSpeedMeterLabel,
            "独立した token/s メーターを表示")
        XCTAssertEqual(
            AppStrings(language: .zhHans).menuBarTokenSpeedMeterRequiresMacOS26,
            "此样式需要 macOS 26 或更高版本；旧系统不会显示这个独立速度项。")

        XCTAssertEqual(
            AppStrings(language: .zhHans).menuBarTokenSpeedTooltip(tokensPerSecond: 48),
            "当前 Codex 吞吐：48 token/s")
        XCTAssertEqual(
            AppStrings(language: .en).menuBarTokenSpeedTooltip(tokensPerSecond: 48),
            "Current Codex throughput: 48 token/s")
        XCTAssertEqual(
            AppStrings(language: .ja).menuBarTokenSpeedTooltip(tokensPerSecond: 48),
            "現在の Codex スループット: 48 token/s")
        XCTAssertEqual(
            AppStrings(language: .zhHans).tokenSpeedCurveTitle,
            "最近 600 秒吞吐曲线")
        XCTAssertEqual(
            AppStrings(language: .en).tokenSpeedHistoryTitle,
            "Throughput History")
        XCTAssertEqual(
            AppStrings(language: .ja).noTokenSpeedHistoryData,
            "非ゼロのスループット記録はまだありません。")
        XCTAssertEqual(
            AppStrings(language: .zhHans).tokenSpeedHistoryValueText(44445),
            "44,445 tokens")
        XCTAssertEqual(
            AppStrings(language: .zhHans).tokenSpeedFloatingChartButtonText(isPresented: false),
            "弹出桌面浮窗")
        XCTAssertEqual(
            AppStrings(language: .en).tokenSpeedFloatingChartButtonText(isPresented: true),
            "Close floating chart")
        XCTAssertEqual(
            AppStrings(language: .en).tokenSpeedFloatingTodayTokensLabel,
            "token")
        XCTAssertEqual(
            AppStrings(language: .zhHans).tokenSpeedFloatingTodayInstructionsLabel,
            "指令")
    }

    func test_messageActivityPeakBubbleTextIsLocalized() {
        XCTAssertEqual(AppStrings(language: .zhHans).messageActivityPeakBubbleText(12), "12 次")
        XCTAssertEqual(AppStrings(language: .en).messageActivityPeakBubbleText(12), "12 instr")
        XCTAssertEqual(AppStrings(language: .ja).messageActivityPeakBubbleText(12), "12回")
    }

    func test_recentFortyEightHourChartStyleStringsAreLocalized() {
        let zh = AppStrings(language: .zhHans)
        XCTAssertEqual(zh.recentFortyEightHourChartStyleLabel, "48 小时图表样式")
        XCTAssertEqual(zh.recentFortyEightHourChartStyleTitle(.bars), "小时柱图")
        XCTAssertEqual(zh.recentFortyEightHourChartStyleTitle(.wave), "波浪曲线")
        XCTAssertEqual(
            zh.recentFortyEightHourChartStyleDescription(.bars),
            "与最近 30 天一致的蓝色柱状图，每小时一根柱子。")

        let en = AppStrings(language: .en)
        XCTAssertEqual(en.recentFortyEightHourChartStyleLabel, "48-hour chart style")
        XCTAssertEqual(en.recentFortyEightHourChartStyleTitle(.bars), "Hourly Bars")
        XCTAssertEqual(en.recentFortyEightHourChartStyleTitle(.wave), "Wave Chart")
        XCTAssertEqual(
            en.recentFortyEightHourChartStyleDescription(.wave),
            "Keep the current filled wave line for a more continuous trend view.")

        let ja = AppStrings(language: .ja)
        XCTAssertEqual(ja.recentFortyEightHourChartStyleLabel, "48時間チャートスタイル")
        XCTAssertEqual(ja.recentFortyEightHourChartStyleTitle(.bars), "時間バー")
        XCTAssertEqual(ja.recentFortyEightHourChartStyleTitle(.wave), "波形チャート")
    }

    func test_menuPopupStyleStringsAreLocalized() {
        let zh = AppStrings(language: .zhHans)
        XCTAssertEqual(zh.menuPopupStyleLabel, "弹窗风格")
        XCTAssertEqual(zh.menuPopupStyleTitle(.liquidGlass), "液态玻璃")
        XCTAssertEqual(zh.menuPopupStyleTitle(.systemPopover), "系统 popover")

        let en = AppStrings(language: .en)
        XCTAssertEqual(en.menuPopupStyleLabel, "Popup style")
        XCTAssertEqual(en.menuPopupStyleTitle(.liquidGlass), "Liquid Glass")
        XCTAssertEqual(en.menuPopupStyleTitle(.systemPopover), "System Popover")

        let ja = AppStrings(language: .ja)
        XCTAssertEqual(ja.menuPopupStyleLabel, "ポップアップスタイル")
        XCTAssertEqual(ja.menuPopupStyleTitle(.liquidGlass), "リキッドガラス")
        XCTAssertEqual(ja.menuPopupStyleTitle(.systemPopover), "システムポップオーバー")
    }

    func test_menuVisualThemeStringsAreLocalized() {
        let zh = AppStrings(language: .zhHans)
        XCTAssertEqual(zh.settingsThemeCategoryTitle, "主题")
        XCTAssertEqual(zh.settingsThemeCategoryDescription, "集中管理菜单面板主题与弹窗容器风格。")
        XCTAssertEqual(zh.previewAppearanceLabel, "视觉风格")
        XCTAssertEqual(zh.previewContainerStyleLabel, "弹窗容器")
        XCTAssertEqual(zh.menuVisualThemeLabel, "主题风格")
        XCTAssertEqual(zh.menuVisualThemeTitle(.liquidGlassClassic), "液态玻璃经典")
        XCTAssertEqual(zh.menuVisualThemeTitle(.pureLiquidGlass), "纯粹液态玻璃")
        XCTAssertEqual(zh.menuVisualThemeTitle(.pixelGame), "像素游戏")
        XCTAssertEqual(zh.menuVisualThemeTitle(.pixelArcade), "像素街机")
        XCTAssertEqual(zh.menuVisualThemeTitle(.insCream), "INS 奶油")
        XCTAssertEqual(zh.menuVisualThemeTitle(.handbookCollage), "手帐拼贴")
        XCTAssertEqual(zh.menuVisualThemeTitle(.diaryPaper), "日记纸感")
        XCTAssertEqual(zh.menuVisualThemeTitle(.retroCopper), "复古铜棕")
        XCTAssertEqual(zh.menuVisualThemeTitle(.cyberNeon), "赛博霓虹")
        XCTAssertEqual(zh.menuVisualThemeTitle(.sakura), "少女樱花")
        XCTAssertEqual(zh.menuVisualThemeTitle(.literaryFresh), "文艺清新")
        XCTAssertEqual(zh.menuVisualThemeTitle(.minimalBlackWhite), "极简黑白")
        XCTAssertEqual(zh.menuVisualThemeTitle(.midnightBlue), "深夜蓝调")
        XCTAssertEqual(zh.menuVisualThemeTitle(.forestMatcha), "森林抹茶")
        XCTAssertEqual(zh.menuVisualThemeTitle(.citrusSunset), "柑橘日落")
        XCTAssertEqual(zh.menuVisualThemeTitle(.seaSaltMint), "海盐薄荷")
        XCTAssertEqual(zh.menuVisualThemeTitle(.purpleMist), "紫雾梦境")
        XCTAssertEqual(zh.menuVisualThemeTitle(.amberFilm), "琥珀胶片")
        XCTAssertEqual(zh.menuVisualThemeTitle(.nordicCoolGray), "北欧冷灰")
        XCTAssertEqual(zh.menuVisualThemeTitle(.industrialUtility), "机能工业")
        XCTAssertEqual(zh.menuVisualThemeTitle(.frenchCafe), "法式奶咖")
        XCTAssertEqual(zh.menuVisualThemeDescription, "为菜单面板选择显示主题。你可以在不改变交互方式的情况下，切换颜色、底纹与高亮风格。")

        let en = AppStrings(language: .en)
        XCTAssertEqual(en.settingsThemeCategoryTitle, "Themes")
        XCTAssertEqual(en.settingsThemeCategoryDescription, "Manage menu panel themes and popup container style in one place.")
        XCTAssertEqual(en.previewAppearanceLabel, "Visual style")
        XCTAssertEqual(en.previewContainerStyleLabel, "Popup container")
        XCTAssertEqual(en.menuVisualThemeLabel, "Theme style")
        XCTAssertEqual(en.menuVisualThemeTitle(.liquidGlassClassic), "Liquid Glass Classic")
        XCTAssertEqual(en.menuVisualThemeTitle(.pureLiquidGlass), "Pure Liquid Glass")
        XCTAssertEqual(en.menuVisualThemeTitle(.pixelGame), "Pixel Game")
        XCTAssertEqual(en.menuVisualThemeTitle(.pixelArcade), "Pixel Arcade")
        XCTAssertEqual(en.menuVisualThemeTitle(.insCream), "INS Cream")
        XCTAssertEqual(en.menuVisualThemeTitle(.handbookCollage), "Handbook Collage")
        XCTAssertEqual(en.menuVisualThemeTitle(.diaryPaper), "Diary Paper")
        XCTAssertEqual(en.menuVisualThemeTitle(.retroCopper), "Retro Copper")
        XCTAssertEqual(en.menuVisualThemeTitle(.cyberNeon), "Cyber Neon")
        XCTAssertEqual(en.menuVisualThemeTitle(.sakura), "Sakura Bloom")
        XCTAssertEqual(en.menuVisualThemeTitle(.literaryFresh), "Literary Fresh")
        XCTAssertEqual(en.menuVisualThemeTitle(.minimalBlackWhite), "Minimal Black & White")
        XCTAssertEqual(en.menuVisualThemeTitle(.midnightBlue), "Midnight Blue")
        XCTAssertEqual(en.menuVisualThemeTitle(.forestMatcha), "Forest Matcha")
        XCTAssertEqual(en.menuVisualThemeTitle(.citrusSunset), "Citrus Sunset")
        XCTAssertEqual(en.menuVisualThemeTitle(.seaSaltMint), "Sea Salt Mint")
        XCTAssertEqual(en.menuVisualThemeTitle(.purpleMist), "Purple Mist")
        XCTAssertEqual(en.menuVisualThemeTitle(.amberFilm), "Amber Film")
        XCTAssertEqual(en.menuVisualThemeTitle(.nordicCoolGray), "Nordic Cool Gray")
        XCTAssertEqual(en.menuVisualThemeTitle(.industrialUtility), "Industrial Utility")
        XCTAssertEqual(en.menuVisualThemeTitle(.frenchCafe), "French Cafe")
        XCTAssertEqual(
            en.menuVisualThemeDescription,
            "Choose a visual theme for the menu panel. Colors, textures, and accent look change without affecting behavior.")

        let ja = AppStrings(language: .ja)
        XCTAssertEqual(ja.settingsThemeCategoryTitle, "テーマ")
        XCTAssertEqual(ja.settingsThemeCategoryDescription, "メニューパネルのテーマとポップアップコンテナのスタイルをまとめて管理します。")
        XCTAssertEqual(ja.previewAppearanceLabel, "ビジュアルスタイル")
        XCTAssertEqual(ja.previewContainerStyleLabel, "ポップアップコンテナ")
        XCTAssertEqual(ja.menuVisualThemeLabel, "テーマスタイル")
        XCTAssertEqual(ja.menuVisualThemeTitle(.liquidGlassClassic), "リキッドガラス クラシック")
        XCTAssertEqual(ja.menuVisualThemeTitle(.pureLiquidGlass), "ピュアリキッドガラス")
        XCTAssertEqual(ja.menuVisualThemeTitle(.pixelGame), "ピクセルゲーム")
        XCTAssertEqual(ja.menuVisualThemeTitle(.pixelArcade), "ピクセルアーケード")
        XCTAssertEqual(ja.menuVisualThemeTitle(.insCream), "INS クリーム")
        XCTAssertEqual(ja.menuVisualThemeTitle(.handbookCollage), "手帳コラージュ")
        XCTAssertEqual(ja.menuVisualThemeTitle(.diaryPaper), "日記ペーパー")
        XCTAssertEqual(ja.menuVisualThemeTitle(.retroCopper), "レトロコッパー")
        XCTAssertEqual(ja.menuVisualThemeTitle(.cyberNeon), "サイバーネオン")
        XCTAssertEqual(ja.menuVisualThemeTitle(.sakura), "さくらブロッサム")
        XCTAssertEqual(ja.menuVisualThemeTitle(.literaryFresh), "文芸フレッシュ")
        XCTAssertEqual(ja.menuVisualThemeTitle(.minimalBlackWhite), "ミニマル白黒")
        XCTAssertEqual(ja.menuVisualThemeTitle(.midnightBlue), "ミッドナイトブルー")
        XCTAssertEqual(ja.menuVisualThemeTitle(.forestMatcha), "フォレスト抹茶")
        XCTAssertEqual(ja.menuVisualThemeTitle(.citrusSunset), "シトラスサンセット")
        XCTAssertEqual(ja.menuVisualThemeTitle(.seaSaltMint), "シーソルトミント")
        XCTAssertEqual(ja.menuVisualThemeTitle(.purpleMist), "パープルミスト")
        XCTAssertEqual(ja.menuVisualThemeTitle(.amberFilm), "アンバーフィルム")
        XCTAssertEqual(ja.menuVisualThemeTitle(.nordicCoolGray), "北欧クールグレー")
        XCTAssertEqual(ja.menuVisualThemeTitle(.industrialUtility), "インダストリアルユーティリティ")
        XCTAssertEqual(ja.menuVisualThemeTitle(.frenchCafe), "フレンチカフェ")
        XCTAssertEqual(
            ja.menuVisualThemeDescription,
            "メニューパネルの外観テーマを選択します。操作挙動は変わらず、配色や質感、アクセントの見た目だけを切り替えます。")
    }

    func test_resetSubtitleIsLocalized() {
        XCTAssertEqual(AppStrings(language: .zhHans).resetSubtitle("19:21"), "重置时间 19:21")
        XCTAssertEqual(AppStrings(language: .zhHans).resetSubtitle("重置时间：19:21"), "重置时间 19:21")
        XCTAssertEqual(AppStrings(language: .en).resetSubtitle("7:21 PM"), "Reset 7:21 PM")
        XCTAssertEqual(AppStrings(language: .en).resetSubtitle("Reset time: 7:21 PM"), "Reset 7:21 PM")
        XCTAssertEqual(AppStrings(language: .ja).resetSubtitle("19:21"), "リセット 19:21")
    }

    func test_resetTextKeepsTimeForSameDayReset() throws {
        let strings = AppStrings(language: .zhHans)
        let date = try self.sameDayDate(hour: 13, minute: 37)

        XCTAssertEqual(
            strings.resetText(for: RateWindow(
                usedPercent: 22,
                windowMinutes: 5 * 60,
                resetsAt: date,
                resetDescription: nil)),
            "13:37")
    }

    func test_resetTextUsesCompactDateTimeForWeeklyReset() throws {
        let strings = AppStrings(language: .zhHans)
        let date = try self.fixedDate(year: 2026, month: 3, day: 26, hour: 11, minute: 11)

        XCTAssertEqual(
            strings.resetText(for: RateWindow(
                usedPercent: 12,
                windowMinutes: 7 * 24 * 60,
                resetsAt: date,
                resetDescription: nil)),
            "3.26 11:11")
    }

    func test_quotaDetailTextAddsCompactGuidanceForFutureMultiDayWindows() throws {
        let now = try self.fixedDate(year: 2026, month: 3, day: 22, hour: 12, minute: 0)
        let resetDate = try self.fixedDate(year: 2026, month: 3, day: 26, hour: 6, minute: 12)
        let window = RateWindow(
            usedPercent: 55,
            windowMinutes: 7 * 24 * 60,
            resetsAt: resetDate,
            resetDescription: nil)

        XCTAssertEqual(
            AppStrings(language: .zhHans).quotaDetailText(for: window, now: now),
            "3.26 06:12 · 剩 4 天 · 日均 11%")
        XCTAssertEqual(
            AppStrings(language: .en).quotaDetailText(for: window, now: now),
            "3/26 06:12 · 4d left · 11%/day")
        XCTAssertEqual(
            AppStrings(language: .ja).quotaDetailText(for: window, now: now),
            "3/26 06:12 ・ 残り4日 ・ 1日11%")
    }

    func test_quotaDetailTextUsesResetDescriptionFallbackWhenDateIsParseable() throws {
        let now = try self.fixedDate(year: 2026, month: 3, day: 22, hour: 12, minute: 0)
        let window = RateWindow(
            usedPercent: 55,
            windowMinutes: 7 * 24 * 60,
            resetsAt: nil,
            resetDescription: "Reset time: Mar 26, 2026 06:12")

        XCTAssertEqual(
            AppStrings(language: .zhHans).quotaDetailText(for: window, now: now),
            "3.26 06:12 · 剩 4 天 · 日均 11%")
    }

    func test_quotaDetailTextLeavesShortWindowsUnchanged() {
        let window = RateWindow(
            usedPercent: 44,
            windowMinutes: 5 * 60,
            resetsAt: nil,
            resetDescription: "00:04")

        XCTAssertEqual(AppStrings(language: .zhHans).quotaDetailText(for: window), "00:04")
    }

    func test_quotaDetailTextUsesLessThanOnePercentForTinyDailyBudget() throws {
        let now = try self.fixedDate(year: 2026, month: 3, day: 22, hour: 12, minute: 0)
        let resetDate = try self.fixedDate(year: 2026, month: 3, day: 25, hour: 12, minute: 0)
        let window = RateWindow(
            usedPercent: 99,
            windowMinutes: 7 * 24 * 60,
            resetsAt: resetDate,
            resetDescription: nil)

        XCTAssertEqual(
            AppStrings(language: .zhHans).quotaDetailText(for: window, now: now),
            "3.25 12:00 · 剩 3 天 · 日均 <1%")
    }

    func test_resetTextCompactsPrefixedDatesAcrossLanguages() {
        XCTAssertEqual(
            AppStrings(language: .zhHans).resetText(for: RateWindow(
                usedPercent: 12,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: "Reset time: Mar 18, 2026")),
            "3月18日")
        XCTAssertEqual(
            AppStrings(language: .en).resetText(for: RateWindow(
                usedPercent: 12,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: "重置时间：2026年3月18日")),
            "Mar 18")
        XCTAssertEqual(
            AppStrings(language: .ja).resetText(for: RateWindow(
                usedPercent: 12,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: "リセット 2026年3月18日")),
            "3月18日")
        XCTAssertEqual(
            AppStrings(language: .zhHans).resetText(for: RateWindow(
                usedPercent: 12,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: "Reset time: Mar 26, 2026 11:11")),
            "3.26 11:11")
    }

    func test_exactTokenTextUsesProvidedLocale() {
        XCTAssertEqual(UsageStore.exactTokenText(1_234_567, locale: Locale(identifier: "en_US")), "1,234,567")
    }

    func test_compactTokenTextUsesLocalizedUnits() {
        XCTAssertEqual(AppStrings(language: .zhHans).compactTokenText(1_560_000_000), "15.6 亿")
        XCTAssertEqual(AppStrings(language: .en).compactTokenText(1_560_000_000), "1.6B")
        XCTAssertEqual(AppStrings(language: .ja).compactTokenText(1_560_000_000), "15.6 億")
        XCTAssertEqual(AppStrings(language: .zhHans).compactTokenText(12345), "1.2 万")
        XCTAssertEqual(AppStrings(language: .en).compactTokenText(12345), "12.3K")
        XCTAssertEqual(AppStrings(language: .ja).compactTokenText(12345), "1.2 万")
    }

    func test_refreshFrequencyTitleIncludesOneMinute() {
        XCTAssertEqual(AppStrings(language: .zhHans).refreshFrequencyTitle(.oneMinute), "每 1 分钟")
        XCTAssertEqual(AppStrings(language: .en).refreshFrequencyTitle(.oneMinute), "Every 1 minute")
        XCTAssertEqual(AppStrings(language: .ja).refreshFrequencyTitle(.oneMinute), "1 分ごと")
    }

    func test_usageStatisticsRefreshFrequencyTitleIncludesThirtyMinutes() {
        XCTAssertEqual(
            AppStrings(language: .zhHans).usageStatisticsRefreshFrequencyTitle(.thirtyMinutes),
            "每 30 分钟")
        XCTAssertEqual(
            AppStrings(language: .en).usageStatisticsRefreshFrequencyTitle(.thirtyMinutes),
            "Every 30 minutes")
        XCTAssertEqual(
            AppStrings(language: .ja).usageStatisticsRefreshFrequencyTitle(.thirtyMinutes),
            "30 分ごと")
    }

    func test_thirtyDayPeakTokenTextUsesStaticPeakUnits() {
        XCTAssertEqual(AppStrings(language: .zhHans).thirtyDayPeakTokenText(156_000_000), "1.6亿")
        XCTAssertEqual(AppStrings(language: .zhHans).thirtyDayPeakTokenText(35_000_000), "0.4亿")
        XCTAssertEqual(AppStrings(language: .en).thirtyDayPeakTokenText(1_560_000_000), "1.6B")
        XCTAssertEqual(AppStrings(language: .ja).thirtyDayPeakTokenText(1_560_000_000), "15.6億")
    }

    func test_recentTwentyFourHourPeakBubbleTextUsesYiScaleForChinese() {
        XCTAssertEqual(AppStrings(language: .zhHans).recentTwentyFourHourPeakBubbleText(156_000_000), "1.6亿")
        XCTAssertEqual(AppStrings(language: .zhHans).recentTwentyFourHourPeakBubbleText(20_000_000), "0.2亿")
        XCTAssertEqual(AppStrings(language: .zhHans).recentTwentyFourHourPeakBubbleText(100_000_000), "1亿")
        XCTAssertEqual(AppStrings(language: .en).recentTwentyFourHourPeakBubbleText(1_560_000_000), "1.6B")
        XCTAssertEqual(AppStrings(language: .ja).recentTwentyFourHourPeakBubbleText(1_560_000_000), "15.6億")
    }

    func test_recentTwentyFourHourHeaderTotalTextIsLocalized() {
        XCTAssertEqual(AppStrings(language: .zhHans).recentTwentyFourHourHeaderTotalText(156_000_000), "24h 1.6亿")
        XCTAssertEqual(AppStrings(language: .zhHans).recentTwentyFourHourHeaderTotalText(20_000_000), "24h 0.2亿")
        XCTAssertEqual(AppStrings(language: .en).recentTwentyFourHourHeaderTotalText(1_560_000_000), "24h 1.6B")
        XCTAssertEqual(AppStrings(language: .ja).recentTwentyFourHourHeaderTotalText(156_000_000), "24時間 1.6億")
    }

    func test_recentFortyEightHourHeaderTotalTextIsLocalized() {
        XCTAssertEqual(AppStrings(language: .zhHans).recentFortyEightHourHeaderTotalText(156_000_000), "48h 1.6亿")
        XCTAssertEqual(AppStrings(language: .zhHans).recentFortyEightHourHeaderTotalText(20_000_000), "48h 0.2亿")
        XCTAssertEqual(AppStrings(language: .en).recentFortyEightHourHeaderTotalText(1_560_000_000), "48h 1.6B")
        XCTAssertEqual(AppStrings(language: .ja).recentFortyEightHourHeaderTotalText(156_000_000), "48時間 1.6億")
    }

    func test_dualCompactMenuBarSummaryIsLocalized() {
        XCTAssertEqual(
            AppStrings(language: .zhHans).menuBarDualQuotaSummary(
                primaryLabel: "5 小时",
                primaryPercentText: "56%",
                secondaryLabel: "2 周",
                secondaryPercentText: "88%"),
            "5 小时 56%，2 周 88%")
        XCTAssertEqual(
            AppStrings(language: .en).menuBarDualQuotaSummary(
                primaryLabel: "5 hours",
                primaryPercentText: "56%",
                secondaryLabel: "2 weeks",
                secondaryPercentText: "88%"),
            "5 hours 56%, 2 weeks 88%")
        XCTAssertEqual(
            AppStrings(language: .ja).menuBarDualQuotaSummary(
                primaryLabel: "5時間",
                primaryPercentText: "56%",
                secondaryLabel: "2週間",
                secondaryPercentText: "88%"),
            "5時間 56%、2週間 88%")
    }

    func test_dualCompactMenuBarTitlesAreLocalized() {
        XCTAssertEqual(AppStrings(language: .zhHans).menuBarDisplayTitle(.quotaDualCompact), "双窗口极简")
        XCTAssertEqual(AppStrings(language: .en).menuBarDisplayTitle(.quotaDualCompact), "Dual Window Compact")
        XCTAssertEqual(AppStrings(language: .ja).menuBarDisplayTitle(.quotaDualCompact), "2 ウィンドウのコンパクト表示")
    }

    func test_dualKnockoutMenuBarLocalizationIsLocalized() {
        XCTAssertEqual(AppStrings(language: .zhHans).menuBarDisplayTitle(.quotaDualKnockout), "镂空白底双窗口")
        XCTAssertEqual(AppStrings(language: .en).menuBarDisplayTitle(.quotaDualKnockout), "Dual Window Knockout")
        XCTAssertEqual(AppStrings(language: .ja).menuBarDisplayTitle(.quotaDualKnockout), "白抜き 2 ウィンドウ")

        XCTAssertEqual(AppStrings(language: .zhHans).menuBarAppearanceTitle(.dualKnockout), "镂空白底双窗口")
        XCTAssertEqual(AppStrings(language: .en).menuBarAppearanceTitle(.dualKnockout), "Dual Window Knockout")
        XCTAssertEqual(AppStrings(language: .ja).menuBarAppearanceTitle(.dualKnockout), "白抜き 2 ウィンドウ")

        XCTAssertEqual(
            AppStrings(language: .zhHans).menuBarAppearanceDescription(.dualKnockout),
            "沿用 5 小时和第二窗口双行布局，白底里标签和数字透明镂空。")
        XCTAssertEqual(
            AppStrings(language: .en).menuBarAppearanceDescription(.dualKnockout),
            "Keeps the 5-hour plus secondary two-row layout with transparent knockout labels inside a white shell.")
        XCTAssertEqual(
            AppStrings(language: .ja).menuBarAppearanceDescription(.dualKnockout),
            "5 時間と第 2 ウィンドウの 2 段構成を保ちつつ、白地の中をラベルと数字が透明に抜けます。")
    }

    private func sameDayDate(hour: Int, minute: Int) throws -> Date {
        let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let year = try XCTUnwrap(today.year)
        let month = try XCTUnwrap(today.month)
        let day = try XCTUnwrap(today.day)
        return try self.fixedDate(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute)
    }

    private func fixedDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) throws -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = TimeZone.current
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return try XCTUnwrap(calendar.date(from: components))
    }
}
