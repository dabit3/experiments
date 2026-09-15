import SwiftUI

@main
struct LastfortApp: App {
  @StateObject private var profile: Profile
  @StateObject private var session: Session
  private let catalogue: Result<Catalogue, Error>
  init() {
    registerFonts()
    let options = LaunchOptions()
    let defaults =
      options["TEST"].flatMap { UserDefaults(suiteName: "com.lastfort.test.\($0)") } ?? .standard
    let profile = Profile(defaults: defaults)
    _profile = StateObject(wrappedValue: profile)
    _session = StateObject(wrappedValue: Session(profile: profile, options: options))
    catalogue = Result { try Catalogue.load() }
  }
  var body: some Scene {
    #if os(macOS)
      Window("Lastfort", id: "lastfort") { content }
        .defaultSize(width: 1280, height: 820)
    #else
      WindowGroup { content }
    #endif
  }
  @ViewBuilder private var content: some View {
    switch catalogue {
    case .success(let catalogue):
      RootView(catalogue: catalogue)
        .environmentObject(profile).environmentObject(session)
        .preferredColorScheme(
          profile.data.theme == "dark" ? .dark : profile.data.theme == "light" ? .light : nil)
    case .failure(let error):
      ContentUnavailableView(
        "Resources could not load", systemImage: "exclamationmark.triangle",
        description: Text(error.localizedDescription))
    }
  }
}
struct RootView: View {
  @EnvironmentObject private var profile: Profile
  @EnvironmentObject private var session: Session
  @Environment(\.scenePhase) private var scenePhase
  let catalogue: Catalogue
  var body: some View {
    VStack(spacing: 0) {
      if let error = session.error ?? profile.persistenceError {
        HStack {
          Image(systemName: "exclamationmark.triangle.fill")
          Text(error).font(.custom("Rajdhani-Medium", size: 16)).frame(
            maxWidth: .infinity, alignment: .leading)
          Button("Dismiss") {
            session.error = nil
            profile.persistenceError = nil
          }
        }.padding(10).foregroundStyle(.white).background(Color.fortDanger.opacity(0.8))
      }
      if let match = session.match {
        MatchFlow(match: match, catalogue: catalogue).id(ObjectIdentifier(match))
      } else {
        HubView(catalogue: catalogue)
      }
    }
    .font(.custom("Rajdhani-Medium", size: 18)).tint(.fortTeal)
    .task { session.connect() }
    .onChange(of: scenePhase) { _, phase in
      #if os(iOS)
        if phase == .background { session.disconnect() }
        if phase == .active && session.connection == .offline { session.connect() }
      #endif
    }
    #if os(macOS)
      .frame(minWidth: 640, minHeight: 480)
    #endif
  }
}
struct MatchFlow: View {
  @ObservedObject var match: MatchReplica
  let catalogue: Catalogue
  var body: some View {
    if let summary = match.summary {
      ResultsView(summary: summary, playerID: match.localID)
    } else {
      MatchView(match: match, catalogue: catalogue)
    }
  }
}
