import SwiftUI

@main
struct PowderlineApp: App {
  var body: some Scene {
    WindowGroup {
      PowderlineView()
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
  }
}
