import Combine
import SwiftUI
import UIKit

struct PelotonView: View {
  @EnvironmentObject private var store: GameStore
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reducedMotion
  @AppStorage("tapSprint") private var tapSprint = false
  @State private var sharePayload: RaceShare?
  private let clock = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Ink.cream.ignoresSafeArea()
        switch store.screen {
        case .home: home(size: geometry.size)
        case .racing: gameplay
        case .result:
          if let result = store.race.result { resultView(result) }
        }
        if store.paused && store.screen == .racing { pauseOverlay }
        if store.showGuide { guideOverlay }
      }
      .foregroundStyle(Ink.navy)
      .sheet(isPresented: $store.showSettings) { settings }
      .sheet(item: $sharePayload) { payload in
        ShareSheet(image: payload.image, text: payload.text)
      }
      .onReceive(clock) { store.tick($0) }
      .onChange(of: scenePhase) { _, phase in
        if phase != .active { store.pause() }
      }
    }
  }

  private func home(size: CGSize) -> some View {
    ZStack(alignment: .top) {
      CoastArtwork(race: RaceState(course: store.course), hero: true, reducedMotion: reducedMotion)
        .ignoresSafeArea()
      LinearGradient(
        colors: [Ink.cream, Ink.cream.opacity(0.92), .clear],
        startPoint: .top, endPoint: .bottom
      )
      .frame(height: size.height * 0.48)
      .ignoresSafeArea(edges: .top)
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          eyebrow("THE POCKET SPORTS CLUB")
          Spacer()
          Button {
            store.showSettings = true
          } label: {
            Image(systemName: "slider.horizontal.3").font(.system(size: 19, weight: .medium))
              .frame(width: 44, height: 44)
          }
          .accessibilityLabel("Settings")
          .accessibilityIdentifier("settingsButton")
        }
        HStack(alignment: .top) {
          Text("Pocket\nPeloton.")
            .font(.system(size: min(size.width * 0.168, 76), weight: .black, design: .serif))
            .tracking(-3).lineSpacing(-12)
            .fixedSize(horizontal: false, vertical: true)
          Spacer()
          VStack(spacing: 3) {
            Text("01—03").font(.system(size: 11, weight: .heavy, design: .monospaced))
            Rectangle().frame(width: 38, height: 1)
            Text("COAST\nSERIES").font(.system(size: 9, weight: .bold)).tracking(1)
          }.padding(.top, 17)
        }
        Text("Little roads. Legendary finishes.")
          .font(.system(size: 14, weight: .medium)).padding(.top, 11)
        Spacer(minLength: 10)
        HStack(alignment: .bottom) {
          VStack(alignment: .leading, spacing: 4) {
            Text("DRAFT.\nATTACK.\nDISAPPEAR.")
              .font(.system(size: 20, weight: .black, design: .rounded))
              .tracking(-0.5)
            Rectangle().fill(Ink.red).frame(width: 34, height: 4)
          }
          Spacer()
          Text("SEA AIR.\nRACE LEGS.")
            .font(.system(size: 9, weight: .heavy)).tracking(1.2)
            .fixedSize()
            .rotationEffect(.degrees(-90)).frame(width: 25, height: 94)
        }
        Spacer(minLength: 10)
        VStack(alignment: .leading, spacing: 14) {
          HStack {
            eyebrow("CHOOSE YOUR ROAD")
            Spacer()
            Text("\(store.results.filter { $0.rank == 1 }.count) WINS")
              .font(.system(size: 10, weight: .bold, design: .monospaced))
          }
          HStack(spacing: 7) {
            ForEach(Course.allCases) { course in
              Button {
                store.course = course
              } label: {
                VStack(alignment: .leading, spacing: 6) {
                  Text("0\(course.rawValue + 1)").font(
                    .system(size: 12, weight: .bold, design: .monospaced))
                  Text(course.title).font(.system(size: 13, weight: .bold)).lineLimit(1)
                    .minimumScaleFactor(0.7)
                  Text("\(Int(course.length)) m").font(.system(size: 11, weight: .medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(11)
                .background(store.course == course ? Ink.navy : Ink.navy.opacity(0.05))
                .foregroundStyle(store.course == course ? Ink.cream : Ink.navy)
              }
              .accessibilityLabel("\(course.title), \(Int(course.length)) meters")
              .accessibilityAddTraits(store.course == course ? .isSelected : [])
              .accessibilityIdentifier("route\(course.rawValue)")
            }
          }
          HStack {
            Text(
              store.best(for: store.course).map { "PERSONAL BEST  \($0.timeLabel)" }
                ?? "YOUR FIRST FINISH IS WAITING"
            )
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            Spacer()
            Text("~\(Int(store.course.length / 14)) SEC").font(.system(size: 10, weight: .bold))
          }
          primary("RIDE THE COAST", icon: "arrow.right", id: "startRace") { store.start() }
        }
        .padding(18)
        .background(Ink.cream)
        .padding(.horizontal, -8)
        .padding(.bottom, 8)
      }
      .padding(.horizontal, 24)
    }
  }

  private var gameplay: some View {
    ZStack {
      CoastArtwork(race: store.race, reducedMotion: reducedMotion, riderLane: store.displayLane)
        .ignoresSafeArea()
        .gesture(
          DragGesture(minimumDistance: 24).onEnded { value in
            if abs(value.translation.width) > abs(value.translation.height) {
              store.move(value.translation.width > 0 ? 1 : -1)
            }
          })
      VStack(spacing: 12) {
        HStack(alignment: .center, spacing: 12) {
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("\(store.race.rank)").font(.system(size: 46, weight: .black, design: .serif))
            Text("/4").font(.system(size: 17, weight: .bold))
          }
          .accessibilityLabel("Position \(store.race.rank) of 4")
          Rectangle().fill(Ink.navy.opacity(0.2)).frame(width: 1, height: 38)
          VStack(alignment: .leading, spacing: 5) {
            eyebrow(store.course.title.uppercased())
            Text(String(format: "%05.1f", store.race.elapsed) + "  /  \(store.race.remaining)m")
              .font(.system(size: 15, weight: .bold, design: .monospaced))
              .contentTransition(.numericText())
          }
          Spacer(minLength: 0)
          Button {
            store.pause()
          } label: {
            Image(systemName: "pause.fill").font(.system(size: 18))
              .frame(width: 44, height: 44)
          }
          .accessibilityLabel("Pause race")
          .accessibilityIdentifier("pauseRace")
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
        .background(Ink.cream)
        GeometryReader { geo in
          ZStack(alignment: .leading) {
            Rectangle().fill(Ink.navy.opacity(0.12))
            Rectangle().fill(Ink.red).frame(width: geo.size.width * store.race.progress)
          }
        }.frame(height: 4).padding(.top, -12)
        HStack(spacing: 8) {
          Image(systemName: statusIcon)
          Text(statusTitle).tracking(0.7)
        }
        .font(.system(size: 11, weight: .heavy))
        .padding(.horizontal, 15).padding(.vertical, 10)
        .background(store.race.collisionRemaining > 0 ? Ink.red : Ink.navy, in: Capsule())
        .foregroundStyle(Ink.cream)
        .accessibilityIdentifier("raceStatus")
        Spacer()
        if store.race.attackReady {
          Text("SLIPSTREAM CHARGED  ·  SWITCH LANE TO ATTACK")
            .font(.system(size: 10, weight: .heavy))
            .padding(11).background(Ink.butter, in: Capsule())
            .transition(.opacity)
        }
        controls
      }
      .padding(.horizontal, 16).padding(.bottom, 8)
    }
  }

  private var statusTitle: String {
    if store.race.collisionRemaining > 0 { return "ROAD BLOCK  ·  RECOVERING" }
    if store.race.attackRemaining > 0 { return "SLINGSHOT  ·  GO, GO, GO" }
    if store.race.exhausted { return "CATCH YOUR BREATH  ·  RECOVER TO 28%" }
    if store.race.isSprinting { return "ATTACKING  ·  \(Int(store.race.speed * 3.6)) KM/H" }
    if store.race.drafting { return "IN THE SLIPSTREAM  ·  ENERGY +" }
    if store.race.remaining < 100 {
      return "FINAL \(store.race.remaining) METERS  ·  EMPTY THE TANK"
    }
    if store.race.isBend {
      return "BEND  ·  \(store.race.insideLane == 0 ? "LEFT" : "RIGHT") LINE IS QUICKER"
    }
    return "FIND A WHEEL  ·  \(tapSprint ? "TAP" : "HOLD") TO SPRINT"
  }

  private var statusIcon: String {
    if store.race.collisionRemaining > 0 { return "exclamationmark.triangle.fill" }
    if store.race.attackRemaining > 0 || store.race.isSprinting { return "bolt.fill" }
    return "wind"
  }

  private var controls: some View {
    VStack(spacing: 12) {
      HStack {
        eyebrow(store.race.drafting ? "RECHARGING IN THE DRAFT" : "ENERGY")
        Spacer()
        Text("\(Int(store.race.energy))%").font(
          .system(size: 13, weight: .black, design: .monospaced))
      }
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule().fill(Ink.navy.opacity(0.10))
          Capsule().fill(store.race.energy < 28 ? Ink.red : Ink.navy)
            .frame(width: max(0, geo.size.width * store.race.energy / 100))
        }
      }.frame(height: 7).accessibilityLabel("Energy \(Int(store.race.energy)) percent")
      HStack(spacing: 10) {
        laneButton(-1)
        Group {
          if tapSprint {
            Button {
              store.race.sprintHeld.toggle()
            } label: {
              sprintLabel
            }
          } else {
            sprintLabel
              .gesture(
                DragGesture(minimumDistance: 0)
                  .onChanged { _ in store.race.sprintHeld = true }
                  .onEnded { _ in store.race.sprintHeld = false }
              )
              .accessibilityAddTraits(.isButton)
              .accessibilityAction { store.race.sprintHeld.toggle() }
          }
        }
        .accessibilityLabel(
          tapSprint
            ? (store.race.sprintHeld ? "Cancel sprint" : "Start sprinting") : "Hold to sprint"
        )
        .accessibilityIdentifier("sprintButton")
        laneButton(1)
      }
      Text(
        tapSprint
          ? "TAP SPRINT TO TOGGLE  ·  ARROWS OR SWIPE TO STEER"
          : "HOLD TO SPRINT  ·  ARROWS OR SWIPE TO STEER"
      )
      .font(.system(size: 8, weight: .bold)).tracking(0.5)
      .lineLimit(1).minimumScaleFactor(0.8)
    }
    .padding(16).background(Ink.cream)
  }

  private var sprintLabel: some View {
    HStack(spacing: 7) {
      Image(systemName: "bolt.fill")
      Text(store.race.exhausted ? "RECOVERING" : (store.race.isSprinting ? "SPRINTING" : "SPRINT"))
        .tracking(1)
        .lineLimit(1).minimumScaleFactor(0.8)
    }
    .font(.system(size: 15, weight: .black))
    .frame(maxWidth: .infinity).frame(height: 56)
    .background(store.race.sprintHeld ? Ink.navy : Ink.red)
    .foregroundStyle(Ink.cream)
    .contentShape(Rectangle())
  }

  private func laneButton(_ direction: Int) -> some View {
    Button {
      store.move(direction)
    } label: {
      Image(systemName: direction < 0 ? "arrow.left" : "arrow.right")
        .font(.system(size: 22, weight: .medium))
        .frame(width: 52, height: 56)
        .background(Ink.navy.opacity(0.08))
    }
    .accessibilityLabel(direction < 0 ? "Move left" : "Move right")
    .accessibilityIdentifier(direction < 0 ? "moveLeft" : "moveRight")
  }

  private var pauseOverlay: some View {
    overlayPanel {
      eyebrow("TAKE A BREATHER")
      Text("The coast\ncan wait.").font(.system(size: 42, weight: .bold, design: .serif))
      primary("BACK IN THE SADDLE", icon: "play.fill", id: "resumeRace") {
        store.paused = false
      }
      secondary("Restart race", id: "restartRace") { store.start() }
      secondary("Leave the race", id: "leaveRace") {
        store.paused = false
        store.screen = .home
      }
    }
  }

  private var guideOverlay: some View {
    overlayPanel {
      eyebrow("A LITTLE RACE CRAFT")
      Text("Find a wheel.\nThen fly.").font(.system(size: 38, weight: .bold, design: .serif))
      guideRow(
        "arrow.left.arrow.right", "Pick your line",
        "Swipe the road or tap the arrows. The inside of a bend is a little faster.")
      guideRow(
        "wind", "Borrow the slipstream",
        "Sit behind a rival to refill energy. When charged, switch lane for a slingshot.")
      guideRow(
        "bolt.fill", "Time your attack",
        "Hold SPRINT. Release to recover. Dodge striped road blocks and empty the tank at the finish."
      )
      Toggle("Tap-to-toggle sprint", isOn: $tapSprint)
        .font(.system(size: 14, weight: .semibold)).tint(Ink.red)
        .accessibilityIdentifier("tutorialTapSprint")
      Text("Prefer a mouse or one-tap controls? Enable this.")
        .font(.system(size: 11)).foregroundStyle(Ink.navy.opacity(0.7))
      primary("LET’S RIDE", icon: "arrow.right", id: "dismissTutorial") {
        store.coached = true
        store.showGuide = false
      }
    }
  }

  private func guideRow(_ icon: String, _ title: String, _ subtitle: String) -> some View {
    HStack(alignment: .top, spacing: 13) {
      Image(systemName: icon).font(.system(size: 22, weight: .medium))
        .frame(width: 34, height: 38).foregroundStyle(Ink.red)
      VStack(alignment: .leading, spacing: 3) {
        Text(title).font(.system(size: 16, weight: .bold))
        Text(subtitle).font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private func overlayPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Ink.navy.opacity(0.68).ignoresSafeArea()
      ScrollView {
        VStack(alignment: .leading, spacing: 20, content: content)
          .padding(26).background(Ink.cream).padding(22)
      }
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  private func resultView(_ result: RaceResult) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        HStack {
          eyebrow("THE FINISH EDITION")
          Spacer()
          Text("0\(result.course.rawValue + 1) / 03").font(
            .system(size: 11, weight: .bold, design: .monospaced))
        }
        Text(result.headline).font(.system(size: 42, weight: .black, design: .serif)).tracking(-1.7)
          .minimumScaleFactor(0.7).lineLimit(1)
        RacePoster(result: result, compact: true)
          .frame(height: 330).clipped()
          .accessibilityLabel(
            "\(ordinal(result.rank)) place, \(result.timeLabel), gap \(result.gapLabel)")
        HStack(alignment: .top) {
          resultStat("SLIPSTREAM", String(format: "%.1fs", result.draftSeconds))
          Spacer()
          resultStat("ATTACKS", "\(result.attacks)")
          Spacer()
          resultStat("ROAD BLOCKS", "\(result.collisions)")
        }
        Text(
          result.rank == 1
            ? "A perfectly timed escape. The coast is yours."
            : "Stay in a slipstream, switch lanes when charged, then sprint clear."
        )
        .font(.system(size: 13, weight: .medium))
        .fixedSize(horizontal: false, vertical: true)
        primary("RACE AGAIN", icon: "arrow.clockwise", id: "raceAgain") { store.start() }
        HStack(spacing: 10) {
          Button {
            let renderer = ImageRenderer(
              content: RacePoster(result: result).frame(width: 600, height: 820))
            renderer.scale = 2
            if let image = renderer.uiImage {
              sharePayload = RaceShare(
                image: image,
                text:
                  "\(result.course.title) — \(result.timeLabel), \(ordinal(result.rank)) place. \(result.gapLabel) to the fastest rival. Pocket Peloton."
              )
            }
          } label: {
            Label("Share poster", systemImage: "square.and.arrow.up")
              .font(.system(size: 14, weight: .bold)).frame(maxWidth: .infinity, minHeight: 48)
              .background(Ink.navy.opacity(0.07))
          }.accessibilityIdentifier("shareResult")
          Button {
            store.screen = .home
          } label: {
            Label("Clubhouse", systemImage: "house")
              .font(.system(size: 14, weight: .bold)).frame(maxWidth: .infinity, minHeight: 48)
              .background(Ink.navy.opacity(0.07))
          }.accessibilityIdentifier("backHome")
        }
      }.padding(24)
    }
    .accessibilityIdentifier("raceResults")
  }

  private func resultStat(_ title: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(title).font(.system(size: 9, weight: .bold)).tracking(0.5)
      Text(value).font(.system(size: 24, weight: .bold, design: .serif))
    }
  }

  private var settings: some View {
    NavigationStack {
      Form {
        Section("Your ride") {
          Toggle("Sound effects", isOn: $store.sound).accessibilityIdentifier("soundToggle")
          Toggle("Haptic feedback", isOn: $store.haptics).accessibilityIdentifier("hapticsToggle")
          Toggle("Tap-to-toggle sprint", isOn: $tapSprint).accessibilityIdentifier(
            "tapSprintToggle")
          Button("How to ride") {
            store.showSettings = false
            store.showGuide = true
          }.accessibilityIdentifier("showTutorial")
        }
        Section("Local race book") {
          ForEach(Course.allCases) { course in
            HStack {
              Text(course.title)
              Spacer()
              Text(store.best(for: course)?.timeLabel ?? "Unridden")
                .font(.system(.body, design: .monospaced))
            }
          }
          Text("\(store.results.count) finishes saved on this device.")
            .font(.footnote)
        }
        Section {
          Text(
            "Three roads. Four riders. No accounts, no network, just race craft.\n\nFinish gap compares your crossing time with the fastest rival. A negative gap means you won."
          )
          .font(.footnote)
        }
      }
      .tint(Ink.red)
      .navigationTitle("Club settings")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { store.showSettings = false }.accessibilityIdentifier("closeSettings")
        }
      }
    }
  }

  private func eyebrow(_ text: String) -> some View {
    Text(text).font(.system(size: 9, weight: .heavy)).tracking(1.2)
  }

  private func primary(_ text: String, icon: String, id: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      HStack {
        Text(text).tracking(1.2)
        Spacer()
        Image(systemName: icon)
      }
      .font(.system(size: 13, weight: .heavy))
      .padding(.horizontal, 20).frame(height: 54)
      .background(Ink.red).foregroundStyle(Ink.cream)
    }
    .accessibilityIdentifier(id)
  }

  private func secondary(_ text: String, id: String, action: @escaping () -> Void) -> some View {
    Button(text, action: action)
      .font(.system(size: 16, weight: .semibold))
      .frame(maxWidth: .infinity, minHeight: 44)
      .accessibilityIdentifier(id)
  }

  private func ordinal(_ value: Int) -> String { ["", "1st", "2nd", "3rd", "4th"][value] }
}

