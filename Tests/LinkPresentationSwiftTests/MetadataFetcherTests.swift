import Foundation
import Testing

@testable import LinkPresentationSwift

@Suite("Metadata Fetcher Tests")
struct MetadataFetcherTests {
    let fetcher = MetadataFetcher()

    @Test("Fetch HTML from valid URL", .timeLimit(.minutes(1)))
    func fetchHTMLFromValidURL() async throws {
        let url = URL(string: "https://httpbin.org/status/200")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            forHTTPHeaderField: "User-Agent"
        )

        let (html, finalURL) = try await fetcher.fetchHTML(for: request)

        #expect(!html.isEmpty)
        #expect(finalURL.host == url.host)
    }

    @Test("Fetch HTML from invalid URL should throw error", .timeLimit(.minutes(1)))
    func fetchHTMLFromInvalidURL() async throws {
        let url = URL(string: "https://this-domain-should-not-exist-12345.com")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0

        await #expect {
            try await fetcher.fetchHTML(for: request)
        } throws: { error in
            return error is LinkPresentationSwift.Error || error is URLError
        }
    }

    @Test("Fetch HTML with 404 response should throw error", .timeLimit(.minutes(1)))
    func fetchHTMLWith404Response() async throws {
        let url = URL(string: "https://httpbin.org/status/404")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0

        await #expect {
            try await fetcher.fetchHTML(for: request)
        } throws: { error in
            if let lpError = error as? LinkPresentationSwift.Error {
                return lpError.errorCode == .metadataFetchFailed
            }
            return false
        }
    }

    @Test("Fetch HTML with redirect", .timeLimit(.minutes(1)))
    func fetchHTMLWithRedirect() async throws {
        let url = URL(string: "https://httpbin.org/status/200")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0

        let (html, finalURL) = try await fetcher.fetchHTML(for: request)

        #expect(!html.isEmpty)
        #expect(finalURL.host == url.host)
    }

    @Test("Fetch HTML timeout should throw error", .timeLimit(.minutes(1)))
    func fetchHTMLTimeout() async throws {
        let url = URL(string: "https://httpbin.org/delay/5")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.0

        await #expect {
            try await fetcher.fetchHTML(for: request)
        } throws: { error in
            return error is URLError || error is LinkPresentationSwift.Error
        }
    }

    @Test("Fetch HTML includes user agent", .timeLimit(.minutes(1)))
    func fetchHTMLUserAgent() async throws {
        let url = URL(string: "https://httpbin.org/status/200")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        request.setValue("Custom-User-Agent", forHTTPHeaderField: "User-Agent")

        let (html, _) = try await fetcher.fetchHTML(for: request)

        #expect(!html.isEmpty)
    }

    @Test
    func nicovideo() async throws {
        let url = URL(string: "https://www.nicovideo.jp/watch/sm44611089")!
        let provider = MetadataProvider()
        try await provider.metadata(for: url)
    }

    @Test
    func fedibird() async throws {
        let url = URL(string: "https://fedibird.com/@yamako/115711788135712894")!
        let provider = MetadataProvider()
        let metadata = try await provider.metadata(for: url)
        print(metadata)
    }

}
