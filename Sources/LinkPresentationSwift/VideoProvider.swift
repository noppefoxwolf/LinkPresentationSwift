import Foundation
import CoreTransferable

/// Provider for video data with optional pre-fetching support.
/// 
/// VideoProvider handles video content downloading with security validation
/// and supports both immediate data access (when pre-fetched) and on-demand loading.
public struct VideoProvider: Transferable, Sendable {
    /// The URL of the video resource
    public let url: URL
    
    /// Pre-fetched video data (when shouldFetchSubresources = true)
    private let videoData: Data?
    
    /// Creates a VideoProvider with URL reference only.
    /// Video data will be downloaded when loadVideoData() is called.
    ///
    /// - Parameter url: The URL of the video resource
    public init(url: URL) {
        self.url = url
        self.videoData = nil
    }
    
    /// Creates a VideoProvider with pre-fetched data.
    /// This initializer is used internally when shouldFetchSubresources = true.
    ///
    /// - Parameters:
    ///   - url: The URL of the video resource  
    ///   - data: Pre-fetched video data
    internal init(url: URL, data: Data) {
        self.url = url
        self.videoData = data
    }
    
    /// Loads video data asynchronously.
    ///
    /// Returns immediately if data was pre-fetched during metadata parsing.
    /// Otherwise downloads the video with security validation.
    ///
    /// - Returns: Video data as Data
    /// - Throws: LinkPresentationSwift.Error if download fails or security validation fails
    public func loadVideoData() async throws -> Data {
        // Return pre-fetched data immediately if available
        if let cachedData = videoData {
            return cachedData
        }
        
        // Download video on-demand with security validation
        return try await downloadVideoSecurely(from: url)
    }
    
    /// Downloads video data with comprehensive security validation.
    ///
    /// Enforces HTTPS, size limits, and basic video format validation.
    ///
    /// - Parameter url: The video URL to download from
    /// - Returns: Downloaded video data
    /// - Throws: LinkPresentationSwift.Error for security or network failures
    private func downloadVideoSecurely(from url: URL) async throws -> Data {
        // Security: Only allow HTTPS URLs
        guard url.scheme == "https" else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        // Create secure URLRequest
        var request = URLRequest(url: url)
        request.setValue("LinkPresentationSwift/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30.0
        request.cachePolicy = .useProtocolCachePolicy
        
        // Download video data
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        // Security: Enforce size limit (50MB for videos)
        guard data.count <= 50_000_000 else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        // Validate video format (basic check)
        guard isValidVideoData(data) else {
            throw Error(errorCode: .metadataFetchFailed)
        }
        
        return data
    }
    
    /// Validates video data format by checking file signatures.
    ///
    /// Supports common video formats: MP4, WebM, AVI, MOV, WMV
    ///
    /// - Parameter data: Video data to validate
    /// - Returns: true if data appears to be a valid video format
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
        
        // MOV (QuickTime)
        if header[4...7] == [0x66, 0x74, 0x79, 0x70] &&
           (header[8...11] == [0x71, 0x74, 0x20, 0x20] || // "qt  "
            header[8...11] == [0x6D, 0x6F, 0x6F, 0x76]) { // "moov"
            return true
        }
        
        // WMV/ASF
        if header.starts(with: [0x30, 0x26, 0xB2, 0x75, 0x8E, 0x66, 0xCF, 0x11]) {
            return true
        }
        
        return false
    }
    
    // MARK: - Transferable Conformance
    
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .video) { provider in
            try await provider.loadVideoData()
        }
    }
}