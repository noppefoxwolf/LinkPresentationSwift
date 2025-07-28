import CoreTransferable
import Foundation

public struct Image: Sendable, Transferable {
    
    let remoteURL: URL
    
    public static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.remoteURL)
        FileRepresentation(exportedContentType: .image) { image in
            let (fileURL, _) = try await URLSession.shared.download(from: image.remoteURL)
            return SentTransferredFile(fileURL)
        }
    }
}
