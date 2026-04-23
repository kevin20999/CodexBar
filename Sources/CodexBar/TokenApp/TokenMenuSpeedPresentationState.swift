import Foundation
import Observation

enum TokenMenuSpeedPresentationPhase: String, Equatable, Sendable {
    case idle
    case ignite
    case thrust
    case hold
    case dismissing
}

struct TokenMenuSpeedPresentationState: Equatable, Sendable {
    let displayedTokensPerSecond: Int
    let bubbleDisplayText: String
    let launchStrength: Double
    let lastBurstDate: Date?
    let burstID: Int
    let phase: TokenMenuSpeedPresentationPhase

    static let idle = TokenMenuSpeedPresentationState(
        displayedTokensPerSecond: 0,
        bubbleDisplayText: "0",
        launchStrength: 0,
        lastBurstDate: nil,
        burstID: 0,
        phase: .idle)

    var usesRocketIcon: Bool {
        self.phase != .idle
    }

    var keepsBubbleMounted: Bool {
        self.phase != .idle
    }

    var bubblePresented: Bool {
        switch self.phase {
        case .idle:
            false
        case .ignite, .thrust, .hold, .dismissing:
            true
        }
    }

    var speedText: String {
        "\(self.displayedTokensPerSecond) token/s"
    }

    var numericValueText: String {
        String(self.displayedTokensPerSecond)
    }
}

@MainActor
@Observable
final class TokenMenuSpeedPresentationCoordinator {
    struct Timing: Equatable, Sendable {
        let igniteDuration: Duration
        let thrustDuration: Duration
        let holdDuration: Duration
        let dismissDuration: Duration

        static let live = Timing(
            igniteDuration: .milliseconds(140),
            thrustDuration: .milliseconds(320),
            holdDuration: .milliseconds(2400),
            dismissDuration: .milliseconds(420))
    }

    private static let minimumBurstStrength = 0.38

    private let timing: Timing
    private(set) var state: TokenMenuSpeedPresentationState = .idle
    private var lifecycleTask: Task<Void, Never>?
    private var nextBurstID = 0

    init(timing: Timing = .live) {
        self.timing = timing
    }

    func consume(rawMetrics: MenuBarTokenSpeedMetrics, bubbleDisplayText: String) {
        guard rawMetrics.tokensPerSecond > 0 else { return }

        self.lifecycleTask?.cancel()
        self.nextBurstID += 1

        let burstID = self.nextBurstID
        let launchStrength = max(rawMetrics.launchStrength, Self.minimumBurstStrength)
        let burstDate = rawMetrics.launchDate ?? Date()

        self.state = TokenMenuSpeedPresentationState(
            displayedTokensPerSecond: rawMetrics.tokensPerSecond,
            bubbleDisplayText: bubbleDisplayText,
            launchStrength: launchStrength,
            lastBurstDate: burstDate,
            burstID: burstID,
            phase: .ignite)

        self.lifecycleTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.runLifecycle(for: burstID)
        }
    }

    func reset() {
        self.lifecycleTask?.cancel()
        self.lifecycleTask = nil
        self.state = .idle
    }

    private func runLifecycle(for burstID: Int) async {
        do {
            try await Task.sleep(for: self.timing.igniteDuration)
            guard !Task.isCancelled else { return }
            self.updatePhase(.thrust, for: burstID)

            try await Task.sleep(for: self.timing.thrustDuration)
            guard !Task.isCancelled else { return }
            self.updatePhase(.hold, for: burstID)

            let remainingHold = max(
                .zero,
                self.timing.holdDuration - self.timing.igniteDuration - self.timing.thrustDuration)
            try await Task.sleep(for: remainingHold)
            guard !Task.isCancelled else { return }
            self.updatePhase(.dismissing, for: burstID)

            try await Task.sleep(for: self.timing.dismissDuration)
            guard !Task.isCancelled else { return }
            self.completeDismiss(for: burstID)
        } catch {
            return
        }
    }

    private func updatePhase(_ phase: TokenMenuSpeedPresentationPhase, for burstID: Int) {
        guard self.state.burstID == burstID else { return }
        self.state = TokenMenuSpeedPresentationState(
            displayedTokensPerSecond: self.state.displayedTokensPerSecond,
            bubbleDisplayText: self.state.bubbleDisplayText,
            launchStrength: self.state.launchStrength,
            lastBurstDate: self.state.lastBurstDate,
            burstID: burstID,
            phase: phase)
    }

    private func completeDismiss(for burstID: Int) {
        guard self.state.burstID == burstID else { return }
        self.state = .idle
        self.lifecycleTask = nil
    }
}
