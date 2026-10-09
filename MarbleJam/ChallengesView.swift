import SwiftUI

/// The five worlds and their levels, with stars and locks. Tap an open level to play it.
struct ChallengesView: View {
    let progress: ChallengeProgress
    let background: BackgroundOption?
    let onPlay: (Challenge) -> Void
    let onBack: () -> Void

    @State private var levels: [Challenge] = []
    @Environment(\.theme) private var theme
    private let ink = Color(red: 0.95, green: 0.96, blue: 1)
    private let muted = Color(red: 0.6, green: 0.65, blue: 0.78)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Image(systemName: "chevron.left").font(.system(size: 16, weight: .heavy)).frame(width: 40, height: 40) }
                    .buttonStyle(Chip()).accessibilityLabel("Menu")
                Spacer()
                Text("Challenges").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(ink)
                Spacer()
                Label("\(progress.totalStars(in: levels))", systemImage: "star.fill")
                    .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.yellow)
                    .frame(minWidth: 40).accessibilityLabel("\(progress.totalStars(in: levels)) stars")
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            if levels.isEmpty {
                Spacer(); ProgressView().tint(ink); Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(1...5, id: \.self) { w in world(w) }
                    }
                    .padding(16)
                }
            }
        }
        .background { Backdrop(option: background) }
        .task { if levels.isEmpty { levels = await Task.detached(priority: .userInitiated) { Challenges.all }.value } }  // built once, off screen
    }

    private func world(_ w: Int) -> some View {
        let inWorld = levels.filter { $0.world == w }
        let open = inWorld.first.map { progress.isUnlocked($0, in: levels) } ?? false
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(w). \(Challenges.worldNames[w - 1])").font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(ink)
                Spacer()
                Text("\(progress.totalStars(in: inWorld)) / \(inWorld.count * 3) ★").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(muted)
            }
            if !open && w > 1 {
                Text("Earn \(10 * (w - 1)) stars and finish world \(w - 1) to open.").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(muted)
            }
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(inWorld) { c in cell(c) }
            }
        }
    }

    private func cell(_ c: Challenge) -> some View {
        let open = progress.isUnlocked(c, in: levels), stars = progress.stars(c.id)
        return Button { onPlay(c) } label: {
            VStack(spacing: 6) {
                Text("\(c.number)").font(.system(size: 24, weight: .black, design: .rounded))
                if open {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star").font(.system(size: 11)).foregroundStyle(i < stars ? Color.yellow : muted)
                        }
                    }
                } else {
                    Image(systemName: "lock.fill").font(.system(size: 13)).foregroundStyle(muted)
                }
                Text(c.title).font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(muted).lineLimit(1)
            }
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(theme.chipFill.color.opacity(0.92), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.chipStroke.color.opacity(theme.chipStrokeOpacity)))
            .opacity(open ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!open)
        .accessibilityLabel(open ? "Level \(c.number), \(c.title), \(stars) of 3 stars" : "Level \(c.number), locked")
    }
}
