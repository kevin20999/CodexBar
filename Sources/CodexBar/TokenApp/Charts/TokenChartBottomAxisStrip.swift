import CoreGraphics
import SwiftUI

struct TokenChartAxisMarker: Identifiable, Equatable {
    enum Priority: String, Equatable, Sendable {
        case normal
        case compressed
        case boundary
    }

    let id: String
    let text: String
    let normalizedX: CGFloat
    let priority: Priority
}

struct TokenChartBottomAxisStrip<LabelContent: View>: View {
    let markers: [TokenChartAxisMarker]
    let frameHeight: CGFloat
    let rowCenterY: CGFloat
    let labelWidth: (TokenChartAxisMarker) -> CGFloat
    let label: (TokenChartAxisMarker, ThirtyDayChartAxisLabelResolver.TextAlignment) -> LabelContent

    var body: some View {
        GeometryReader { geo in
            let placements = self.placements(in: geo.size.width)
            let markerLookup = Dictionary(uniqueKeysWithValues: self.markers.map { ($0.id, $0) })

            ZStack(alignment: .topLeading) {
                ForEach(placements) { placement in
                    if let marker = markerLookup[placement.id] {
                        self.label(marker, placement.alignment)
                            .frame(width: placement.width, alignment: placement.alignment.frameAlignment)
                            .position(x: placement.centerX, y: placement.centerY)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: self.frameHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func placements(in availableWidth: CGFloat) -> [ThirtyDayChartAxisLabelResolver.Placement] {
        guard availableWidth > 0, !self.markers.isEmpty else { return [] }

        let plotFrame = CGRect(x: 0, y: 0, width: availableWidth, height: self.frameHeight)
        let labels = self.markers.map { marker in
            ThirtyDayChartAxisLabelResolver.Label(
                id: marker.id,
                text: marker.text,
                centerX: min(max(marker.normalizedX, 0), 1) * availableWidth,
                width: self.labelWidth(marker))
        }

        return ThirtyDayChartAxisLabelResolver.resolvePlacements(
            labels: labels,
            plotFrame: plotFrame,
            rowCenterY: min(max(self.rowCenterY, 0), self.frameHeight))
    }
}
