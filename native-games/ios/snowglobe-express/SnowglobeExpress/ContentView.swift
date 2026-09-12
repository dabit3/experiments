import AVFoundation
import SwiftUI
import UIKit

struct ContentView: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        WinterBackdrop()
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
    }
    .sheet(item: $panel) { panel in
      panelView(panel)
        .preferredColorScheme(.light)
        .presentationDragIndicator(.visible)
        .presentationDetents(panel == .routes ? [.large] : [.medium, .large])
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
    ScrollView {
      VStack(spacing: 16) {
        HStack {
          HStack(spacing: 8) {
            Image(systemName: "shippingbox").font(.system(size: 12, weight: .light))
            eyebrow("THE WINTER POST")
          }
          Spacer()
          iconButton("gearshape", label: "Settings", id: "settings") { panel = .settings }
        }
        .padding(.top, 6)
        VStack(spacing: 3) {
          Text("Snowglobe")
            .font(.system(size: 49, weight: .regular, design: .serif))
            .tracking(-2)
          HStack(spacing: 16) {
            Rectangle().frame(width: 26, height: 0.5)
            Text("E X P R E S S")
              .font(.system(size: 10, weight: .medium))
              .tracking(3)
            Rectangle().frame(width: 26, height: 0.5)
          }
          .foregroundStyle(Winter.amber)
        }
        VillageArt(journey: Journey(puzzle: .routes[0]), illuminated: true, showsMarkers: false)
          .frame(width: min(size.width - 48, size.height * 0.48))
          .padding(.vertical, -10)
        VStack(spacing: 6) {
          Text("A little warmth, delivered.")
            .font(.system(size: 23, weight: .regular, design: .serif))
            .italic()
          Text("Clear the snow. Find a way home.")
            .font(.system(size: 12))
            .tracking(0.3)
            .foregroundStyle(Winter.powder)
        }
        .padding(.bottom, 6)
        primary(
          saved != nil ? "Continue your journey" : "Begin your journey", symbol: "arrow.right",
          id: "start"
        ) {
          if let saved {
            self.journey = saved
            selectAvailable(saved)
          } else {
            start(nextPuzzle)
          }
        }
        HStack(spacing: 18) {
          Button {
            panel = .routes
          } label: {
            VStack(alignment: .leading, spacing: 6) {
              eyebrow("THE COLLECTION")
              HStack {
                Text("Six village routes")
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 11))
              }
            }
            .frame(maxWidth: .infinity, minHeight: 48)
          }
          .accessibilityIdentifier("routes")
          Rectangle().fill(Winter.powder.opacity(0.2)).frame(width: 0.5, height: 30)
          Button {
            start(.daily())
          } label: {
            VStack(alignment: .leading, spacing: 6) {
              eyebrow("ONE QUIET CHALLENGE")
              HStack {
                Text("Daily dispatch")
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 11))
              }
            }
            .frame(maxWidth: .infinity, minHeight: 48)
          }
          .accessibilityIdentifier("daily")
        }
        .font(.system(size: 12, weight: .medium))
        .padding(.top, 3)
        .buttonStyle(.plain)
        Rectangle().fill(Winter.powder.opacity(0.18)).frame(height: 0.5)
        HStack(spacing: 7) {
          Image(systemName: "star.fill").foregroundStyle(Winter.amber)
          Text("\(totalStars) / 18 village stars")
          Text("·").padding(.horizontal, 3)
          Text("Collected with care")
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(Winter.powder.opacity(0.85))
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 20)
      .frame(maxWidth: 520)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
  }

  private func play(_ journey: Journey, size: CGSize) -> some View {
    let preview = journey.preview(selected)
    return ScrollView {
      VStack(spacing: 10) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 4) {
            eyebrow(
              journey.puzzle.id.hasPrefix("daily")
                ? "DAILY DISPATCH" : "VILLAGE ROUTE 0\(journey.puzzle.number)")
            Text(journey.puzzle.name)
              .font(.system(size: 28, weight: .regular, design: .serif))
              .tracking(-0.7)
          }
          Spacer()
          iconButton("questionmark", label: "How to play", id: "help") { panel = .tutorial }
          iconButton("pause.fill", label: "Pause route", id: "pause") { panel = .pause }
        }
        .padding(.top, 8)
        HStack(alignment: .center, spacing: 15) {
          HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text("\(journey.fuelLeft)")
              .font(.system(size: 29, weight: .regular, design: .serif))
              .foregroundStyle(journey.fuelLeft < 5 ? Winter.amber : Winter.cream)
              .contentTransition(.numericText())
            Text("/ \(journey.puzzle.fuel)")
              .font(.system(size: 12, weight: .light))
              .foregroundStyle(Winter.powder)
          }
          VStack(alignment: .leading, spacing: 6) {
            eyebrow("FUEL REMAINING")
            HStack(spacing: 3) {
              ForEach(0..<12) { index in
                Capsule()
                  .fill(
                    Double(index) / 12 < Double(journey.fuelLeft) / Double(journey.puzzle.fuel)
                      ? Winter.amber : Winter.powder.opacity(0.14)
                  )
                  .frame(width: 4, height: 9)
              }
            }
          }
          Spacer()
          HStack(spacing: 7) {
            ForEach(Array(journey.puzzle.homes.enumerated()), id: \.offset) { index, home in
              Group {
                if journey.position.delivered.contains(home.square) {
                  Image(systemName: "checkmark").font(.system(size: 10, weight: .semibold))
                } else {
                  Text("\(index + 1)").font(.system(size: 13, weight: .regular, design: .serif))
                }
              }
              .frame(width: 25, height: 25)
              .background(
                journey.position.delivered.contains(home.square)
                  ? Winter.amber.opacity(0.13) : .clear
              )
              .clipShape(Circle())
              .overlay(
                Circle().strokeBorder(
                  index == 0 && journey.position.delivered.isEmpty
                    ? Winter.cranberry : Winter.amber.opacity(0.45),
                  lineWidth: 0.7)
              )
              .foregroundStyle(
                journey.position.delivered.contains(home.square) ? Winter.amber : Winter.powder
              )
            }
          }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .top) {
          Rectangle().fill(Winter.powder.opacity(0.2)).frame(height: 0.5)
        }
        .overlay(alignment: .bottom) {
          Rectangle().fill(Winter.powder.opacity(0.2)).frame(height: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
          "\(journey.fuelLeft) fuel remaining. \(journey.position.delivered.count) of 3 parcels delivered."
        )
        VillageArt(journey: journey, selected: selected)
          .frame(width: min(size.width - 48, size.height * 0.45))
          .padding(.vertical, -8)
        Text(note)
          .font(.system(size: 12, weight: .regular, design: .serif))
          .italic()
          .foregroundStyle(Winter.powder)
          .multilineTextAlignment(.center)
          .frame(minHeight: 28)
          .accessibilityIdentifier("route-message")
        HStack(spacing: 18) {
          VStack(spacing: 5) {
            HStack(spacing: 5) {
              directionButton(.west, journey: journey)
              directionButton(.north, journey: journey)
            }
            HStack(spacing: 5) {
              directionButton(.south, journey: journey)
              directionButton(.east, journey: journey)
            }
          }
          .padding(6)
          .background(Winter.midnight.opacity(0.4), in: RoundedRectangle(cornerRadius: 28))
          .overlay(
            RoundedRectangle(cornerRadius: 28).strokeBorder(
              Winter.amber.opacity(0.2), lineWidth: 0.6))
          VStack(alignment: .leading, spacing: 6) {
            eyebrow("NEXT TURN · \(selected.rawValue.uppercased())")
            Text(preview.allowed ? "\(preview.cost) fuel" : "Lane blocked")
              .font(.system(size: 25, weight: .regular, design: .serif))
            Text(
              preview.reason
                ?? (preview.depth > 0
                  ? "Push \(preview.depth) snow ahead.\nLeave a clear lane behind."
                  : "A clear lane.\nOne quiet step closer.")
            )
            .font(.system(size: 11))
            .foregroundStyle(Winter.powder)
            .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 4)
        primary(
          preview.allowed ? "Drive \(selected.rawValue)" : "Choose another direction",
          symbol: "arrow.right", id: "drive", disabled: !preview.allowed
        ) { drive() }
        HStack {
          Button {
            undo()
          } label: {
            Label("Undo", systemImage: "arrow.uturn.backward")
              .frame(minHeight: 44)
          }
          .disabled(journey.history.isEmpty)
          .accessibilityIdentifier("undo")
          Spacer()
          Text("3 stars in ≤ \(journey.puzzle.par) fuel")
            .font(.system(size: 10))
            .foregroundStyle(Winter.powder)
          Spacer()
          Button {
            start(journey.puzzle, showTutorial: false)
          } label: {
            Image(systemName: "arrow.counterclockwise")
              .frame(width: 44, height: 44)
          }
          .accessibilityLabel("Restart route")
          .accessibilityIdentifier("restart")
        }
        .buttonStyle(.plain)
        .font(.system(size: 13, weight: .medium))
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 10)
      .frame(maxWidth: 520)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
  }

  private func results(_ journey: Journey, size: CGSize) -> some View {
    ScrollView {
      VStack(spacing: 14) {
        eyebrow(journey.won ? "EVERY PARCEL IS HOME" : "THE VILLAGE CAN WAIT")
          .padding(.top, 25)
        Text(journey.won ? "You brought\nwinter to life." : "A little short on fuel.")
          .font(.system(size: 39, weight: .regular, design: .serif))
          .tracking(-1.2)
          .multilineTextAlignment(.center)
          .accessibilityIdentifier("result-title")
        VillageArt(journey: journey, illuminated: journey.won, showsMarkers: false)
          .frame(width: min(size.width - 48, size.height * 0.43))
          .padding(.vertical, -10)
        if journey.won {
          stars(journey.stars, size: 20)
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(journey.score)")
              .font(.system(size: 47, weight: .regular, design: .serif))
            Text("EFFICIENCY POINTS")
              .font(.system(size: 9, weight: .medium))
              .tracking(1.2)
              .foregroundStyle(Winter.powder)
          }
          Text(
            "\(journey.position.moves) moves  ·  \(journey.position.fuelUsed) fuel used  ·  Best \(progress[journey.puzzle.id]?.score ?? journey.score)"
          )
          .font(.system(size: 12))
          .foregroundStyle(Winter.powder)
          primary("Send a winter postcard", symbol: "square.and.arrow.up", id: "share") {
            createShare(journey)
          }
          HStack(spacing: 20) {
            Button("Replay route") { start(journey.puzzle, showTutorial: false) }
              .accessibilityIdentifier("replay")
            if !journey.puzzle.id.hasPrefix("daily") && journey.puzzle.number < 6 {
              Button("Next village →") {
                start(.routes[journey.puzzle.number], showTutorial: false)
              }
              .accessibilityIdentifier("next-route")
            }
          }
          .frame(minHeight: 44)
        } else {
          Text("No affordable lane remains. Undo a turn,\nor begin again with a different path.")
            .font(.system(size: 14))
            .foregroundStyle(Winter.powder)
            .multilineTextAlignment(.center)
          primary("Try the route again", symbol: "arrow.counterclockwise", id: "retry") {
            start(journey.puzzle, showTutorial: false)
          }
          Button("Undo the last move") { undo() }
            .frame(minHeight: 44)
            .accessibilityIdentifier("undo-failure")
        }
        Button("Back to the snow globe") { goHome() }
          .foregroundStyle(Winter.powder)
          .frame(minHeight: 44)
          .accessibilityIdentifier("home")
      }
      .font(.system(size: 14, weight: .semibold))
      .buttonStyle(.plain)
      .padding(.horizontal, 24)
      .padding(.bottom, 15)
      .frame(maxWidth: 520)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
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
      HStack(spacing: 7) {
        Image(systemName: arrows[direction] ?? direction.symbol).font(
          .system(size: 15, weight: .semibold))
        Text(String(direction.title.prefix(1))).font(.system(size: 11, weight: .bold))
      }
      .frame(width: 58, height: 44)
      .background(
        selected == direction ? Winter.cream : Winter.powder.opacity(allowed ? 0.07 : 0.02)
      )
      .foregroundStyle(
        selected == direction
          ? Winter.midnight : allowed ? Winter.cream : Winter.powder.opacity(0.45)
      )
      .clipShape(RoundedRectangle(cornerRadius: 18))
      .overlay {
        RoundedRectangle(cornerRadius: 18).strokeBorder(Winter.powder.opacity(0.12), lineWidth: 0.5)
      }
    }
    .buttonStyle(DispatchButtonStyle())
    .accessibilityLabel("Preview \(direction.rawValue)")
    .accessibilityValue(
      selected == direction
        ? "Selected. \(journey.preview(direction).cost) fuel" : allowed ? "Available" : "Blocked"
    )
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
              .font(.system(size: 30, weight: .regular, design: .serif))
            Spacer()
            iconButton("xmark", label: "Close", id: "close-panel") { self.panel = nil }
          }
          switch panel {
          case .routes:
            Text("Six small villages. Eighteen little stars.\nReplay any route to use less fuel.")
              .font(.system(size: 14)).foregroundStyle(Winter.ink.opacity(0.75))
            ForEach(Puzzle.routes) { puzzle in
              Button {
                self.panel = nil
                start(puzzle)
              } label: {
                HStack(spacing: 16) {
                  Text(String(format: "%02d", puzzle.number))
                    .font(.system(size: 25, weight: .light, design: .serif))
                    .foregroundStyle(Winter.cranberry)
                  VStack(alignment: .leading, spacing: 5) {
                    Text(puzzle.name).font(.system(size: 17, weight: .semibold))
                    Text("\(puzzle.fuel) fuel · 3 stars in ≤ \(puzzle.par)")
                      .font(.system(size: 11)).foregroundStyle(Winter.ink.opacity(0.7))
                  }
                  Spacer()
                  stars(progress[puzzle.id]?.stars ?? 0, size: 10)
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
              "1", title: "The bakery gets the first parcel.",
              text: "Reach the red 1 home first. Then visit homes 2 and 3 in either order.")
            tutorialStep(
              "2", title: "Preview, then drive.",
              text:
                "N, E, S and W follow the diagonal lanes. Choose a direction; the gold tile shows your next stop."
            )
            tutorialStep(
              "3", title: "Snow goes one square ahead.",
              text:
                "Driving costs 1 fuel plus the snow depth. Drifts hold up to 3. Trees block pushes; snow at the village edge falls away."
            )
            Text("Undo is free. Every route is solvable. Save fuel for more stars.")
              .font(.system(size: 13, weight: .semibold))
            primary("Ready for the snow", symbol: "arrow.right", id: "tutorial-done") {
              learned = true
              self.panel = nil
            }
          case .pause:
            Text("The parcels are safe.\nTake a moment; winter is in no hurry.")
              .font(.system(size: 17, weight: .regular, design: .serif))
            primary("Back to the route", symbol: "play.fill", id: "resume") { self.panel = nil }
            if let journey {
              Button("Restart this route") {
                self.panel = nil
                start(journey.puzzle, showTutorial: false)
              }
              .frame(minHeight: 44).accessibilityIdentifier("pause-restart")
            }
            Button("Save & return home") { goHome() }
              .frame(minHeight: 44).accessibilityIdentifier("save-home")
          }
        }
        .padding(26)
        .padding(.top, 10)
        .foregroundStyle(Winter.ink)
        .tint(Winter.cranberry)
        .buttonStyle(.plain)
      }
    }
  }

  private func tutorialStep(_ number: String, title: String, text: String) -> some View {
    HStack(alignment: .top, spacing: 15) {
      Text(number)
        .font(.system(size: 17, weight: .bold, design: .rounded))
        .frame(width: 32, height: 32)
        .background(Winter.powder)
        .clipShape(Circle())
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.system(size: 16, weight: .semibold))
        Text(text).font(.system(size: 13)).foregroundStyle(Winter.ink.opacity(0.8))
      }
    }
  }

  private func panelTitle(_ panel: Panel) -> String {
    switch panel {
    case .routes: "The village routes"
    case .settings: "A quieter winter"
    case .tutorial: "Your first delivery"
    case .pause: "A moment of stillness"
    }
  }

  private func eyebrow(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 8, weight: .medium))
      .tracking(1.6)
      .foregroundStyle(Winter.amber)
  }

  private func stars(_ count: Int, size: CGFloat) -> some View {
    HStack(spacing: size * 0.25) {
      ForEach(0..<3) { index in
        Image(systemName: index < count ? "star.fill" : "star")
          .foregroundStyle(index < count ? Winter.amber : Winter.powder.opacity(0.5))
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
          .font(.system(size: 14, weight: .medium))
          .frame(width: 30, height: 30)
          .overlay(Circle().strokeBorder(Winter.ink.opacity(0.25), lineWidth: 0.6))
      }
      .font(.system(size: 15, weight: .medium))
      .padding(.leading, 24)
      .padding(.trailing, 13)
      .frame(minHeight: 56)
      .background {
        Capsule().fill(
          LinearGradient(
            colors: disabled
              ? [Winter.ink, Winter.ink]
              : [Winter.cream, Color(red: 0.86, green: 0.82, blue: 0.68)],
            startPoint: .topLeading, endPoint: .bottomTrailing))
      }
      .foregroundStyle(disabled ? Winter.powder : Winter.midnight)
      .overlay(Capsule().strokeBorder(.white.opacity(disabled ? 0.05 : 0.45), lineWidth: 0.7))
      .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
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
        ? "Every window is glowing. Beautifully delivered."
        : "A parcel delivered. A window comes to life."
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
        : "A clear lane behind you. A warm doorstep ahead."
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
        "A little warmth, delivered. \(journey.score) points in Snowglobe Express · \(journey.puzzle.name)."
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
      Text("Settle into the snowfall.").font(.system(size: 15))
      preference("Delivery chime", isOn: $sound, id: "sound-toggle")
      preference("Gentle haptics", isOn: $haptics, id: "haptics-toggle")
      Text(
        "Motion follows your iPhone’s Reduce Motion setting. Your stars and current route stay on this device."
      )
      .font(.system(size: 13)).foregroundStyle(Winter.ink.opacity(0.75))
      Button("How to play", action: showTutorial)
        .frame(minHeight: 44)
        .accessibilityIdentifier("settings-tutorial")
    }
  }

  private func preference(_ title: String, isOn: Binding<Bool>, id: String) -> some View {
    HStack {
      Text(title)
      Spacer()
      Picker(title, selection: isOn) {
        Text("Off").tag(false)
        Text("On").tag(true)
      }
      .pickerStyle(.segmented)
      .frame(width: 130)
      .accessibilityIdentifier(id)
    }
    .frame(minHeight: 44)
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
      VStack(spacing: 14) {
        Text("THE WINTER POST  /  SNOWGLOBE EXPRESS")
          .font(.system(size: 8, weight: .medium)).tracking(1.5).foregroundStyle(Winter.amber)
        Text("A little warmth,\ndelivered.")
          .font(.system(size: 39, weight: .regular, design: .serif))
          .tracking(-0.8)
          .multilineTextAlignment(.center)
        VillageArt(journey: journey, illuminated: true, animate: false).frame(width: 370)
          .padding(.vertical, -14)
        Rectangle().fill(Winter.amber.opacity(0.4)).frame(width: 300, height: 0.5)
        Text("\(journey.score) efficiency points")
          .font(.system(size: 26, weight: .regular, design: .serif))
        Text("\(journey.puzzle.name) · \(journey.position.fuelUsed) fuel · \(journey.stars) stars")
          .font(.system(size: 12)).foregroundStyle(Winter.powder)
        Text("A village worth keeping.").font(.system(size: 14, weight: .regular, design: .serif))
          .italic()
          .padding(.top, 12)
      }
      .foregroundStyle(Winter.cream)
    }
    .frame(width: 390, height: 660)
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
