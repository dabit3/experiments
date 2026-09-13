import SwiftUI

@main
struct OrbitalVersusApp: App {
  @StateObject private var client = GameClient()
  @Environment(\.scenePhase) private var scenePhase
  var body: some Scene {
    WindowGroup {
      GameScreen(client: client)
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .onChange(of: scenePhase) { _, phase in
          if phase != .active { client.suspendInput() }
        }
    }
  }
}
