import SpriteKit
import SwiftUI

/// Start screen: the lettering on top, the main buttons in the middle, and a demo course playing behind them.
struct MenuView: View {
    let background: BackgroundOption?
    @Binding var backgroundID: String
    let onCreate: () -> Void
    @State private var toast: String?
    @State private var picking = false
    @State private var attract: AttractScene = { let s = AttractScene(); s.scaleMode = .resizeFill; return s }()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let night = Color(red: 0.03, green: 0.035, blue: 0.075)

    var body: some View {
        ZStack {
            if background == nil {
                LinearGradient(colors: [Color(red: 0.09, green: 0.11, blue: 0.25), night], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
            SpriteView(scene: attract, options: [.allowsTransparency]).ignoresSafeArea().allowsHitTesting(false)
                .accessibilityHidden(true)
            VStack {
                Image("Title").resizable().scaledToFit().frame(maxWidth: 300)
                    .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
                    .padding(.top, 24)
                    .accessibilityLabel("Marble Jam")
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            VStack(spacing: 12) {                                                // centred on the screen, all the same size
                menuButton("Challenges") { toast = "Challenges are coming soon" }
                menuButton("Create", primary: true, action: onCreate)
                if !BackgroundLibrary.bundled.isEmpty { menuButton("Backgrounds") { picking = true } }
                menuButton("Store") { toast = "Store is coming soon" }
                menuButton("Sign in") { toast = "Sign in is coming soon" }
            }
            if let t = toast {
                VStack { Spacer(); Toast(text: t).padding(.bottom, 12) }
                    .task(id: t) { try? await Task.sleep(nanoseconds: 2_000_000_000); toast = nil }
            }
        }
        .background { Backdrop(option: background) }
        .onAppear { attract.animated = !reduceMotion }
        .onChange(of: reduceMotion) { _, still in attract.animated = !still }
        .sheet(isPresented: $picking) { BackgroundPicker(options: BackgroundLibrary.bundled, selectedID: $backgroundID) }
    }

    private func menuButton(_ title: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(title).frame(width: primary ? 182 : 200) }.buttonStyle(Chip(primary: primary))   // Play's style adds 18 pt of padding
    }
}
