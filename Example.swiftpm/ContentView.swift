import LinkPresentationSwift
import SwiftUI

struct ContentView: View {
    @State
    var text: String = ""

    @State
    var metadata: LinkMetadata? = nil

    var body: some View {
        VStack(content: {
            TextField("https://google.com", text: $text)
                .keyboardType(.URL)

            if let metadata {
                Text(metadata.title ?? "-")
                Text(metadata.url?.absoluteString ?? "-")
                Text(metadata.originalURL?.absoluteString ?? "-")
            }
        })
        .task(id: text) {
            let url = URL(string: text)
            guard let url else { return }
            do {
                let provider = MetadataProvider()
                metadata = try await provider.metadata(for: url)
            } catch {
                print(error)
            }
        }
    }
}
