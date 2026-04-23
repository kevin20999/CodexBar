import Foundation

public struct TokenHistoryRefreshExecutionResult: Sendable, Equatable {
    public let document: TokenHistoryDocument
    public let firstError: String?

    public init(document: TokenHistoryDocument, firstError: String?) {
        self.document = document
        self.firstError = firstError
    }
}

public enum TokenHistoryRefreshExecutor {
    public static func refresh(
        provider: CodexSessionTokenProvider,
        historyStore: TokenHistoryStore,
        priority: TaskPriority = .userInitiated)
        async throws -> TokenHistoryRefreshExecutionResult
    {
        try await Task.detached(priority: priority) {
            let result = try provider.refresh()
            let document = try historyStore.merge(refreshResult: result)
            return TokenHistoryRefreshExecutionResult(
                document: document,
                firstError: result.errors.first)
        }.value
    }

    public static func rebuild(
        provider: CodexSessionTokenProvider,
        historyStore: TokenHistoryStore,
        priority: TaskPriority = .userInitiated)
        async throws -> TokenHistoryRefreshExecutionResult
    {
        try await Task.detached(priority: priority) {
            let result = try provider.rebuild()
            let document = try historyStore.rebuild(from: result)
            return TokenHistoryRefreshExecutionResult(
                document: document,
                firstError: result.errors.first)
        }.value
    }

    public static func refreshMigrationBatch(
        provider: CodexSessionTokenProvider,
        historyStore: TokenHistoryStore,
        maxRuntime: Duration,
        priority: TaskPriority = .userInitiated)
        async throws -> TokenHistoryRefreshExecutionResult
    {
        try await Task.detached(priority: priority) {
            let result = try provider.refreshMigrationBatch(maxRuntime: maxRuntime)
            let document = try historyStore.merge(refreshResult: result)
            return TokenHistoryRefreshExecutionResult(
                document: document,
                firstError: result.errors.first)
        }.value
    }
}
