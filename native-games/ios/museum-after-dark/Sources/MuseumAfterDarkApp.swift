import SwiftUI
import UIKit

@main
struct MuseumAfterDarkApp: App {
  @StateObject private var store = HeistStore()
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      MuseumRoot()
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
          if phase == .background {
            store.persist()
            if store.screen == .play && store.state.outcome == .playing { store.showPause = true }
          }
        }
    }
  }
}

struct MuseumRoot: View {
  @EnvironmentObject private var store: HeistStore
  var body: some View {
    ZStack {
      Palette.ink.ignoresSafeArea()
      switch store.screen {
      case .home: HomeView()
      case .rooms: RoomsView()
      case .play:
        if store.state.outcome == .escaped { ResultView() } else { PlayView() }
      }
    }
    .foregroundStyle(Palette.paper)
    .tint(Palette.gold)
    .sheet(isPresented: $store.showSettings, onDismiss: store.persist) { SettingsView() }
    .sheet(isPresented: $store.showPause) { PauseView() }
  }
}

struct Eyebrow: View {
  let text: String
  var color = Palette.gold
  var body: some View {
    Text(text).font(.system(size: 10, weight: .semibold, design: .monospaced))
      .tracking(2.3).foregroundStyle(color)
  }
}

struct GoldButton: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 14, weight: .semibold))
      .tracking(1)
      .foregroundStyle(Palette.ink)
      .frame(maxWidth: .infinity)
      .frame(height: 54)
      .background(
        configuration.isPressed ? Palette.paper : Palette.gold,
        in: RoundedRectangle(cornerRadius: 4)
      )
      .scaleEffect(configuration.isPressed ? 0.985 : 1)
  }
}

struct IconButton: View {
  let symbol: String
  let label: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Image(systemName: symbol).font(.system(size: 17, weight: .light))
        .frame(width: 44, height: 44)
        .overlay(Circle().stroke(Palette.gold.opacity(0.28), lineWidth: 1))
    }
    .accessibilityLabel(label)
    .accessibilityIdentifier(label)
  }
}

struct HomeView: View {
  @EnvironmentObject private var store: HeistStore
  var body: some View {
    GeometryReader { geo in
      ScrollView {
        VStack(spacing: 0) {
          HStack {
            Eyebrow(text: "A COLLECTION OF QUIET CRIMES")
            Spacer()
            IconButton(symbol: "slider.horizontal.3", label: "Settings") {
              store.showSettings = true
            }
          }
          .padding(.top, 8)
          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 1) {
              Text("Museum").font(.system(size: 51, weight: .regular, design: .serif))
              Text("After Dark").font(.system(size: 47, weight: .regular, design: .serif)).italic()
                .foregroundStyle(Palette.gold)
            }
            Spacer()
            VStack(spacing: 6) {
              Rectangle().fill(Palette.gold.opacity(0.4)).frame(width: 1, height: 28)
              Text("EST.\n00:00").font(.system(size: 9, design: .monospaced)).lineSpacing(5)
            }
            .padding(.top, 16)
          }
          .padding(.top, 23)
          .padding(.bottom, 8)
          ZStack {
            MuseumBoard(
              room: Rooms.all[0], state: HeistEngine.initial(Rooms.all[0]), interactive: false
            )
            .rotationEffect(.degrees(-7))
            .scaleEffect(1.08)
            .padding(.horizontal, 16)
            LinearGradient(
              colors: [Palette.ink, .clear, .clear, Palette.ink], startPoint: .top,
              endPoint: .bottom
            )
            .allowsHitTesting(false)
            VStack {
              Spacer()
              HStack(spacing: 8) {
                Circle().fill(Palette.ruby).frame(width: 4, height: 4)
                Eyebrow(text: "SECURITY ACTIVE  /  YOU ARE INVITED", color: Palette.muted)
              }
            }
          }
          .frame(height: max(220, min(360, geo.size.height - 380)))
          .clipped()
          VStack(alignment: .leading, spacing: 14) {
            Text("Take nothing for granted.\nExcept the art.").font(
              .system(size: 23, design: .serif)
            ).lineSpacing(3)
            Text("Ten galleries. One exquisite escape.").font(.system(size: 12)).foregroundStyle(
              Palette.muted)
            Button {
              store.begin(store.saved.roomIndex, fresh: store.state.outcome != .playing)
            } label: {
              HStack {
                Text(
                  store.saved.state.turn > 0 && store.state.outcome == .playing
                    ? "CONTINUE THE HEIST" : "ENTER THE MUSEUM")
                Spacer()
                Image(systemName: "arrow.right")
              }.padding(.horizontal, 20)
            }
            .buttonStyle(GoldButton())
            .accessibilityIdentifier("start-heist")
            Button {
              store.screen = .rooms
            } label: {
              HStack {
                Text("THE COLLECTION")
                Spacer()
                Text("\(store.saved.best.count) / 10 ACQUIRED")
                Image(systemName: "arrow.up.right")
              }
              .font(.system(size: 10, weight: .medium, design: .monospaced))
              .tracking(1.2)
              .frame(height: 44)
              .foregroundStyle(Palette.muted)
            }
            .accessibilityIdentifier("collection")
          }
          .padding(.top, 18)
          Spacer(minLength: 12)
        }
        .padding(.horizontal, 26)
        .frame(minHeight: geo.size.height)
      }
      .scrollIndicators(.hidden)
    }
  }
}

