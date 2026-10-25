import SwiftUI

/// Menu → My Songs → builder. Owns the song store and the one GameModel.
struct RootView: View {
    enum Screen: String { case menu, library, play, challenges, store, account }
    @State private var store: SongStore
    @State private var model: GameModel                 // not observed here: ContentView observes it, so the scene is not rebuilt per change
    @State private var screen = Screen.menu
    @State private var progress = ChallengeProgress(cloud: NSUbiquitousKeyValueStore.default)
    @StateObject private var shop = Store()
    @StateObject private var gameCenter = GameCenter()
    @State private var syncTick = 0
    @State private var syncing = false                       // bumped after iCloud brings in songs or stars, so screens re-read them
    @AppStorage("skin.v1") private var skinID = Skins.classic.id
    /// The chosen skin while it is owned (a refunded pack falls back to Classic).
    private var skin: Skin {
        #if DEBUG
        if let id = CaptureMode.current.skin { return Skins.skin(id) }          // captures may show any marble
        #endif
        let s = Skins.skin(skinID)
        return Skins.isOwned(s, stars: progress.mainStars(), holidaysDone: progress.holidaysDone(), purchased: shop.purchased) ? s : Skins.classic
    }
    @Environment(\.scenePhase) private var phase
    @AppStorage("background.v1") private var backgroundID = ""   // "" = night sky
    @AppStorage("season.preview") private var seasonPreview = ""        // DEBUG builds only (see MenuView); "" = by date
    private var season: Season? {
        #if DEBUG
        Seasons.current(on: Date(), preview: CaptureMode.current.season ?? seasonPreview)
        #else
        Seasons.current(on: Date(), preview: "")
        #endif
    }
    private var backgrounds: [BackgroundOption] { BackgroundLibrary.available(BackgroundLibrary.bundled, season: season?.id) }
    private var background: BackgroundOption? {
        #if DEBUG
        let chosen = CaptureMode.current.background ?? backgroundID
        #else
        let chosen = backgroundID
        #endif
        return BackgroundLibrary.resolve(BackgroundLibrary.bundled, chosenID: chosen, season: season?.id)
    }

    init() {
        let s = SongStore(folder: SongStore.appFolder())
        _store = State(initialValue: s)
        let m = GameModel(store: s)
        #if DEBUG
        if let open = CaptureMode.current.screen {                          // captures: straight to a screen, the builder with a fresh demo
            _screen = State(initialValue: open)
            if open == .play { m.open(s.resetDemo()) }
        }
        #endif
        _model = State(initialValue: m)
    }

    var body: some View {
        ZStack {
            switch screen {
            case .menu:
                MenuView(background: background, backgrounds: backgrounds, season: season, backgroundID: $backgroundID, onCreate: { screen = .library }, onChallenges: { screen = .challenges }, onStore: { screen = .store }, onAccount: { screen = .account })
                    .transition(.opacity)
            case .library:
                LibraryView(store: store, background: background, season: season, onOpen: { model.open($0); screen = .play }, onBack: { screen = .menu })
                    .id(syncTick)
                    .transition(.opacity)
            case .play:
                ContentView(model: model, background: background, progress: progress, onMenu: {
                    model.stop(); model.save(); screen = model.challenge == nil ? .library : .challenges
                    gameCenter.report(progress)
                })
                    .transition(.opacity)
            case .store:
                StoreView(store: shop, progress: progress, background: background, skinID: $skinID, onBack: { screen = .menu })
                    .transition(.opacity)
            case .account:
                AccountView(gameCenter: gameCenter, store: shop, background: background, onBack: { screen = .menu })
                    .transition(.opacity)
            case .challenges:
                ChallengesView(progress: progress, background: background, season: season, onPlay: { model.open(challenge: $0, progress: progress); screen = .play },
                               onBack: { screen = .menu })
                    .id(syncTick)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screen)
        .preferredColorScheme(.dark)
        .environment(\.theme, Theme.forSeason(season?.id))
        .environment(\.marbleSkin, skin)
        .task { await shop.refreshPurchases() }
        .onChange(of: phase) { _, p in
            guard p == .active else { return }
            AppIcons.update(for: season?.id)                    // holiday icon on when it starts, off when it ends
            syncSongs()
        }
        .onChange(of: season?.id) { _, id in AppIcons.update(for: id) }
        .task {
            store.migrateIfNeeded(defaults: .standard)
            await connectCloud()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)) { _ in pullFromCloud() }
        .onChange(of: skinID) { _, id in NSUbiquitousKeyValueStore.default.set(id, forKey: "skin.v1") }
        #if DEBUG
        .task {                                                             // captures: press Drop after the delay asked for
            guard let delay = CaptureMode.current.autoPlay, screen == .play else { return }
            try? await Task.sleep(for: .seconds(delay))
            if screen == .play, !model.playing { model.start() }
        }
        #endif
    }

    /// iCloud: stars and the chosen marble through the key-value store, songs through the app's iCloud Drive folder.
    /// Without iCloud (signed out, or no entitlement) all of this quietly does nothing and everything stays on the phone.
    private func connectCloud() async {
        gameCenter.onSignIn = { [progress, gameCenter] in gameCenter.report(progress) }
        gameCenter.resume()
        NSUbiquitousKeyValueStore.default.synchronize()
        pullFromCloud()
        let container = await Task.detached { FileManager.default.url(forUbiquityContainerIdentifier: nil) }.value   // can be slow: never on the main thread
        if let container {
            store.mirror = container.appendingPathComponent("Documents/Songs", isDirectory: true)
            syncSongs()
        }
    }

    private func pullFromCloud() {
        progress.pullFromCloud()
        if let id = NSUbiquitousKeyValueStore.default.string(forKey: "skin.v1"), id != skinID, Skins.all.contains(where: { $0.id == id }) { skinID = id }
        syncTick += 1
    }

    private func syncSongs() {
        guard store.mirror != nil, screen != .play, !syncing else { return }   // never swap a song out from under the builder
        syncing = true
        Task {
            await Task.detached { [store] in store.syncWithMirror() }.value    // reads and writes every song: off the main thread
            syncing = false
            syncTick += 1
        }
    }
}
