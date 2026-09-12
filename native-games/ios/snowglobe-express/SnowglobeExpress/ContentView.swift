import AVFoundation
import SwiftUI
import UIKit

struct ContentView: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.dynamicTypeSize) private var typeSize
  @AppStorage("village.sound") private var sound = true
  @AppStorage("village.haptics") private var haptics = true
  @AppStorage("village.learned") private var learned = false
  @State private var journey: Journey?
  @State private var saved: Journey? = LocalStore().resume()
  @State private var progress = LocalStore().loadProgress()
  @State private var selected: Direction = .north
  @State private var panel: Panel?
  @State private var note = "Choose a direction to preview your next move."
  @State private var sharedPostcard: SharedPostcard?
  @State private var shareFailed = false
  @State private var chime: AVAudioPlayer?
  private let store = LocalStore()

  enum Panel: String, Identifiable {
    case routes, settings, tutorial, pause
    var id: String { rawValue }
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        if let journey {
          if journey.won || journey.stranded {
            results(journey, size: geometry.size)
          } else {
            play(journey, size: geometry.size)
          }
        } else {
          home(size: geometry.size)
        }
      }
      .foregroundStyle(Winter.cream)
      .clipped()
      .background { WinterBackdrop() }
    }
    .sheet(item: $panel) { panel in
      panelView(panel)
        .preferredColorScheme(.light)
        .presentationDragIndicator(.visible)
        .presentationDetents(
          panel == .routes || panel == .tutorial ? [.large] : [.medium, .large])
    }
    .sheet(item: $sharedPostcard) { postcard in
      ActivitySheet(image: postcard.image, text: postcard.text)
    }
    .alert("The postcard couldn’t be prepared.", isPresented: $shareFailed) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Your result is safe. Please try sharing again.")
    }
    .onChange(of: scenePhase) { _, phase in
      if let journey {
        store.save(journey)
        if phase != .active && !journey.won && panel == nil { panel = .pause }
      }
    }
  }

  private func home(size: CGSize) -> some View {
    let current = saved ?? Journey(puzzle: nextPuzzle)
    let wide = size.width >= DispatchLayout.wideThreshold
    return ScrollView {
      VStack(spacing: 16) {
        HStack {
          Text("Snowglobe Express").font(DispatchType.title)
          Spacer()
          iconButton("gearshape", label: "Settings", id: "settings") { panel = .settings }
        }
        .padding(.top, 6)
        if wide {
          HStack(spacing: 32) {
            VillageArt(journey: current, showsMarkers: false)
              .frame(width: min(size.width * 0.48, 510))
            VStack(alignment: .leading, spacing: 20) {
              routeBriefing(current)
              startButton
              routeChoices
            }
            .frame(maxWidth: 400)
          }
        } else {
          routeBriefing(current)
          VillageArt(journey: current, showsMarkers: false)
            .frame(width: min(size.width - 48, size.height * 0.42))
          startButton
          routeChoices
        }
      }
      .padding(.horizontal, DispatchLayout.gutter)
      .padding(.bottom, 20)
      .frame(maxWidth: wide ? DispatchLayout.maxWidth : 520)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
  }

  private func routeBriefing(_ current: Journey) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      metadata(
        saved == nil ? "Your next delivery · \(routeLabel(current.puzzle))" : "Route in progress")
      Text(current.puzzle.name).font(DispatchType.heading)
      Text(
        saved == nil
          ? "\(current.puzzle.fuel) fuel · Deliver to the bakery first"
          : "\(current.fuelLeft) fuel left · \(current.position.delivered.count) of 3 delivered"
      )
      .font(DispatchType.body)
      .foregroundStyle(Winter.powder)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var startButton: some View {
    primary(saved != nil ? "Resume route" : "Start route", symbol: "arrow.right", id: "start") {
      if let saved {
        self.journey = saved
        selectAvailable(saved)
        note = "Route resumed. Choose a direction to preview."
      } else {
        start(nextPuzzle)
      }
    }
  }

  private var routeChoices: some View {
    let daily = Puzzle.daily()
    let key = daily.id.dropFirst(6)
    let date = "\(key.prefix(4))-\(key.dropFirst(4).prefix(2))-\(key.suffix(2)) UTC"
    let best = progress[daily.id].map { "Best \($0.score) points" } ?? "Not played"
    return VStack(spacing: 0) {
      rule
      navigationRow(
        "Village routes",
        detail: totalStars == 0
          ? "6 routes · Earn stars by saving fuel" : "6 routes · \(totalStars) of 18 stars",
        id: "routes"
      ) { panel = .routes }
      rule
      navigationRow(
        "Daily dispatch",
        detail: "\(date) · \(best)",
        id: "daily"
      ) { start(daily) }
    }
  }

  private func navigationRow(
    _ title: String, detail: String, id: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 5) {
          Text(title).font(DispatchType.heading)
          Text(detail).font(DispatchType.caption).foregroundStyle(Winter.powder)
        }
        Spacer(minLength: 0)
        Image(systemName: "chevron.right").font(DispatchType.label)
      }
      .padding(.vertical, 16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(DispatchButtonStyle())
    .accessibilityIdentifier(id)
  }

  private func routeLabel(_ puzzle: Puzzle) -> String {
    puzzle.id.hasPrefix("daily") ? "Daily dispatch" : "Route \(puzzle.number) of 6"
  }

  private func play(_ journey: Journey, size: CGSize) -> some View {
    let wide = size.width >= DispatchLayout.wideThreshold
    return ScrollView {
      VStack(spacing: 12) {
        HStack(spacing: 8) {
          VStack(alignment: .leading, spacing: 4) {
            metadata(routeLabel(journey.puzzle))
            Text(journey.puzzle.name).font(DispatchType.title)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          iconButton("questionmark", label: "How to play", id: "help") { panel = .tutorial }
          iconButton("pause.fill", label: "Pause route", id: "pause") { panel = .pause }
        }
        .padding(.top, 8)
        if wide {
          HStack(spacing: 32) {
            VillageArt(journey: journey, selected: selected)
              .frame(width: min(size.width * 0.48, 510))
            VStack(spacing: 16) {
              routeStatus(journey)
              playControls(journey)
            }
            .frame(maxWidth: 400)
          }
        } else {
          routeStatus(journey)
          VillageArt(journey: journey, selected: selected)
            .frame(width: min(size.width - 48, size.height * 0.42))
          playControls(journey)
        }
      }
      .padding(.horizontal, DispatchLayout.gutter)
      .padding(.bottom, 12)
      .frame(maxWidth: wide ? DispatchLayout.maxWidth : 520)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
  }

  private func routeStatus(_ journey: Journey) -> some View {
    VStack(spacing: 10) {
      rule
      HStack(alignment: .top, spacing: 24) {
        VStack(alignment: .leading, spacing: 5) {
          metadata("Fuel left")
          HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text("\(journey.fuelLeft)")
              .font(DispatchType.number).monospacedDigit()
              .foregroundStyle(journey.fuelLeft < 5 ? Winter.amber : Winter.cream)
              .contentTransition(.numericText())
            Text("/ \(journey.puzzle.fuel)")
              .font(DispatchType.body).foregroundStyle(Winter.powder)
          }
          ProgressView(value: Double(journey.fuelLeft), total: Double(journey.puzzle.fuel))
            .tint(Winter.amber)
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        VStack(alignment: .leading, spacing: 5) {
          metadata("Parcels delivered")
          Text("\(journey.position.delivered.count) / \(journey.puzzle.homes.count)")
            .font(DispatchType.number).monospacedDigit()
          Text(journey.position.delivered.isEmpty ? "Bakery first" : "Remaining homes in any order")
            .font(DispatchType.caption)
            .foregroundStyle(Winter.powder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .accessibilityElement(children: .combine)
      rule
    }
  }

  private func playControls(_ journey: Journey) -> some View {
    let preview = journey.preview(selected)
    let layout =
      typeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
      : AnyLayout(HStackLayout(alignment: .center, spacing: 20))
    return VStack(spacing: 12) {
      layout {
        VStack(spacing: 8) {
          HStack(spacing: 8) {
            directionButton(.west, journey: journey)
            directionButton(.north, journey: journey)
          }
          HStack(spacing: 8) {
            directionButton(.south, journey: journey)
            directionButton(.east, journey: journey)
          }
        }
        .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : 148)
        VStack(alignment: .leading, spacing: 5) {
          metadata("Preview · \(selected.title)")
          Text(preview.allowed ? "\(preview.cost) fuel" : "Lane blocked")
            .font(DispatchType.heading).monospacedDigit()
          Text(
            preview.reason
              ?? (preview.depth > 0 ? "Push \(preview.depth) snow ahead" : "Clear lane")
          )
          .font(DispatchType.caption)
          .foregroundStyle(Winter.powder)
          .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      primary(
        preview.allowed ? "Drive \(selected.rawValue)" : "Choose another direction",
        symbol: "arrow.right", id: "drive", disabled: !preview.allowed
      ) { drive() }
      Text(note)
        .font(DispatchType.caption)
        .foregroundStyle(Winter.powder)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("route-message")
      HStack(spacing: 12) {
        Button {
          undo()
        } label: {
          Label("Undo", systemImage: "arrow.uturn.backward")
            .frame(minHeight: 44)
        }
        .disabled(journey.history.isEmpty)
        .opacity(journey.history.isEmpty ? 0.45 : 1)
        .accessibilityIdentifier("undo")
        Spacer(minLength: 0)
        Text("3 stars: ≤ \(journey.puzzle.par) fuel")
          .font(DispatchType.caption)
          .foregroundStyle(Winter.powder)
        iconButton("arrow.counterclockwise", label: "Restart route", id: "restart") {
          start(journey.puzzle, showTutorial: false)
        }
      }
      .buttonStyle(.plain)
      .font(DispatchType.label)
    }
  }

  private func results(_ journey: Journey, size: CGSize) -> some View {
    let wide = size.width >= DispatchLayout.wideThreshold
    return ScrollView {
      VStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 5) {
          metadata(journey.puzzle.name)
          Text(journey.won ? "Village delivered" : "No moves left")
            .font(DispatchType.title)
            .accessibilityIdentifier("result-title")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 24)
        if wide {
          HStack(spacing: 32) {
            VillageArt(journey: journey, illuminated: journey.won, showsMarkers: false)
              .frame(width: min(size.width * 0.48, 510))
            resultDetails(journey).frame(maxWidth: 400)
          }
        } else {
          VillageArt(journey: journey, illuminated: journey.won, showsMarkers: false)
            .frame(width: min(size.width - 48, size.height * 0.42))
          resultDetails(journey)
        }
      }
      .padding(.horizontal, DispatchLayout.gutter)
      .padding(.bottom, 16)
      .frame(maxWidth: wide ? DispatchLayout.maxWidth : 520)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
  }

  private func resultDetails(_ journey: Journey) -> some View {
    VStack(spacing: 12) {
      if journey.won {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 0) {
            Text("\(journey.score)").font(DispatchType.score).monospacedDigit()
            metadata("Efficiency points")
          }
          Spacer()
          stars(journey.stars, size: 20)
        }
        rule
        resultRow("Fuel used", value: "\(journey.position.fuelUsed) of \(journey.puzzle.fuel)")
        resultRow("Moves", value: "\(journey.position.moves)")
        resultRow("Personal best", value: "\(progress[journey.puzzle.id]?.score ?? journey.score)")
        Text("3 stars: use \(journey.puzzle.par) fuel or less")
          .font(DispatchType.caption).foregroundStyle(Winter.powder)
          .frame(maxWidth: .infinity, alignment: .leading)
        if !journey.puzzle.id.hasPrefix("daily") && journey.puzzle.number < 6 {
          primary("Next route", symbol: "arrow.right", id: "next-route") {
            start(.routes[journey.puzzle.number], showTutorial: false)
          }
          Button("Replay route") { start(journey.puzzle, showTutorial: false) }
            .frame(minHeight: 44).accessibilityIdentifier("replay")
        } else {
          primary("Replay route", symbol: "arrow.counterclockwise", id: "replay") {
            start(journey.puzzle, showTutorial: false)
          }
        }
        Button {
          createShare(journey)
        } label: {
          Label("Share postcard", systemImage: "square.and.arrow.up")
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .accessibilityIdentifier("share")
      } else {
        Text("No affordable lane remains. Undo a move or retry with a different route.")
          .font(DispatchType.body).foregroundStyle(Winter.powder)
          .frame(maxWidth: .infinity, alignment: .leading)
        primary("Retry route", symbol: "arrow.counterclockwise", id: "retry") {
          start(journey.puzzle, showTutorial: false)
        }
        Button("Undo last move") { undo() }
          .frame(minHeight: 44).accessibilityIdentifier("undo-failure")
      }
      Button("Back to routes") { goHome() }
        .foregroundStyle(Winter.powder)
        .frame(minHeight: 44).accessibilityIdentifier("home")
    }
    .font(DispatchType.label)
    .buttonStyle(.plain)
  }

  private func resultRow(_ title: String, value: String) -> some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title).foregroundStyle(Winter.powder)
      Spacer()
      Text(value).monospacedDigit()
    }
    .font(DispatchType.body)
    .accessibilityElement(children: .combine)
  }

  private func directionButton(_ direction: Direction, journey: Journey) -> some View {
    let allowed = journey.preview(direction).allowed
    let arrows: [Direction: String] = [
      .north: "arrow.up.right", .east: "arrow.down.right",
      .south: "arrow.down.left", .west: "arrow.up.left",
    ]
    return Button {
      selected = direction
    } label: {
      HStack(spacing: 6) {
        Image(systemName: arrows[direction] ?? direction.symbol)
          .font(.system(size: 18, weight: .semibold))
        Text(String(direction.title.prefix(1))).font(DispatchType.label)
      }
      .frame(maxWidth: .infinity, minHeight: 50)
      .background(selected == direction ? Winter.cream : Winter.ink)
      .foregroundStyle(
        selected == direction
          ? Winter.midnight : allowed ? Winter.cream : Winter.powder.opacity(0.65)
      )
      .clipShape(RoundedRectangle(cornerRadius: DispatchLayout.corner))
    }
    .buttonStyle(DispatchButtonStyle())
    .accessibilityLabel("Preview \(direction.rawValue)")
    .accessibilityValue(
      selected == direction
        ? (allowed ? "Selected. \(journey.preview(direction).cost) fuel" : "Selected. Blocked")
        : allowed ? "\(journey.preview(direction).cost) fuel" : "Blocked"
    )
    .accessibilityAddTraits(selected == direction ? .isSelected : [])
    .accessibilityIdentifier("direction-\(direction.rawValue)")
  }

  @ViewBuilder
  private func panelView(_ panel: Panel) -> some View {
    ZStack {
      Winter.cream.ignoresSafeArea()
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          HStack {
            Text(panelTitle(panel))
              .font(DispatchType.title)
            Spacer()
            iconButton("xmark", label: "Close", id: "close-panel") { self.panel = nil }
          }
          switch panel {
          case .routes:
            Text("Replay any route to save fuel and earn more stars.")
              .font(DispatchType.body).foregroundStyle(Winter.ink)
            ForEach(Puzzle.routes) { puzzle in
              Button {
                self.panel = nil
                start(puzzle)
              } label: {
                HStack(spacing: 16) {
                  Text(String(format: "%02d", puzzle.number))
                    .font(DispatchType.number).monospacedDigit()
                    .foregroundStyle(Winter.cranberry)
                  VStack(alignment: .leading, spacing: 5) {
                    Text(puzzle.name).font(DispatchType.heading)
                    Text("\(puzzle.fuel) fuel · 3 stars in ≤ \(puzzle.par)")
                      .font(DispatchType.caption).foregroundStyle(Winter.ink)
                  }
                  Spacer()
                  stars(progress[puzzle.id]?.stars ?? 0, size: 12, onLight: true)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
              }
              .accessibilityIdentifier("route-\(puzzle.number)")
              Divider()
            }
          case .settings:
            SettingsControls { self.panel = .tutorial }
          case .tutorial:
            tutorialStep(
              "1", title: "Deliver to the bakery first",
              text: "Reach the red 1 home first. Then visit homes 2 and 3 in either order.")
            tutorialStep(
              "2", title: "Preview, then drive",
              text:
                "N, E, S and W follow the diagonal lanes. Choose a direction; the gold tile shows your next stop."
            )
            tutorialStep(
              "3", title: "Push snow one square ahead",
              text:
                "Driving costs 1 fuel plus the snow depth. Drifts hold up to 3. Trees block pushes; snow at the village edge falls away."
            )
            Text("Undo is free. Every route is solvable. Save fuel for more stars.")
              .font(DispatchType.label)
            primary("Got it", symbol: "arrow.right", id: "tutorial-done") {
              learned = true
              self.panel = nil
            }
          case .pause:
            Text("Your route is saved on this device.").font(DispatchType.body)
            primary("Resume route", symbol: "play.fill", id: "resume") { self.panel = nil }
            if let journey {
              Button("Restart this route") {
                self.panel = nil
                start(journey.puzzle, showTutorial: false)
              }
              .frame(minHeight: 44).accessibilityIdentifier("pause-restart")
            }
            Button("Save & return to routes") { goHome() }
              .frame(minHeight: 44).accessibilityIdentifier("save-home")
          }
        }
        .padding(26)
        .padding(.top, 10)
        .font(DispatchType.body)
        .foregroundStyle(Winter.ink)
        .tint(Winter.cranberry)
        .buttonStyle(.plain)
      }
    }
  }

  private func tutorialStep(_ number: String, title: String, text: String) -> some View {
    HStack(alignment: .top, spacing: 15) {
      Text(number)
        .font(DispatchType.number)
        .foregroundStyle(Winter.cranberry)
        .frame(width: 32)
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(DispatchType.heading)
        Text(text).font(DispatchType.body).foregroundStyle(Winter.ink)
      }
    }
  }

  private func panelTitle(_ panel: Panel) -> String {
    switch panel {
    case .routes: "Village routes"
    case .settings: "Settings"
    case .tutorial: "How to deliver"
    case .pause: "Route paused"
    }
  }

  private func metadata(_ text: String) -> some View {
    Text(text)
      .font(DispatchType.caption)
      .foregroundStyle(Winter.powder)
  }

  private var rule: some View {
    Rectangle().fill(Winter.powder.opacity(0.24)).frame(height: 1)
  }

  private func stars(_ count: Int, size: CGFloat, onLight: Bool = false) -> some View {
    HStack(spacing: size * 0.25) {
      ForEach(0..<3) { index in
        Image(systemName: index < count ? "star.fill" : "star")
          .foregroundStyle(
            index < count
              ? (onLight ? Winter.cranberry : Winter.amber)
              : (onLight ? Winter.ink.opacity(0.65) : Winter.powder))
      }
    }
    .font(.system(size: size))
    .accessibilityLabel("\(count) stars")
  }

  private func iconButton(_ symbol: String, label: String, id: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 16, weight: .medium))
        .frame(width: 44, height: 44)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
    .accessibilityIdentifier(id)
  }

  private func primary(
    _ title: String, symbol: String, id: String, disabled: Bool = false,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack {
        Text(title)
        Spacer()
        Image(systemName: symbol)
          .font(DispatchType.label)
      }
      .font(DispatchType.heading)
      .padding(.horizontal, 18)
      .padding(.vertical, 14)
      .frame(minHeight: 52)
      .background(disabled ? Winter.ink : Winter.cranberry)
      .foregroundStyle(disabled ? Winter.powder : Winter.cream)
      .clipShape(RoundedRectangle(cornerRadius: DispatchLayout.corner))
    }
    .buttonStyle(DispatchButtonStyle())
    .disabled(disabled)
    .accessibilityIdentifier(id)
  }

  private var totalStars: Int {
    Puzzle.routes.reduce(0) { $0 + (progress[$1.id]?.stars ?? 0) }
  }

  private var nextPuzzle: Puzzle {
    Puzzle.routes.first { progress[$0.id]?.stars ?? 0 == 0 } ?? .routes[0]
  }

  private func start(_ puzzle: Puzzle, showTutorial: Bool = true) {
    let value = Journey(puzzle: puzzle)
    journey = value
    store.save(value)
    saved = value
    selected = .north
    note = "First stop: the bakery, marked with a red 1."
    if !learned && showTutorial { panel = .tutorial }
  }

  private func selectAvailable(_ journey: Journey) {
    selected = Direction.allCases.first { journey.preview($0).allowed } ?? .north
  }

  private func drive() {
    guard var value = journey else { return }
    let previous = value.position.delivered.count
    guard value.move(selected) else { return }
    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { journey = value }
    if value.position.delivered.count > previous {
      note =
        value.won
        ? "All three parcels delivered."
        : "Parcel delivered. Visit the remaining homes in any order."
      feedback(delivered: true)
    } else if value.puzzle.homes.contains(where: { $0.square == value.position.van && !$0.priority }
    )
      && value.position.delivered.isEmpty
    {
      note = "The bakery needs its parcel first. Come back after stop 1."
      feedback(delivered: false)
    } else {
      note =
        value.fuelLeft < 5
        ? "Fuel is low. Preview carefully; undo is always free."
        : "Move complete. Preview your next direction."
      feedback(delivered: false)
    }
    store.save(value)
    saved = value
    if value.won {
      store.record(value)
      progress = store.loadProgress()
    }
  }

  private func undo() {
    guard var value = journey else { return }
    value.undo()
    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { journey = value }
    store.save(value)
    saved = value
    note = "One turn back. Snow, parcels and fuel restored."
    selectAvailable(value)
  }

  private func goHome() {
    panel = nil
    if let journey, !journey.won {
      saved = journey
      store.save(journey)
    } else {
      saved = nil
      store.save(nil)
    }
    self.journey = nil
  }

  private func feedback(delivered: Bool) {
    if haptics {
      if delivered {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
      } else {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      }
    }
    if delivered && sound, let url = Bundle.main.url(forResource: "delivery", withExtension: "wav")
    {
      try? AVAudioSession.sharedInstance().setCategory(.ambient)
      chime = try? AVAudioPlayer(contentsOf: url)
      chime?.play()
    }
  }

  @MainActor
  private func createShare(_ journey: Journey) {
    let renderer = ImageRenderer(content: Postcard(journey: journey))
    renderer.scale = 3
    guard let image = renderer.uiImage else {
      shareFailed = true
      return
    }
    sharedPostcard = SharedPostcard(
      image: image,
      text:
        "Village delivered. \(journey.score) points in Snowglobe Express · \(journey.puzzle.name)."
    )
  }
}

