import Testing
import Foundation
@testable import LinkPresentationSwift

@Suite("VideoProvider Feature Tests")
struct VideoProviderTests {
    
    @Test("VideoProvider with URL only creates correctly")
    func videoProviderURLOnly() throws {
        let url = URL(string: "https://example.com/video.mp4")!
        let provider = VideoProvider(url: url)
        
        #expect(provider.url == url)
    }
    
    @Test("VideoProvider with pre-fetched data returns immediately")
    func videoProviderWithData() async throws {
        let url = URL(string: "https://example.com/video.mp4")!
        let testData = Data([
            // MP4 file signature
            0x00, 0x00, 0x00, 0x20,  // Box size
            0x66, 0x74, 0x79, 0x70,  // "ftyp" box
            0x69, 0x73, 0x6F, 0x6D   // "isom" brand
        ])
        
        let provider = VideoProvider(url: url, data: testData)
        
        let loadedData = try await provider.loadVideoData()
        #expect(loadedData == testData)
    }
    
    @Test("VideoProvider validates HTTPS URLs only")
    func videoProviderValidatesHTTPS() async throws {
        let httpURL = URL(string: "http://example.com/video.mp4")!
        let provider = VideoProvider(url: httpURL)
        
        // Should fail for HTTP URLs
        await #expect(throws: LinkPresentationSwift.Error.self) {
            try await provider.loadVideoData()
        }
    }
    
    @Test("shouldFetchSubresources = true should create VideoProvider with data")
    func shouldFetchSubresourcesVideoTrue() async throws {
        let mockFetcher = MockMetadataFetcher()
        let parser = HTMLParser()
        
        let htmlWithVideo = """
        <html>
        <head>
            <meta property="og:video" content="https://example.com/video.mp4">
            <meta property="og:video:url" content="https://example.com/stream.mp4">
            <title>Test Page</title>
        </head>
        </html>
        """
        
        mockFetcher.htmlToReturn = htmlWithVideo
        mockFetcher.urlToReturn = URL(string: "https://example.com")
        
        var provider = MetadataProvider(fetcher: mockFetcher, parser: parser)
        provider.shouldFetchSubresources = true
        
        let metadata = try await provider.metadata(for: URL(string: "https://example.com")!)
        
        // Should have VideoProvider and remoteVideoURL
        #expect(metadata.videoProvider != nil)
        #expect(metadata.remoteVideoURL?.absoluteString == "https://example.com/stream.mp4")
        
        if let videoProvider = metadata.videoProvider as? VideoProvider {
            #expect(videoProvider.url.absoluteString == "https://example.com/video.mp4")
        }
    }
    
    @Test("shouldFetchSubresources = false should create VideoProvider without data")
    func shouldFetchSubresourcesVideoFalse() async throws {
        let mockFetcher = MockMetadataFetcher()
        let parser = HTMLParser()
        
        let htmlWithVideo = """
        <html>
        <head>
            <meta property="og:video" content="https://example.com/video.mp4">
            <meta name="twitter:player:stream" content="https://example.com/player.mp4">
            <title>Test Page</title>
        </head>
        </html>
        """
        
        mockFetcher.htmlToReturn = htmlWithVideo
        mockFetcher.urlToReturn = URL(string: "https://example.com")
        
        var provider = MetadataProvider(fetcher: mockFetcher, parser: parser)
        provider.shouldFetchSubresources = false
        
        let metadata = try await provider.metadata(for: URL(string: "https://example.com")!)
        
        // Should have VideoProvider with URL only and remoteVideoURL
        #expect(metadata.videoProvider != nil)
        #expect(metadata.remoteVideoURL?.absoluteString == "https://example.com/player.mp4")
        
        if let videoProvider = metadata.videoProvider as? VideoProvider {
            #expect(videoProvider.url.absoluteString == "https://example.com/video.mp4")
        }
    }
    
    @Test("Twitter card video metadata parsing")
    func twitterCardVideo() async throws {
        let mockFetcher = MockMetadataFetcher()
        let parser = HTMLParser()
        
        let htmlWithTwitterVideo = """
        <html>
        <head>
            <meta name="twitter:card" content="player">
            <meta name="twitter:player" content="https://example.com/player.html">
            <meta name="twitter:player:stream" content="https://example.com/video.mp4">
            <meta name="twitter:player:width" content="1280">
            <meta name="twitter:player:height" content="720">
            <title>Video Page</title>
        </head>
        </html>
        """
        
        mockFetcher.htmlToReturn = htmlWithTwitterVideo
        mockFetcher.urlToReturn = URL(string: "https://example.com")
        
        var provider = MetadataProvider(fetcher: mockFetcher, parser: parser)
        provider.shouldFetchSubresources = false
        
        let metadata = try await provider.metadata(for: URL(string: "https://example.com")!)
        
        // Twitter player should be parsed as video
        #expect(metadata.videoProvider != nil)
        #expect(metadata.remoteVideoURL?.absoluteString == "https://example.com/video.mp4")
        
        if let videoProvider = metadata.videoProvider as? VideoProvider {
            #expect(videoProvider.url.absoluteString == "https://example.com/player.html")
        }
    }
    
    @Test("Mixed video metadata prioritization")
    func mixedVideoMetadata() async throws {
        let mockFetcher = MockMetadataFetcher()
        let parser = HTMLParser()
        
        let htmlWithMixedVideo = """
        <html>
        <head>
            <meta property="og:video" content="https://example.com/og-video.mp4">
            <meta property="og:video:url" content="https://example.com/og-url.mp4">
            <meta name="twitter:player" content="https://example.com/twitter-player.html">
            <meta name="twitter:player:stream" content="https://example.com/twitter-stream.mp4">
            <title>Mixed Video Page</title>
        </head>
        </html>
        """
        
        mockFetcher.htmlToReturn = htmlWithMixedVideo
        mockFetcher.urlToReturn = URL(string: "https://example.com")
        
        var provider = MetadataProvider(fetcher: mockFetcher, parser: parser)
        provider.shouldFetchSubresources = false
        
        let metadata = try await provider.metadata(for: URL(string: "https://example.com")!)
        
        // First video tag wins (og:video)
        #expect(metadata.videoProvider != nil)
        if let videoProvider = metadata.videoProvider as? VideoProvider {
            #expect(videoProvider.url.absoluteString == "https://example.com/og-video.mp4")
        }
        
        // First remoteVideoURL tag wins (og:video:url)
        #expect(metadata.remoteVideoURL?.absoluteString == "https://example.com/og-url.mp4")
    }
}