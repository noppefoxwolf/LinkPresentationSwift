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
    func parseHTMLMetadata(html: String, baseMetadata: LinkMetadata) async -> LinkMetadata
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
    func parseHTMLMetadata(html: String, baseMetadata: LinkMetadata) async -> LinkMetadata {
        var metadata = baseMetadata

        // First extract meta tags (which have higher priority)
        await extractMetaTags(from: html, into: &metadata)

        // Then extract title from HTML as fallback if no OG/Twitter title was found
        if metadata.title == nil {
            metadata.title = extractTitle(from: html)
        }

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

    /// Processes meta tags and link tags using functional programming patterns.
    ///
    /// Transforms raw regex matches into structured MetaTag objects,
    /// then applies type-safe processing for each metadata type.
    /// Downloads images if shouldFetchSubresources is enabled.
    private func extractMetaTags(from html: String, into metadata: inout LinkMetadata) async {
        // Support any attribute order by first grabbing the entire tag,
        // then parsing attributes individually.
        let metaTagRegex = /<meta\b[^>]*>/

        for match in html.matches(of: metaTagRegex) {
            let tag = String(match.0)
            let attributes = parseAttributes(from: tag)
            guard let metaTag = MetaTag(attributes: attributes) else { continue }
            await processMetaTag(metaTag, into: &metadata)

            // Short-circuit once the key meta fields are filled.
            if metadata.isMetaSatisfied { break }
        }

        // Extract link tags for favicon/icon (attribute order agnostic)
        let linkTagRegex = /<link\b[^>]*>/

        for match in html.matches(of: linkTagRegex) {
            let tag = String(match.0)
            let attributes = parseAttributes(from: tag)

            guard let relValue = attributes["rel"], let href = attributes["href"],
                metadata.iconURL == nil
            else { continue }

            let relTokens = relValue
                .split(whereSeparator: { $0.isWhitespace })
                .map { $0.lowercased() }

            let isIcon = relTokens.contains("icon") || relTokens.contains("shortcut") ||
                relTokens.contains("apple-touch-icon")

            if isIcon, let iconURL = URL(string: href) {
                metadata.iconURL = iconURL
                break
            }
        }
    }

    /// Processes individual meta tags based on their semantic type.
    ///
    /// Uses enum pattern matching for type-safe metadata assignment,
    /// prioritizing Open Graph and Twitter Card data over standard meta tags.
    /// Downloads image/video data if shouldFetchSubresources is enabled.
    private func processMetaTag(_ metaTag: MetaTag, into metadata: inout LinkMetadata) async {
        switch metaTag.type {
        case .title:
            if !metaTag.content.isEmpty {
                metadata.title = metaTag.content  // OG/Twitter titles take priority over HTML title
            }
        case .image:
            guard let imageURL = URL(string: metaTag.content),
                metadata.imageURL == nil
            else { break }  // First image wins

            metadata.imageURL = imageURL
        case .video:
            guard let videoURL = URL(string: metaTag.content),
                metadata.remoteVideoURL == nil
            else { break }  // First video wins

            metadata.remoteVideoURL = videoURL
        case .remoteVideoURL:
            guard let videoURL = URL(string: metaTag.content),
                metadata.remoteVideoURL == nil
            else { break }  // First remoteVideoURL wins
            metadata.remoteVideoURL = videoURL
        case .icon:
            guard let iconURL = URL(string: metaTag.content),
                metadata.iconURL == nil
            else { break }  // First icon wins
            metadata.iconURL = iconURL
        case .description:
            // Future enhancement: could extend LinkMetadata to include description
            break
        }
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

    /// Initializes a MetaTag from parsed HTML attributes.
    ///
    /// Accepts property/name/content in any order to better support real-world HTML.
    init?(attributes: [String: String]) {
        let property = attributes["property"]?.lowercased() ?? ""
        let name = attributes["name"]?.lowercased() ?? ""

        guard let content = attributes["content"],
            let type = MetaTagType.from(property: property, name: name)
        else { return nil }

        self.type = type
        self.content = content
    }
}

/// Semantic classification of meta tag types for structured processing.
///
/// Enables type-safe handling of different metadata categories using
/// Swift's enum pattern matching capabilities.
private enum MetaTagType {
    case title  // Page title (og:title, twitter:title)
    case image  // Featured image (og:image, twitter:image)
    case description  // Page description (og:description, description, twitter:description)
    case video  // Video content (og:video, twitter:player)
    case remoteVideoURL  // Direct video URL (og:video:url, twitter:player:stream)
    case icon  // Page icon (og:icon, apple-touch-icon, icon)

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
        case ("og:icon", _), (_, "apple-touch-icon"):
            return .icon
        default:
            return nil  // Unsupported meta tag type
        }
    }
}

// MARK: - Attribute Parsing

/// Parses key/value HTML attributes from a tag string.
///
/// Designed to be attribute-order agnostic and tolerant of both single and
/// double quotes.
private func parseAttributes(from tag: String) -> [String: String] {
    let attributeRegex = /([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*["']([^"']*)["']/
    var attributes: [String: String] = [:]

    for match in tag.matches(of: attributeRegex) {
        let name = match.1.lowercased()
        let value = String(match.2)
        // Only keep attributes we might use to reduce allocations.
        switch name {
        case "property", "name", "content", "rel", "href":
            attributes[name] = value
        default:
            continue
        }
    }

    return attributes
}

// MARK: - Convenience

private extension LinkMetadata {
    /// Whether all meta-derived fields we care about have been filled.
    var isMetaSatisfied: Bool {
        imageURL != nil && title != nil && remoteVideoURL != nil
    }
}
