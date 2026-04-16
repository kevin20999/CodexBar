import CodexBarCore

typealias TokenSpeedSample = CodexBarCore.TokenSpeedSample
typealias TokenSpeedHistoryEntry = CodexBarCore.TokenSpeedHistoryEntry
typealias TokenSpeedHistoryStore = CodexBarCore.TokenSpeedHistoryStore

extension TokenSpeedSample {
    var icon: String {
        MenuBarTokenSpeedMetrics.historyIcon(for: self.tokens)
    }
}

extension TokenSpeedHistoryEntry {
    var icon: String {
        MenuBarTokenSpeedMetrics.historyIcon(for: self.tokens)
    }
}
