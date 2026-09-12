import Combine
import LinkPresentation
import SwiftUI
import UIKit

struct PelotonView: View {
  @EnvironmentObject private var store: GameStore
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reducedMotion
  @Environment(\.dynamicTypeSize) private var textSize
  @AppStorage("tapSprint") private var tapSprint = false
  @State private var sharePayload: RaceShare?
  @State private var shareFailed = false
  private let clock = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Ink.paper.ignoresSafeArea()
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
      .alert("Couldn't create poster", isPresented: $shareFailed) {
        Button("OK", role: .cancel) {}
      } message: {
        Text("Your result is saved. Try Share poster again.")
      }
      .onReceive(clock) { store.tick($0) }
      .onChange(of: scenePhase) { _, phase in
        if phase != .active { store.pause() }
      }
    }
  }

  private func home(size: CGSize) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Pocket Peloton").font(RaceType.title).tracking(-0.8)
            Text("Coastal sprint racing").font(RaceType.body)
          }
          Spacer()
          Button {
            store.showSettings = true
          } label: {
            Image(systemName: "slider.horizontal.3").font(.system(size: 17, weight: .medium))
              .frame(width: 44, height: 44)
              .contentShape(Rectangle())
          }
          .accessibilityLabel("Settings")
          .accessibilityIdentifier("settingsButton")
        }
        CoastalCover().frame(height: min(size.height * 0.24, 210))
          .overlay(alignment: .bottom) {
            HStack(spacing: 0) {
              Ink.red.frame(maxWidth: .infinity)
              Ink.butter.frame(width: 52)
              Ink.sea.frame(width: 28)
            }.frame(height: 4).accessibilityHidden(true)
          }
        adaptiveRow {
          Text("Choose your route").font(RaceType.heading)
          if !textSize.isAccessibilitySize { Spacer() }
          Text("4 riders").font(RaceType.caption)
        }
        VStack(spacing: 0) {
          RaceRule()
          ForEach(Course.allCases) { course in
            routeRow(course)
            RaceRule()
          }
        }
        Text(
          store.results.isEmpty
            ? "Finish a race to set your first best time."
            : "\(store.results.count) finishes · \(store.results.filter { $0.rank == 1 }.count) wins"
        )
        .font(RaceType.caption)
        .foregroundStyle(Ink.navy.opacity(0.75))
      }
      .padding(RaceLayout.gutter)
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      primary("Race \(store.course.title)", icon: "arrow.right", id: "startRace") {
        store.start()
      }
      .padding(.horizontal, RaceLayout.gutter).padding(.vertical, 12)
      .background(Ink.paper)
    }
  }

  private func routeRow(_ course: Course) -> some View {
    Button {
      store.course = course
    } label: {
      HStack(spacing: 14) {
        if !textSize.isAccessibilitySize {
          Text(String(format: "%02d", course.rawValue + 1))
            .font(RaceType.heading).monospacedDigit()
            .foregroundStyle(store.course == course ? Ink.red : Ink.navy)
            .frame(width: 30)
        }
        VStack(alignment: .leading, spacing: 4) {
          Text(course.title).font(RaceType.label)
          Text("\(Int(course.length)) m · \(course.obstacles.count) road blocks")
            .font(RaceType.caption)
          Text(store.best(for: course).map { "Best \($0.timeLabel)" } ?? "Not raced yet")
            .font(RaceType.caption).monospacedDigit()
            .foregroundStyle(Ink.navy.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Image(systemName: store.course == course ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 21, weight: .regular))
          .foregroundStyle(store.course == course ? Ink.red : Ink.navy.opacity(0.5))
      }
      .padding(.vertical, 14)
      .contentShape(Rectangle())
    }
    .accessibilityLabel(
      "\(course.title), \(Int(course.length)) meters, \(course.obstacles.count) road blocks, "
        + (store.best(for: course).map { "best \($0.timeLabel)" } ?? "not raced yet")
    )
    .accessibilityAddTraits(store.course == course ? .isSelected : [])
    .accessibilityIdentifier("route\(course.rawValue)")
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
      VStack(spacing: 8) {
        VStack(spacing: 6) {
          HStack {
            RaceStripe()
            Text(store.course.title).font(RaceType.label)
            Spacer()
            Button {
              store.pause()
            } label: {
              Image(systemName: "pause.fill").font(.system(size: 13))
                .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Pause race")
            .accessibilityIdentifier("pauseRace")
          }
          HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
              HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(store.race.rank)")
                  .font(RaceType.instrument).monospacedDigit()
                Text("/ 4").font(RaceType.body)
                  .foregroundStyle(Ink.cream.opacity(0.75))
              }
              Text("Position").font(RaceType.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Position \(store.race.rank) of 4")
            raceMetric(String(format: "%.1f", store.race.elapsed), "Seconds")
            raceMetric("\(store.race.remaining)", "Meters left")
          }
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Rectangle().fill(Ink.cream.opacity(0.16))
              Rectangle().fill(Ink.sea).frame(width: geo.size.width * store.race.progress)
            }
          }.frame(height: 3).padding(.top, 6)
        }
        .foregroundStyle(Ink.cream)
        .padding(.horizontal, 16).padding(.bottom, 12)
        .background(Ink.navy, in: RoundedRectangle(cornerRadius: RaceLayout.corner))
        HStack(spacing: 8) {
          Image(systemName: statusIcon)
          Text(statusTitle)
          Spacer(minLength: 0)
        }
        .font(RaceType.caption)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
          store.race.collisionRemaining > 0 ? Ink.red : Ink.paper,
          in: RoundedRectangle(cornerRadius: RaceLayout.corner)
        )
        .foregroundStyle(store.race.collisionRemaining > 0 ? Ink.cream : Ink.navy)
        .accessibilityIdentifier("raceStatus")
        Spacer()
        controls
      }
      .padding(.horizontal, 16).padding(.bottom, 8)
      .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
  }

  private func raceMetric(_ value: String, _ label: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(value)
        .font(RaceType.instrument).monospacedDigit()
      Text(label).font(RaceType.caption)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var statusTitle: String {
    if store.race.collisionRemaining > 0 { return "Road block hit · Recovering" }
    if store.race.attackRemaining > 0 { return "Slingshot · \(Int(store.race.speed * 3.6)) km/h" }
    if store.race.exhausted { return "Recover to 28% to sprint again" }
    if store.race.isSprinting { return "Sprinting · \(Int(store.race.speed * 3.6)) km/h" }
    if store.race.drafting { return "Drafting · Recovering energy" }
    if store.race.remaining < 100 {
      return "Final \(store.race.remaining) m · Sprint for the line"
    }
    if store.race.isBend {
      return "Bend ahead · \(store.race.insideLane == 0 ? "Left" : "Right") lane is faster"
    }
    return "Ride behind a rival to save energy"
  }

  private var statusIcon: String {
    if store.race.collisionRemaining > 0 { return "exclamationmark.triangle.fill" }
    if store.race.attackRemaining > 0 || store.race.isSprinting { return "bolt.fill" }
    return "wind"
  }

  private var controls: some View {
    VStack(spacing: 10) {
      HStack {
        Text(store.race.drafting ? "Energy · Recovering" : "Energy").font(RaceType.label)
        Spacer()
        Text("\(Int(store.race.energy))%").font(RaceType.label).monospacedDigit()
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
      Text(
        store.race.attackReady ? "Attack ready · Change lanes now" : "Draft to charge a slingshot"
      )
      .font(RaceType.caption)
      .foregroundStyle(store.race.attackReady ? Ink.butter : Ink.cream.opacity(0.78))
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityIdentifier("attackGuidance")
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
          ? "Tap Sprint to toggle · Swipe or tap arrows to steer"
          : "Hold Sprint · Swipe or tap arrows to steer"
      )
      .font(RaceType.caption)
      .foregroundStyle(Ink.cream.opacity(0.78))
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .foregroundStyle(Ink.cream)
    .padding(16)
    .background(Ink.navy, in: RoundedRectangle(cornerRadius: RaceLayout.corner))
  }

  private var sprintLabel: some View {
    HStack(spacing: 7) {
      Image(systemName: "bolt.fill")
      Text(store.race.exhausted ? "Recovering" : (store.race.isSprinting ? "Sprinting" : "Sprint"))
        .lineLimit(1).minimumScaleFactor(0.8)
    }
    .font(RaceType.action)
    .frame(maxWidth: .infinity).frame(height: RaceLayout.controlHeight)
    .background(
      store.race.exhausted ? Ink.road : Ink.red,
      in: RoundedRectangle(cornerRadius: RaceLayout.corner)
    )
    .overlay(
      RoundedRectangle(cornerRadius: RaceLayout.corner)
        .strokeBorder(Ink.cream.opacity(store.race.sprintHeld ? 0.8 : 0), lineWidth: 2)
    )
    .foregroundStyle(Ink.cream)
    .contentShape(RoundedRectangle(cornerRadius: RaceLayout.corner))
  }

  private func laneButton(_ direction: Int) -> some View {
    Button {
      store.move(direction)
    } label: {
      Image(systemName: direction < 0 ? "arrow.left" : "arrow.right")
        .font(.system(size: 19, weight: .medium))
        .frame(width: 54, height: RaceLayout.controlHeight)
        .background(
          Ink.cream.opacity(0.1), in: RoundedRectangle(cornerRadius: RaceLayout.corner)
        )
        .overlay(
          RoundedRectangle(cornerRadius: RaceLayout.corner).strokeBorder(Ink.cream.opacity(0.3)))
    }
    .disabled(store.race.lane + direction < 0 || store.race.lane + direction > 2)
    .accessibilityLabel(direction < 0 ? "Move left" : "Move right")
    .accessibilityIdentifier(direction < 0 ? "moveLeft" : "moveRight")
  }

  private var pauseOverlay: some View {
    overlayPanel {
      Text("Race paused").font(RaceType.title)
      Text("\(store.course.title) · \(store.race.remaining) m to finish")
        .font(RaceType.body)
      primary("Resume race", icon: "play.fill", id: "resumeRace") {
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
      Text("How to race").font(RaceType.title)
      guideRow(
        "01", "Pick your line",
        "Swipe the road or tap the arrows. The inside of a bend is a little faster.")
      guideRow(
        "02", "Draft behind a rival",
        "Sit behind a rival to refill energy. When charged, switch lane for a slingshot.")
      guideRow(
        "03", "Time your sprint",
        tapSprint
          ? "Tap Sprint to start or stop. Dodge striped road blocks and save energy for the finish."
          : "Hold Sprint. Release to recover. Dodge striped road blocks and save energy for the finish."
      )
      RaceRule()
      Toggle("Tap-to-toggle sprint", isOn: $tapSprint)
        .font(RaceType.label).tint(Ink.red)
        .accessibilityIdentifier("tutorialTapSprint")
      Text("Useful with a mouse or if holding is difficult.")
        .font(RaceType.caption)
      primary(
        store.screen == .racing ? "Start racing" : "Got it", icon: "arrow.right",
        id: "dismissTutorial"
      ) {
        store.coached = true
        store.showGuide = false
      }
    }
  }

  private func guideRow(_ number: String, _ title: String, _ subtitle: String) -> some View {
    HStack(alignment: .top, spacing: 13) {
      if !textSize.isAccessibilitySize {
        Text(number).font(RaceType.label).monospacedDigit()
          .frame(width: 28).foregroundStyle(Ink.red)
      }
      VStack(alignment: .leading, spacing: 3) {
        Text(title).font(RaceType.label)
        Text(subtitle).font(RaceType.body).fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private func overlayPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Ink.navy.opacity(0.68).ignoresSafeArea()
      ScrollView {
        VStack(alignment: .leading, spacing: 20, content: content)
          .padding(textSize.isAccessibilitySize ? 16 : 24)
          .background(Ink.paper, in: RoundedRectangle(cornerRadius: RaceLayout.corner))
          .padding(RaceLayout.gutter)
      }
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  private func resultView(_ result: RaceResult) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Text(result.headline).font(RaceType.title).tracking(-0.6)
        if textSize.isAccessibilitySize {
          Text(result.course.title).font(RaceType.heading)
          resultStat("Place", "\(ordinal(result.rank)) of 4")
          resultStat("Finish time", result.timeLabel)
          resultStat(
            result.rank == 1 ? "Winning gap" : "To winner",
            String(format: "%.2fs", abs(result.gap)))
        } else {
          RacePoster(result: result, compact: true)
            .frame(height: 330)
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
              "\(ordinal(result.rank)) place, \(result.timeLabel), gap \(result.gapLabel)")
        }
        RaceRule()
        adaptiveRow {
          resultStat("Drafting", String(format: "%.1fs", result.draftSeconds))
          resultStat("Slingshots", "\(result.attacks)")
          resultStat("Collisions", "\(result.collisions)")
        }
        RaceRule()
        primary("Race again", icon: "arrow.clockwise", id: "raceAgain") { store.start() }
        adaptiveRow {
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
            } else {
              shareFailed = true
            }
          } label: {
            Label("Share poster", systemImage: "square.and.arrow.up")
              .font(RaceType.label).frame(maxWidth: .infinity, minHeight: 48)
          }.accessibilityIdentifier("shareResult")
          Button {
            store.screen = .home
          } label: {
            Text("Choose route")
              .font(RaceType.label).frame(maxWidth: .infinity, minHeight: 48)
          }.accessibilityIdentifier("backHome")
        }
      }.padding(RaceLayout.gutter)
    }
    .accessibilityIdentifier("raceResults")
  }

  private func resultStat(_ title: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(title).font(RaceType.caption)
      Text(value).font(RaceType.heading).monospacedDigit()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .fixedSize(horizontal: false, vertical: true)
  }

  private func adaptiveRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    let layout =
      textSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: 18))
      : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
    return layout(content)
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
            ViewThatFits(in: .horizontal) {
              HStack {
                Text(course.title).fixedSize()
                Spacer()
                Text(store.best(for: course)?.timeLabel ?? "Not raced")
                  .monospacedDigit().fixedSize()
              }
              VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                Text(store.best(for: course)?.timeLabel ?? "Not raced").monospacedDigit()
              }
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
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { store.showSettings = false }.accessibilityIdentifier("closeSettings")
        }
      }
    }
  }

  private func primary(_ text: String, icon: String, id: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      HStack {
        Text(text)
        Spacer()
        Image(systemName: icon)
      }
      .font(RaceType.action)
      .padding(.horizontal, 18).padding(.vertical, 12)
      .frame(minHeight: RaceLayout.controlHeight)
      .background(Ink.red, in: RoundedRectangle(cornerRadius: RaceLayout.corner))
      .foregroundStyle(Ink.cream)
    }
    .accessibilityIdentifier(id)
  }

  private func secondary(_ text: String, id: String, action: @escaping () -> Void) -> some View {
    Button(text, action: action)
      .font(RaceType.action)
      .frame(maxWidth: .infinity, minHeight: 44)
      .accessibilityIdentifier(id)
  }

  private func ordinal(_ value: Int) -> String { ["", "1st", "2nd", "3rd", "4th"][value] }
}