struct RoomsView: View {
  @EnvironmentObject private var store: HeistStore
  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack {
        IconButton(symbol: "arrow.left", label: "Back to museum") { store.screen = .home }
        Spacer()
        Eyebrow(text: "\(store.medals) PERFECT HEISTS")
      }
      Text("The collection").font(.system(size: 36, design: .serif))
      Text("Each acquisition opens another gallery.").font(.system(size: 13)).foregroundStyle(
        Palette.muted)
      ScrollView {
        VStack(spacing: 0) {
          ForEach(Array(Rooms.all.enumerated()), id: \.element.id) { index, room in
            Button {
              store.begin(index)
            } label: {
              HStack(spacing: 16) {
                Text(String(format: "%02d", room.id)).font(
                  .system(size: 26, weight: .light, design: .serif)
                ).foregroundStyle(Palette.gold)
                VStack(alignment: .leading, spacing: 6) {
                  Eyebrow(text: room.collection, color: Palette.muted)
                  Text(room.title).font(.system(size: 18, design: .serif)).foregroundStyle(
                    Palette.paper)
                  if let best = store.saved.best[room.id] {
                    Text("\(best) MOVES · \(best <= room.par ? "PERFECT" : "ACQUIRED")").font(
                      .system(size: 9, design: .monospaced)
                    ).foregroundStyle(Palette.gold)
                  }
                }
                Spacer(minLength: 0)
                Image(systemName: index >= store.unlocked ? "lock" : "arrow.up.right").font(
                  .system(size: 14))
              }
              .padding(.vertical, 20)
              .opacity(index >= store.unlocked ? 0.4 : 1)
              .overlay(alignment: .bottom) {
                Rectangle().fill(Palette.gold.opacity(0.2)).frame(height: 1)
              }
            }
            .disabled(index >= store.unlocked)
            .accessibilityLabel(
              "Gallery \(room.id), \(room.title), \(index >= store.unlocked ? "locked" : "available")"
            )
          }
        }
      }
      .scrollIndicators(.hidden)
    }
    .padding(.horizontal, 24)
    .padding(.top, 10)
  }
}

