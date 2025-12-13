import Foundation
import Testing

@testable import LinkPresentationSwift

@Suite("Multiple Call Restriction Tests")
struct MultipleCallTests {

    @Test("Provider should throw error on second call with URL")
    func multipleCallsWithURL() async throws {
        let provider = MetadataProvider()

        // First call should succeed (might fail due to network, but shouldn't throw multiple call error)
        do {
            _ = try await provider.metadata(for: URL(string: "https://example.com")!)
        } catch {
            // Network error is acceptable for first call
        }

        // Second call should throw error due to multiple call restriction
        await #expect {
            try await provider.metadata(for: URL(string: "https://example.com")!)
        } throws: { error in
            return error is LinkPresentationSwift.Error
        }
    }

    @Test("Provider should throw error on second call with URLRequest")
    func multipleCallsWithURLRequest() async throws {
        let provider = MetadataProvider()

        // First call
        do {
            _ = try await provider.metadata(
                for: URLRequest(url: URL(string: "https://example.com")!)
            )
        } catch {
            // Network error is acceptable for first call
        }

        // Second call should throw error
        await #expect {
            try await provider.metadata(for: URLRequest(url: URL(string: "https://example.com")!))
        } throws: { error in
            return error is LinkPresentationSwift.Error
        }
    }

    @Test("Provider should throw error on mixed URL and URLRequest calls")
    func mixedCalls() async throws {
        let provider = MetadataProvider()

        // First call with URL
        do {
            _ = try await provider.metadata(for: URL(string: "https://example.com")!)
        } catch {
            // Network error is acceptable for first call
        }

        // Second call with URLRequest should throw error
        await #expect {
            try await provider.metadata(for: URLRequest(url: URL(string: "https://example.com")!))
        } throws: { error in
            return error is LinkPresentationSwift.Error
        }
    }
}
