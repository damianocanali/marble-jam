import SwiftUI
import SpriteKit

struct ContentView: View {
    @ObservedObject var model: GameModel
    let background: BackgroundOption?
    let onMenu: () -> Void
    @State private var scene: RunScene = {
        let s = RunScene(); s.scaleMode = .resizeFill; return s
    }()

    private let ink = Color(red: 0.95, green: 0.96, blue: 1)
    private let muted = Color(red: 0.6, green: 0.65, blue: 0.78)
    private let gold = Color(red: 1, green: 0.85, blue: 0.35)
    private let night = Color(red: 0.03, green: 0.035, blue: 0.075)

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.allowsTransparency]).ignoresSafeArea()
            VStack(spacing: 0) { header; Spacer(); tray }
            VStack {
                HStack {
                    Spacer()
                    Button(action: onMenu) {
                        Image(systemName: "house.fill").font(.system(size: 16, weight: .heavy))
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(Chip())
                    .accessibilityLabel("Menu")
                }
                Spacer()
            }
            .padding(.horizontal, 12).padding(.top, 4)
            if let t = model.toast {
                Toast(text: t)
                    .task(id: t) { try? await Task.sleep(nanoseconds: 2_600_000_000); model.toast = nil }
            }
            if let c = model.celebration {
                CelebrationView(celebration: c, chime: model.chime,
                                onPlayAgain: { model.celebration = nil; model.start() },
                                onDismiss: { model.celebration = nil })
                    .transition(.opacity)
            }
        }
        .background { Backdrop(option: background) }
        .onAppear { scene.model = model }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Marble Jam")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(ink)
            Text(model.info).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(muted).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 52)
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
        .background(LinearGradient(colors: [night.opacity(0.92), night.opacity(0)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .allowsHitTesting(false)
    }

    private var hint: String {
        if model.playing { return "Your song is playing." }
        if let p = model.selectedPad {
            return p.kind == .bar ? "Drag to move. Turn the dial to tilt. ♭ ♯ change the note." : "Drag to move. ♭ ♯ change the note."
        }
        return "The dotted line is where the marble will go. Gold rings are beats: put pads there."
    }

    private var tray: some View {
        VStack(spacing: 8) {
            Text(hint).font(.system(size: 13.5, weight: .semibold, design: .rounded)).foregroundStyle(muted)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if model.selectedPad != nil, !model.playing {
                PadController(model: model)
            }
            HStack(spacing: 8) {
                Button("+ Pad") { model.addPad() }
                Button("+ Bumper") { model.addBumper() }
                Button("Undo") { model.undo() }
                if model.selectedPad != nil {
                    Button("Delete") { model.deleteSelected() }
                } else {
                    Button("Clear") { model.clear() }
                }
            }
            .buttonStyle(Chip()).disabled(model.playing)
            HStack(spacing: 8) {
                Button("Demo") { model.loadDemo() }.buttonStyle(Chip()).disabled(model.playing)
                Button(model.playing ? "Stop ■" : "Drop ▶") { model.toggleDrop() }.buttonStyle(Chip(primary: true, stop: model.playing))
            }
        }
        .padding(.horizontal, 12).padding(.top, 26).padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [night.opacity(0), night.opacity(0.94)], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.34)).ignoresSafeArea())
    }
}

/// Rounded button used across the tray. `primary` is the Drop button.
struct Chip: ButtonStyle {
    var primary = false
    var stop = false
    @Environment(\.isEnabled) private var enabled

    init(primary: Bool = false, stop: Bool = false) { self.primary = primary; self.stop = stop }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: primary ? 16 : 14.5, weight: .heavy, design: .rounded))
            .foregroundStyle(primary ? Color(red: 0.02, green: 0.06, blue: 0.11) : Color(red: 0.95, green: 0.96, blue: 1))
            .padding(.horizontal, primary ? 22 : 13).frame(minHeight: 44)
            .background {
                if primary { RoundedRectangle(cornerRadius: 14).fill(stop ? Color.pink : Color.cyan) }
                else { RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.055, green: 0.07, blue: 0.15).opacity(0.9))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18))) }
            }
            .opacity(enabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
    }
}

/// Short message that fades out after a moment.
struct Toast: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Color(red: 0.95, green: 0.96, blue: 1))
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color(red: 0.03, green: 0.035, blue: 0.075).opacity(0.9), in: RoundedRectangle(cornerRadius: 14))
    }
}
