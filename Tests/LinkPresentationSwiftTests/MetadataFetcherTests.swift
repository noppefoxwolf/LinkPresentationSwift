import Foundation
import Testing

@testable import LinkPresentationSwift

@Suite("Metadata Fetcher Tests", .serialized)
struct MetadataFetcherTests {
    @Test("Stops reading after head closes")
    func stopsReadingAfterHeadCloses() async throws {
        let bodyTail = "BODY_TAIL_SHOULD_NOT_BE_READ"
        let html = """
            <html>
            <head>
                <title>Head Title</title>
            </head>
            <body>
            \(String(repeating: "<p>Ignored body content</p>", count: 1_000))
            \(bodyTail)
            </body>
            </html>
            """

        let fetcher = MetadataFetcher(
            session: streamingSession(body: html),
            maxHTMLBytes: 128 * 1024,
            scanInterval: 64
        )

        let request = URLRequest(url: URL(string: "https://example.com/head")!)
        let result = try await fetcher.fetchHTML(for: request)

        #expect(result.html.contains("<title>Head Title</title>"))
        #expect(!result.html.contains(bodyTail))
    }

    @Test("Stops reading when Open Graph metadata is satisfied")
    func stopsReadingWhenOpenGraphMetadataIsSatisfied() async throws {
        let bodyTail = "OG_BODY_TAIL_SHOULD_NOT_BE_READ"
        let html = """
            <html>
            <head>
                <meta property="og:title" content="OG Title">
                <meta property="og:image" content="https://example.com/image.jpg">
                <meta property="og:video" content="https://example.com/video.mp4">
            \(String(repeating: "<meta name=\"unused\" content=\"ignored\">", count: 1_000))
            \(bodyTail)
            </head>
            </html>
            """

        let fetcher = MetadataFetcher(
            session: streamingSession(body: html),
            maxHTMLBytes: 128 * 1024,
            scanInterval: 64
        )

        let request = URLRequest(url: URL(string: "https://example.com/og")!)
        let result = try await fetcher.fetchHTML(for: request)

        #expect(result.html.contains("og:title"))
        #expect(result.html.contains("og:image"))
        #expect(result.html.contains("og:video"))
        #expect(!result.html.contains(bodyTail))
    }

    @Test("Stops reading at maximum HTML byte count")
    func stopsReadingAtMaximumHTMLByteCount() async throws {
        let html = String(repeating: "a", count: 10_000)
        let fetcher = MetadataFetcher(
            session: streamingSession(body: html),
            maxHTMLBytes: 128,
            scanInterval: 64
        )

        let request = URLRequest(url: URL(string: "https://example.com/large")!)
        let result = try await fetcher.fetchHTML(for: request)

        #expect(result.html.utf8.count == 128)
    }

    private func streamingSession(body: String) -> URLSession {
        StreamingURLProtocol.body = Data(body.utf8)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StreamingURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class StreamingURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var body = Data()

    private var loadingTask: Task<Void, Never>?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else { return }

        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/html; charset=utf-8"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        let body = Self.body
        loadingTask = Task {
            var index = body.startIndex
            while index < body.endIndex, !Task.isCancelled {
                let nextIndex = body.index(index, offsetBy: 16, limitedBy: body.endIndex)
                    ?? body.endIndex
                client?.urlProtocol(self, didLoad: body[index..<nextIndex])
                index = nextIndex
                try? await Task.sleep(for: .milliseconds(1))
            }

            if !Task.isCancelled {
                client?.urlProtocolDidFinishLoading(self)
            }
        }
    }

    override func stopLoading() {
        loadingTask?.cancel()
    }
}
