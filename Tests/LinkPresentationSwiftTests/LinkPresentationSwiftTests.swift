import Testing
@testable import LinkPresentationSwift
import LinkPresentation

@Test(.enabled(if: !isRunningInCI()))
func exampleObjC() async throws {
    let provider = LPMetadataProvider()
    let url = URL(string: "https://applech2.com")!
    let metadata = try await provider.startFetchingMetadata(for: url)
    #expect(metadata.title == "AAPL Ch.")
    #expect(metadata.value(forKey: "summary") as! String == "Macの話題が中心のブログです。")
    #expect(metadata.url == URL(string: "https://applech2.com/")!)
    #expect(metadata.originalURL == url)
}

@Test(.enabled(if: !isRunningInCI()))
func exampleSwift() async throws {
    let provider = MetadataProvider()
    let url = URL(string: "https://applech2.com")!
    let metadata = try await provider.startFetchingMetadata(for: url)
    #expect(metadata.title == "AAPL Ch.")
    #expect(metadata.summary == "Macの話題が中心のブログです。")
    #expect(metadata.url == URL(string: "https://applech2.com/")!)
    #expect(metadata.originalURL == url)
    if #available(macOS 15.2, *) {
        let data = try await metadata.image!.exported(as: .image)
        let image = NSImage(data: data)
        #expect(image != nil)
    }
}

func isRunningInCI() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    
    let ciEnvironments = [
        "GITHUB_ACTIONS",
        "TRAVIS",
        "CIRCLECI",
        "GITLAB_CI",
        "JENKINS_HOME",
        "APPVEYOR"
    ]
    
    for ciEnv in ciEnvironments {
        if environment[ciEnv] != nil {
            return true
        }
    }
    
    return false
}
