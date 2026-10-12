import GameKit
import SwiftUI

/// Game Center: a leaderboard of total stars and one achievement per finished world. It signs in only when the player asks
/// (on the Account screen), and after that quietly on each launch.
@MainActor final class GameCenter: ObservableObject {
    nonisolated static let leaderboardID = "marblejam.stars"
    nonisolated static func achievementID(world: Int) -> String { "marblejam.world\(world)" }

    @Published private(set) var playerName: String?
    @Published private(set) var problem: String?
    var isSignedIn: Bool { playerName != nil }
    /// Called once signed in, e.g. to send the stars earned so far.
    var onSignIn: (() -> Void)?
    private let defaults: UserDefaults
    private let onKey = "gamecenter.on"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func signIn() {
        defaults.set(true, forKey: onKey)
        GKLocalPlayer.local.authenticateHandler = { [weak self] login, error in
            Task { @MainActor in
                guard let self else { return }
                if let login { Self.present(login); return }
                if GKLocalPlayer.local.isAuthenticated {
                    self.playerName = GKLocalPlayer.local.displayName; self.problem = nil
                    self.onSignIn?()
                } else {
                    self.playerName = nil
                    self.problem = error == nil ? nil : "Game Center isn't available. Check that you're signed in under Settings › Game Center."
                }
            }
        }
    }

    /// At launch: sign in again only if the player turned Game Center on before.
    func resume() { if defaults.bool(forKey: onKey) { signIn() } }

    func report(_ progress: ChallengeProgress) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let score = Self.score(progress), worlds = Self.finishedWorlds(progress)
        Task {
            try? await GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [Self.leaderboardID])
            let done = worlds.map { w -> GKAchievement in
                let a = GKAchievement(identifier: Self.achievementID(world: w)); a.percentComplete = 100; a.showsCompletionBanner = true
                return a
            }
            if !done.isEmpty { try? await GKAchievement.report(done) }
        }
    }

    func show(_ state: GKGameCenterViewControllerState) { GKAccessPoint.shared.trigger(state: state) {} }

    /// Every star in every world, holidays included.
    nonisolated static func score(_ p: ChallengeProgress) -> Int {
        p.totalStars(ids: Challenges.mainIDs + Seasons.all.flatMap { Challenges.holidayIDs($0.id) })
    }

    /// Worlds with a star on every level, in order.
    nonisolated static func finishedWorlds(_ p: ChallengeProgress) -> [Int] {
        let main = (1...5).map { w in (w, Challenges.mainIDs.filter { $0.hasPrefix("w\(w)-") }) }
        let holidays = Challenges.holidayWorlds.map { ($0.value, Challenges.holidayIDs($0.key)) }
        return (main + holidays).filter { _, ids in !ids.isEmpty && ids.allSatisfy { p.stars($0) > 0 } }.map(\.0).sorted()
    }

    private static func present(_ vc: UIViewController) {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let next = top?.presentedViewController { top = next }
        top?.present(vc, animated: true)
    }
}

/// Account: iCloud sync status, Game Center, and restoring purchases.
struct AccountView: View {
    @ObservedObject var gameCenter: GameCenter
    @ObservedObject var store: Store
    let background: BackgroundOption?
    let onBack: () -> Void
    @State private var iCloudOn = FileManager.default.ubiquityIdentityToken != nil
    private let ink = Color(red: 0.95, green: 0.96, blue: 1)
    private let muted = Color(red: 0.6, green: 0.65, blue: 0.78)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Image(systemName: "chevron.left").font(.system(size: 16, weight: .heavy)).frame(width: 40, height: 40) }
                    .buttonStyle(Chip()).accessibilityLabel("Menu")
                Spacer()
                Text("Account").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(ink)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    card("iCloud", icon: "icloud") {
                        line(iCloudOn ? "Your songs, stars and marble are kept in iCloud and shared with your other devices."
                                      : "Sign in to iCloud in the Settings app to keep your songs and stars on all your devices.")
                    }
                    card("Game Center", icon: "gamecontroller") {
                        if let name = gameCenter.playerName {
                            line("Signed in as \(name).")
                            HStack(spacing: 10) {
                                Button("Leaderboard") { gameCenter.show(.leaderboards) }.buttonStyle(Chip(primary: true))
                                Button("Achievements") { gameCenter.show(.achievements) }.buttonStyle(Chip())
                            }
                        } else {
                            line("Compare stars with friends and collect a badge for every world you finish.")
                            Button("Sign in to Game Center") { gameCenter.signIn() }.buttonStyle(Chip(primary: true))
                        }
                        if let p = gameCenter.problem { line(p) }
                    }
                    card("Purchases", icon: "bag") {
                        line("Packs you buy work on every device signed in with the same Apple ID.")
                        Button("Restore purchases") { Task { await store.restore() } }.buttonStyle(Chip())
                        if let m = store.message ?? store.failed { line(m) }
                    }
                }
                .padding(16)
            }
        }
        .background { Backdrop(option: background) }
        .onReceive(NotificationCenter.default.publisher(for: .NSUbiquityIdentityDidChange)) { _ in
            iCloudOn = FileManager.default.ubiquityIdentityToken != nil
        }
    }

    private func line(_ text: String) -> some View {
        Text(text).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(muted).fixedSize(horizontal: false, vertical: true)
    }

    private func card<Content: View>(_ title: String, icon: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(ink)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.15)))
    }
}
