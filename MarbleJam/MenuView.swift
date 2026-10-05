import SwiftUI

/// Start screen: big logo, the name, and the main buttons. Marbles drift in the background.
struct MenuView: View {
    let background: BackgroundOption?
    @Binding var backgroundID: String
    let onPlay: () -> Void
    let onDemo: () -> Void
    @State private var toast: String?
    @State private var picking = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let night = Color(red: 0.03, green: 0.035, blue: 0.075)

    var body: some View {
        ZStack {
            if background == nil {
                LinearGradient(colors: [Color(red: 0.09, green: 0.11, blue: 0.25), night], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
            DriftingMarbles(paused: reduceMotion).ignoresSafeArea().allowsHitTesting(false)
            VStack(spacing: 18) {
                Spacer()
                Image("Logo").resizable().scaledToFit().frame(maxWidth: 280, maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 56, style: .continuous))
                    .shadow(color: .cyan.opacity(0.45), radius: 30)
                    .accessibilityLabel("Marble Jam")
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                VStack(spacing: 12) {
                    Button("Play ▶", action: onPlay).buttonStyle(Chip(primary: true)).scaleEffect(1.25).padding(.bottom, 6)
                    Button("Demo Song", action: onDemo).buttonStyle(Chip())
                    if !BackgroundLibrary.bundled.isEmpty {
                        Button("Backgrounds") { picking = true }.buttonStyle(Chip())
                    }
                    HStack(spacing: 10) {
                        Button("Store") { toast = "Store is coming soon" }.buttonStyle(Chip())
                        Button("Sign in") { toast = "Sign in is coming soon" }.buttonStyle(Chip())
                    }
                }
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            if let t = toast {
                VStack { Spacer(); Toast(text: t).padding(.bottom, 12) }
                    .task(id: t) { try? await Task.sleep(nanoseconds: 2_000_000_000); toast = nil }
            }
        }
        .background { Backdrop(option: background) }
        .sheet(isPresented: $picking) { BackgroundPicker(options: BackgroundLibrary.bundled, selectedID: $backgroundID) }
    }
}

/// A few glowing marbles in the note colours, floating slowly.
private struct DriftingMarbles: View {
    let paused: Bool
    var body: some View {
        TimelineView(.animation(paused: paused)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                for (i, hue) in Notes.hues.enumerated() {
                    let k = Double(i)
                    let x = size.width * (0.5 + 0.42 * sin(t * (0.07 + 0.013 * k) + k * 1.7))
                    let y = size.height * (0.5 + 0.45 * cos(t * (0.05 + 0.011 * k) + k * 2.3))
                    let r = 10 + 4 * Double(i % 3)
                    let color = Color(hue: hue / 360, saturation: 0.82, brightness: 1)
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r * 2.5, y: y - r * 2.5, width: r * 5, height: r * 5)), with: .color(color.opacity(0.12)))
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(color.opacity(0.75)))
                }
            }
        }
    }
}
