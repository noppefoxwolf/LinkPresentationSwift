import LinkPresentationSwift
import SwiftUI

struct ContentView: View {
    @State
    private var links: [PreviewLink] = PreviewLink.samples

    @State
    private var draftURL = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    addLinkForm
                }

                Section {
                    ForEach($links) { $link in
                        LinkPreviewRow(link: $link)
                            .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: deleteLinks)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Link Previews")
            .toolbar {
                ToolbarItem {
                    Button {
                        reloadAll()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Reload")
                }
            }
        }
    }

    private var addLinkForm: some View {
        HStack(spacing: 10) {
            TextField("https://example.com", text: $draftURL)
                .urlInputStyle()

            Button {
                addDraftURL()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .disabled(validDraftURL == nil)
            .accessibilityLabel("Add link")
        }
        .padding(.vertical, 4)
    }

    private var validDraftURL: URL? {
        guard let url = URL(string: draftURL.trimmingCharacters(in: .whitespacesAndNewlines)),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            url.host?.isEmpty == false
        else {
            return nil
        }

        return url
    }

    private func addDraftURL() {
        guard let url = validDraftURL else { return }
        links.insert(PreviewLink(url: url), at: 0)
        draftURL = ""
    }

    private func deleteLinks(at offsets: IndexSet) {
        links.remove(atOffsets: offsets)
    }

    private func reloadAll() {
        for index in links.indices {
            links[index].reloadToken = UUID()
        }
    }
}

private struct LinkPreviewRow: View {
    @Binding
    var link: PreviewLink

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                thumbnail

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)

                    Text(displayURL)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    statusView
                }

                Spacer(minLength: 0)
            }

            if let finalURL = link.metadata?.url, finalURL != link.url {
                Label(finalURL.absoluteString, systemImage: "arrow.triangle.branch")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
        .task(id: link.reloadToken) {
            await loadMetadata()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                link.reloadToken = UUID()
            } label: {
                Label("Reload", systemImage: "arrow.clockwise")
            }
            .tint(.blue)
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let imageURL = link.metadata?.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholderThumbnail(systemImage: "photo")
                case .empty:
                    ProgressView()
                @unknown default:
                    placeholderThumbnail(systemImage: "photo")
                }
            }
            .frame(width: 72, height: 72)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            placeholderThumbnail(systemImage: "link")
        }
    }

    private var statusView: some View {
        Group {
            switch link.state {
            case .idle:
                Label("Ready", systemImage: "circle")
            case .loading:
                Label("Loading", systemImage: "progress.indicator")
            case .loaded:
                Label("Loaded", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        .font(.caption)
        .lineLimit(1)
    }

    private var title: String {
        link.metadata?.title ?? link.url.host() ?? link.url.absoluteString
    }

    private var displayURL: String {
        link.url.absoluteString
    }

    private func placeholderThumbnail(systemImage: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary)

            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 72, height: 72)
    }

    private func loadMetadata() async {
        link.state = .loading

        do {
            let provider = MetadataProvider()
            link.metadata = try await provider.metadata(for: link.url)
            link.state = .loaded
        } catch {
            link.state = .failed(error.localizedDescription)
        }
    }
}

private struct PreviewLink: Identifiable {
    let id = UUID()
    var url: URL
    var metadata: LinkMetadata?
    var state: PreviewState = .idle
    var reloadToken = UUID()

    static let samples: [PreviewLink] = [
        PreviewLink(url: URL(string: "https://www.apple.com")!),
        PreviewLink(url: URL(string: "https://developer.apple.com")!),
        PreviewLink(url: URL(string: "https://www.swift.org")!),
        PreviewLink(url: URL(string: "https://github.com/noppefoxwolf/LinkPresentationSwift")!),
    ]
}

private enum PreviewState {
    case idle
    case loading
    case loaded
    case failed(String)
}

private extension View {
    @ViewBuilder
    func urlInputStyle() -> some View {
        #if os(iOS)
        self
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.URL)
            .textContentType(.URL)
        #else
        self
        #endif
    }
}
