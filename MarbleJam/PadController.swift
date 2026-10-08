import SwiftUI

/// Shown while a piece is selected: a dial to tilt bars and ramps, ♭/♯ for the note, and a ramp's length and bend. Moving is done by dragging.
struct PadController: View {
    @ObservedObject var model: GameModel
    @Environment(\.theme) private var theme
    @GestureState private var dialing = false     // resets on its own if the gesture is cancelled
    @State private var dialMarked = false

    private let ink = Color(red: 0.95, green: 0.96, blue: 1)
    private let panel = Color(red: 0.055, green: 0.07, blue: 0.15).opacity(0.9)

    var body: some View {
        if let p = model.selectedPad, !model.isLocked(p.id) {
          VStack(spacing: 8) {
            if p.kind == .ramp {
                HStack(spacing: 8) {
                    Button { model.stepLength(-1) } label: { Image(systemName: "arrow.right.and.line.vertical.and.arrow.left") }.accessibilityLabel("Shorter")
                    Text("Length").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(ink)
                    Button { model.stepLength(1) } label: { Image(systemName: "arrow.left.and.line.vertical.and.arrow.right") }.accessibilityLabel("Longer")
                    Spacer().frame(width: 12)
                    Button { model.stepBend(-1) } label: { Image(systemName: "arrow.up.right.and.arrow.down.left") }.accessibilityLabel("More hump")
                    Text("Bend").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(ink)
                    Button { model.stepBend(1) } label: { Image(systemName: "arrow.down.left.and.arrow.up.right") }.accessibilityLabel("More dip")
                }
                .buttonStyle(Chip())
            }
            HStack(spacing: 10) {
                if p.kind != .bumper {
                    spin("arrow.counterclockwise", -1)
                    dial(angle: p.angle)
                    spin("arrow.clockwise", 1)
                    Spacer().frame(width: 10)
                }
                if model.canChangeNote { Button("♭") { model.stepNote(-1) }.buttonStyle(Chip()) }
                Text(Notes.label(p, instrument: model.instrument)).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(ink).frame(minWidth: 40)
                if model.canChangeNote { Button("♯") { model.stepNote(1) }.buttonStyle(Chip()) }
            }
          }
        }
    }

    // MARK: rotate dial

    private func dial(angle: Double) -> some View {
        let size = 56.0
        return ZStack {
            Circle().fill(panel).overlay(Circle().stroke(Color.white.opacity(0.18)))
            Capsule().fill(theme.accent.color).frame(width: size * 0.7, height: 5).rotationEffect(.radians(angle))
            Circle().fill(.white).frame(width: 8, height: 8)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 0).updating($dialing) { _, s, _ in s = true }.onChanged { v in
            if !dialMarked { dialMarked = true; model.mark() }
            model.setAngle(Rules.barAngle(dx: v.location.x - size / 2, dy: v.location.y - size / 2))
        })
        .onChange(of: dialing) { _, down in if !down && dialMarked { dialMarked = false; if model.finishEdit() { Haptics.snapped() } } }
        .accessibilityLabel("Tilt")
    }

    /// 5° per tap; repeats while held.
    private func spin(_ icon: String, _ dir: Double) -> some View {
        HoldButton(onBegin: { model.mark() }, onEnd: { if model.finishEdit() { Haptics.snapped() } }, onTick: { n in
            if n == 0 || (n >= 9 && n % 3 == 0) { model.rotate(by: dir * Rules.rotateStep) }
        }) {
            Image(systemName: icon).font(.system(size: 15, weight: .heavy)).foregroundStyle(ink)
                .frame(width: 44, height: 44)
                .background(panel, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.18)))
        }
        .accessibilityLabel(dir < 0 ? "Tilt left" : "Tilt right")
    }
}

/// A button that fires `onTick(0)` on touch-down, then `onTick(1, 2, ...)` every 1/30 s until released.
struct HoldButton<Label: View>: View {
    var onBegin: () -> Void = {}
    var onEnd: () -> Void = {}
    let onTick: (Int) -> Void
    @ViewBuilder let label: () -> Label
    @GestureState private var pressed = false     // resets on its own if the gesture is cancelled
    @State private var task: Task<Void, Never>?
    @Environment(\.isEnabled) private var enabled
    @Environment(\.scenePhase) private var phase

    var body: some View {
        label()
            .opacity(pressed ? 0.7 : 1)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).updating($pressed) { _, s, _ in s = true })
            .onChange(of: pressed) { _, down in down ? begin() : stop() }
            .onChange(of: phase) { _, p in if p != .active { stop() } }
            .onDisappear { stop() }
    }

    private func begin() {
        guard task == nil, enabled else { return }
        onBegin()
        task = Task { @MainActor in
            var n = 0
            while !Task.isCancelled {
                onTick(n); n += 1
                try? await Task.sleep(nanoseconds: 33_000_000)
            }
        }
    }

    private func stop() {
        guard let t = task else { return }
        t.cancel(); task = nil; onEnd()
    }
}
