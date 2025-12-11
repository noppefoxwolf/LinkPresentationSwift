import Testing
import Foundation
@testable import LinkPresentationSwift

@Suite("Edge Case and Bug Detection Tests")
struct EdgeCaseTests {
    
    @Test("URLRequest with invalid URL should throw error instead of crash")
    func urlRequestWithInvalidURL() async throws {
        // Test with various invalid URL scenarios that could cause crashes
        let provider = MetadataProvider()
        
        // Test 1: Since URL(string: "")! will crash, we need a different approach
        // Let's test with a malformed URL that won't crash during creation
        await #expect {
            let malformedURL = URL(string: "http://")! // Malformed but doesn't crash during creation
            let invalidRequest = URLRequest(url: malformedURL)
            try await provider.metadata(for: invalidRequest)
        } throws: { error in
            return error is LinkPresentationSwift.Error || error is URLError
        }
        
        // Test 2: URL that's syntactically valid but will fail to connect
        await #expect {
            let unreachableURL = URL(string: "https://invalid-domain-that-does-not-exist-12345.com")!
            let unreachableRequest = URLRequest(url: unreachableURL)
            try await provider.metadata(for: unreachableRequest)
        } throws: { error in
            return error is LinkPresentationSwift.Error || error is URLError
        }
    }
    
    @Test("Empty HTML should not crash parser")
    func emptyHTMLParsing() async throws {
        let parser = HTMLParser()
        let emptyHTML = ""
        
        var baseMetadata = LinkMetadata()
        baseMetadata.originalURL = URL(string: "https://example.com")
        
        let metadata = await parser.parseHTMLMetadata(html: emptyHTML, baseMetadata: baseMetadata, shouldFetchSubresources: false)
        
        #expect(metadata.title == nil)
        #expect(metadata.imageURL == nil)
    }
    
    @Test("Very large HTML should not cause memory issues")
    func largeHTMLParsing() async throws {
        let parser = HTMLParser()
        
        // Create a large HTML string (1MB)
        let largeContent = String(repeating: "<p>Large content</p>\n", count: 10000)
        let largeHTML = """
        <html>
        <head>
            <title>Large Page</title>
            <meta property="og:title" content="Large OG Title">
        </head>
        <body>
        \(largeContent)
        </body>
        </html>
        """
        
        var baseMetadata = LinkMetadata()
        baseMetadata.originalURL = URL(string: "https://example.com")
        
        let metadata = await parser.parseHTMLMetadata(html: largeHTML, baseMetadata: baseMetadata, shouldFetchSubresources: false)
        
        #expect(metadata.title == "Large OG Title")
    }
    
    @Test("HTML with malformed meta tags should not crash")
    func malformedMetaTags() async throws {
        let parser = HTMLParser()
        
        let malformedHTML = """
        <html>
        <head>
            <meta property="og:title" content="Valid Title">
            <meta property="og:image" content=> // Missing closing quote
            <meta property= content="No property name">
            <meta property="og:broken" content="Missing closing tag
            <meta property="og:description" content="Valid Description">
        </head>
        </html>
        """
        
        var baseMetadata = LinkMetadata()
        baseMetadata.originalURL = URL(string: "https://example.com")
        
        let metadata = await parser.parseHTMLMetadata(html: malformedHTML, baseMetadata: baseMetadata, shouldFetchSubresources: false)
        
        // Should still extract valid metadata
        #expect(metadata.title == "Valid Title")
    }
    
    @Test("Unicode and special characters in metadata")
    func unicodeHandling() async throws {
        let parser = HTMLParser()
        
        let unicodeHTML = """
        <html>
        <head>
            <title>🚀 Test émojis & spéciäl cháracters 中文 العربية</title>
            <meta property="og:title" content="Unicode: 🌟 Special: &quot;&amp;&lt;&gt;">
        </head>
        </html>
        """
        
        var baseMetadata = LinkMetadata()
        baseMetadata.originalURL = URL(string: "https://example.com")
        
        let metadata = await parser.parseHTMLMetadata(html: unicodeHTML, baseMetadata: baseMetadata, shouldFetchSubresources: false)
        
        #expect(metadata.title?.contains("🌟") == true)
        #expect(metadata.title?.contains("&quot;") == true) // HTML entities should be preserved
    }
}