private struct DispatchButtonStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.82 : 1)
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
      .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
  }
}

private struct SettingsControls: View {
  @AppStorage("village.sound") private var sound = true
  @AppStorage("village.haptics") private var haptics = true
  let showTutorial: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      preference("Delivery chime", isOn: $sound, id: "sound-toggle")
      Divider()
      preference("Haptics", isOn: $haptics, id: "haptics-toggle")
      Divider()
      Text(
        "Motion follows your device’s Reduce Motion setting. Stars and the current route are saved on this device."
      )
      .font(DispatchType.caption).foregroundStyle(Winter.ink)
      Button("How to play", action: showTutorial)
        .frame(minHeight: 44)
        .accessibilityIdentifier("settings-tutorial")
    }
  }

  private func preference(_ title: String, isOn: Binding<Bool>, id: String) -> some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 16) {
        Text(title).fixedSize()
        Spacer()
        preferencePicker(title, isOn: isOn, id: id)
      }
      VStack(alignment: .leading, spacing: 10) {
        Text(title)
        preferencePicker(title, isOn: isOn, id: id)
      }
    }
    .font(DispatchType.body)
    .frame(minHeight: 44)
  }

  private func preferencePicker(_ title: String, isOn: Binding<Bool>, id: String) -> some View {
    Picker(title, selection: isOn) {
      Text("Off").tag(false)
      Text("On").tag(true)
    }
    .pickerStyle(.segmented)
    .frame(width: 130)
    .accessibilityIdentifier(id)
  }
}

