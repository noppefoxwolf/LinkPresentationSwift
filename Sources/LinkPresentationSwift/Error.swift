import Foundation

public struct Error: Swift.Error, LocalizedError, Sendable {
    /// A code for the error.
    public let errorCode: Code

    /// Human-readable reason for debugging / logging.
    public let reason: String?

    /// Underlying error description (if any) for additional context.
    public let underlyingErrorDescription: String?

    /// Create a new error with optional context.
    public init(
        errorCode: Code,
        reason: String? = nil,
        underlyingError: (any Swift.Error)? = nil
    ) {
        self.errorCode = errorCode
        self.reason = reason
        self.underlyingErrorDescription = underlyingError?.localizedDescription
    }

    public enum Code: Sendable {
        // An error indicating that the metadata fetch was canceled by the client.
        case metadataFetchCancelled

        // An error indicating that a metadata fetch failed.
        case metadataFetchFailed

        // An error indicating that the metadata fetch took longer than allowed.
        case metadataFetchTimedOut

        // An unknown error.
        case unknown

        // An error indicating that the metadata fetch was not allowed due to system policies.
        case metadataFetchNotAllowed
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch errorCode {
        case .metadataFetchCancelled:
            return reason ?? "Metadata fetch was cancelled."
        case .metadataFetchFailed:
            return reason ?? "Metadata fetch failed."
        case .metadataFetchTimedOut:
            return reason ?? "Metadata fetch timed out."
        case .metadataFetchNotAllowed:
            return reason ?? "Metadata fetch not allowed."
        case .unknown:
            return reason ?? "Unknown metadata error."
        }
    }
}
