import Foundation
import CoreTransferable
import UniformTypeIdentifiers

public struct LinkMetadata: Sendable, Codable {
    public init(
        originalURL: URL? = nil,
        url: URL? = nil,
        title: String? = nil,
        iconURL: URL? = nil,
        imageURL: URL? = nil,
        remoteVideoURL: URL? = nil
    ) {
        self.originalURL = originalURL
        self.url = url
        self.title = title
        self.iconURL = iconURL
        self.imageURL = imageURL
        self.remoteVideoURL = remoteVideoURL
    }
    
    // The original URL of the metadata request.
    public var originalURL: URL?
    
    // The URL that returned the metadata, taking server-side redirects into account.
    public var url: URL?
    
    // A representative title for the URL.
    public var title: String?
    
    // A remote URL corresponding to a representative icon for the URL.
    public var iconURL: URL?
    
    // A remote URL corresponding to a representative image for the URL.
    public var imageURL: URL?
    
    // A remote URL corresponding to a representative video for the URL.
    public var remoteVideoURL: URL?
}

extension UTType {
    static var linkMetadata: UTType { UTType(exportedAs: "dev.noppe.linkmetadata") }
}

enum LinkMetadataError: Swift.Error {
    case noImageURL
}
