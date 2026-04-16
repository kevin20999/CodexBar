import Foundation

extension AppStrings {
    func menuBarDisplayTitle(_ mode: MenuBarDisplayMode) -> String {
        switch (self.resolvedLanguage, mode) {
        case (.zhHans, .todayIO):
            "今日输入 / 输出"
        case (.zhHans, .quota5h):
            "5 小时剩余量"
        case (.zhHans, .quotaDualCompact):
            "双窗口极简"
        case (.zhHans, .quotaDualKnockout):
            "镂空白底双窗口"
        case (.en, .todayIO):
            "Today's Input / Output"
        case (.en, .quota5h):
            "5-hour Remaining"
        case (.en, .quotaDualCompact):
            "Dual Window Compact"
        case (.en, .quotaDualKnockout):
            "Dual Window Knockout"
        case (.ja, .todayIO):
            "今日の入力 / 出力"
        case (.ja, .quota5h):
            "5 時間の残量"
        case (.ja, .quotaDualCompact):
            "2 ウィンドウのコンパクト表示"
        case (.ja, .quotaDualKnockout):
            "白抜き 2 ウィンドウ"
        default:
            "今日输入 / 输出"
        }
    }

    func menuBarDisplayDescription(_ mode: MenuBarDisplayMode) -> String {
        switch (self.resolvedLanguage, mode) {
        case (.zhHans, .todayIO):
            "上下两行显示今日输入和输出，绿色和蓝色圆点分别代表输入和输出。"
        case (.zhHans, .quota5h):
            "显示 5 小时窗口的剩余比例。"
        case (.zhHans, .quotaDualCompact):
            "上下两行微字同时显示主窗口和第二窗口的剩余比例，尽量压缩宽度。"
        case (.zhHans, .quotaDualKnockout):
            "沿用双窗口上下两行布局，白底内标签和数字为透明镂空。"
        case (.en, .todayIO):
            "Shows today's input and output on two rows, with green and blue dots for each stream."
        case (.en, .quota5h):
            "Shows the remaining percentage for the 5-hour window."
        case (.en, .quotaDualCompact):
            "Uses two compact rows to show the primary and secondary remaining windows with minimal width."
        case (.en, .quotaDualKnockout):
            "Keeps the dual-window stacked layout with a white shell and transparent knockout labels and numerals."
        case (.ja, .todayIO):
            "今日の入力と出力を 2 段で表示し、緑と青のドットで区別します。"
        case (.ja, .quota5h):
            "5 時間ウィンドウの残量を表示します。"
        case (.ja, .quotaDualCompact):
            "上下 2 段のコンパクト表示で、主ウィンドウと第 2 ウィンドウの残量を最小幅で表示します。"
        case (.ja, .quotaDualKnockout):
            "2 段のレイアウトはそのままに、白地の中をラベルと数字が透明に抜ける表示です。"
        default:
            "上下两行显示今日输入和输出，绿色和蓝色圆点分别代表输入和输出。"
        }
    }

    func menuBarQuotaSummary(percentText: String) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            "5小时 \(percentText)"
        case .en:
            "5h \(percentText)"
        case .ja:
            "5時間 \(percentText)"
        default:
            "5小时 \(percentText)"
        }
    }

    func menuBarDualQuotaSummary(
        primaryLabel: String,
        primaryPercentText: String,
        secondaryLabel: String?,
        secondaryPercentText: String?) -> String
    {
        guard let secondaryLabel, let secondaryPercentText else {
            return "\(primaryLabel) \(primaryPercentText)"
        }

        switch self.resolvedLanguage {
        case .zhHans:
            return "\(primaryLabel) \(primaryPercentText)，\(secondaryLabel) \(secondaryPercentText)"
        case .en:
            return "\(primaryLabel) \(primaryPercentText), \(secondaryLabel) \(secondaryPercentText)"
        case .ja:
            return "\(primaryLabel) \(primaryPercentText)、\(secondaryLabel) \(secondaryPercentText)"
        default:
            return "\(primaryLabel) \(primaryPercentText), \(secondaryLabel) \(secondaryPercentText)"
        }
    }
}
