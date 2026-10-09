import SwiftUI

/// The "You did it!" sticker: slams in with a springy tilt, stars pop with chimes, confetti bursts.
struct CelebrationView: View {
    let celebration: Celebration
    let chime: (Int) -> Void
    let onPlayAgain: () -> Void
    let onDismiss: () -> Void
    var onNext: (() -> Void)? = nil                    // challenges: go on to the next level

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var starsShown = 0
    @State private var burst: Date?

    var body: some View {
        ZStack {
            Color.black.opacity(shown ? 0.45 : 0).ignoresSafeArea().onTapGesture(perform: onDismiss)
            if let b = burst { Confetti(start: b).allowsHitTesting(false) }
            sticker
                .scaleEffect(reduceMotion ? 1 : (shown ? 1 : 0.2))
                .rotationEffect(.degrees(reduceMotion ? -6 : (shown ? -6 : -25)))
                .opacity(shown ? 1 : 0)
        }
        .task { await play() }
    }

    private var sticker: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < celebration.stars ? "star.fill" : "star")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(i < celebration.stars ? Color.yellow : Color.white.opacity(0.5))
                        .scaleEffect(i < starsShown ? 1 : 0.01)
                        .animation(.spring(response: 0.3, dampingFraction: 0.45), value: starsShown)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(celebration.stars) of 3 stars")
            Text(celebration.headline)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: 3)
                .multilineTextAlignment(.center)
            Text("\(celebration.notes) notes · \(celebration.onBeat) on the beat")
                .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.9))
            HStack(spacing: 8) {
                Button(onNext == nil ? "Keep editing" : "Stay", action: onDismiss).buttonStyle(Chip())
                if let onNext {
                    Button("Next level ▶", action: onNext).buttonStyle(Chip(primary: true))
                } else {
                    Button("Play again ▶", action: onPlayAgain).buttonStyle(Chip(primary: true))
                }
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 26).padding(.vertical, 22)
        .background(LinearGradient(colors: [.purple, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white, lineWidth: 7))       // die-cut border
        .shadow(color: .black.opacity(0.5), radius: 18, y: 10)
        .padding(24)
    }

    private func play() async {
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.3)) { shown = true }
            starsShown = 3
            for i in 0..<celebration.stars { chime(i) }
            return
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { shown = true }
        try? await Task.sleep(nanoseconds: 350_000_000)
        burst = Date()
        for i in 0..<3 {
            starsShown = i + 1
            if i < celebration.stars { chime(i) }
            try? await Task.sleep(nanoseconds: 180_000_000)
        }
    }
}

/// A one-shot burst of coloured pieces in the note hues, falling and fading over 1.5 s.
private struct Confetti: View {
    let start: Date
    @State private var pieces: [(vx: Double, vy: Double, spin: Double, hue: Double)] = (0..<70).map { _ in
        (Double.random(in: -320...320), Double.random(in: -620 ... -220), Double.random(in: -8...8),
         Notes.hues.randomElement()! / 360)
    }

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSince(start)
                guard t < 1.5 else { return }
                let cx = size.width / 2, cy = size.height * 0.42
                for p in pieces {
                    let x = cx + p.vx * t, y = cy + p.vy * t + 0.5 * 900 * t * t
                    var c = ctx
                    c.translateBy(x: x, y: y); c.rotate(by: .radians(p.spin * t))
                    c.opacity = max(0, 1 - t / 1.5)
                    c.fill(Path(CGRect(x: -5, y: -3, width: 10, height: 6)),
                           with: .color(Color(hue: p.hue, saturation: 0.82, brightness: 1)))
                }
            }
        }
        .ignoresSafeArea()
    }
}
