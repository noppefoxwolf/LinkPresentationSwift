import Foundation
import LinkPresentationSwift
import Testing

@Suite("URL Validation Tests")
struct URLValidationTests {

    @Test("Invalid scheme should throw validation error")
    func invalidScheme() async throws {
        let provider = MetadataProvider()
        let url = URL(string: "ftp://example.com")!

        await #expect {
            try await provider.metadata(for: url)
        } throws: { error in
            error is LinkPresentationSwift.Error
        }
    }

    @Test("Missing scheme should throw validation error")
    func missingScheme() async throws {
        let provider = MetadataProvider()
        let url = URL(string: "example.com")!

        await #expect {
            try await provider.metadata(for: url)
        } throws: { error in
            error is LinkPresentationSwift.Error
        }
    }

    @Test("Empty host should throw validation error")
    func emptyHost() async throws {
        let provider = MetadataProvider()
        let url = URL(string: "https://")!

        await #expect {
            try await provider.metadata(for: url)
        } throws: { error in
            error is LinkPresentationSwift.Error
        }
    }

    @Test("URLRequest with invalid URL should throw validation error")
    func urlRequestWithInvalidURL() async throws {
        let provider = MetadataProvider()
        let url = URL(string: "ftp://example.com")!
        let request = URLRequest(url: url)

        await #expect {
            try await provider.metadata(for: request)
        } throws: { error in
            error is LinkPresentationSwift.Error
        }
    }
}
