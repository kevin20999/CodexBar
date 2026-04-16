import Foundation

extension AppStrings {
    var menuBarAppearanceSelectionDescription: String {
        self.text(
            zh: "直接选择顶部菜单栏的最终样式。每项都会显示名称、说明和小预览。",
            en: "Choose the final menu bar style directly. Each option shows its name, description, and preview.",
            ja: "上部メニューバーの最終スタイルを直接選べます。各項目には名前、説明、小さなプレビューを表示します。")
    }

    func menuBarAppearanceTitle(_ option: MenuBarAppearanceOption) -> String {
        switch option {
        case .todayIO:
            self.menuBarDisplayTitle(.todayIO)
        case .classicCapsule:
            self.menuBarQuotaStyleTitle(.capsule)
        case .splitBadge:
            self.menuBarQuotaStyleTitle(.split)
        case .slimMeter:
            self.menuBarQuotaStyleTitle(.meter)
        case .lightOutline:
            self.menuBarQuotaStyleTitle(.outline)
        case .codexMinimal:
            self.menuBarQuotaStyleTitle(.codexMinimal)
        case .dualCompact:
            self.menuBarDisplayTitle(.quotaDualCompact)
        case .dualKnockout:
            self.menuBarDisplayTitle(.quotaDualKnockout)
        }
    }

    func menuBarAppearanceDescription(_ option: MenuBarAppearanceOption) -> String {
        switch option {
        case .todayIO:
            self.text(
                zh: "上下两行显示今日输入和输出，适合同时盯住两个数值。",
                en: "Shows today's input and output on two rows so both values stay visible.",
                ja: "今日の入力と出力を 2 段で表示し、両方の数値を同時に確認できます。")
        case .classicCapsule:
            self.text(
                zh: "经典胶囊百分比样式，信息完整，识别最快。",
                en: "Classic capsule percentage style with the fullest information at a glance.",
                ja: "情報量が最も多く、ひと目で把握しやすいクラシックなカプセル表示です。")
        case .splitBadge:
            self.text(
                zh: "左侧标签配右侧百分比，层次更清晰。",
                en: "Pairs a left badge with a right percentage for clearer hierarchy.",
                ja: "左のバッジと右の割合で情報の階層が分かりやすくなります。")
        case .slimMeter:
            self.text(
                zh: "更细的进度条和数字，占用最少的视觉空间。",
                en: "Uses the thinnest meter and numerals to keep visual weight low.",
                ja: "最も細いメーターと数字で、視覚的な占有を抑えます。")
        case .lightOutline:
            self.text(
                zh: "轻描边外壳，边界更明显，观感更克制。",
                en: "Adds a light outline shell so the boundary reads more clearly.",
                ja: "軽いアウトラインで境界が見やすく、主張は控えめです。")
        case .codexMinimal:
            self.text(
                zh: "保留最简 Codex 风格，只强调核心剩余比例。",
                en: "Keeps the most minimal Codex look and emphasizes only the key percentage.",
                ja: "最小限の Codex スタイルで、残量の割合だけを強調します。")
        case .dualCompact:
            self.text(
                zh: "用上下两行微字同时放进 5 小时和第二窗口剩余，宽度最省。",
                en: "Stacks the 5-hour and secondary windows into two micro rows to save the most width.",
                ja: "5 時間と第 2 ウィンドウの残量を上下 2 段の極小表示にまとめ、横幅を最も節約します。")
        case .dualKnockout:
            self.text(
                zh: "沿用 5 小时和第二窗口双行布局，白底里标签和数字透明镂空。",
                en: "Keeps the 5-hour plus secondary two-row layout with transparent knockout labels "
                    + "inside a white shell.",
                ja: "5 時間と第 2 ウィンドウの 2 段構成を保ちつつ、白地の中をラベルと数字が透明に抜けます。")
        }
    }
}
