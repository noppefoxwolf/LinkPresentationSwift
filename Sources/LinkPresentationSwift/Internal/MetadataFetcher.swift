import Foundation

/// Protocol defining HTTP fetching capabilities for metadata extraction.
internal protocol MetadataFetcherProtocol: Sendable {
    /// Fetches HTML content from a URLRequest and returns both content and final URL.
    ///
    /// - Parameter request: URLRequest with headers, timeout, and other configurations
    /// - Returns: Tuple containing HTML string and the final URL after redirects
    /// - Throws: Error if network request fails, non-2xx response, or invalid content
    func fetchHTML(for request: URLRequest) async throws -> (html: String, finalURL: URL)
}

/// HTTP client for fetching HTML content with validation and error handling.
///
/// Handles network requests, HTTP status validation, content encoding,
/// and provides proper error propagation for metadata fetching operations.
internal final class MetadataFetcher: MetadataFetcherProtocol, Sendable {

    /// Fetches HTML content using URLSession with comprehensive validation.
    ///
    /// Performs network request, validates HTTP status codes, ensures UTF-8 encoding,
    /// and handles URL redirects properly. Throws descriptive errors for all failure cases.
    func fetchHTML(for request: URLRequest) async throws -> (html: String, finalURL: URL) {
        let session = URLSession.shared

        // Execute network request with provided URLRequest configuration
        let (data, response) = try await session.data(for: request)

        // Validate HTTP response status (200-299 range)
        guard let httpResponse = response as? HTTPURLResponse,
            200...299 ~= httpResponse.statusCode
        else {
            throw Error(errorCode: .metadataFetchFailed)
        }

        // Convert response data to UTF-8 string
        guard let html = String(data: data, encoding: .utf8) else {
            throw Error(errorCode: .metadataFetchFailed)
        }

        // Determine final URL after potential redirects, fallback to original
        guard let finalURL = response.url ?? request.url else {
            throw Error(errorCode: .metadataFetchFailed)
        }

        return (html: html, finalURL: finalURL)
    }
}
