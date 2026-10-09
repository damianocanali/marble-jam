import SpriteKit
import SwiftUI

/// Start screen: the lettering on top, the main buttons in the middle, and a demo course playing behind them.
struct MenuView: View {
    let background: BackgroundOption?
    let backgrounds: [BackgroundOption]                 // what the picker offers right now (season-aware)
    let season: Season?
    @Binding var backgroundID: String
    @AppStorage("season.preview") private var seasonPreview = ""
    let onCreate: () -> Void
    let onChallenges: () -> Void
    let onStore: () -> Void
    @State private var toast: String?
    @State private var picking = false
    @State private var attract: AttractScene = { let s = AttractScene(); s.scaleMode = .resizeFill; return s }()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.theme) private var theme
    @Environment(\.marbleSkin) private var skin

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
                if let season, let art = UIImage(named: season.titleArt) {      // the holiday's own artwork replaces title and banner
                    Image(uiImage: art).resizable().scaledToFit().frame(maxWidth: 320, maxHeight: 235)   // clear of the centred buttons
                        .padding(.top, 8)
                        .accessibilityLabel("Marble Jam. \(season.banner)")
                        .accessibilityAddTraits(.isHeader)
                } else {
                    Image("Title").resizable().scaledToFit().frame(maxWidth: 300)
                        .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
                        .padding(.top, 24)
                        .accessibilityLabel("Marble Jam")
                        .accessibilityAddTraits(.isHeader)
                }
                if let season, UIImage(named: season.titleArt) == nil {
                    Text(season.banner)
                        .font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.black.opacity(0.45), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.25)))
                }
                Spacer()
            }
            VStack(spacing: 12) {                                                // centred on the screen, all the same size
                menuButton("Challenges", primary: true, action: onChallenges)
                menuButton("Create", action: onCreate)
                if !backgrounds.isEmpty { menuButton("Backgrounds") { picking = true } }
                menuButton("Store", action: onStore)
                menuButton("Sign in") { toast = "Sign in is coming soon" }
            }
            #if DEBUG
            VStack {                                                             // preview a holiday pack before its date (never in release builds)
                Spacer()
                HStack {
                    Menu {
                        Button("By date") { seasonPreview = "" }
                        Button("Off-season") { seasonPreview = "off" }
                        ForEach(Seasons.all) { s in Button("\(s.emoji) \(s.title)") { seasonPreview = s.id } }
                    } label: { Text("Preview season").font(.system(size: 12, weight: .bold, design: .rounded)) }
                    .menuStyle(.button).buttonStyle(Chip())
                    Spacer()
                }
            }
            .padding(12)
            #endif
            if let t = toast {
                VStack { Spacer(); Toast(text: t).padding(.bottom, 12) }
                    .task(id: t) { try? await Task.sleep(nanoseconds: 2_000_000_000); toast = nil }
            }
        }
        .background { Backdrop(option: background) }
        .onAppear { attract.animated = !reduceMotion; attract.marbleGlow = theme.marbleGlow.uiColor; attract.skin = skin }
        .onChange(of: theme) { _, t in attract.marbleGlow = t.marbleGlow.uiColor }
        .onChange(of: reduceMotion) { _, still in attract.animated = !still }
        .sheet(isPresented: $picking) { BackgroundPicker(options: backgrounds, selectedID: $backgroundID) }
    }

    private func menuButton(_ title: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(title).frame(width: primary ? 182 : 200) }.buttonStyle(Chip(primary: primary))   // Play's style adds 18 pt of padding
    }
}
