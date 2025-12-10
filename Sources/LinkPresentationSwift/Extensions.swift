import Foundation

// MARK: - Modern Error Handling Extensions

public extension Error {
    /// Creates a domain-specific error for multiple metadata fetch attempts.
    ///
    /// Provides semantic meaning to prevent confusion with generic fetch failures.
    /// Should be used when startFetchingMetadata is called multiple times on the same provider.
    static func multipleCalls() -> LinkPresentationSwift.Error {
        LinkPresentationSwift.Error(errorCode: .metadataFetchFailed)
    }
    
    /// Creates a domain-specific error for network timeout conditions.
    ///
    /// Distinguishes timeout errors from other network failures for better error handling.
    static func timeout() -> LinkPresentationSwift.Error {
        LinkPresentationSwift.Error(errorCode: .metadataFetchTimedOut)
    }
    
    /// Creates a domain-specific error for URL validation failures.
    ///
    /// Used when URLs are malformed, use unsupported schemes, or are otherwise invalid.
    static func invalidURL() -> LinkPresentationSwift.Error {
        LinkPresentationSwift.Error(errorCode: .metadataFetchFailed)
    }
}

// MARK: - Result Type Extensions for Error Mapping

public extension Result where Failure == Swift.Error {
    /// Maps generic network errors to domain-specific LinkPresentationSwift errors.
    ///
    /// Transforms URLError cases into semantically meaningful errors for better
    /// error handling and user experience. Preserves success cases unchanged.
    func mapNetworkError() -> Result<Success, LinkPresentationSwift.Error> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    return .failure(.timeout())
                case .unsupportedURL, .badURL:
                    return .failure(.invalidURL())
                default:
                    return .failure(LinkPresentationSwift.Error(errorCode: .metadataFetchFailed))
                }
            }
            return .failure(LinkPresentationSwift.Error(errorCode: .metadataFetchFailed))
        }
    }
}

// MARK: - URLRequest Builder Pattern

public extension URLRequest {
    /// Creates a URLRequest optimized for metadata fetching with modern browser headers.
    ///
    /// Applies best practices for web scraping including realistic User-Agent,
    /// appropriate Accept headers, and compression support for improved compatibility
    /// with web servers and CDNs.
    ///
    /// - Parameters:
    ///   - url: The target URL for metadata fetching
    ///   - timeout: Network timeout in seconds (default: 30.0)
    /// - Returns: Configured URLRequest ready for metadata fetching
    static func metadataRequest(url: URL, timeout: TimeInterval = 30.0) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        
        // Modern browser User-Agent for better compatibility
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko)", 
                        forHTTPHeaderField: "User-Agent")
        
        // Accept HTML and related content types with quality preferences
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", 
                        forHTTPHeaderField: "Accept")
        
        // Enable compression for faster downloads
        request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        
        return request
    }
}