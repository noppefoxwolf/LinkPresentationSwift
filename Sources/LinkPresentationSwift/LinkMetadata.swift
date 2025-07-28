import Foundation

public struct LinkMetadata: Sendable {
    public var url: URL?
    public var originalURL: URL?
    public var title: String?
    public var summary: String?
    public var siteName: String?
    public var image: Image?
}

