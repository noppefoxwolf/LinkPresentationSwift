# LinkPresentationSwift

A lightweight macOS 15+ library that fetches link metadata (title, representative image, etc.) using Swift Concurrency and `Transferable`. It mirrors the behavior of Apple's LinkPresentation but with a smaller surface and predictable async/await API.

## Features
- Simple async API: call `MetadataProvider.metadata(for:)`.
- Extracts Open Graph, Twitter Card, and standard `<title>` values (title & representative image URL).
- Ships an `ImageProvider` that is `Transferable` for drag-and-drop use.
- HTTPS-only image download with content-type validation and size limits for safety.
- Single-use call guard (CallTracker) to mimic LinkPresentation's one-shot behavior.

## Requirements
- Swift 6.2+
- macOS 15+ (matches `platforms` in `Package.swift`)

## Installation (Swift Package Manager)
Add the package to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/noppefoxwolf/LinkPresentationSwift.git", branch: "main")
]
```

Then add the library to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "LinkPresentationSwift", package: "LinkPresentationSwift")
    ]
)
```

## Usage
### Minimal example
```swift
import LinkPresentationSwift

let url = URL(string: "https://example.com")!
let provider = MetadataProvider()

Task {
    do {
        let metadata = try await provider.metadata(for: url)
        print(metadata.title ?? "(no title)")

        if let imageProvider = metadata.imageProvider as? ImageProvider {
            // Use imageProvider.url for display or caching
            print("image: \(imageProvider.url)")
        }
    } catch {
        // Throws LinkPresentationSwift.Error or URLError, etc.
        print("metadata fetch failed: \(error)")
    }
}
```

### Customizing requests
- To tweak timeout/headers, build a request with `URLRequest.metadataRequest(url:timeout:)` and pass it to `metadata(for:)`.
- To skip downloading images (keep only URLs), set `shouldFetchSubresources` to `false`.

```swift
var provider = MetadataProvider()
provider.timeout = 15          // default is 30s
provider.shouldFetchSubresources = false

let request = URLRequest.metadataRequest(url: url, timeout: provider.timeout)
let metadata = try await provider.metadata(for: request)
```

## Error model
`LinkPresentationSwift.Error.Code`:
- `metadataFetchCancelled`
- `metadataFetchFailed`
- `metadataFetchTimedOut`
- `metadataFetchNotAllowed`
- `unknown`

`Error.mapNetworkError()` helps convert `URLError` to domain errors.

## Limitations / Notes
- Currently extracts only title and representative image URL (description/video not yet supported).
- HTML parsing is regex-based and lightweight; very complex pages may be partially parsed.
- `CallTracker` allows only one call per `MetadataProvider` instance; create a new instance for additional fetches.
- Image downloads are HTTPS-only and fail above 10 MB; adjust if needed.

## Development & Tests
```bash
swift test
```
Tests cover mock fetcher/parser injection and integration checks against `httpbin.org`.

## License
[MIT](LICENCE)

## Contributing
Issues and PRs are welcome. For larger changes, please open a discussion first.
