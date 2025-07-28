# LinkPresentationSwift

A modern Swift implementation of link metadata extraction and presentation, designed as an alternative to Apple's LinkPresentation framework with improved cross-platform compatibility.

## Features

- **Metadata Extraction**: Automatically extracts title, description, site name, and images from web pages
- **OGP Support**: Full support for Open Graph Protocol meta tags
- **Fallback Mechanisms**: Multiple fallback strategies for HTML title, meta descriptions, and Twitter cards
- **Image Support**: Handles remote images with CoreTransferable integration
- **Async/Await**: Modern Swift concurrency support
- **Cross-Platform**: Compatible with iOS 17+ and macOS 15+
- **Error Handling**: Comprehensive error types for different failure scenarios

## Installation

Add this package to your Xcode project or Swift Package:

```swift
dependencies: [
    .package(url: "https://github.com/noppefoxwolf/LinkPresentationSwift", from: "1.0.0")
]
```

## Usage

### Basic Metadata Extraction

```swift
import LinkPresentationSwift

let provider = MetadataProvider()
let url = URL(string: "https://example.com")!

do {
    let metadata = try await provider.startFetchingMetadata(for: url)
    
    print("Title: \(metadata.title ?? "No title")")
    print("Description: \(metadata.summary ?? "No description")")
    print("Site: \(metadata.siteName ?? "Unknown site")")
    
    if let imageURL = metadata.image?.remoteURL {
        print("Image: \(imageURL)")
    }
} catch {
    print("Failed to fetch metadata: \(error)")
}
```

### Custom URLRequest

```swift
var request = URLRequest(url: url)
request.setValue("Custom User Agent", forHTTPHeaderField: "User-Agent")

let metadata = try await provider.startFetchingMetadata(for: request)
```

### Using Custom URLSession

```swift
let customSession = URLSession(configuration: .default)
let provider = MetadataProvider(customSession)
```

### Timeout Configuration

```swift
let provider = MetadataProvider()
provider.timeout = 10.0 // 10 seconds
```

## Data Types

### LinkMetadata

```swift
public struct LinkMetadata: Sendable {
    public var url: URL?           // Final URL after redirects
    public var originalURL: URL?   // Original requested URL
    public var title: String?      // Page title
    public var summary: String?    // Page description
    public var siteName: String?   // Site name
    public var image: Image?       // Featured image
}
```

### LinkPresentationError

```swift
public enum LinkPresentationError: Error, Sendable {
    case cancelled    // Request was cancelled
    case failed      // General failure
    case timedOut    // Request timed out
    case unknown     // Unknown error
    case notAllowed  // Request not allowed
}
```

### Image

Images are represented with CoreTransferable support for easy integration with SwiftUI and data transfer:

```swift
public struct Image: Sendable, Transferable {
    public let remoteURL: URL
}
```

## Implementation Details

The library uses a comprehensive approach to metadata extraction:

1. **Primary**: Open Graph Protocol (OGP) meta tags
2. **Fallback**: Standard HTML meta tags and Twitter cards
3. **Last Resort**: HTML title and heading tags

### Supported Meta Tags

- Open Graph: `og:title`, `og:description`, `og:site_name`, `og:image`
- Twitter Cards: `twitter:image`, `twitter:description`
- Standard HTML: `<title>`, `<meta name="description">`, `<link rel="image_src">`

## Testing

The package includes comprehensive tests that compare the Swift implementation with Apple's LinkPresentation framework:

```bash
swift test
```

Tests are automatically disabled in CI environments to avoid network dependencies.

## Requirements

- iOS 17.0+ / macOS 15.0+
- Swift 6.1+
- Xcode 16.0+

## License

This project is available under the MIT license.