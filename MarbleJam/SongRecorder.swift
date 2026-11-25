import ReplayKit
import SwiftUI

/// "Share video": records the screen and the app's sound (never the microphone) while the song replays. iOS asks the
/// player's permission the first time. The video stays on the device until the player shares or saves it.
@MainActor
final class SongRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    static let maxSeconds: UInt64 = 30                                  // long enough for a reel, short enough to share

    var isAvailable: Bool { RPScreenRecorder.shared().isAvailable }

    func start() async -> Bool {
        let r = RPScreenRecorder.shared()
        guard r.isAvailable, !r.isRecording else { return false }
        r.isMicrophoneEnabled = false
        do { try await r.startRecording() } catch { return false }
        isRecording = true
        return true
    }

    /// Stops and writes the video to a temporary file; nil if that failed.
    func stop() async -> URL? {
        guard isRecording else { return nil }
        isRecording = false
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Marble Beats.mp4")
        try? FileManager.default.removeItem(at: url)
        do { try await RPScreenRecorder.shared().stopRecording(withOutput: url) } catch { return nil }
        return url
    }
}

/// A finished video waiting for the share sheet.
struct SharedVideo: Identifiable { let id = UUID(); let url: URL }

/// The system share sheet (Messages, Photos, TikTok, Instagram...).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
