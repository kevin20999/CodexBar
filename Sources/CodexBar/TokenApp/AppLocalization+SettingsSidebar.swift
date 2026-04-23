import Foundation

extension AppStrings {
    var settingsGeneralCategoryTitle: String {
        self.text(zh: "通用", en: "General", ja: "一般")
    }

    var settingsDisplayCategoryTitle: String {
        self.text(zh: "显示", en: "Display", ja: "表示")
    }

    var settingsThemeCategoryTitle: String {
        self.text(zh: "主题", en: "Themes", ja: "テーマ")
    }

    var settingsOpenAIWebCategoryTitle: String {
        self.text(zh: "OpenAI Web", en: "OpenAI Web", ja: "OpenAI Web")
    }

    var settingsDashboardCategoryTitle: String {
        self.text(zh: "看板模块", en: "Dashboard Cards", ja: "ダッシュボードカード")
    }

    var settingsSystemCategoryTitle: String {
        self.text(zh: "系统", en: "System", ja: "システム")
    }

    var settingsGeneralCategoryDescription: String {
        self.text(
            zh: "调整语言与刷新节奏。",
            en: "Adjust language and refresh behavior.",
            ja: "言語と更新頻度を調整します。")
    }

    var settingsDisplayCategoryDescription: String {
        self.text(
            zh: "管理菜单栏样式与显示相关设置。",
            en: "Manage menu bar appearance and display-related options.",
            ja: "メニューバーの表示スタイルと表示関連設定を管理します。")
    }

    var settingsThemeCategoryDescription: String {
        self.text(
            zh: "集中管理菜单面板主题与弹窗容器风格。",
            en: "Manage menu panel themes and popup container style in one place.",
            ja: "メニューパネルのテーマとポップアップコンテナのスタイルをまとめて管理します。")
    }

    var settingsOpenAIWebCategoryDescription: String {
        self.text(
            zh: "配置 OpenAI 网页访问、Cookie 与调试信息。",
            en: "Configure OpenAI web access, cookies, and debug details.",
            ja: "OpenAI Web のアクセス、Cookie、デバッグ情報を設定します。")
    }

    var settingsDashboardCategoryDescription: String {
        self.text(
            zh: "控制看板中各个模块的显示与排序。",
            en: "Control dashboard module visibility and order.",
            ja: "ダッシュボードに表示するモジュールの表示と並び順を管理します。")
    }

    var dashboardLargeCardsSectionTitle: String {
        self.text(zh: "大卡片排序", en: "Large Card Order", ja: "大型カードの並び順")
    }

    var dashboardLargeCardsSectionDescription: String {
        self.text(
            zh: "拖动左侧手柄调整顺序，顺序会同步到数据看板。",
            en: "Drag the handle to reorder large cards in the dashboard.",
            ja: "左側のハンドルをドラッグして、大型カードの順序をダッシュボードに反映します。")
    }

    var dashboardOverviewRowsSectionTitle: String {
        self.text(zh: "汇总卡片内容", en: "Totals Card Content", ja: "合計カードの内容")
    }

    var dashboardOverviewRowsSectionDescription: String {
        self.text(
            zh: "这些开关只影响汇总卡片内部的统计项，不参与拖动排序。",
            en: "These toggles only affect rows inside the totals card and do not move.",
            ja: "これらの切り替えは合計カード内の行だけに影響し、ドラッグ並べ替えの対象外です。")
    }

    var settingsSystemCategoryDescription: String {
        self.text(
            zh: "管理开机启动和本地存储位置。",
            en: "Manage launch behavior and local storage.",
            ja: "起動設定とローカル保存先を管理します。")
    }

    var previewAppearanceLabel: String {
        self.text(zh: "视觉风格", en: "Visual style", ja: "ビジュアルスタイル")
    }

    var previewContainerStyleLabel: String {
        self.text(zh: "弹窗容器", en: "Popup container", ja: "ポップアップコンテナ")
    }
}
