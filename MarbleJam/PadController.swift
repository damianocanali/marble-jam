import SwiftUI

/// Shown while a pad is selected: D-pad to move, ♭/♯ for the note, a dial to tilt bars.
struct PadController: View {
    @ObservedObject var model: GameModel
    @GestureState private var dialing = false     // resets on its own if the gesture is cancelled
    @State private var dialMarked = false

    private let ink = Color(red: 0.95, green: 0.96, blue: 1)
    private let panel = Color(red: 0.055, green: 0.07, blue: 0.15).opacity(0.9)

    var body: some View {
        if let p = model.selectedPad {
            HStack(alignment: .center, spacing: 14) {
                dpad
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Button("♭") { model.stepNote(-1) }.buttonStyle(Chip())
                        Text(Notes.name(p)).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(ink).frame(minWidth: 40)
                        Button("♯") { model.stepNote(1) }.buttonStyle(Chip())
                    }
                    HStack(spacing: 6) {
                        Button { model.deleteSelected() } label: { Image(systemName: "trash") }.buttonStyle(Chip())
                            .accessibilityLabel("Delete")
                        Button("✓ Done") { model.selected = nil }.buttonStyle(Chip())
                    }
                }
                dial(enabled: p.kind == .bar, angle: p.angle)
            }
        }
    }

    // MARK: D-pad

    private var dpad: some View {
        VStack(spacing: 2) {
            arrow("chevron.up", 0, -1)
            HStack(spacing: 2) {
                arrow("chevron.left", -1, 0)
                Circle().fill(ink.opacity(0.25)).frame(width: 10, height: 10).frame(width: 38, height: 38)
                arrow("chevron.right", 1, 0)
            }
            arrow("chevron.down", 0, 1)
        }
    }

    /// Tap moves 4 points; after a short hold it keeps sliding, speeding up to 12 points a tick.
    private func arrow(_ icon: String, _ ux: Double, _ uy: Double) -> some View {
        HoldButton(onBegin: { model.mark() }, onEnd: { model.save() }, onTick: { n in
            guard n == 0 || n >= 9 else { return }
            let step = n == 0 ? 4 : min(12, 4 + 8 * Double(n - 9) / 30)
            model.nudge(dx: ux * step, dy: uy * step)
        }) {
            Image(systemName: icon).font(.system(size: 16, weight: .heavy)).foregroundStyle(ink)
                .frame(width: 38, height: 38)
                .background(panel, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.18)))
        }
    }

    // MARK: rotate dial

    private func dial(enabled: Bool, angle: Double) -> some View {
        let size = 72.0
        return VStack(spacing: 6) {
            ZStack {
                Circle().fill(panel).overlay(Circle().stroke(Color.white.opacity(0.18)))
                Capsule().fill(Color.cyan).frame(width: size * 0.7, height: 6).rotationEffect(.radians(angle))
                Circle().fill(.white).frame(width: 10, height: 10)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0).updating($dialing) { _, s, _ in s = true }.onChanged { v in
                if !dialMarked { dialMarked = true; model.mark() }
                model.setAngle(Rules.barAngle(dx: v.location.x - size / 2, dy: v.location.y - size / 2))
            })
            .onChange(of: dialing) { _, down in if !down && dialMarked { dialMarked = false; model.save() } }
            HStack(spacing: 6) {
                spin("arrow.counterclockwise", -1)
                spin("arrow.clockwise", 1)
            }
        }
        .opacity(enabled ? 1 : 0.35)
        .disabled(!enabled)
    }

    /// 5° per tap; repeats while held.
    private func spin(_ icon: String, _ dir: Double) -> some View {
        HoldButton(onBegin: { model.mark() }, onEnd: { model.save() }, onTick: { n in
            if n == 0 || (n >= 9 && n % 3 == 0) { model.rotate(by: dir * Rules.rotateStep) }
        }) {
            Image(systemName: icon).font(.system(size: 13, weight: .heavy)).foregroundStyle(ink)
                .frame(width: 33, height: 30)
                .background(panel, in: RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(0.18)))
        }
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