struct PlayView: View {
  @EnvironmentObject private var store: HeistStore
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  var body: some View {
    GeometryReader { geo in
      VStack(spacing: 12) {
        HStack {
          IconButton(symbol: "pause", label: "Pause heist") { store.showPause = true }
          Spacer()
          Eyebrow(text: String(format: "GALLERY %02d / 10", store.room.id))
          Spacer()
          Text(String(format: "%02d", store.state.turn)).font(
            .system(size: 24, weight: .light, design: .monospaced)
          )
          .frame(width: 44, height: 44)
          .accessibilityLabel("\(store.state.turn) moves")
        }
        VStack(alignment: .leading, spacing: 7) {
          Eyebrow(text: store.room.collection, color: Palette.muted)
          HStack(alignment: .firstTextBaseline) {
            Text(store.room.title).font(.system(size: 27, design: .serif)).minimumScaleFactor(0.8)
              .lineLimit(1)
            Spacer(minLength: 4)
            Text("PAR \(store.room.par)").font(.system(size: 11, design: .monospaced))
              .foregroundStyle(Palette.gold)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        HStack(spacing: 8) {
          Image(systemName: store.state.hasArtifact ? "arrow.down.left" : "diamond")
          Text(
            store.state.hasArtifact
              ? "ARTIFACT SECURED  ·  RETURN TO EXIT" : "ACQUIRE THE ARTIFACT  ·  THEN EXIT")
          Spacer(minLength: 0)
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .tracking(0.2)
        .foregroundStyle(store.state.hasArtifact ? Palette.mint : Palette.gold)
        .frame(height: 24)
        ZStack {
          MuseumBoard(room: store.room, state: store.state, tap: store.tap)
            .frame(maxWidth: min(geo.size.width, max(245, (geo.size.height - 300) * 7 / 8)))
          if store.state.outcome == .caught {
            caughtOverlay
          }
          if store.revealArtifact && store.state.outcome == .playing {
            artifactReveal
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, -14)
        HStack(spacing: 14) {
          HStack(spacing: 4) {
            ThiefFigure().frame(width: 18, height: 20)
            Text("YOU").font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.paper)
          }.accessibilityHidden(true)
          legend("xmark", text: "DANGER NOW", color: Palette.ruby)
          if !store.room.sentries.isEmpty {
            legend("square.dashed", text: "NEXT SWEEP", color: Palette.amber)
          }
          Spacer(minLength: 0)
        }
        VStack(alignment: .leading, spacing: 5) {
          Eyebrow(text: instructionTitle)
          Text(instruction)
            .font(.system(size: 13)).lineSpacing(3).foregroundStyle(Palette.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("context-instruction")
        }
        .frame(minHeight: 48, alignment: .topLeading)
        HStack(spacing: 10) {
          control("arrow.uturn.backward", text: "Undo", disabled: store.saved.history.isEmpty) {
            store.undo()
          }
          control("clock.arrow.circlepath", text: "Wait") { store.act(.wait) }
          control("arrow.counterclockwise", text: "Restart") { store.restart() }
        }
        .padding(.bottom, 8)
      }
      .padding(.horizontal, 22)
      .padding(.top, 6)
      .allowsHitTesting(!store.revealArtifact || store.state.outcome != .playing)
      .overlay {
        if store.revealArtifact && store.state.outcome == .playing {
          Color.clear.contentShape(Rectangle()).onTapGesture { store.revealArtifact = false }
            .accessibilityLabel("Continue with artifact").accessibilityAddTraits(.isButton)
        }
      }
      .task(id: store.revealArtifact) {
        if store.revealArtifact {
          try? await Task.sleep(for: .seconds(reduceMotion ? 1.0 : 1.8))
          withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) {
            store.revealArtifact = false
          }
        }
      }
    }
  }

  private var instructionTitle: String {
    if !store.message.isEmpty { return "A QUIET REMINDER" }
    if store.state.hasArtifact { return "MAKE YOUR EXIT" }
    if store.state.turn == 0 { return "THE PLAN" }
    if (store.room.nodes + store.room.mirrors).contains(where: {
      store.state.player.distance(to: $0) == 1
    }) {
      return "WITHIN REACH"
    }
    return "ONE MOVE AHEAD"
  }
  private var instruction: String {
    if !store.message.isEmpty { return store.message }
    if store.state.hasArtifact {
      return "The piece is yours. Retrace a safe route to the green EXIT."
    }
    if store.state.turn == 0 { return store.room.briefing }
    if let node = store.room.nodes.first(where: { store.state.player.distance(to: $0) == 1 }) {
      return "Tap brass node \(store.room.circuit(at: node) + 1) to toggle its laser circuit."
    }
    if store.room.mirrors.contains(where: { store.state.player.distance(to: $0) == 1 }) {
      return "Tap the round mirror to rotate it. Check where the beam will go."
    }
    return store.room.sentries.isEmpty
      ? "Tap a mint-outlined neighbor to step. Never enter an active ruby beam."
      : "Tap a neighbor to step. Avoid solid light now and dotted amber on the next turn."
  }

  private func legend(_ symbol: String, text: String, color: Color) -> some View {
    HStack(spacing: 5) {
      Image(systemName: symbol).font(.system(size: 8))
      Text(text).font(.system(size: 10, design: .monospaced)).tracking(0.5)
    }.foregroundStyle(color.opacity(0.8))
  }

  private func control(
    _ symbol: String, text: String, disabled: Bool = false, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 7) {
        Image(systemName: symbol)
        Text(text)
      }
      .font(.system(size: 12))
      .frame(maxWidth: .infinity)
      .frame(height: 46)
      .overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.gold.opacity(0.3), lineWidth: 1))
      .opacity(disabled ? 0.3 : 1)
    }
    .disabled(disabled || store.state.outcome != .playing)
    .accessibilityIdentifier(text.lowercased())
  }

  private var caughtOverlay: some View {
    VStack(spacing: 13) {
      Eyebrow(text: "SECURITY ALERT", color: Palette.ruby)
      Text("Spotted.").font(.system(size: 42, design: .serif))
      Text("A beam found you.\nUndo your move, or try a fresh approach.")
        .font(.system(size: 13)).lineSpacing(4).multilineTextAlignment(.center).foregroundStyle(
          Palette.muted)
      Button("UNDO LAST MOVE") { store.undo() }.buttonStyle(GoldButton()).accessibilityIdentifier(
        "undo-caught")
      Button("Restart gallery") { store.restart() }.font(.system(size: 13)).frame(height: 44)
        .accessibilityIdentifier("restart-caught")
    }
    .padding(24)
    .background(Palette.ink.opacity(0.97), in: RoundedRectangle(cornerRadius: 8))
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.ruby.opacity(0.5), lineWidth: 1))
    .padding(.horizontal, 12)
  }

  private var artifactReveal: some View {
    VStack(spacing: 9) {
      Jewel(size: 84, artifactID: store.room.id).overlay(AcquisitionParticles())
      Eyebrow(text: "ACQUIRED")
      Text(store.room.artifactName).font(.system(size: 27, design: .serif))
      Text("Now, disappear.").font(.system(size: 13)).foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      RadialGradient(
        colors: [Palette.ink.opacity(0.98), Palette.ink.opacity(0.75), .clear], center: .center,
        startRadius: 50, endRadius: 230)
    )
    .transition(.opacity)
  }
}

