import Testing
import Foundation
@testable import LinkPresentationSwift

@Suite("ImageProvider Tests")
struct ImageProviderTests {
    
    @Test("ImageProvider initialization")
    func initialization() async throws {
        let url = URL(string: "https://example.com/image.jpg")!
        let provider = ImageProvider(url: url)
        
        #expect(provider.url == url)
    }
    
    @Test("ImageProvider conforms to Transferable")
    func conformsToTransferable() async throws {
        let url = URL(string: "https://httpbin.org/image/png")!
        let _ = ImageProvider(url: url)
        
        // Test that transferRepresentation is accessible (compile-time check)
        let _ = ImageProvider.transferRepresentation
    }
}