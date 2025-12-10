import Foundation
import CoreTransferable

public struct LinkMetadata: Sendable {
    public init(
        url: URL? = nil,
        originalURL: URL? = nil,
        title: String? = nil,
        iconProvider: (any Transferable)? = nil,
        imageProvider: (any Transferable)? = nil,
        remoteVideoURL: URL? = nil,
        videoProvider: (any Transferable)? = nil
    ) {
        self.url = url
        self.originalURL = originalURL
        self.title = title
        self.iconProvider = iconProvider
        self.imageProvider = imageProvider
        self.remoteVideoURL = remoteVideoURL
        self.videoProvider = videoProvider
    }
    
    // The URL that returned the metadata, taking server-side redirects into account.
    public var url: URL?
    
    // The original URL of the metadata request.
    public var originalURL: URL?
    
    // A representative title for the URL.
    public var title: String?
    
    // An object that retrieves data corresponding to a representative icon for the URL.
    public var iconProvider: (any Transferable)?
    
    // An object that retrieves data corresponding to a representative image for the URL.
    public var imageProvider: (any Transferable)?
    
    // A remote URL corresponding to a representative video for the URL.
    public var remoteVideoURL: URL?
    
    // An object that retrieves data corresponding to a representative video for the URL.
    public var videoProvider: (any Transferable)?
}
