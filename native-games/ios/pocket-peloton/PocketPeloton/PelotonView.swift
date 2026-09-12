import Combine
import LinkPresentation
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
      .buttonStyle(ClubButtonStyle())
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
      CoastalCover()
        .ignoresSafeArea()
      LinearGradient(
        colors: [Ink.cream.opacity(0.92), Ink.cream.opacity(0.4), .clear],
        startPoint: .top, endPoint: .bottom
      )
      .frame(height: size.height * 0.34)
      .ignoresSafeArea(edges: .top)
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          ClubEmblem()
          Text("POCKET SPORTS CLUB")
            .font(.system(size: 9, weight: .bold)).tracking(2)
          Spacer()
          Button {
            store.showSettings = true
          } label: {
            Image(systemName: "slider.horizontal.3").font(.system(size: 17, weight: .medium))
              .frame(width: 44, height: 44)
              .background(Ink.cream.opacity(0.7), in: Circle())
              .overlay(Circle().strokeBorder(Ink.navy.opacity(0.12)))
          }
          .accessibilityLabel("Settings")
          .accessibilityIdentifier("settingsButton")
        }
        Text("Pocket Peloton")
          .font(.system(size: min(size.width * 0.119, 54), weight: .bold, design: .serif).italic())
          .tracking(-2.6)
          .lineLimit(1).minimumScaleFactor(0.8)
          .padding(.top, 14)
        HStack(spacing: 10) {
          RaceStripe()
          Text("LITTLE ROADS. LEGENDARY FINISHES.")
            .font(.system(size: 8, weight: .bold)).tracking(1.1)
            .lineLimit(1).minimumScaleFactor(0.8)
        }.padding(.top, 10)
        Spacer(minLength: 22)
        HStack(alignment: .bottom) {
          VStack(alignment: .leading, spacing: 6) {
            Text("THE COASTAL COLLECTION")
              .font(.system(size: 8, weight: .heavy)).tracking(1.6)
            Text("Sea air.\nRace legs.")
              .font(.system(size: 29, weight: .medium, design: .serif).italic())
              .tracking(-0.8)
          }
          .padding(14)
          .background(Ink.cream.opacity(0.93), in: RoundedRectangle(cornerRadius: 3))
          Spacer()
        }
        .padding(.bottom, 16)
        VStack(alignment: .leading, spacing: 14) {
          HStack {
            eyebrow("YOUR NEXT ESCAPE")
            Spacer()
            Image(systemName: "laurel.leading")
            Text("\(store.results.filter { $0.rank == 1 }.count)")
              .font(.system(size: 10, weight: .bold, design: .monospaced))
            Image(systemName: "laurel.trailing")
          }
          .font(.system(size: 14, weight: .medium))
          HStack(spacing: 0) {
            ForEach(Course.allCases) { course in
              Button {
                store.course = course
              } label: {
                VStack(spacing: 8) {
                  HStack(spacing: 5) {
                    Text("0\(course.rawValue + 1)")
                      .foregroundStyle(store.course == course ? Ink.red : Ink.navy.opacity(0.4))
                    Text(["RIVIERA", "HEADLAND", "GOLDEN"][course.rawValue])
                  }
                  .font(.system(size: 9, weight: .bold)).tracking(0.5)
                  .lineLimit(1).minimumScaleFactor(0.8)
                  Rectangle()
                    .fill(store.course == course ? Ink.red : Ink.navy.opacity(0.12))
                    .frame(height: store.course == course ? 2 : 1)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
              }
              .accessibilityLabel("\(course.title), \(Int(course.length)) meters")
              .accessibilityAddTraits(store.course == course ? .isSelected : [])
              .accessibilityIdentifier("route\(course.rawValue)")
            }
          }
          HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
              Text(store.course.title)
                .font(.system(size: 25, weight: .medium, design: .serif)).tracking(-0.8)
              Text(
                [
                  "Salt air & sweeping bends", "High roads & brave attacks",
                  "One last ride into the sun",
                ][store.course.rawValue]
              )
              .font(.system(size: 11, weight: .medium))
              .foregroundStyle(Ink.navy.opacity(0.68))
            }
            Spacer(minLength: 0)
            VStack(spacing: 2) {
              CourseTrace(course: store.course).frame(width: 65, height: 29)
              Text("\(Int(store.course.length)) M")
                .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1)
            }
          }
          HStack {
            Text(
              store.best(for: store.course).map { "BEST  \($0.timeLabel)" }
                ?? "MAKE YOUR FIRST MARK"
            )
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            Spacer()
            Text("~\(Int(store.course.length / 14)) SEC").font(.system(size: 10, weight: .bold))
          }
          primary("RIDE THE COAST", icon: "arrow.right", id: "startRace") { store.start() }
        }
        .padding(20)
        .background(Ink.cream, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.7)))
        .shadow(color: Ink.navy.opacity(0.18), radius: 24, x: 0, y: 10)
        .padding(.bottom, 8)
      }
      .padding(.horizontal, 22)
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
        VStack(spacing: 8) {
          HStack {
            RaceStripe()
            eyebrow(store.course.title.uppercased())
            Spacer()
            Button {
              store.pause()
            } label: {
              Image(systemName: "pause.fill").font(.system(size: 13))
                .frame(width: 44, height: 44)
                .background(Ink.cream.opacity(0.08), in: Circle())
            }
            .accessibilityLabel("Pause race")
            .accessibilityIdentifier("pauseRace")
          }
          HStack(alignment: .firstTextBaseline, spacing: 18) {
            VStack(alignment: .leading, spacing: 2) {
              HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(store.race.rank)")
                  .font(.system(size: 37, weight: .medium, design: .serif).italic())
                Text("/ 4").font(.system(size: 13, weight: .medium))
                  .foregroundStyle(Ink.cream.opacity(0.5))
              }
              eyebrow("POSITION")
            }
            .accessibilityLabel("Position \(store.race.rank) of 4")
            Spacer(minLength: 0)
            raceMetric(String(format: "%05.1f", store.race.elapsed), "TIME / SEC")
            Spacer(minLength: 0)
            raceMetric("\(store.race.remaining)", "METERS LEFT")
          }
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Capsule().fill(Ink.cream.opacity(0.16))
              Capsule().fill(Ink.sea).frame(width: geo.size.width * store.race.progress)
              Circle().fill(Ink.butter).frame(width: 7, height: 7)
                .offset(x: max(0, (geo.size.width - 7) * store.race.progress))
            }
          }.frame(height: 3).padding(.top, 7)
        }
        .foregroundStyle(Ink.cream)
        .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 18)
        .background(
          LinearGradient(
            colors: [Ink.navy, Ink.navy.opacity(0.95)], startPoint: .topLeading,
            endPoint: .bottomTrailing),
          in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Ink.cream.opacity(0.18)))
        .shadow(color: Ink.navy.opacity(0.2), radius: 12, y: 7)
        HStack(spacing: 8) {
          Image(systemName: statusIcon)
          Text(statusTitle).tracking(0.7)
        }
        .font(.system(size: 10, weight: .bold))
        .lineLimit(1).minimumScaleFactor(0.8)
        .padding(.horizontal, 15).padding(.vertical, 11)
        .background(store.race.collisionRemaining > 0 ? Ink.red : Ink.cream, in: Capsule())
        .foregroundStyle(store.race.collisionRemaining > 0 ? Ink.cream : Ink.navy)
        .shadow(color: Ink.navy.opacity(0.12), radius: 8, y: 3)
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

  private func raceMetric(_ value: String, _ label: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(value)
        .font(.system(size: 27, weight: .medium, design: .rounded))
        .monospacedDigit()
      eyebrow(label).foregroundStyle(Ink.cream.opacity(0.62))
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
    VStack(spacing: 14) {
      HStack {
        Image(systemName: store.race.drafting ? "wind" : "bolt.heart")
          .font(.system(size: 12, weight: .medium)).foregroundStyle(Ink.sea)
        eyebrow(store.race.drafting ? "RECHARGING IN THE DRAFT" : "POWER RESERVE")
        Spacer()
        Text("\(Int(store.race.energy))%").font(
          .system(size: 13, weight: .black, design: .monospaced))
      }
      HStack(spacing: 3) {
        ForEach(0..<24) { segment in
          RoundedRectangle(cornerRadius: 1.5)
            .fill(
              Double(segment) < store.race.energy / 100 * 24
                ? (store.race.energy < 28 ? Ink.red : Ink.butter)
                : Ink.cream.opacity(0.12))
        }
      }.frame(height: 6).accessibilityLabel("Energy \(Int(store.race.energy)) percent")
      HStack(spacing: 12) {
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
      .font(.system(size: 9, weight: .bold)).tracking(0.4)
      .foregroundStyle(Ink.cream.opacity(0.62))
      .lineLimit(1).minimumScaleFactor(0.8)
    }
    .foregroundStyle(Ink.cream)
    .padding(18)
    .background(Ink.navy, in: RoundedRectangle(cornerRadius: 28))
    .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Ink.cream.opacity(0.18)))
    .shadow(color: Ink.navy.opacity(0.24), radius: 16, y: 8)
  }

  private var sprintLabel: some View {
    HStack(spacing: 7) {
      Image(systemName: "bolt.fill")
      Text(store.race.exhausted ? "RECOVERING" : (store.race.isSprinting ? "SPRINTING" : "SPRINT"))
        .tracking(1)
        .lineLimit(1).minimumScaleFactor(0.8)
    }
    .font(.system(size: 15, weight: .black))
    .frame(maxWidth: .infinity).frame(height: 58)
    .background(
      LinearGradient(
        colors: store.race.exhausted
          ? [Ink.road, Ink.road]
          : [store.race.sprintHeld ? Ink.red : Ink.red.opacity(0.95), Ink.red.opacity(0.72)],
        startPoint: .top, endPoint: .bottom),
      in: Capsule()
    )
    .overlay(Capsule().strokeBorder(Ink.cream.opacity(0.28), lineWidth: 1))
    .compositingGroup()
    .shadow(color: .black.opacity(0.2), radius: 0, y: store.race.sprintHeld ? 1 : 4)
    .foregroundStyle(Ink.cream)
    .contentShape(Capsule())
  }

  private func laneButton(_ direction: Int) -> some View {
    Button {
      store.move(direction)
    } label: {
      Image(systemName: direction < 0 ? "arrow.left" : "arrow.right")
        .font(.system(size: 19, weight: .medium))
        .frame(width: 54, height: 58)
        .background(Ink.cream.opacity(0.08), in: Capsule())
        .overlay(Capsule().strokeBorder(Ink.cream.opacity(0.16)))
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
          .padding(26)
          .background(Ink.cream, in: RoundedRectangle(cornerRadius: 26))
          .overlay(alignment: .topLeading) { RaceStripe().padding(.leading, 26).padding(.top, 12) }
          .shadow(color: Ink.navy.opacity(0.25), radius: 30, y: 16)
          .padding(22)
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
          .frame(height: 330)
          .clipShape(RoundedRectangle(cornerRadius: 18))
          .shadow(color: Ink.navy.opacity(0.15), radius: 15, y: 8)
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
              .background(Ink.navy.opacity(0.06), in: Capsule())
          }.accessibilityIdentifier("shareResult")
          Button {
            store.screen = .home
          } label: {
            Label("Clubhouse", systemImage: "house")
              .font(.system(size: 14, weight: .bold)).frame(maxWidth: .infinity, minHeight: 48)
              .background(Ink.navy.opacity(0.06), in: Capsule())
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
    Text(text).font(.system(size: 10, weight: .heavy)).tracking(1.1)
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
      .background(
        LinearGradient(
          colors: [Ink.red, Ink.red.opacity(0.9)], startPoint: .topLeading,
          endPoint: .bottomTrailing),
        in: Capsule()
      )
      .overlay(Capsule().strokeBorder(.white.opacity(0.22)))
      .compositingGroup()
      .shadow(color: Ink.red.opacity(0.2), radius: 8, y: 4)
      .foregroundStyle(Ink.cream)
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
    GeometryReader { geometry in
      ZStack {
        CoastalCover()
        LinearGradient(
          colors: [Ink.cream.opacity(0.8), .clear, Ink.navy.opacity(0.2)],
          startPoint: .top, endPoint: .bottom)
        VStack(alignment: .leading, spacing: compact ? 10 : 22) {
          HStack {
            ClubEmblem(size: compact ? 25 : 42)
            Text("POCKET PELOTON")
              .font(.system(size: compact ? 9 : 16, weight: .bold)).tracking(2)
            Spacer()
            RaceStripe()
          }
          VStack(alignment: .leading, spacing: compact ? 8 : 16) {
            Text(result.course.title)
              .font(.system(size: compact ? 26 : 47, weight: .medium, design: .serif).italic())
              .tracking(-1)
            Text("COAST SERIES  /  FINISH No. 0\(result.course.rawValue + 1)")
              .font(.system(size: compact ? 7 : 11, weight: .bold)).tracking(1.5)
          }
          ZStack {
            Circle().fill(Ink.navy)
            Circle().strokeBorder(Ink.butter.opacity(0.7), lineWidth: 1).padding(5)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
              Text("\(result.rank)")
                .font(.system(size: compact ? 43 : 77, weight: .medium, design: .serif).italic())
              Text(["", "ST", "ND", "RD", "TH"][result.rank])
                .font(.system(size: compact ? 11 : 18, weight: .bold, design: .serif))
            }
            .foregroundStyle(Ink.butter)
          }
          .frame(width: compact ? 85 : 154, height: compact ? 85 : 154)
          .rotationEffect(.degrees(-8))
          .shadow(color: Ink.navy.opacity(0.18), radius: 10, y: 5)
          Spacer()
          HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
              Text("FINISH TIME").font(.system(size: compact ? 8 : 11, weight: .heavy)).tracking(
                1.5)
              Text(result.timeLabel).font(
                .system(size: compact ? 29 : 56, weight: .medium, design: .serif))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
              Text(result.rank == 1 ? "WINNING MARGIN" : "TO THE WINNER")
                .font(.system(size: compact ? 8 : 11, weight: .heavy)).tracking(1)
              Text(String(format: "%.2fs", abs(result.gap)))
                .font(.system(size: compact ? 23 : 42, weight: .bold, design: .serif))
            }
          }
          .foregroundStyle(Ink.cream)
          .padding(compact ? 15 : 26)
          .background(Ink.navy)
          .padding(.horizontal, compact ? -18 : -36)
          .padding(.bottom, compact ? -18 : -36)
        }
        .padding(compact ? 18 : 36)
        .foregroundStyle(Ink.navy)
        if !compact {
          Text("RIDE WELL. FINISH BEAUTIFULLY.")
            .font(.system(size: 10, weight: .bold)).tracking(2)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Ink.cream)
            .rotationEffect(.degrees(-90))
            .position(x: geometry.size.width - 24, y: geometry.size.height * 0.46)
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
    let items = UIActivityItemsConfiguration(objects: [image, text as NSString])
    items.perItemMetadataProvider = { index, key in
      guard index == 0, key == .linkPresentationMetadata else { return nil }
      let metadata = LPLinkMetadata()
      metadata.title = text
      metadata.imageProvider = NSItemProvider(object: image)
      return metadata
    }
    return UIActivityViewController(activityItemsConfiguration: items)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