struct RacePoster: View {
  let result: RaceResult
  var compact = false

  var body: some View {
    ZStack {
      CoastalCover()
      VStack(spacing: 0) {
        HStack(spacing: 10) {
          ClubEmblem(size: compact ? 24 : 36)
          Text("Pocket Peloton")
            .font(.system(size: compact ? 13 : 20, weight: .semibold))
          Spacer()
          RaceStripe()
        }
        .padding(compact ? 12 : 24)
        .background(Ink.paper)
        HStack(spacing: compact ? 16 : 28) {
          VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
              Text("\(result.rank)")
                .font(.system(size: compact ? 46 : 88, weight: .bold))
                .fontWidth(.condensed).monospacedDigit()
              Text("/ 4").font(.system(size: compact ? 14 : 22, weight: .medium))
            }
            Text("Place").font(.system(size: compact ? 12 : 18, weight: .medium))
          }
          Rectangle().fill(Ink.navy.opacity(0.2))
            .frame(width: 1, height: compact ? 56 : 96)
          VStack(alignment: .leading, spacing: compact ? 5 : 10) {
            Text(result.course.title)
              .font(.system(size: compact ? 22 : 36, weight: .bold)).tracking(-0.5)
              .fixedSize(horizontal: false, vertical: true)
            Text("\(Int(result.course.length)) m · Coastal series")
              .font(.system(size: compact ? 12 : 18, weight: .medium))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, compact ? 14 : 28).padding(.bottom, compact ? 14 : 28)
        .background(Ink.paper)
        Spacer(minLength: 16)
        HStack(alignment: .bottom, spacing: 12) {
          posterMetric("Finish time", result.timeLabel)
          Spacer(minLength: 0)
          posterMetric(
            result.rank == 1 ? "Winning gap" : "To winner",
            String(format: "%.2fs", abs(result.gap)))
        }
        .padding(compact ? 14 : 28)
        .foregroundStyle(Ink.cream).background(Ink.navy)
      }
    }
    .foregroundStyle(Ink.navy)
  }

  private func posterMetric(_ title: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.system(size: compact ? 12 : 18, weight: .medium))
      Text(value).font(.system(size: compact ? 26 : 44, weight: .semibold))
        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.85)
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
