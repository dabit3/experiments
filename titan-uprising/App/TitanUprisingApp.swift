import SwiftUI

@main
struct TitanUprisingApp: App {
  @StateObject private var game = GameModel()
  var body: some Scene {
    WindowGroup {
      ContentView(game: game)
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .onOpenURL { game.handleURL($0) }
    }
  }
}
