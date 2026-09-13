import SwiftUI

@main
struct MetroImpactApp: App {
  @StateObject private var session = Session()
  var body: some Scene {
    WindowGroup {
      Group {
        if session.state != nil { ArenaView(session: session) } else { LobbyView(session: session) }
      }
      .ignoresSafeArea()
      .preferredColorScheme(.dark)
      .statusBarHidden()
      .onOpenURL { session.handleURL($0) }
      .onReceive(
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
      ) { _ in session.releaseAll() }
    }
  }
}

struct LobbyView: View {
  @ObservedObject var session: Session
  private let gold = Color(red: 1, green: 0.8, blue: 0.25)
  private let cyan = Color(red: 0.37, green: 0.91, blue: 0.88)
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Image(uiImage: assetImage("harbor")).resizable().interpolation(.none).scaledToFill()
          .frame(width: geometry.size.width, height: geometry.size.height).clipped()
        LinearGradient(
          colors: [.black.opacity(0.25), Color(red: 0.03, green: 0.05, blue: 0.13).opacity(0.96)],
          startPoint: .top, endPoint: .bottom)
        HStack(spacing: 28) {
          VStack(spacing: 4) {
            Text("ONLINE ARCADE • VOL. 01").font(
              .system(size: 11, weight: .bold, design: .monospaced)
            ).tracking(3).foregroundStyle(cyan)
            Image(uiImage: assetImage("title")).resizable().interpolation(.none).scaledToFit()
              .frame(maxHeight: 150)
            Text("THE HARBOR NEVER BACKS DOWN.").font(
              .custom("AvenirNextCondensed-Heavy", size: 18)
            ).foregroundStyle(gold)
            Text("2 PLAYERS · REAL-TIME VERSUS").font(
              .system(size: 10, weight: .bold, design: .monospaced)
            ).foregroundStyle(.white.opacity(0.75)).padding(.top, 8)
            HStack(spacing: 11) {
              fighterCard(
                "kai", title: "KAI", subtitle: "WAVE FIST", detail: "Balanced / quick footwork")
              fighterCard(
                "rhea", title: "RHEA", subtitle: "BLAZE KICK", detail: "Power / extended reach")
            }.padding(.top, 9)
          }.frame(maxWidth: .infinity)
          VStack(alignment: .leading, spacing: 10) {
            HStack {
              Text("ENTER THE ARENA").font(.custom("AvenirNextCondensed-HeavyItalic", size: 28))
                .foregroundStyle(gold)
              Spacer()
              Text("01 / 02").font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(cyan)
            }
            field("GUEST NAME", text: $session.guestName, placeholder: "Your name", id: "guestName")
            field(
              "LOCAL SERVER", text: $session.serverAddress, placeholder: "ws://192.168.1.5:8743",
              id: "serverAddress")
            field(
              "ROOM CODE", text: $session.roomEntry, placeholder: "Blank creates a random code",
              id: "roomCode")
            HStack(spacing: 10) {
              Button {
                session.connect(create: true)
              } label: {
                Text("CREATE ROOM").frame(maxWidth: .infinity).padding(.vertical, 13)
              }.buttonStyle(.plain).background(gold).foregroundStyle(.black)
                .accessibilityIdentifier("createRoom")
              Button {
                session.connect(create: false)
              } label: {
                Text("JOIN").frame(width: 84).padding(.vertical, 13)
              }.buttonStyle(.plain).background(cyan.opacity(0.2)).overlay(Rectangle().stroke(cyan))
                .foregroundStyle(cyan).accessibilityIdentifier("joinRoom")
            }.font(.system(size: 13, weight: .black, design: .monospaced)).disabled(
              session.connecting)
            Text(
              session.connecting
                ? "CONNECTING TO THE HARBOR…"
                : session.error.isEmpty
                  ? "Start the local server, then share your room code.\nNo accounts. Two humans. One stage."
                  : session.error
            )
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(session.error.isEmpty ? .white.opacity(0.65) : .orange)
            .frame(minHeight: 33, alignment: .topLeading)
          }
          .padding(20).frame(width: min(geometry.size.width * 0.43, 400))
          .background(Color(red: 0.04, green: 0.07, blue: 0.14).opacity(0.95))
          .overlay(Rectangle().stroke(.white.opacity(0.2), lineWidth: 1))
        }.padding(.horizontal, max(45, geometry.safeAreaInsets.leading + 16)).padding(.vertical, 18)
        VStack {
          Spacer()
          Text("METRO IMPACT  /  ORIGINAL ARCADE FIGHTER  /  PIER 94")
            .font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(2).foregroundStyle(
              .white.opacity(0.45)
            ).padding(.bottom, 7)
        }
      }
    }
  }

  private func fighterCard(_ character: String, title: String, subtitle: String, detail: String)
    -> some View
  {
    Button {
      session.chosenCharacter = character
    } label: {
      VStack(spacing: 3) {
        HStack(spacing: 0) {
          Image(uiImage: assetImage("\(character)_portrait")).resizable().interpolation(.none)
            .scaledToFit().frame(width: 61, height: 61)
          VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.custom("AvenirNextCondensed-Heavy", size: 25)).foregroundStyle(gold)
            Text(subtitle).font(.system(size: 7, weight: .heavy, design: .monospaced))
              .foregroundStyle(cyan)
          }
        }
        Text(detail).font(.system(size: 7, weight: .medium, design: .monospaced)).foregroundStyle(
          .white.opacity(0.7))
      }
      .frame(maxWidth: .infinity).padding(.vertical, 6)
      .background(session.chosenCharacter == character ? cyan.opacity(0.16) : .black.opacity(0.4))
      .overlay(
        Rectangle().stroke(
          session.chosenCharacter == character ? gold : .white.opacity(0.18), lineWidth: 2))
    }.buttonStyle(.plain).accessibilityIdentifier("character-\(character)")
  }

  private func field(_ title: String, text: Binding<String>, placeholder: String, id: String)
    -> some View
  {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1.5)
        .foregroundStyle(cyan)
      TextField(placeholder, text: text)
        .font(.system(size: 13, weight: .medium, design: .monospaced))
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .padding(9).background(.white.opacity(0.06))
        .overlay(Rectangle().stroke(.white.opacity(0.17)))
        .accessibilityIdentifier(id)
    }
  }
}
