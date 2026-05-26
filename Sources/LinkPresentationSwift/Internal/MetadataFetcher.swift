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
    private let session: URLSession
    private let maxHTMLBytes: Int
    private let scanInterval: Int

    init(
        session: URLSession = .shared,
        maxHTMLBytes: Int = 128 * 1024,
        scanInterval: Int = 2 * 1024
    ) {
        self.session = session
        self.maxHTMLBytes = maxHTMLBytes
        self.scanInterval = scanInterval
    }

    /// Fetches HTML content using URLSession with comprehensive validation.
    ///
    /// Performs network request, validates HTTP status codes, ensures UTF-8 encoding,
    /// and handles URL redirects properly. Throws descriptive errors for all failure cases.
    func fetchHTML(for request: URLRequest) async throws -> (html: String, finalURL: URL) {
        let response: URLResponse
        let bytes: URLSession.AsyncBytes

        do {
            (bytes, response) = try await session.bytes(for: request)
        } catch {
            throw Error(
                errorCode: .metadataFetchFailed,
                reason: "Network request failed",
                underlyingError: error
            )
        }

        // Validate HTTP response status (200-299 range)
        guard let httpResponse = response as? HTTPURLResponse,
            200...299 ~= httpResponse.statusCode
        else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw Error(
                errorCode: .metadataFetchFailed,
                reason: "Unexpected HTTP status: \(status)"
            )
        }

        // Determine final URL after potential redirects, fallback to original
        guard let finalURL = response.url ?? request.url else {
            throw Error(
                errorCode: .metadataFetchFailed,
                reason: "Response did not contain a final URL"
            )
        }

        let data: Data
        do {
            data = try await collectHTMLPrefix(from: bytes)
        } catch {
            throw Error(
                errorCode: .metadataFetchFailed,
                reason: "Network request failed",
                underlyingError: error
            )
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw Error(
                errorCode: .metadataFetchFailed,
                reason: "Response was not valid UTF-8"
            )
        }

        return (html: html, finalURL: finalURL)
    }

    private func collectHTMLPrefix(from bytes: URLSession.AsyncBytes) async throws -> Data {
        var data = Data()
        data.reserveCapacity(min(maxHTMLBytes, scanInterval * 2))

        for try await byte in bytes {
            data.append(byte)

            if data.count >= maxHTMLBytes {
                break
            }

            guard data.count % scanInterval == 0 else { continue }
            if shouldStopReading(data: data) {
                break
            }
        }

        return data
    }

    private func shouldStopReading(data: Data) -> Bool {
        guard let html = String(data: data, encoding: .utf8) else {
            return false
        }

        let lowercasedHTML = html.lowercased()
        if lowercasedHTML.contains("</head>") {
            return true
        }

        return lowercasedHTML.contains("og:title")
            && lowercasedHTML.contains("og:image")
            && (
                lowercasedHTML.contains("og:video")
                    || lowercasedHTML.contains("twitter:player")
                    || lowercasedHTML.contains("og:video:url")
                    || lowercasedHTML.contains("og:video:secure_url")
                    || lowercasedHTML.contains("twitter:player:stream")
            )
    }
}
