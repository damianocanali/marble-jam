import SwiftUI
import SpriteKit
import StoreKit

struct ContentView: View {
    @ObservedObject var model: GameModel
    let background: BackgroundOption?
    let progress: ChallengeProgress
    let onMenu: () -> Void
    @Environment(\.theme) private var theme
    @Environment(\.marbleSkin) private var skin
    @State private var renaming = false
    @State private var offeringReminders = false
    @State private var newName = ""
    @State private var scene: RunScene = {
        let s = RunScene(); s.scaleMode = .resizeFill; return s
    }()
    @State private var room = Course3D()
    @AppStorage("renderer.3d") private var use3D = true                     // DEBUG builds can switch back to the 2D look to compare
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.requestReview) private var requestReview
    @StateObject private var recorder = SongRecorder()
    @State private var sharing: SharedVideo?
    @State private var askingGrownUp = false
    @State private var wrongAnswer = false
    @State private var gate = ParentalGate.question()
    @State private var answer = ""

    private let ink = Color(red: 0.95, green: 0.96, blue: 1)
    private let muted = Color(red: 0.6, green: 0.65, blue: 0.78)
    private let gold = Color(red: 1, green: 0.85, blue: 0.35)
    private let night = Color(red: 0.03, green: 0.035, blue: 0.075)

    /// Recording a reel (`-mbClean 1`, DEBUG builds): nothing but the run while the song plays.
    /// Also while recording a video to share.
    private var cleanShot: Bool {
        if recorder.isRecording { return true }
        #if DEBUG
        return CaptureMode.current.clean && model.playing
        #else
        return false
        #endif
    }

    /// Closes the celebration; after the first challenge win, offers reminders.
    private func closeCelebration(_ c: Celebration, offerReminders: Bool = true) {
        let inChallenge = model.challenge != nil
        model.celebration = nil
        ReviewPrompt.shared.recordWin(stars: c.stars)
        if offerReminders, ReminderScheduler.shared.shouldOffer(after: c, inChallenge: inChallenge) { offeringReminders = true }
    }

    /// "Keep editing" / "Stay": a calm moment, the only one where the rating prompt may appear.
    private func dismissCelebration(_ c: Celebration) {
        closeCelebration(c)
        #if DEBUG
        if CaptureMode.current.isActive { return }
        #endif
        if !offeringReminders, ReviewPrompt.shared.askNow(version: ReviewPrompt.appVersion) { requestReview() }
    }

    /// Share a video: a grown-up says yes, then the song replays from the top while the screen is recorded.
    private func askToShare() {
        gate = ParentalGate.question(); answer = ""; askingGrownUp = true
    }
    private func recordAndShare() {
        if let c = model.celebration { closeCelebration(c, offerReminders: false) }
        Task {
            guard await recorder.start() else { model.toast = "Couldn't record the screen."; return }
            model.start()
            if !model.playing { _ = await recorder.stop() }                      // nothing to play after all
        }
    }
    /// The song ended (or hit the time limit): stop recording and open the share sheet.
    private func finishRecording() {
        Task {
            let url = await recorder.stop()
            model.celebration = nil                                              // they've seen this sticker already
            if let url { sharing = SharedVideo(url: url) } else { model.toast = "Couldn't save the video." }
        }
    }

    var body: some View {
        ZStack {
            if use3D { Course3DView(room: room).ignoresSafeArea() }
            SpriteView(scene: scene, options: [.allowsTransparency]).ignoresSafeArea()
            VStack {
                LinearGradient(colors: [night.opacity(0.92), night.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 150).ignoresSafeArea()
                Spacer()
            }
            .allowsHitTesting(false)
            .opacity(cleanShot ? 0 : 1).animation(.easeInOut(duration: 0.5), value: cleanShot)
            VStack(spacing: 0) { header; Spacer(); tray }
                .opacity(cleanShot ? 0 : 1).animation(.easeInOut(duration: 0.5), value: cleanShot)
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
            .opacity(cleanShot ? 0 : 1).animation(.easeInOut(duration: 0.5), value: cleanShot)
            if let t = model.toast {
                Toast(text: t)
                    .task(id: t) { try? await Task.sleep(nanoseconds: 2_600_000_000); model.toast = nil }
            }
            if let c = model.celebration {
                CelebrationView(celebration: c, chime: model.chime,
                                onPlayAgain: { closeCelebration(c); model.start() },
                                onDismiss: { dismissCelebration(c) },
                                onNext: model.nextChallenge.map { next in { closeCelebration(c); model.open(challenge: next, progress: progress) } },
                                onShare: recorder.isAvailable ? { askToShare() } : nil)
                    .transition(.opacity)
            }
            if recorder.isRecording {                                            // the logo, in the corner of every shared video
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("Title").resizable().scaledToFit().frame(height: 30)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.black.opacity(0.35), in: Capsule())
                    }
                }
                .padding(.trailing, 14).padding(.bottom, 24)
                .allowsHitTesting(false)
            }
            if offeringReminders {
                ReminderCard(onYes: {
                    offeringReminders = false; ReminderScheduler.shared.markOffered()
                    Task { await ReminderScheduler.shared.askPermission(progress: progress) }
                }, onNo: { offeringReminders = false; ReminderScheduler.shared.markOffered() })
                .transition(.opacity)
            }
        }
        .background { Backdrop(option: background) }
        .onAppear {
            scene.model = model; scene.marbleGlow = theme.marbleGlow.uiColor; scene.skin = skin
            room.setSkin(skin); room.reduceMotion = reduceMotion
            room.setWall(background.flatMap { UIImage(contentsOfFile: $0.image.path) }, tint: background?.tint ?? 0)
            scene.room = use3D ? room : nil
        }
        .onChange(of: skin.id) { _, _ in scene.skin = skin; room.setSkin(skin) }
        .onChange(of: use3D) { _, on in scene.room = on ? room : nil }
        .onChange(of: model.playing) { _, playing in if !playing && recorder.isRecording { finishRecording() } }
        .task(id: recorder.isRecording) {                                        // shared videos stop at the time limit
            guard recorder.isRecording else { return }
            try? await Task.sleep(nanoseconds: SongRecorder.maxSeconds * 1_000_000_000)
            if recorder.isRecording && model.playing { model.stop() }
        }
        .sheet(item: $sharing, onDismiss: { try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent("Marble Beats.mp4")) }) { v in
            ShareSheet(items: [v.url]).presentationDetents([.medium, .large])
        }
        .alert("Ask a grown-up", isPresented: $askingGrownUp) {
            TextField("Answer", text: $answer).keyboardType(.numberPad)
            Button("Continue") { if ParentalGate.check(answer, against: gate) { recordAndShare() } else { wrongAnswer = true } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Sharing a video needs a grown-up. " + gate.text) }
        .alert("That's not right", isPresented: $wrongAnswer) { Button("OK", role: .cancel) {} } message: { Text("Sharing needs a grown-up.") }
        .alert("Rename song", isPresented: $renaming) {
            TextField("Name", text: $newName)
            Button("Save") { model.rename(to: newName) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Image("Title").resizable().scaledToFit().frame(height: 54)    // the lettering drawn by tools/make_title.swift
                .accessibilityLabel("Marble Beats").allowsHitTesting(false)
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
        if let c = model.challenge { return challengeHint(c) }
        if let p = model.selectedPad {
            switch p.kind {
            case .bar: return "Drag to move, tilt with the dial. Close to the beat? Let go and it snaps on."
            case .ramp: return "The marble rolls along a ramp. Tilt, stretch and bend it; it plays its note when the marble lands."
            case .bumper: return "Drag to move. ♭ ♯ change the note."
            }
        }
        return "The dotted line is where the marble will go. Pads glow gold when they hit on the beat."
    }

    /// Challenges: what to do next, one step at a time.
    private func challengeHint(_ c: Challenge) -> String {
        let stuck = model.canHint ? " Stuck? Tap 💡 Hint (the level then gives up to 2 stars)." : ""
        if let p = model.selectedPad {
            if model.ghost(for: p) != nil { return "Drag it onto the glowing outline. Let go close by and it clicks into place." }
            switch c.goal {
            case .melody: return "Drag the note under the dotted line, where the tune has a gap. Turn the dial so the marble bounces on." + stuck
            case .fix: return "Drag this pad until its ring on the dotted line turns gold: then it plays on the beat." + stuck
            case .target: return "Drag it under the dotted line and turn the dial to steer the marble into the gold ring." + stuck
            }
        }
        if !model.trayLeft.isEmpty {
            if case .melody = c.goal { return "Tap a ♪ note below to take it out of the tray." }
            return "Tap a piece below to take it out of the tray."
        }
        switch c.goal {
        case .fix: return "Pads with a 🔒 stay put. Tap one of the others and drag it until it plays on the beat." + stuck
        case .melody, .target: return "Press Drop to try it. Tap a piece to move it again." + stuck
        }
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
            if model.canHint {
                Button("💡 Hint") { model.showHint() }.accessibilityLabel("Hint: show where a piece goes")
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
