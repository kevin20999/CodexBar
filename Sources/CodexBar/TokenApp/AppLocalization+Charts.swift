import Foundation

extension AppStrings {
    func recentTwentyFourHourHeaderTotalText(_ value: Int) -> String {
        let formatted = switch self.resolvedLanguage {
        case .zhHans:
            self.localizedChartBubbleNumber(value, divisor: 100_000_000, unit: "亿")
        case .en, .ja:
            self.chartCompactTokenText(value)
        default:
            self.chartCompactTokenText(value)
        }

        switch self.resolvedLanguage {
        case .zhHans, .en:
            return "24h \(formatted)"
        case .ja:
            return "24時間 \(formatted)"
        default:
            return "24h \(formatted)"
        }
    }

    func recentFortyEightHourHeaderTotalText(_ value: Int) -> String {
        let formatted = switch self.resolvedLanguage {
        case .zhHans:
            self.localizedChartBubbleNumber(value, divisor: 100_000_000, unit: "亿")
        case .en, .ja:
            self.chartCompactTokenText(value)
        default:
            self.chartCompactTokenText(value)
        }

        switch self.resolvedLanguage {
        case .zhHans, .en:
            return "48h \(formatted)"
        case .ja:
            return "48時間 \(formatted)"
        default:
            return "48h \(formatted)"
        }
    }

    func recentTwentyFourHourPeakBubbleText(_ value: Int) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            self.localizedChartBubbleNumber(value, divisor: 100_000_000, unit: "亿")
        case .en, .ja:
            self.chartCompactTokenText(value)
        default:
            self.chartCompactTokenText(value)
        }
    }

    private func localizedChartBubbleNumber(_ value: Int, divisor: Double, unit: String) -> String {
        let formatter = NumberFormatter()
        formatter.locale = self.locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0

        let scaled = Double(value) / divisor
        let number = formatter.string(from: NSNumber(value: scaled)) ?? "\(scaled)"
        return "\(number)\(unit)"
    }
}
