import SwiftUI

@main
struct ChompCrownApp: App {
  @StateObject private var client = GameClient()
  var body: some Scene {
    WindowGroup {
      ContentView(client: client)
        .preferredColorScheme(.dark)
        .onOpenURL { client.handleURL($0) }
    }
  }
}
