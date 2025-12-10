import Foundation

/// Protocol defining HTML parsing capabilities for metadata extraction.
internal protocol HTMLParserProtocol: Sendable {
    /// Extracts metadata from HTML content and merges with base metadata.
    ///
    /// - Parameters:
    ///   - html: The HTML content to parse
    ///   - baseMetadata: Existing metadata to merge with (contains URLs)
    ///   - shouldFetchSubresources: Whether to download images and other subresources
    /// - Returns: Updated LinkMetadata with extracted information
    func parseHTMLMetadata(html: String, baseMetadata: LinkMetadata, shouldFetchSubresources: Bool) async -> LinkMetadata
}

/// Modern HTML parser using Swift Regex and functional programming patterns.
///
/// Extracts Open Graph, Twitter Card, and standard HTML meta information
/// from HTML content using thread-safe regex patterns and structured data types.
internal final class HTMLParser: HTMLParserProtocol, Sendable {
    
    /// Parses HTML content and extracts metadata using modern Swift patterns.
    ///
    /// Uses functional programming approach with separate extraction methods
    /// for different types of metadata (title, meta tags). Optionally downloads
    /// subresources like images based on shouldFetchSubresources parameter.
    func parseHTMLMetadata(html: String, baseMetadata: LinkMetadata, shouldFetchSubresources: Bool) async -> LinkMetadata {
        var metadata = baseMetadata
        
        // Extract page title using Swift Regex with named captures
        metadata.title = extractTitle(from: html)
        
        // Process meta tags using functional transformation pipeline
        await extractMetaTags(from: html, into: &metadata, shouldFetchSubresources: shouldFetchSubresources)
        
        return metadata
    }
    
    // MARK: - Private Methods
    
    /// Extracts the page title from HTML using modern Swift Regex.
    ///
    /// Uses named capture groups for better readability and thread-safe
    /// regex compilation within the method scope.
    private func extractTitle(from html: String) -> String? {
        // Swift Regex with named captures (compiled per-call for thread safety)
        let titleRegex = /<title[^>]*>(?<title>[^<]*)<\/title>/
        
        guard let titleMatch = html.firstMatch(of: titleRegex) else { return nil }
        
        let title = String(titleMatch.title).trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : title
    }
    
    /// Processes meta tags using functional programming patterns.
    ///
    /// Transforms raw regex matches into structured MetaTag objects,
    /// then applies type-safe processing for each metadata type.
    /// Downloads images if shouldFetchSubresources is enabled.
    private func extractMetaTags(from html: String, into metadata: inout LinkMetadata, shouldFetchSubresources: Bool) async {
        let metaRegex = /<meta[^>]*(?:property=["'](?<property>[^"']*)["']|name=["'](?<name>[^"']*)["'])[^>]*content=["'](?<content>[^"']*)["'][^>]*>/
        
        for match in html.matches(of: metaRegex) {
            guard let metaTag = MetaTag(match) else { continue }
            await processMetaTag(metaTag, into: &metadata, shouldFetchSubresources: shouldFetchSubresources)
        }
    }
    
    /// Processes individual meta tags based on their semantic type.
    ///
    /// Uses enum pattern matching for type-safe metadata assignment,
    /// prioritizing Open Graph and Twitter Card data over standard meta tags.
    /// Downloads image/video data if shouldFetchSubresources is enabled.
    private func processMetaTag(_ metaTag: MetaTag, into metadata: inout LinkMetadata, shouldFetchSubresources: Bool) async {
        switch metaTag.type {
        case .title:
            if !metaTag.content.isEmpty && metadata.title == nil {
                metadata.title = metaTag.content // OG/Twitter titles override HTML title - first wins
            }
        case .image:
            guard let imageURL = URL(string: metaTag.content),
                  metadata.imageProvider == nil else { break } // First image wins
            
            if shouldFetchSubresources {
                // Pre-fetch image data for immediate availability
                do {
                    let imageData = try await downloadImageSecurely(from: imageURL)
                    metadata.imageProvider = ImageProvider(url: imageURL, data: imageData)
                } catch {
                    // Fallback to URL-only provider if download fails
                    metadata.imageProvider = ImageProvider(url: imageURL)
                }
            } else {
                // URL reference only - no download
                metadata.imageProvider = ImageProvider(url: imageURL)
            }
        case .video:
            guard let videoURL = URL(string: metaTag.content), 
                  metadata.videoProvider == nil else { break } // First video wins
            
            if shouldFetchSubresources {
                // Pre-fetch video data for immediate availability
                do {
                    let videoData = try await downloadVideoSecurely(from: videoURL)
                    metadata.videoProvider = VideoProvider(url: videoURL, data: videoData)
                } catch {
                    // Fallback to URL-only provider if download fails
                    metadata.videoProvider = VideoProvider(url: videoURL)
                }
            } else {
                // URL reference only - no download
                metadata.videoProvider = VideoProvider(url: videoURL)
            }
        case .remoteVideoURL:
            guard let videoURL = URL(string: metaTag.content),
                  metadata.remoteVideoURL == nil else { break } // First remoteVideoURL wins
            metadata.remoteVideoURL = videoURL
        case .description:
            // Future enhancement: could extend LinkMetadata to include description
            break
        }
    }
    
