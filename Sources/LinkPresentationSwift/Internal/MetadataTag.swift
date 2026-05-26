import Foundation

internal enum MetadataTag {
    case title
    case image
    case description
    case video
    case remoteVideoURL
    case icon

    private static let propertyTypes: [String: MetadataTag] = [
        "og:title": .title,
        "og:image": .image,
        "og:description": .description,
        "og:video": .video,
        "og:video:url": .remoteVideoURL,
        "og:video:secure_url": .remoteVideoURL,
        "og:icon": .icon,
    ]

    private static let nameTypes: [String: MetadataTag] = [
        "twitter:title": .title,
        "twitter:image": .image,
        "description": .description,
        "twitter:description": .description,
        "twitter:player": .video,
        "twitter:player:stream": .remoteVideoURL,
        "apple-touch-icon": .icon,
    ]

    static let requiredEarlyStopTags: Set<String> = [
        "og:title",
        "og:image",
    ]

    static let videoEarlyStopTags: Set<String> = [
        "og:video",
        "og:video:url",
        "og:video:secure_url",
        "twitter:player",
        "twitter:player:stream",
    ]

    static func from(property: String, name: String) -> MetadataTag? {
        if let type = propertyTypes[property] {
            return type
        }

        return nameTypes[name]
    }
}
