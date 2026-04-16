public enum KeychainAccessGate {
    @TaskLocal private static var taskOverrideValue: Bool?
    public nonisolated(unsafe) static var isDisabled: Bool = false

    static func withTaskOverrideForTesting<T>(
        _ disabled: Bool?,
        operation: () throws -> T) rethrows -> T
    {
        try self.$taskOverrideValue.withValue(disabled) {
            let previous = self.isDisabled
            if let disabled {
                self.isDisabled = disabled
            }
            defer { self.isDisabled = previous }
            return try operation()
        }
    }

    static func withTaskOverrideForTesting<T>(
        _ disabled: Bool?,
        operation: () async throws -> T) async rethrows -> T
    {
        try await self.$taskOverrideValue.withValue(disabled) {
            let previous = self.isDisabled
            if let disabled {
                self.isDisabled = disabled
            }
            defer { self.isDisabled = previous }
            return try await operation()
        }
    }
}
