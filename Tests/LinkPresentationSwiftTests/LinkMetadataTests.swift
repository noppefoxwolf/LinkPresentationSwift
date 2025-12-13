import Foundation
import Testing

@testable import LinkPresentationSwift

@Suite("LinkMetadata Tests")
struct LinkMetadataTests {

    @Test("LinkMetadata initialization with all parameters")
    func initializationWithAllParameters() async throws {
        let url = URL(string: "https://example.com")
        let originalURL = URL(string: "https://original.com")
        let iconURL = URL(string: "https://example.com/icon.ico")
        let imageURL = URL(string: "https://example.com/image.jpg")
        let remoteVideoURL = URL(string: "https://example.com/video.mp4")

        let metadata = LinkMetadata(
            originalURL: originalURL,
            url: url,
            title: "Test Title",
            iconURL: iconURL,
            imageURL: imageURL,
            remoteVideoURL: remoteVideoURL
        )

        #expect(metadata.url == url)
        #expect(metadata.originalURL == originalURL)
        #expect(metadata.title == "Test Title")
        #expect(metadata.iconURL == iconURL)
        #expect(metadata.imageURL == imageURL)
        #expect(metadata.remoteVideoURL == remoteVideoURL)
    }

    @Test("LinkMetadata default initialization")
    func defaultInitialization() async throws {
        let metadata = LinkMetadata()

        #expect(metadata.url == nil)
        #expect(metadata.originalURL == nil)
        #expect(metadata.title == nil)
        #expect(metadata.iconURL == nil)
        #expect(metadata.imageURL == nil)
        #expect(metadata.remoteVideoURL == nil)
    }

    @Test("LinkMetadata properties are mutable")
    func propertiesAreMutable() async throws {
        var metadata = LinkMetadata()

        let url = URL(string: "https://example.com")
        metadata.url = url
        #expect(metadata.url == url)

        metadata.title = "New Title"
        #expect(metadata.title == "New Title")

        let imageURL = URL(string: "https://example.com/image.jpg")
        metadata.imageURL = imageURL
        #expect(metadata.imageURL == imageURL)
    }
}