struct SharedPostcard: Identifiable {
  let id = UUID()
  let image: UIImage
  let text: String
}

struct Postcard: View {
  let journey: Journey
  var body: some View {
    ZStack {
      WinterBackdrop()
      VStack(spacing: 16) {
        Text("Snowglobe Express").font(DispatchType.heading)
          .foregroundStyle(Winter.powder)
        Text("Village delivered").font(DispatchType.title)
        VillageArt(journey: journey, illuminated: true, animate: false).frame(width: 370)
          .padding(.vertical, -14)
        HStack(spacing: 6) {
          ForEach(0..<3) { index in
            Image(systemName: index < journey.stars ? "star.fill" : "star")
          }
        }
        .font(DispatchType.heading).foregroundStyle(Winter.amber)
        Text("\(journey.score) efficiency points")
          .font(DispatchType.number).monospacedDigit()
        Text(journey.puzzle.name).font(DispatchType.heading)
        Text("\(journey.position.moves) moves · \(journey.position.fuelUsed) fuel used")
          .font(DispatchType.body).foregroundStyle(Winter.powder)
      }
      .foregroundStyle(Winter.cream)
    }
    .frame(width: 390, height: 660)
    .dynamicTypeSize(.large)
  }
}

struct ActivitySheet: UIViewControllerRepresentable {
  let image: UIImage
  let text: String
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
  }
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