    /// Downloads image data with security validation.
    ///
    /// Applies same security constraints as ImageProvider but integrated
    /// into the parsing process for efficient batch downloading.
    private func downloadImageSecurely(from url: URL) async throws -> Data {
        // Security: Only allow HTTPS URLs
        guard url.scheme == "https" else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        // Configure secure request
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (compatible; LinkPresentationSwift)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15  // Shorter timeout for subresource downloads
        request.cachePolicy = .returnCacheDataElseLoad
        
        let session = URLSession.shared
        let (data, response) = try await session.data(for: request)
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        // Validate image size (max 5MB for metadata parsing)
        guard data.count <= 5_000_000 else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        // Basic image validation
        guard isValidImageData(data) else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        return data
    }
    
    /// Validates image file signatures for security.
    private func isValidImageData(_ data: Data) -> Bool {
        guard data.count >= 8 else { return false }
        
        let header = data.prefix(8)
        
        // Check for common image file signatures
        if header.starts(with: [0xFF, 0xD8, 0xFF]) { return true }  // JPEG
        if header.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) { return true }  // PNG
        if header.starts(with: [0x47, 0x49, 0x46, 0x38]) { return true }  // GIF
        if header.starts(with: [0x52, 0x49, 0x46, 0x46]) && data.count > 12 { // WebP
            let webpHeader = data[8..<12]
            if webpHeader.starts(with: [0x57, 0x45, 0x42, 0x50]) { return true }
        }
        
        return false
    }
    
    /// Downloads video data with security validation.
    ///
    /// Similar to image downloading but with video-specific validation
    /// and appropriate size limits for video content.
    private func downloadVideoSecurely(from url: URL) async throws -> Data {
        // Security: Only allow HTTPS URLs
        guard url.scheme == "https" else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        // Configure secure request
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (compatible; LinkPresentationSwift)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30  // Longer timeout for video downloads
        request.cachePolicy = .returnCacheDataElseLoad
        
        let session = URLSession.shared
        let (data, response) = try await session.data(for: request)
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        // Validate video size (max 20MB for metadata parsing)
        guard data.count <= 20_000_000 else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        // Basic video validation
        guard isValidVideoData(data) else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        return data
    }
    
    /// Validates video file signatures for security.
    ///
    /// Checks common video format signatures to prevent processing
    /// of non-video content as video data.
    private func isValidVideoData(_ data: Data) -> Bool {
        guard data.count >= 12 else { return false }
        
        let header = Array(data.prefix(12))
        
        // MP4 (ftyp box)
        if header[4...7] == [0x66, 0x74, 0x79, 0x70] {
            return true
        }
        
        // WebM (EBML header)
        if header.starts(with: [0x1A, 0x45, 0xDF, 0xA3]) {
            return true
        }
        
        // AVI (RIFF...AVI)
        if header.starts(with: [0x52, 0x49, 0x46, 0x46]) && 
           header[8...11] == [0x41, 0x56, 0x49, 0x20] {
            return true
        }
        
        return false
    }
}

// MARK: - Supporting Types

/// Structured representation of an HTML meta tag with semantic typing.
///
/// Converts raw regex match data into a strongly-typed object that can be
/// processed using Swift's pattern matching and type system.
private struct MetaTag {
    let type: MetaTagType
    let content: String
    
    /// Initializes a MetaTag from a regex match result.
    ///
    /// Determines the semantic type based on property/name attributes
    /// and extracts the content value. Returns nil for unsupported tag types.
    init?(_ match: Regex<(Substring, property: Substring?, name: Substring?, content: Substring)>.Match) {
        let property = match.property?.lowercased() ?? ""
        let name = match.name?.lowercased() ?? ""
        let content = String(match.content)
        
        guard let type = MetaTagType.from(property: property, name: name) else { return nil }
        
        self.type = type
        self.content = content
    }
}

/// Semantic classification of meta tag types for structured processing.
///
/// Enables type-safe handling of different metadata categories using
/// Swift's enum pattern matching capabilities.
private enum MetaTagType {
    case title       // Page title (og:title, twitter:title)
    case image       // Featured image (og:image, twitter:image)  
    case description // Page description (og:description, description, twitter:description)
    case video       // Video content (og:video, twitter:player)
    case remoteVideoURL // Direct video URL (og:video:url, twitter:player:stream)
    
    /// Maps meta tag property/name attributes to semantic types.
    ///
    /// Prioritizes Open Graph and Twitter Card standards while supporting
    /// fallback to standard HTML meta tags.
    static func from(property: String, name: String) -> MetaTagType? {
        switch (property, name) {
        case ("og:title", _), (_, "twitter:title"):
            return .title
        case ("og:image", _), (_, "twitter:image"):
            return .image
        case ("og:description", _), (_, "description"), (_, "twitter:description"):
            return .description
        case ("og:video", _), (_, "twitter:player"):
            return .video
        case ("og:video:url", _), ("og:video:secure_url", _), (_, "twitter:player:stream"):
            return .remoteVideoURL
        default:
            return nil // Unsupported meta tag type
        }
    }
}
