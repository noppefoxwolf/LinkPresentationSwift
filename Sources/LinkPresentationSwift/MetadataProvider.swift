import Foundation

/// A provider that fetches metadata from web URLs using async/await patterns.
///
/// Extracts Open Graph, Twitter Card, and standard HTML metadata from web pages.
/// Implements single-use policy to match Apple's LinkPresentation framework behavior.
/// Uses modern Swift concurrency and actor-based thread safety.
public struct MetadataProvider: Sendable {
    private let fetcher: any MetadataFetcherProtocol
    private let parser: any HTMLParserProtocol
    private let callTracker: CallTracker

    /// Creates a new MetadataProvider with default implementations.
    ///
    /// Uses secure HTTP client and modern HTML parser with Swift Regex support.
    public init() {
        self.fetcher = MetadataFetcher()
        self.parser = HTMLParser()
        self.callTracker = CallTracker()
    }

    /// Creates a MetadataProvider with custom implementations for testing.
    ///
    /// Allows dependency injection for unit testing with mock implementations.
    internal init(fetcher: any MetadataFetcherProtocol, parser: any HTMLParserProtocol) {
        self.fetcher = fetcher
        self.parser = parser
        self.callTracker = CallTracker()
    }

    @discardableResult
    public func metadata(for url: URL) async throws -> LinkMetadata {
        // Validate URL before processing
        try validateURL(url)

        // Use modern URLRequest builder
        let request = URLRequest.metadataRequest(url: url, timeout: timeout)
        return try await metadata(for: request)
    }

    @discardableResult
    public func metadata(for request: URLRequest) async throws -> LinkMetadata {
        try await callTracker.recordCall()

        // Validate that the request has a URL
        guard let originalURL = request.url else {
            throw Error(
                errorCode: .metadataFetchFailed,
                reason: "URLRequest is missing a URL."
            )
        }

        // Validate URL before processing
        try validateURL(originalURL)

        // Use async/await pattern with proper error handling
        do {
            let (html, finalURL) = try await fetcher.fetchHTML(for: request)

            var metadata = LinkMetadata()
            metadata.originalURL = originalURL
            metadata.url = finalURL

            return await parser.parseHTMLMetadata(html: html, baseMetadata: metadata)
        } catch {
            throw error
        }
    }

    /// The timeout interval for network requests in seconds.
    ///
    /// Applies to both HTML fetching and image downloading operations.
    /// If a request takes longer than this timeout, it will fail with a timeout error.
    /// Default is 30 seconds.
    public var timeout: TimeInterval = 30

    // MARK: - Private Methods

    /// Validates URL for metadata fetching
    ///
    /// Ensures URL has proper scheme (http/https) and host component.
    /// Throws invalidURL error for malformed or unsupported URLs.
    private func validateURL(_ url: URL) throws {
        // Check for valid scheme
        guard let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            throw Error.invalidURL()
        }

        // Check for valid host
        guard url.host != nil,
            !url.host!.isEmpty
        else {
            throw Error.invalidURL()
        }
    }
}
