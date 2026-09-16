import SwiftUI

@main
struct FlappyOtterApp: App {
  var body: some Scene {
    WindowGroup {
      OtterGameView()
        .preferredColorScheme(.light)
    }
  }
}
