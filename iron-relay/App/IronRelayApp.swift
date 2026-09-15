import SwiftUI

@main
struct IronRelayApp: App {
  @StateObject private var client = GameClient()
  var body: some Scene {
    WindowGroup {
      ContentView(client: client)
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .onOpenURL { client.handleURL($0) }
    }
  }
}
