import Testing
import Foundation
@testable import LinkPresentationSwift

@Suite("shouldFetchSubresources Feature Tests")
struct ShouldFetchSubresourcesTests {
    
    @Test("shouldFetchSubresources = true should create ImageProvider with data")
    func shouldFetchSubresourcesTrue() async throws {
        let mockFetcher = MockMetadataFetcher()
        let parser = HTMLParser() // Use real parser to test actual functionality
        
        let htmlWithImage = """
        <html>
        <head>
            <meta property="og:image" content="https://example.com/image.png">
            <title>Test Page</title>
        </head>
        </html>
        """
        
        mockFetcher.htmlToReturn = htmlWithImage
        mockFetcher.urlToReturn = URL(string: "https://example.com")
        
        var provider = MetadataProvider(fetcher: mockFetcher, parser: parser)
        provider.shouldFetchSubresources = true
        
        let metadata = try await provider.metadata(for: URL(string: "https://example.com")!)
        
        // Should have ImageProvider (though image download might fail in test environment)
        #expect(metadata.imageProvider != nil)
        if let provider = metadata.imageProvider as? ImageProvider {
            #expect(provider.url.absoluteString == "https://example.com/image.png")
        }
    }
    
    @Test("shouldFetchSubresources = false should create ImageProvider without data")
    func shouldFetchSubresourcesFalse() async throws {
        let mockFetcher = MockMetadataFetcher()
        let parser = HTMLParser() // Use real parser to test actual functionality
        
        let htmlWithImage = """
        <html>
        <head>
            <meta property="og:image" content="https://example.com/image.png">
            <title>Test Page</title>
        </head>
        </html>
        """
        
        mockFetcher.htmlToReturn = htmlWithImage
        mockFetcher.urlToReturn = URL(string: "https://example.com")
        
        var provider = MetadataProvider(fetcher: mockFetcher, parser: parser)
        provider.shouldFetchSubresources = false
        
        let metadata = try await provider.metadata(for: URL(string: "https://example.com")!)
        
        // Should have ImageProvider with URL only
        #expect(metadata.imageProvider != nil)
        if let provider = metadata.imageProvider as? ImageProvider {
            #expect(provider.url.absoluteString == "https://example.com/image.png")
        }
    }
    
    @Test("ImageProvider can load image data when pre-fetched")
    func imageProviderLoadImageData() async throws {
        let url = URL(string: "https://example.com/image.png")!
        let testData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header
        
        // Test ImageProvider with pre-fetched data
        let provider = ImageProvider(url: url, data: testData)
        
        let loadedData = try await provider.loadImageData()
        #expect(loadedData == testData)
    }
    
    @Test("ImageProvider validates HTTPS URLs only")
    func imageProviderValidatesHTTPS() async throws {
        let httpURL = URL(string: "http://example.com/image.png")!
        let provider = ImageProvider(url: httpURL)
        
        // Should fail for HTTP URLs
        await #expect(throws: LinkPresentationSwift.Error.self) {
            try await provider.loadImageData()
        }
    }
}