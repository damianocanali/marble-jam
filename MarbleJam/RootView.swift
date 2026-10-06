import SwiftUI

/// Menu → My Songs → builder. Owns the song store and the one GameModel.
struct RootView: View {
    enum Screen { case menu, library, play }
    @State private var store: SongStore
    @State private var model: GameModel                 // not observed here: ContentView observes it, so the scene is not rebuilt per change
    @State private var screen = Screen.menu
    @AppStorage("background.v1") private var backgroundID = ""   // "" = night sky
    private var background: BackgroundOption? { BackgroundLibrary.bundled.first { $0.id == backgroundID } }

    init() {
        let s = SongStore(folder: SongStore.appFolder())
        _store = State(initialValue: s)
        _model = State(initialValue: GameModel(store: s))
    }

    var body: some View {
        ZStack {
            switch screen {
            case .menu:
                MenuView(background: background, backgroundID: $backgroundID, onCreate: { screen = .library })
                    .transition(.opacity)
            case .library:
                LibraryView(store: store, background: background, onOpen: { model.open($0); screen = .play }, onBack: { screen = .menu })
                    .transition(.opacity)
            case .play:
                ContentView(model: model, background: background, onMenu: { model.stop(); model.save(); screen = .library })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screen)
        .preferredColorScheme(.dark)
        .task { store.migrateIfNeeded(defaults: .standard) }
    }
}
