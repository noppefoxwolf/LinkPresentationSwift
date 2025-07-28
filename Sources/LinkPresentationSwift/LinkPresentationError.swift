public enum LinkPresentationError: Error, Sendable {
    case cancelled
    case failed
    case timedOut
    case unknown
    case notAllowed
}
