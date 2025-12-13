import Foundation
import Testing

@testable import LinkPresentationSwift

@Suite("HTML Parser Tests")
struct HTMLParserTests {
  let parser = HTMLParser()

  @Test("Parse basic title from HTML")
  func parseTitle() async throws {
    let html = """
      <html>
      <head>
          <title>Test Page Title</title>
      </head>
      <body></body>
      </html>
      """

    var baseMetadata = LinkMetadata()
    baseMetadata.originalURL = URL(string: "https://example.com")

    let metadata = await parser.parseHTMLMetadata(html: html, baseMetadata: baseMetadata)

    #expect(metadata.title == "Test Page Title")
  }

  @Test("Parse empty title returns nil")
  func parseEmptyTitle() async throws {
    let html = """
      <html>
      <head>
          <title></title>
      </head>
      <body></body>
      </html>
      """

    var baseMetadata = LinkMetadata()
    baseMetadata.originalURL = URL(string: "https://example.com")

    let metadata = await parser.parseHTMLMetadata(html: html, baseMetadata: baseMetadata)

    #expect(metadata.title == nil)
  }

  @Test("Open Graph title overrides regular title")
  func parseOpenGraphTitle() async throws {
    let html = """
      <html>
      <head>
          <title>Original Title</title>
          <meta property="og:title" content="Open Graph Title">
      </head>
      <body></body>
      </html>
      """

    var baseMetadata = LinkMetadata()
    baseMetadata.originalURL = URL(string: "https://example.com")

    let metadata = await parser.parseHTMLMetadata(html: html, baseMetadata: baseMetadata)

    #expect(metadata.title == "Open Graph Title")
  }

  @Test("Twitter title overrides regular title")
  func parseTwitterTitle() async throws {
    let html = """
      <html>
      <head>
          <title>Original Title</title>
          <meta name="twitter:title" content="Twitter Title">
      </head>
      <body></body>
      </html>
      """

    var baseMetadata = LinkMetadata()
    baseMetadata.originalURL = URL(string: "https://example.com")

    let metadata = await parser.parseHTMLMetadata(html: html, baseMetadata: baseMetadata)

    #expect(metadata.title == "Twitter Title")
  }

  @Test("Parse Open Graph image")
  func parseOpenGraphImage() async throws {
    let html = """
      <html>
      <head>
          <meta property="og:image" content="https://example.com/image.jpg">
      </head>
      <body></body>
      </html>
      """

    var baseMetadata = LinkMetadata()
    baseMetadata.originalURL = URL(string: "https://example.com")

    let metadata = await parser.parseHTMLMetadata(html: html, baseMetadata: baseMetadata)

    #expect(metadata.imageURL != nil)
    #expect(metadata.imageURL == URL(string: "https://example.com/image.jpg"))
  }

  @Test("Parse Twitter image")
  func parseTwitterImage() async throws {
    let html = """
      <html>
      <head>
          <meta name="twitter:image" content="https://example.com/twitter-image.png">
      </head>
      <body></body>
      </html>
      """

    var baseMetadata = LinkMetadata()
    baseMetadata.originalURL = URL(string: "https://example.com")

    let metadata = await parser.parseHTMLMetadata(html: html, baseMetadata: baseMetadata)

    #expect(metadata.imageURL != nil)
    #expect(metadata.imageURL == URL(string: "https://example.com/twitter-image.png"))
  }

  @Test("Parse complete metadata with multiple tags")
  func parseCompleteMetadata() async throws {
    let html = """
      <html>
      <head>
          <title>Original Title</title>
          <meta property="og:title" content="Complete Example">
          <meta property="og:image" content="https://example.com/og-image.jpg">
          <meta property="og:description" content="This is a description">
      </head>
      <body></body>
      </html>
      """

    var baseMetadata = LinkMetadata()
    baseMetadata.originalURL = URL(string: "https://example.com")

    let metadata = await parser.parseHTMLMetadata(html: html, baseMetadata: baseMetadata)

    #expect(metadata.title == "Complete Example")
    #expect(metadata.imageURL != nil)
    #expect(metadata.imageURL == URL(string: "https://example.com/og-image.jpg"))
  }

  @Test("Parse HTML with no metadata")
  func parseNoMetadata() async throws {
    let html = """
      <html>
      <head>
      </head>
      <body><p>No metadata here</p></body>
      </html>
      """

    var baseMetadata = LinkMetadata()
    baseMetadata.originalURL = URL(string: "https://example.com")

    let metadata = await parser.parseHTMLMetadata(html: html, baseMetadata: baseMetadata)

    #expect(metadata.title == nil)
    #expect(metadata.imageURL == nil)
    #expect(metadata.originalURL == URL(string: "https://example.com"))
  }

  @Test("Parse malformed HTML still extracts metadata")
  func parseMalformedHTML() async throws {
    let html = """
      <html><head><title>Malformed Title<meta property="og:title" content="Better Title"></head><body></body></html>
      """

    var baseMetadata = LinkMetadata()
    baseMetadata.originalURL = URL(string: "https://example.com")

    let metadata = await parser.parseHTMLMetadata(html: html, baseMetadata: baseMetadata)

    // Should still parse the Open Graph title
    #expect(metadata.title == "Better Title")
  }
}
