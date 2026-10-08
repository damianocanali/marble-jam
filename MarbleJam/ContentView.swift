import SwiftUI
import SpriteKit

struct ContentView: View {
    @ObservedObject var model: GameModel
    let background: BackgroundOption?
    let progress: ChallengeProgress
    let onMenu: () -> Void
    @Environment(\.theme) private var theme
    @State private var renaming = false
    @State private var newName = ""
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
            VStack {
                LinearGradient(colors: [night.opacity(0.92), night.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 150).ignoresSafeArea()
                Spacer()
            }
            .allowsHitTesting(false)
            VStack(spacing: 0) { header; Spacer(); tray }
            VStack {
                HStack {
                    Spacer()
                    Menu {
                        ForEach(Instrument.allCases) { i in
                            Button { model.setInstrument(i) } label: { Label(i.title, systemImage: i.symbol) }
                        }
                    } label: {
                        Image(systemName: model.instrument.symbol).font(.system(size: 16, weight: .heavy)).frame(width: 40, height: 40)
                    }
                    .menuStyle(.button).buttonStyle(Chip())
                    .accessibilityLabel("Instrument: \(model.instrument.title)")
                    .disabled(model.playing)
                    .opacity(model.challenge == nil ? 1 : 0).allowsHitTesting(model.challenge == nil)      // a challenge plays its own instrument
                    Button(action: onMenu) {
                        Image(systemName: "house.fill").font(.system(size: 16, weight: .heavy))
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(Chip())
                    .accessibilityLabel(model.challenge == nil ? "My Songs" : "Challenges")
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
                                onDismiss: { model.celebration = nil },
                                onNext: model.nextChallenge.map { next in { model.celebration = nil; model.open(challenge: next, progress: progress) } })
                    .transition(.opacity)
            }
        }
        .background { Backdrop(option: background) }
        .onAppear { scene.model = model; scene.marbleGlow = theme.marbleGlow.uiColor }
        .alert("Rename song", isPresented: $renaming) {
            TextField("Name", text: $newName)
            Button("Save") { model.rename(to: newName) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Image("Title").resizable().scaledToFit().frame(height: 54)    // the lettering from art/Text.PNG
                .accessibilityLabel("Marble Jam").allowsHitTesting(false)
            if let c = model.challenge {
                Text("\(c.world)-\(c.number) · \(c.title)").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(ink).lineLimit(1)
                Text(c.goalText).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(muted).lineLimit(2)
            } else {
            HStack(spacing: 4) {
                Button { newName = model.song?.name ?? ""; renaming = true } label: {
                    Text(model.song?.name ?? "Song").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(ink).lineLimit(1)
                }
                .layoutPriority(1)                                         // the name keeps its room; the counts give way
                .accessibilityHint("Rename")
                Text("· " + model.info).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(muted).monospacedDigit()
                    .lineLimit(1).allowsHitTesting(false)
            }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
    }

    private var hint: String {
        if model.playing { return "Your song is playing." }
        if let id = model.selected, model.isLocked(id) { return "This piece is locked: it's part of the puzzle." }
        if let p = model.selectedPad {
            switch p.kind {
            case .bar: return "Drag to move, tilt with the dial. Close to the beat? Let go and it snaps on."
            case .ramp: return "The marble rolls along a ramp. Tilt, stretch and bend it; it plays its note when the marble lands."
            case .bumper: return "Drag to move. ♭ ♯ change the note."
            }
        }
        return "The dotted line is where the marble will go. Pads glow gold when they hit on the beat."
    }

    private var tray: some View {
        VStack(spacing: 8) {
            Text(hint).font(.system(size: 13.5, weight: .semibold, design: .rounded)).foregroundStyle(muted)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if model.selectedPad != nil, !model.playing {
                PadController(model: model)
            }
            Group {
                if model.challenge != nil { trayRow } else {
                    ViewThatFits(in: .horizontal) {                               // narrow phones (iPhone SE): drop the "+ "
                        pieceRow(plus: true)
                        pieceRow(plus: false)
                    }
                }
            }
            .buttonStyle(Chip()).disabled(model.playing)
            Button(model.playing ? "Stop ■" : "Drop ▶") { model.toggleDrop() }.buttonStyle(Chip(primary: true, stop: model.playing))
        }
        .padding(.horizontal, 12).padding(.top, 26).padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [night.opacity(0), night.opacity(0.94)], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.34)).ignoresSafeArea())
    }

    /// Challenges: the pieces left in the tray (each is placed at its hint spot), undo and reset.
    private var trayRow: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(model.trayLeft.enumerated()), id: \.element.id) { i, p in
                        Button(trayLabel(p)) { model.placeFromTray(i) }
                            .accessibilityLabel(model.challenge.map { if case .melody = $0.goal { "Place note \(Notes.label(p, instrument: model.instrument))" } else { "Place \(trayLabel(p))" } } ?? "")
                    }
                    if model.trayLeft.isEmpty { Text("Tray empty").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(muted) }
                }
            }
            Button { model.undo() } label: { Image(systemName: "arrow.uturn.backward") }.accessibilityLabel("Undo")
            if let id = model.selected, model.isPlaced(id) {
                Button { model.deleteSelected() } label: { Image(systemName: "tray.and.arrow.down") }.accessibilityLabel("Back to tray")
            } else {
                Button { model.resetChallenge() } label: { Image(systemName: "arrow.counterclockwise") }.accessibilityLabel("Reset level")
            }
        }
    }

    private func trayLabel(_ p: Pad) -> String {
        switch model.challenge?.goal {
        case .melody?: return "♪ " + Notes.label(p, instrument: model.instrument)
        default: return p.kind == .ramp ? "+ Ramp" : p.kind == .bumper ? "+ Bumper" : "+ Pad"
        }
    }

    private func pieceRow(plus: Bool) -> some View {
        HStack(spacing: 8) {
            Button(plus ? "+ Pad" : "Pad") { model.addPad() }.accessibilityLabel("Add pad")
            Button(plus ? "+ Bumper" : "Bumper") { model.addBumper() }.accessibilityLabel("Add bumper")
            Button(plus ? "+ Ramp" : "Ramp") { model.addRamp() }.accessibilityLabel("Add ramp")
            Button { model.undo() } label: { Image(systemName: "arrow.uturn.backward") }.accessibilityLabel("Undo")
            if model.selectedPad != nil {
                Button { model.deleteSelected() } label: { Image(systemName: "trash") }.accessibilityLabel("Delete")
            } else {
                Button { model.clear() } label: { Image(systemName: "xmark.bin") }.accessibilityLabel("Clear")
            }
        }
    }
}

/// Rounded button used across the tray. `primary` is the Drop button.
struct Chip: ButtonStyle {
    var primary = false
    var stop = false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.theme) private var theme

    init(primary: Bool = false, stop: Bool = false) { self.primary = primary; self.stop = stop }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: primary ? 16 : 14.5, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .foregroundStyle(primary ? (stop ? Color(red: 0.02, green: 0.06, blue: 0.11) : theme.primaryText.color) : Color(red: 0.95, green: 0.96, blue: 1))
            .padding(.horizontal, primary ? 22 : 13).frame(minHeight: 44)
            .background {
                if primary { RoundedRectangle(cornerRadius: 14).fill(stop ? Color.pink : theme.primary.color) }
                else { RoundedRectangle(cornerRadius: 14).fill(theme.chipFill.color.opacity(0.9))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.chipStroke.color.opacity(theme.chipStrokeOpacity))) }
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
