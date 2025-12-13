import Foundation
import Testing

@testable import LinkPresentationSwift

@Suite("shouldFetchSubresources Feature Tests")
struct ShouldFetchSubresourcesTests {

  @Test("shouldFetchSubresources = true should extract image URLs")
  func shouldFetchSubresourcesTrue() async throws {
    let mockFetcher = MockMetadataFetcher()
    let parser = HTMLParser()  // Use real parser to test actual functionality

    let htmlWithImage = """
      <html>
      <head>
          <meta property="og:image" content="https://example.com/image.png">
          <title>Test Page</title>
      </head>
      </html>
      """

    mockFetcher.htmlToReturn = htmlWithImage
    mockFetcher.urlToReturn = URL(string: "https://example.com")

    let provider = MetadataProvider(fetcher: mockFetcher, parser: parser)

    let metadata = try await provider.metadata(for: URL(string: "https://example.com")!)

    // Should have imageURL
    #expect(metadata.imageURL?.absoluteString == "https://example.com/image.png")
  }

  @Test("shouldFetchSubresources = false should extract image URLs")
  func shouldFetchSubresourcesFalse() async throws {
    let mockFetcher = MockMetadataFetcher()
    let parser = HTMLParser()  // Use real parser to test actual functionality

    let htmlWithImage = """
      <html>
      <head>
          <meta property="og:image" content="https://example.com/image.png">
          <title>Test Page</title>
      </head>
      </html>
      """

    mockFetcher.htmlToReturn = htmlWithImage
    mockFetcher.urlToReturn = URL(string: "https://example.com")

    let provider = MetadataProvider(fetcher: mockFetcher, parser: parser)

    let metadata = try await provider.metadata(for: URL(string: "https://example.com")!)

    // Should have imageURL
    #expect(metadata.imageURL?.absoluteString == "https://example.com/image.png")
  }

  @Test("Extract icon URLs from link tags")
  func extractIconFromLinkTags() async throws {
    let mockFetcher = MockMetadataFetcher()
    let parser = HTMLParser()

    let htmlWithIcon = """
      <html>
      <head>
          <link rel="icon" href="https://example.com/favicon.ico">
          <title>Test Page</title>
      </head>
      </html>
      """

    mockFetcher.htmlToReturn = htmlWithIcon
    mockFetcher.urlToReturn = URL(string: "https://example.com")

    let provider = MetadataProvider(fetcher: mockFetcher, parser: parser)

    let metadata = try await provider.metadata(for: URL(string: "https://example.com")!)

    #expect(metadata.iconURL?.absoluteString == "https://example.com/favicon.ico")
  }
}