struct PauseView: View {
  @EnvironmentObject private var store: HeistStore
  var body: some View {
    VStack(alignment: .leading, spacing: 22) {
      Eyebrow(text: "THE MUSEUM CAN WAIT")
      Text("Hold your breath.").font(.system(size: 35, design: .serif))
      Text("Your heist is saved after every move.").font(.system(size: 14)).foregroundStyle(
        Palette.muted)
      Button("RESUME HEIST") { store.showPause = false }.buttonStyle(GoldButton())
      Button("Restart this gallery") { store.restart() }.frame(height: 44)
      Button("Return to the museum") {
        store.showPause = false
        store.screen = .home
      }.frame(height: 44)
    }
    .padding(30)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(.top, 24)
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
    .presentationBackground(Palette.ink)
    .foregroundStyle(Palette.paper)
    .tint(Palette.gold)
  }
}

struct SettingsView: View {
  @EnvironmentObject private var store: HeistStore
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      Form {
        Section("Atmosphere") {
          Toggle("Sound effects", isOn: $store.saved.sound).accessibilityIdentifier("sound-toggle")
          Toggle("Haptic feedback", isOn: $store.saved.haptics).accessibilityIdentifier(
            "haptics-toggle")
        }
        Section("The rules") {
          Text(
            "Tap an adjacent floor tile to move. Tap adjacent brass nodes or round mirrors to interact. Wait advances the watch without moving."
          )
          Text(
            "Ruby beams and amber searchlights catch you. Searchlights rotate clockwise after every action; dotted amber tiles preview their next position."
          )
          Text(
            "Take the artifact back to EXIT. Undo is unlimited. Match the par move count for a perfect-heist medal."
          )
        }
        Section("On your device") {
          Text(
            "Ten authored galleries. Progress stays on this device. Reduced Motion follows your iPhone's accessibility setting."
          )
        }
      }
      .font(.system(size: 14))
      .scrollContentBackground(.hidden)
      .background(Palette.ink)
      .navigationTitle("After hours")
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
    .tint(Palette.gold)
  }
}