struct RacePoster: View {
  let result: RaceResult
  var compact = false

  var body: some View {
    GeometryReader { geo in
      ZStack {
        CoastArtwork(race: RaceState(course: result.course), hero: true, reducedMotion: true)
        LinearGradient(
          colors: [Ink.navy.opacity(0.94), Ink.navy.opacity(0.20), .clear],
          startPoint: .topLeading, endPoint: .bottomTrailing)
        VStack(alignment: .leading, spacing: compact ? 4 : 12) {
          Text("POCKET PELOTON   /   RACE CLUB")
            .font(.system(size: compact ? 8 : 13, weight: .heavy)).tracking(2)
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("\(result.rank)")
              .font(.system(size: compact ? 104 : 190, weight: .black, design: .serif))
              .tracking(-8)
            Text(["", "ST", "ND", "RD", "TH"][result.rank])
              .font(.system(size: compact ? 25 : 44, weight: .black, design: .serif))
          }
          .foregroundStyle(Ink.butter)
          Text(result.course.title.uppercased())
            .font(.system(size: compact ? 12 : 24, weight: .black)).tracking(1)
          Spacer()
          HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
              Text("FINISH TIME").font(.system(size: compact ? 8 : 11, weight: .heavy)).tracking(
                1.5)
              Text(result.timeLabel).font(
                .system(size: compact ? 29 : 56, weight: .black, design: .serif))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
              Text(result.rank == 1 ? "WINNING MARGIN" : "TO THE WINNER")
                .font(.system(size: compact ? 8 : 11, weight: .heavy)).tracking(1)
              Text(String(format: "%.2fs", abs(result.gap)))
                .font(.system(size: compact ? 23 : 42, weight: .bold, design: .serif))
            }
          }
          .padding(compact ? 13 : 22)
          .background(Ink.navy)
          .padding(compact ? -8 : -12)
        }
        .padding(compact ? 22 : 42)
        .foregroundStyle(Ink.cream)
        if !compact {
          Text("LITTLE ROADS. LEGENDARY FINISHES.")
            .font(.system(size: 12, weight: .bold)).tracking(2)
            .rotationEffect(.degrees(-90))
            .position(x: geo.size.width - 25, y: geo.size.height * 0.46)
            .foregroundStyle(Ink.navy)
        }
      }
    }
  }
}

private struct RaceShare: Identifiable {
  let id = UUID()
  let image: UIImage
  let text: String
}

struct ShareSheet: UIViewControllerRepresentable {
  let image: UIImage
  let text: String

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
