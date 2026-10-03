import SwiftUI

/// Switches between the start menu and the game. Owns the one GameModel so the course survives the trip.
struct RootView: View {
    enum Screen { case menu, play }
    @StateObject private var model = GameModel()
    @State private var screen = Screen.menu

    var body: some View {
        ZStack {
            switch screen {
            case .menu:
                MenuView(onPlay: { screen = .play }, onDemo: { model.loadDemo(); screen = .play })
                    .transition(.opacity)
            case .play:
                ContentView(model: model, onMenu: { model.stop(); model.save(); screen = .menu })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screen)
        .preferredColorScheme(.dark)
    }
}
