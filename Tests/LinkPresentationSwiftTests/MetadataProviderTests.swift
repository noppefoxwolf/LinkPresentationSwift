import Foundation
import Testing

@testable import LinkPresentationSwift

// Mock classes for testing
final class MockMetadataFetcher: MetadataFetcherProtocol, @unchecked Sendable {
  var htmlToReturn: String = ""
  var urlToReturn: URL?
  var errorToThrow: Error?
  var lastRequest: URLRequest?

  func fetchHTML(for request: URLRequest) async throws -> (html: String, finalURL: URL) {
    lastRequest = request
    if let error = errorToThrow {
      throw error
    }
    return (html: htmlToReturn, finalURL: urlToReturn ?? request.url!)
  }
}

final class MockHTMLParser: HTMLParserProtocol, @unchecked Sendable {
  var metadataToReturn: LinkMetadata?

  func parseHTMLMetadata(html: String, baseMetadata: LinkMetadata) async -> LinkMetadata {
    return metadataToReturn ?? baseMetadata
  }
}

@Suite("Metadata Provider Tests")
struct MetadataProviderTests {

  @Test("Start fetching metadata success with mocks")
  func startFetchingMetadataSuccess() async throws {
    let mockFetcher = MockMetadataFetcher()
    let mockParser = MockHTMLParser()

    let originalURL = URL(string: "https://example.com")!
    let finalURL = URL(string: "https://example.com/final")!

    mockFetcher.htmlToReturn = "<html><head><title>Test</title></head></html>"
    mockFetcher.urlToReturn = finalURL

    var expectedMetadata = LinkMetadata()
    expectedMetadata.originalURL = originalURL
    expectedMetadata.url = finalURL
    expectedMetadata.title = "Parsed Title"
    mockParser.metadataToReturn = expectedMetadata

    let provider = MetadataProvider(fetcher: mockFetcher, parser: mockParser)

    let metadata = try await provider.metadata(for: originalURL)

    #expect(metadata.originalURL == originalURL)
    #expect(metadata.url == finalURL)
    #expect(metadata.title == "Parsed Title")
  }

  @Test("Start fetching metadata with fetch error")
  func startFetchingMetadataFetchError() async throws {
    let mockFetcher = MockMetadataFetcher()
    let mockParser = MockHTMLParser()

    mockFetcher.errorToThrow = LinkPresentationSwift.Error(errorCode: .metadataFetchFailed)

    let provider = MetadataProvider(fetcher: mockFetcher, parser: mockParser)
    let url = URL(string: "https://example.com")!

    await #expect {
      try await provider.metadata(for: url)
    } throws: { error in
      if let lpError = error as? LinkPresentationSwift.Error {
        return lpError.errorCode == .metadataFetchFailed
      }
      return false
    }
  }

  @Test("Start fetching metadata for URLRequest uses request directly")
  func startFetchingMetadataForURLRequest() async throws {
    let mockFetcher = MockMetadataFetcher()
    let mockParser = MockHTMLParser()

    let url = URL(string: "https://example.com")!
    var request = URLRequest(url: url)
    request.setValue("custom-header-value", forHTTPHeaderField: "Custom-Header")

    mockFetcher.htmlToReturn = "<html></html>"

    var expectedMetadata = LinkMetadata()
    expectedMetadata.title = "Request Title"
    mockParser.metadataToReturn = expectedMetadata

    let provider = MetadataProvider(fetcher: mockFetcher, parser: mockParser)

    let metadata = try await provider.metadata(for: request)

    #expect(metadata.title == "Request Title")

    // Verify that the request was used directly
    #expect(mockFetcher.lastRequest != nil)
    #expect(
      mockFetcher.lastRequest?.value(forHTTPHeaderField: "Custom-Header") == "custom-header-value")
  }

  @Test("Start fetching metadata for URLRequest without URL")
  func startFetchingMetadataForURLRequestWithoutURL() async throws {
    let provider = MetadataProvider()

    let invalidRequest = URLRequest(url: URL(string: "invalid-url")!)

    await #expect {
      try await provider.metadata(for: invalidRequest)
    } throws: { error in
      return error is URLError || error is LinkPresentationSwift.Error
    }
  }

  @Test("Default initialization has correct default values")
  func defaultInitialization() async throws {
    let provider = MetadataProvider()

    #expect(provider.timeout == 30)
  }

  @Test("Timeout property can be changed")
  func timeoutProperty() async throws {
    var provider = MetadataProvider()

    provider.timeout = 60
    #expect(provider.timeout == 60)
  }
}
