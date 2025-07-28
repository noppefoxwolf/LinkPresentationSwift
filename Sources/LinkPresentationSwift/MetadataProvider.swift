import LinkPresentation

public final class MetadataProvider: Sendable {
    
    private let session: URLSession
    
    static var defaultUserAgent: String {
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
    }
    
    public init(_ session: URLSession = .shared) {
        self.session = session
    }
    
    public func startFetchingMetadata(
        for url: URL
    ) async throws(LinkPresentationError) -> LinkMetadata {
        var request = URLRequest(url: url)
        request.setValue(Self.defaultUserAgent, forHTTPHeaderField: "User-Agent")
        return try await startFetchingMetadata(for: request)
    }
    
    public func startFetchingMetadata(
        for request: URLRequest
    ) async throws(LinkPresentationError) -> LinkMetadata {
        do {
            let (data, response) = try await session.data(for: request)
            let metadata = try extract(request: request, data: data, response: response)
            return metadata
        } catch let error as LinkPresentationError {
            throw error
        } catch let error as URLError {
            throw error.code == .timedOut ? .timedOut : .failed
        } catch is CancellationError {
            throw .cancelled
        } catch {
            throw LinkPresentationError.unknown
        }
    }
    
    public func cancel() {
        session.invalidateAndCancel()
    }
    
    public var timeout: TimeInterval {
        get { session.configuration.timeoutIntervalForRequest }
        set { session.configuration.timeoutIntervalForRequest = newValue }
    }
    
    // Private
    
    func extract(
        request: URLRequest,
        data: Data,
        response: URLResponse
    ) throws(LinkPresentationError) -> LinkMetadata {
        guard let html = String(data: data, encoding: .utf8) else {
            throw LinkPresentationError.unknown
        }
        return LinkMetadata(
            url: response.url,
            originalURL: request.url,
            title: extractOGPProperty("title", from: html) ?? extractHTMLTitle(from: html),
            summary: extractOGPProperty("description", from: html) ?? extractMetaDescription(from: html),
            siteName: extractOGPProperty("site_name", from: html) ?? extractSiteName(from: response.url),
            image: extractOGPImageURL(from: html, baseURL: response.url).map(Image.init(remoteURL:))
        )
    }
    
    // MARK: - OGP Property Extraction
    
    func extractOGPProperty(_ property: String, from html: String) -> String? {
        let patterns = [
            #"<meta[^>]*property="og:\#(property)"[^>]*content="([^"]*)"[^>]*>"#,
            #"<meta[^>]*content="([^"]*)"[^>]*property="og:\#(property)"[^>]*>"#
        ]
        
        for pattern in patterns {
            if let content = extractFirst(pattern: pattern, from: html, groupIndex: property == "title" ? 2 : 1) {
                let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanContent.isEmpty {
                    return cleanContent
                }
            }
        }
        
        return nil
    }
    
    func extractOGPImageURL(from html: String, baseURL: URL?) -> URL? {
        if let imageString = extractOGPProperty("image", from: html) {
            if let url = URL(string: imageString) {
                return url.scheme != nil ? url : URL(string: imageString, relativeTo: baseURL)
            }
        }
        
        // Fallback to other image meta tags
        let imagePatterns = [
            #"<meta[^>]*name="twitter:image"[^>]*content="([^"]*)"[^>]*>"#,
            #"<meta[^>]*property="twitter:image"[^>]*content="([^"]*)"[^>]*>"#,
            #"<link[^>]*rel="image_src"[^>]*href="([^"]*)"[^>]*>"#
        ]
        
        for pattern in imagePatterns {
            if let imageString = extractFirst(pattern: pattern, from: html) {
                if let url = URL(string: imageString) {
                    return url.scheme != nil ? url : URL(string: imageString, relativeTo: baseURL)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Fallback Extraction Methods
    
    func extractHTMLTitle(from html: String) -> String? {
        let patterns = [
            #"<title[^>]*>([^<]+)</title>"#,
            #"<h1[^>]*>([^<]+)</h1>"#
        ]
        
        for pattern in patterns {
            if let title = extractFirst(pattern: pattern, from: html) {
                let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanTitle.isEmpty {
                    return cleanTitle
                }
            }
        }
        
        return nil
    }
    
    func extractMetaDescription(from html: String) -> String? {
        let patterns = [
            #"<meta[^>]*name="description"[^>]*content="([^"]*)"[^>]*>"#,
            #"<meta[^>]*content="([^"]*)"[^>]*name="description"[^>]*>"#,
            #"<meta[^>]*name="twitter:description"[^>]*content="([^"]*)"[^>]*>"#
        ]
        
        for pattern in patterns {
            if let description = extractFirst(pattern: pattern, from: html) {
                let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanDescription.isEmpty {
                    return cleanDescription
                }
            }
        }
        
        return nil
    }
    
    func extractSiteName(from url: URL?) -> String? {
        if let host = url?.host {
            // Remove www. prefix and get domain name
            let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            
            // Extract main domain name (remove subdomains)
            let components = domain.components(separatedBy: ".")
            if components.count >= 2 {
                return components[components.count - 2].capitalized
            }
            
            return domain.capitalized
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    func extractFirst(pattern: String, from html: String, groupIndex: Int = 1) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        
        if let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           match.numberOfRanges > groupIndex,
           let range = Range(match.range(at: groupIndex), in: html) {
            return String(html[range])
        }
        
        return nil
    }

}
