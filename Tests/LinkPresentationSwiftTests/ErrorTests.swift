import Testing

@testable import LinkPresentationSwift

@Suite("Error Tests")
struct ErrorTests {

  @Test("Error codes are correctly defined")
  func errorCodes() async throws {
    let cancelledError = LinkPresentationSwift.Error(errorCode: .metadataFetchCancelled)
    #expect(cancelledError.errorCode == .metadataFetchCancelled)

    let failedError = LinkPresentationSwift.Error(errorCode: .metadataFetchFailed)
    #expect(failedError.errorCode == .metadataFetchFailed)

    let timeoutError = LinkPresentationSwift.Error(errorCode: .metadataFetchTimedOut)
    #expect(timeoutError.errorCode == .metadataFetchTimedOut)

    let unknownError = LinkPresentationSwift.Error(errorCode: .unknown)
    #expect(unknownError.errorCode == .unknown)

    let notAllowedError = LinkPresentationSwift.Error(errorCode: .metadataFetchNotAllowed)
    #expect(notAllowedError.errorCode == .metadataFetchNotAllowed)
  }
}