struct DossierView: View {
  let room: Room
  let moves: Int
  var compact = false
  var body: some View {
    VStack(spacing: compact ? 15 : 24) {
      HStack {
        Eyebrow(text: "M / AD")
        Spacer()
        Eyebrow(text: String(format: "DOSSIER NO. %03d", room.id), color: Palette.muted)
      }
      Rectangle().fill(Palette.gold.opacity(0.4)).frame(height: 1)
      ZStack {
        Circle().stroke(Palette.gold.opacity(0.18), lineWidth: 1).frame(width: compact ? 134 : 210)
        Circle().stroke(Palette.gold.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [2, 5]))
          .frame(width: compact ? 158 : 245)
        Jewel(size: compact ? 112 : 185, artifactID: room.id)
      }
      .frame(height: compact ? 165 : 270)
      VStack(spacing: 7) {
        Eyebrow(text: "REMOVED FROM THE COLLECTION")
        Text(room.artifactName).font(.system(size: compact ? 27 : 38, design: .serif))
        Text(room.collection).font(.system(size: 9, design: .monospaced)).tracking(2)
          .foregroundStyle(Palette.muted)
      }
      HStack(alignment: .lastTextBaseline) {
        VStack(alignment: .leading, spacing: 4) {
          Text("\(moves)").font(.system(size: compact ? 32 : 50, weight: .light, design: .serif))
          Eyebrow(text: "MOVES", color: Palette.muted)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 8) {
          Image(systemName: moves <= room.par ? "seal" : "checkmark.seal").font(
            .system(size: 22, weight: .ultraLight))
          Eyebrow(text: moves <= room.par ? "PERFECT HEIST" : "CLEAN ESCAPE")
        }
      }
      Rectangle().fill(Palette.gold.opacity(0.4)).frame(height: 1)
      Text("MUSEUM AFTER DARK").font(.system(size: 9, design: .monospaced)).tracking(3)
        .foregroundStyle(Palette.muted)
    }
    .padding(compact ? 22 : 42)
    .foregroundStyle(Palette.paper)
    .background(
      LinearGradient(
        colors: [Palette.stone.opacity(0.8), Palette.ink], startPoint: .topLeading,
        endPoint: .bottomTrailing)
    )
    .overlay(Rectangle().stroke(Palette.gold.opacity(0.55), lineWidth: 1))
    .padding(1)
    .background(Palette.ink)
  }
}

struct SharedDossier: Identifiable {
  let id = UUID()
  let image: UIImage
  let text: String
}

struct ResultView: View {
  @EnvironmentObject private var store: HeistStore
  @State private var dossier: SharedDossier?
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        HStack {
          Eyebrow(
            text: store.saved.best.count == 10
              ? "THE COLLECTION IS COMPLETE" : "ACQUISITION CONFIRMED")
          Spacer()
          IconButton(symbol: "xmark", label: "Close dossier") { store.screen = .rooms }
        }
        Text("Gone by midnight.").font(.system(size: 35, design: .serif)).minimumScaleFactor(0.8)
          .lineLimit(1)
        DossierView(room: store.room, moves: store.state.turn, compact: true)
        HStack(spacing: 8) {
          Image(systemName: "lock.open").font(.system(size: 12))
          Text(
            store.room.id < 10
              ? "Gallery \(store.room.id + 1) is now open."
              : "All ten galleries are yours. Replay for every medal."
          )
          .font(.system(size: 12))
        }.foregroundStyle(Palette.muted)
        Button(store.room.id < 10 ? "ENTER THE NEXT GALLERY  →" : "VIEW THE COLLECTION  →") {
          if store.room.id < 10 {
            store.begin(store.saved.roomIndex + 1)
          } else {
            store.screen = .rooms
          }
        }.buttonStyle(GoldButton()).accessibilityIdentifier("next-gallery")
        HStack(spacing: 12) {
          Button {
            let renderer = ImageRenderer(
              content: DossierView(room: store.room, moves: store.state.turn).frame(width: 600)
                .padding(30).background(Palette.ink))
            renderer.scale = 2
            if let image = renderer.uiImage {
              dossier = SharedDossier(
                image: image,
                text:
                  "I acquired \(store.room.artifactName) in \(store.state.turn) moves. Museum After Dark — gallery \(store.room.id) of 10."
              )
            }
          } label: {
            Label("Share dossier", systemImage: "square.and.arrow.up").frame(
              maxWidth: .infinity, minHeight: 44)
          }.accessibilityIdentifier("share-dossier")
          Button {
            store.restart()
          } label: {
            Label("Replay", systemImage: "arrow.counterclockwise").frame(
              maxWidth: .infinity, minHeight: 44)
          }.accessibilityIdentifier("replay-gallery")
        }
        .font(.system(size: 12))
      }
      .padding(24)
    }
    .scrollIndicators(.hidden)
    .sheet(item: $dossier) { item in
      ShareSheet(image: item.image, text: item.text)
    }
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  let image: UIImage
  let text: String
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
  }
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
