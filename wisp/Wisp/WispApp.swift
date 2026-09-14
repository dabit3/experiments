import SwiftUI

@main
struct WispApp: App {
    @State private var app = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .tint(.ink)
                .preferredColorScheme(app.settings.appearance.colorScheme)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            if app.hasKey {
                ChatScreen()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: app.hasKey)
    }
}
