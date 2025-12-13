import Foundation

public struct Error: Swift.Error, Sendable {
  // A code for the error.
  public let errorCode: Code

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
}
