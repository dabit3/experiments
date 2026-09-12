import SwiftUI

@main
struct PocketPelotonApp: App {
  @StateObject private var store = GameStore()

  var body: some Scene {
    WindowGroup {
      PelotonView()
        .environmentObject(store)
        .preferredColorScheme(.light)
    }
  }
}
