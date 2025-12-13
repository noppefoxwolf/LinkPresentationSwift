// Internal actor to track method calls and enforce single-use policy
internal actor CallTracker {
    private var hasBeenCalled = false

    func recordCall() throws {
        guard !hasBeenCalled else {
            throw Error(errorCode: .metadataFetchFailed)  // Should ideally be a more specific error
        }
        hasBeenCalled = true
    }
}
