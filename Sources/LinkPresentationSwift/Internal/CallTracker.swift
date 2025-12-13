// Internal actor to track method calls and enforce single-use policy
internal actor CallTracker {
    private var hasBeenCalled = false

    func recordCall() throws {
        guard !hasBeenCalled else {
            throw Error(
                errorCode: .metadataFetchFailed,
                reason: "MetadataProvider.metadata(for:) called more than once."
            )  // Should ideally be a more specific error
        }
        hasBeenCalled = true
    }
}
