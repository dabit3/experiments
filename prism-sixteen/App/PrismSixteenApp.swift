import SwiftUI

@main
struct PrismSixteenApp: App {
  @StateObject private var model = GameModel()

  var body: some Scene {
    WindowGroup {
      ContentView(model: model)
        .preferredColorScheme(.dark)
    }
  }
}
