import SwiftUI

/// Menu → My Songs → builder. Owns the song store and the one GameModel.
struct RootView: View {
    enum Screen { case menu, library, play, challenges }
    @State private var store: SongStore
    @State private var model: GameModel                 // not observed here: ContentView observes it, so the scene is not rebuilt per change
    @State private var screen = Screen.menu
    @State private var progress = ChallengeProgress()
    @Environment(\.scenePhase) private var phase
    @AppStorage("background.v1") private var backgroundID = ""   // "" = night sky
    @AppStorage("season.preview") private var seasonPreview = ""        // DEBUG builds only (see MenuView); "" = by date
    private var season: Season? {
        #if DEBUG
        Seasons.current(on: Date(), preview: seasonPreview)
        #else
        Seasons.current(on: Date(), preview: "")
        #endif
    }
    private var backgrounds: [BackgroundOption] { BackgroundLibrary.available(BackgroundLibrary.bundled, season: season?.id) }
    private var background: BackgroundOption? { BackgroundLibrary.resolve(BackgroundLibrary.bundled, chosenID: backgroundID, season: season?.id) }

    init() {
        let s = SongStore(folder: SongStore.appFolder())
        _store = State(initialValue: s)
        _model = State(initialValue: GameModel(store: s))
    }

    var body: some View {
        ZStack {
            switch screen {
            case .menu:
                MenuView(background: background, backgrounds: backgrounds, season: season, backgroundID: $backgroundID, onCreate: { screen = .library }, onChallenges: { screen = .challenges })
                    .transition(.opacity)
            case .library:
                LibraryView(store: store, background: background, season: season, onOpen: { model.open($0); screen = .play }, onBack: { screen = .menu })
                    .transition(.opacity)
            case .play:
                ContentView(model: model, background: background, progress: progress, onMenu: { model.stop(); model.save(); screen = model.challenge == nil ? .library : .challenges })
                    .transition(.opacity)
            case .challenges:
                ChallengesView(progress: progress, background: background, onPlay: { model.open(challenge: $0, progress: progress); screen = .play },
                               onBack: { screen = .menu })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screen)
        .preferredColorScheme(.dark)
        .environment(\.theme, Theme.forSeason(season?.id))
        .onChange(of: phase) { _, p in if p == .active { AppIcons.update(for: season?.id) } }   // holiday icon on when it starts, off when it ends
        .onChange(of: season?.id) { _, id in AppIcons.update(for: id) }
        .task { store.migrateIfNeeded(defaults: .standard) }
    }
}
