import Foundation
import CoreTransferable

/// Provider for image data associated with link metadata.
///
/// Handles secure downloading and caching of images from web URLs.
/// Supports both URL references and pre-fetched image data based on provider configuration.
/// Implements Transferable for drag & drop and sharing operations.
public struct ImageProvider: Transferable, Sendable {
    /// The source URL of the image.
    public let url: URL
    
    /// Pre-fetched image data when shouldFetchSubresources is enabled.
    private let imageData: Data?
    
    /// Creates an ImageProvider with URL reference only.
    ///
    /// Used when shouldFetchSubresources is disabled - provides URL without downloading image data.
    ///
    /// - Parameter url: The URL of the image resource
    public init(url: URL) {
        self.url = url
        self.imageData = nil
    }
    
    /// Creates an ImageProvider with both URL and pre-fetched data.
    ///
    /// Used when shouldFetchSubresources is enabled - contains actual image data for immediate use.
    ///
    /// - Parameters:
    ///   - url: The source URL of the image
    ///   - data: The downloaded image data
    internal init(url: URL, data: Data) {
        self.url = url
        self.imageData = data
    }
    
    /// Returns the image data, downloading if necessary.
    ///
    /// If image was pre-fetched during metadata extraction, returns cached data immediately.
    /// Otherwise, downloads the image from the URL with security validation.
    ///
    /// - Returns: The image data
    /// - Throws: Error if download fails or image is invalid
    public func loadImageData() async throws -> Data {
        // Return pre-fetched data if available
        if let cachedData = imageData {
            return cachedData
        }
        
        // Download image with security validation
        return try await downloadImage(from: url)
    }
    
    /// Downloads and validates image data from URL.
    ///
    /// Applies security constraints: HTTPS only, size limits, content validation.
    /// Uses URLSession with appropriate timeout and headers.
    private func downloadImage(from url: URL) async throws -> Data {
        // Security: Only allow HTTPS URLs for image downloads
        guard url.scheme == "https" else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        // Configure secure request for image download
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (compatible; LinkPresentationSwift)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        request.cachePolicy = .returnCacheDataElseLoad
        
        let session = URLSession.shared
        let (data, response) = try await session.data(for: request)
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        // Validate image size constraints (max 10MB)
        guard data.count <= 10_000_000 else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        // Basic validation that data appears to be an image
        guard isValidImageData(data) else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        return data
    }
    
    /// Validates that data appears to be valid image content.
    ///
    /// Checks for common image file signatures to prevent processing non-image data.
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
    
    // MARK: - Transferable Conformance
    
    /// Transfer representation for drag & drop and sharing operations.
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .data) { provider in
            try await provider.loadImageData()
        }
    }
}